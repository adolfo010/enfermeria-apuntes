from __future__ import annotations

import argparse
import hashlib
import os
import tempfile
import time
from pathlib import Path

import requests
from openai import OpenAI
from google import genai
from google.genai import types
from pypdf import PdfReader, PdfWriter
import fitz
import re

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
GOOGLE_ACCESS_TOKEN = os.environ.get("GOOGLE_ACCESS_TOKEN", "")
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "")
OPENAI_MODEL = os.environ.get("OPENAI_MODEL", "gpt-5.6-luna")
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-3.8-flash")
AI_PROVIDER = os.environ.get("AI_PROVIDER", "openai").lower()
KNOWLEDGE_USER_ID = os.environ.get("KNOWLEDGE_USER_ID", "")
DEFAULT_CHUNK_PAGES = 3


def require_env() -> None:
    required = [
        ("SUPABASE_URL", SUPABASE_URL),
        ("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY),
        ("KNOWLEDGE_USER_ID", KNOWLEDGE_USER_ID),
    ]
    if AI_PROVIDER == "gemini":
        required.append(("GEMINI_API_KEY", GEMINI_API_KEY))
    elif AI_PROVIDER == "openai":
        required.append(("OPENAI_API_KEY", OPENAI_API_KEY))
    else:
        raise SystemExit(f"Proveedor de IA no soportado: {AI_PROVIDER}")
    missing = [name for name, value in required if not value]
    if missing:
        raise SystemExit("Faltan secretos: " + ", ".join(missing))


def supabase_request(path: str, method: str = "GET", body: object | None = None, headers: dict | None = None):
    merged = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
    }
    if headers:
        merged.update(headers)
    response = requests.request(
        method,
        f"{SUPABASE_URL}/rest/v1/{path}",
        headers=merged,
        json=body,
        timeout=(30, 120),
    )
    response.raise_for_status()
    return response


def google_access_token() -> str:
    if GOOGLE_ACCESS_TOKEN:
        return GOOGLE_ACCESS_TOKEN

    rows = supabase_request(
        "oauth_tokens?id=eq.rossana&select=access_token,expires_at&limit=1"
    ).json()

    if not rows or not rows[0].get("access_token"):
        raise RuntimeError(
            "No hay access token de Google disponible en oauth_tokens para rossana."
        )

    expires_at = rows[0].get("expires_at")
    if expires_at:
        try:
            from datetime import datetime, timezone
            expires = datetime.fromisoformat(str(expires_at).replace("Z", "+00:00"))
            if expires <= datetime.now(timezone.utc):
                refresh_url = f"{SUPABASE_URL}/functions/v1/oauth/refresh"
                refresh_res = requests.post(
                    refresh_url,
                    headers={
                        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
                        "apikey": SUPABASE_SERVICE_ROLE_KEY,
                        "Content-Type": "application/json",
                    },
                    timeout=(30, 60),
                )
                if not refresh_res.ok:
                    raise RuntimeError(
                        f"Google OAuth refresh failed (HTTP {refresh_res.status_code}): {refresh_res.text[:2000]}"
                    )
                refreshed = refresh_res.json()
                if not refreshed.get("access_token"):
                    raise RuntimeError("La renovación de Google no devolvió un access token.")
                return refreshed["access_token"]
        except ValueError:
            pass

    return rows[0]["access_token"]


def drive_meta(file_id: str) -> dict:
    response = requests.get(
        f"https://www.googleapis.com/drive/v3/files/{file_id}",
        params={"fields": "id,name,mimeType,size,modifiedTime,md5Checksum"},
        headers={"Authorization": f"Bearer {GOOGLE_ACCESS_TOKEN}"},
        timeout=(30, 60),
    )
    response.raise_for_status()
    return response.json()


def drive_download(file_id: str, destination: Path) -> None:
    with requests.get(
        f"https://www.googleapis.com/drive/v3/files/{file_id}",
        params={"alt": "media"},
        headers={"Authorization": f"Bearer {GOOGLE_ACCESS_TOKEN}"},
        stream=True,
        timeout=(30, 600),
    ) as response:
        response.raise_for_status()
        with destination.open("wb") as fh:
            for part in response.iter_content(chunk_size=1024 * 1024):
                if part:
                    fh.write(part)


def write_chunk(reader: PdfReader, start: int, end: int, output: Path) -> None:
    writer = PdfWriter()
    for index in range(start, end):
        writer.add_page(reader.pages[index])
    with output.open("wb") as fh:
        writer.write(fh)


def content_hash(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def normalize(value: str) -> str:
    import unicodedata
    value = unicodedata.normalize("NFD", str(value or ""))
    value = "".join(ch for ch in value if unicodedata.category(ch) != "Mn")
    return " ".join("".join(ch if ch.isalnum() or ch.isspace() else " " for ch in value.lower()).split())


def extraction_schema() -> dict:
    return {
        "type": "object",
        "properties": {
            "pages": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "page": {"type": "integer"},
                        "content": {"type": "string"},
                    },
                    "required": ["page", "content"],
                    "additionalProperties": False,
                },
            },
        },
        "required": ["pages"],
        "additionalProperties": False,
    }


def extraction_prompt(page_start: int, page_end: int) -> str:
    return (
        "Extraé el contenido académico de estas páginas para una base de conocimiento. "
        "Conservá definiciones, explicaciones, relaciones, listas y datos relevantes. "
        "NO resumas, NO agregues conocimiento externo y NO inventes contenido. "
        "Devolvé exclusivamente JSON con pages; cada elemento debe tener page "
        "(número de página original) y content (texto académico de esa página). "
        f"Las páginas originales son {page_start}-{page_end}. "
        f"Los valores permitidos para page son exactamente los números {page_start}-{page_end}, "
        "uno por cada página del bloque. "
        "Si una página no contiene contenido académico recuperable, usá content vacío."
    )


def extract_chunk(client, chunk_path: Path, file_name: str, page_start: int, page_end: int) -> dict:
    prompt = extraction_prompt(page_start, page_end)
    schema = extraction_schema()

    if AI_PROVIDER == "openai":
        with chunk_path.open("rb") as chunk_file:
            uploaded = client.files.create(file=chunk_file, purpose="user_data")
        try:
            response = client.responses.create(
                model=OPENAI_MODEL,
                input=[{
                    "role": "user",
                    "content": [
                        {"type": "input_file", "file_id": uploaded.id},
                        {"type": "input_text", "text": prompt},
                    ],
                }],
                text={
                    "format": {
                        "type": "json_schema",
                        "name": "page_extraction",
                        "strict": True,
                        "schema": schema,
                    }
                },
                max_output_tokens=9000,
            )
            import json
            return json.loads(response.output_text or "{}")
        finally:
            try:
                client.files.delete(uploaded.id)
            except Exception:
                pass

    if AI_PROVIDER == "gemini":
        uploaded = client.files.upload(
            file=chunk_path,
            config={"mime_type": "application/pdf"},
        )
        try:
            response = client.models.generate_content(
                model=GEMINI_MODEL,
                contents=[uploaded, prompt],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=schema,
                ),
            )
            import json
            return json.loads(response.text or "{}")
        finally:
            try:
                client.files.delete(name=uploaded.name)
            except Exception:
                pass

    raise RuntimeError(f"Proveedor de IA no soportado: {AI_PROVIDER}")


def validate_extracted_pages(extracted: dict, page_start: int, page_end: int) -> list[dict]:
    pages = extracted.get("pages") if isinstance(extracted, dict) else None
    if not isinstance(pages, list):
        raise RuntimeError("Gemini no devolvió una lista de páginas válida.")

    expected = set(range(page_start, page_end + 1))
    received = [int(page.get("page")) for page in pages if isinstance(page, dict) and page.get("page") is not None]
    received_set = set(received)

    if len(received) != len(received_set) or received_set != expected:
        raise RuntimeError(
            f"Extracción incompleta o inconsistente: se esperaban páginas {page_start}-{page_end}, "
            f"pero se recibieron {received}. El bloque no se confirma."
        )

    for page in pages:
        if not isinstance(page, dict) or "content" not in page:
            raise RuntimeError("La extracción contiene una página sin campo content.")

    return pages


def is_transient_ai_error(exc: Exception) -> bool:
    status = getattr(exc, "status_code", None) or getattr(exc, "code", None)
    if status is None:
        response = getattr(exc, "response", None)
        status = getattr(response, "status_code", None) if response is not None else None
    try:
        return int(status) in {429, 500, 502, 503, 504}
    except (TypeError, ValueError):
        message = str(exc).lower()
        return any(token in message for token in ("429", "500", "502", "503", "504", "unavailable", "resource exhausted"))


def extract_chunk_with_retries(client, chunk_path: Path, file_name: str, page_start: int, page_end: int) -> dict:
    max_attempts = 5
    for attempt in range(1, max_attempts + 1):
        try:
            extracted = extract_chunk(client, chunk_path, file_name, page_start, page_end)
            validate_extracted_pages(extracted, page_start, page_end)
            return extracted
        except Exception as exc:
            if not is_transient_ai_error(exc) or attempt >= max_attempts:
                raise
            delay = min(60, 5 * (2 ** (attempt - 1)))
            print(
                f"Error transitorio de IA ({type(exc).__name__}): {exc}. "
                f"Reintentando {attempt + 1}/{max_attempts} en {delay}s..."
            )
            time.sleep(delay)


def upsert_document(meta: dict) -> tuple[str, int]:
    file_id = meta["id"]
    fingerprint = (
        f"md5:{meta['md5Checksum']}"
        if meta.get("md5Checksum")
        else f"meta:{meta.get('modifiedTime', '')}|{meta.get('size', '')}"
    )
    existing = supabase_request(
        f"knowledge_documents?drive_file_id=eq.{file_id}&select=id,fingerprint,processing_status,page_count&limit=1"
    ).json()
    if existing and existing[0].get("fingerprint") == fingerprint and existing[0].get("processing_status") == "completed":
        return existing[0]["id"], int(existing[0].get("page_count") or 0)

    if existing:
        document_id = existing[0]["id"]
        if existing[0].get("fingerprint") != fingerprint:
            supabase_request(f"knowledge_fragments?document_id=eq.{document_id}", "DELETE")
        supabase_request(
            f"knowledge_documents?id=eq.{document_id}",
            "PATCH",
            {"fingerprint": fingerprint, "processing_status": "running"},
        )
    else:
        response = supabase_request(
            "knowledge_documents",
            "POST",
            {
                "drive_file_id": file_id,
                "file_name": meta["name"],
                "mime_type": meta.get("mimeType"),
                "fingerprint": fingerprint,
                "title": meta["name"],
                "source_type": "google_drive",
                "subject_area": "enfermeria",
                "processing_status": "running",
                "processing_version": "knowledge-v1-worker",
            },
            {"Prefer": "return=representation"},
        )
        document_id = response.json()[0]["id"]

    return document_id, 0


def load_concepts() -> list[dict]:
    return supabase_request(
        "knowledge_concepts?status=eq.active&select=id,name,normalized_name,concept_type&limit=5000"
    ).json()


def save_pages(document_id: str, pages: list[dict], concepts: list[dict]) -> dict[int, int]:
    page_to_fragment: dict[int, int] = {}
    for page in pages:
        content = str(page.get("content") or "").strip()
        page_number = int(page["page"])

        # ----------------------------------------------------------------
        # Una página puede ser exclusivamente una lámina/figura.
        # Se conserva como fragmento técnico mínimo para que las figuras
        # puedan quedar vinculadas y recuperables por página.
        # ----------------------------------------------------------------
        if not content:
            content = "[Página con figura(s) sin texto académico extraíble]"
        page_hash = content_hash(content)
        existing = supabase_request(
            "knowledge_fragments?document_id=eq." + str(document_id)
            + "&page_start=eq." + str(page_number)
            + "&page_end=eq." + str(page_number)
            + "&select=id,content_hash&limit=1"
        ).json()

        if existing:
            fragment_id = existing[0]["id"]
            if existing[0].get("content_hash") != page_hash:
                supabase_request(
                    "knowledge_fragments?id=eq." + str(fragment_id),
                    "PATCH",
                    {
                        "content": content,
                        "content_hash": page_hash,
                        "extraction_method": f"{AI_PROVIDER}_page_extraction_v1",
                    },
                )
                supabase_request(
                    "knowledge_fragment_concepts?fragment_id=eq." + str(fragment_id),
                    "DELETE",
                )
        else:
            response = supabase_request(
                "knowledge_fragments",
                "POST",
                {
                    "document_id": document_id,
                    "page_start": page_number,
                    "page_end": page_number,
                    "content": content,
                    "content_hash": page_hash,
                    "extraction_method": f"{AI_PROVIDER}_page_extraction_v1",
                },
                {"Prefer": "return=representation"},
            )
            fragment_id = response.json()[0]["id"]
        normalized = normalize(content)
        for concept in concepts:
            name = normalize(concept.get("name", ""))
            if len(name) >= 4 and name in normalized:
                supabase_request(
                    "knowledge_fragment_concepts",
                    "POST",
                    {
                        "fragment_id": fragment_id,
                        "concept_id": concept["id"],
                        "relevance": 1,
                        "evidence_type": "exact_term",
                    },
                    {"Prefer": "resolution=ignore-duplicates"},
                )
        page_to_fragment[page_number] = int(fragment_id)
    return page_to_fragment



# ---------------------------------------------------------------------------
# FIGURAS: extracción nativa del PDF + Supabase Storage
# ---------------------------------------------------------------------------

FIGURES_BUCKET = os.environ.get("KNOWLEDGE_FIGURES_BUCKET", "knowledge-figures")


def storage_request(path: str, method: str = "GET", body: bytes | None = None, headers: dict | None = None):
    merged = {
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
    }
    if headers:
        merged.update(headers)
    response = requests.request(
        method,
        f"{SUPABASE_URL}/storage/v1/{path}",
        headers=merged,
        data=body,
        timeout=(30, 120),
    )
    response.raise_for_status()
    return response


def upload_figure(storage_path: str, image_bytes: bytes, content_type: str) -> None:
    # -----------------------------------------------------------------------
    # La figura original se conserva en el bucket privado existente.
    # upsert permite reanudar sin duplicar archivos.
    # -----------------------------------------------------------------------
    storage_request(
        f"object/{FIGURES_BUCKET}/{storage_path}",
        method="POST",
        body=image_bytes,
        headers={
            "Content-Type": content_type,
            "x-upsert": "true",
        },
    )


def figure_bbox_string(bbox) -> str:
    # -----------------------------------------------------------------------
    # Coordenadas PDF/PyMuPDF: x0,y0,x1,y1.
    # -----------------------------------------------------------------------
    return ",".join(f"{float(v):.2f}" for v in bbox)


def figure_number_from_text(text: str, image_order: int) -> int | None:
    # -----------------------------------------------------------------------
    # Intenta recuperar "Figura 12", "Fig. 12", "Lámina 12", etc.
    # Si no existe, se deja NULL: no se inventa numeración.
    # -----------------------------------------------------------------------
    match = re.search(
        r"(?i)\b(?:figura|fig\.?|lámina|lamina|ilustración|ilustracion)\s*(?:n[°º.]?\s*)?(\d+)\b",
        text or "",
    )
    return int(match.group(1)) if match else None


def figure_caption_from_text(text: str, figure_number: int | None) -> str | None:
    # -----------------------------------------------------------------------
    # Captura una línea cercana que parezca ser el epígrafe.
    # No usa IA para inventar captions.
    # -----------------------------------------------------------------------
    lines = [re.sub(r"\s+", " ", x).strip() for x in (text or "").splitlines()]
    for i, line in enumerate(lines):
        if not re.search(r"(?i)\b(?:figura|fig\.?|lámina|lamina|ilustración|ilustracion)\b", line):
            continue
        if figure_number is not None and str(figure_number) not in line:
            continue
        candidate = line[:1000]
        if len(candidate) >= 8:
            return candidate
        if i + 1 < len(lines) and len(lines[i + 1]) >= 8:
            return f"{candidate} {lines[i + 1]}"[:1000]
    return None



def _figure_captions(page) -> list[dict]:
    # -----------------------------------------------------------------------
    # Las leyendas/captions suelen ser texto PDF independiente de la imagen.
    # Se detectan localmente, sin OCR ni IA.
    # -----------------------------------------------------------------------
    captions = []
    pattern = re.compile(
        r"(?i)\b(?:figura|fig\.?|lámina|lamina|ilustración|ilustracion)\s*"
        r"(?:n[°º.]?\s*)?(\d+(?:[.:-]\d+)*)\b"
    )
    for block in page.get_text("blocks"):
        text = str(block[4] or "").strip()
        match = pattern.search(text)
        if not match:
            continue
        captions.append({
            "bbox": fitz.Rect(block[:4]),
            "text": re.sub(r"\s+", " ", text).strip(),
            "number": match.group(1),
        })
    return captions


def _expanded_figure_bbox(page, bbox, padding: float = 42.0) -> fitz.Rect:
    # -----------------------------------------------------------------------
    # Amplía la figura con textos/etiquetas cercanos que están fuera del
    # objeto de imagen.
    # -----------------------------------------------------------------------
    region = fitz.Rect(bbox)
    expanded = fitz.Rect(
        max(page.rect.x0, region.x0 - padding),
        max(page.rect.y0, region.y0 - padding),
        min(page.rect.x1, region.x1 + padding),
        min(page.rect.y1, region.y1 + padding),
    )
    for block in page.get_text("blocks"):
        br = fitz.Rect(block[:4])
        if expanded.intersects(br):
            region |= br
    return region


def extract_page_figures(page, page_number: int) -> list[dict]:
    # -----------------------------------------------------------------------
    # Reconstrucción visual local de figuras.
    #
    # El PDF puede guardar la ilustración/fotografía como imagen embebida y
    # las etiquetas, números, flechas y referencias como objetos separados.
    # Por eso rasterizamos la región visual completa con PyMuPDF.
    #
    # Todo este proceso es local y no utiliza IA.
    # -----------------------------------------------------------------------
    infos = page.get_image_info(xrefs=True)
    candidates = []
    seen = set()

    for order, info in enumerate(infos, start=1):
        bbox = tuple(info.get("bbox") or ())
        if len(bbox) != 4:
            continue
        xref = int(info.get("xref") or 0)
        key = (xref, figure_bbox_string(bbox))
        if key in seen:
            continue
        seen.add(key)

        width = int(info.get("width") or 0)
        height = int(info.get("height") or 0)
        if width < 32 or height < 32:
            continue

        candidates.append({
            "order": order,
            "xref": xref if xref else None,
            "bbox": fitz.Rect(bbox),
            "width": width,
            "height": height,
        })

    if not candidates:
        return []

    captions = _figure_captions(page)
    groups = []
    assigned = set()

    if captions:
        for caption in captions:
            nearby = []
            for candidate in candidates:
                center_y = candidate["bbox"].y0 + candidate["bbox"].height / 2
                distance = abs(center_y - caption["bbox"].y0)
                if distance <= max(page.rect.height * 0.55, 180):
                    nearby.append((distance, candidate))

            if nearby:
                min_distance = min(x[0] for x in nearby)
                pool = [x[1] for x in nearby if x[0] <= min_distance + 220]
                if pool:
                    group_bbox = fitz.Rect(pool[0]["bbox"])
                    for candidate in pool[1:]:
                        group_bbox |= candidate["bbox"]
                    groups.append({
                        "order": min(x["order"] for x in pool),
                        "xref": pool[0]["xref"],
                        "xrefs": [x["xref"] for x in pool if x["xref"] is not None],
                        "bbox": group_bbox,
                        "caption": caption["text"],
                        "figure_number": caption["number"],
                    })
                    assigned.update(id(x) for x in pool)

    for candidate in candidates:
        if id(candidate) in assigned:
            continue
        groups.append({
            "order": candidate["order"],
            "xref": candidate["xref"],
            "xrefs": [candidate["xref"]] if candidate["xref"] is not None else [],
            "bbox": candidate["bbox"],
            "caption": None,
            "figure_number": None,
        })

    groups.sort(key=lambda x: (x["bbox"].y0, x["bbox"].x0, x["order"]))

    figures = []
    for figure_order, group in enumerate(groups, start=1):
        native_bbox = group["bbox"]
        visual_bbox = _expanded_figure_bbox(page, native_bbox, padding=42.0)

        pix = page.get_pixmap(
            clip=visual_bbox,
            dpi=180,
            alpha=False,
        )
        image_bytes = pix.tobytes("png")

        figures.append({
            "page": page_number,
            "order": figure_order,
            "xref": group["xref"],
            "xrefs": group["xrefs"],
            "bbox": tuple(visual_bbox),
            "native_bbox": tuple(native_bbox),
            "bbox_text": figure_bbox_string(visual_bbox),
            "bytes": image_bytes,
            "extension": "png",
            "content_type": "image/png",
            "width": int(pix.width),
            "height": int(pix.height),
            "caption": group["caption"],
            "figure_number": group["figure_number"],
        })

    return figures

def next_figure_key(document_id: int) -> int:
    # -----------------------------------------------------------------------
    # Continúa la numeración existente del documento.
    # -----------------------------------------------------------------------
    rows = supabase_request(
        f"knowledge_figures?document_id=eq.{document_id}&select=figure_key&limit=50000"
    ).json()
    numbers = []
    for row in rows:
        match = re.fullmatch(r"F(\d+)", str(row.get("figure_key") or ""))
        if match:
            numbers.append(int(match.group(1)))
    return max(numbers, default=0) + 1


def save_page_figures(document_id: int, page, page_number: int, fragment_id: int | None, figure_counter: int) -> int:
    # -----------------------------------------------------------------------
    # Guarda figuras y crea la relación figura <-> fragmento de la página.
    # -----------------------------------------------------------------------
    extracted = extract_page_figures(page, page_number)
    page_text = page.get_text("text") or ""

    for item in extracted:
        figure_key = f"F{figure_counter:05d}"
        storage_path = (
            f"doc{document_id}/pdf{page_number:04d}_"
            f"fig{item['order']:02d}_xref{item['xref'] or 'inline'}.{item['extension']}"
        )

        upload_figure(storage_path, item["bytes"], item["content_type"])

        figure_number = figure_number_from_text(page_text, item["order"])
        caption = figure_caption_from_text(page_text, figure_number)

        # La reconstrucción visual local ya puede haber obtenido el número y
        # la leyenda exactos de la figura. Se prefieren esos datos.
        if item.get("figure_number") is not None:
            raw_number = str(item["figure_number"])
            number_match = re.search(r"(\d+)$", raw_number)
            figure_number = int(number_match.group(1)) if number_match else figure_number
        if item.get("caption"):
            caption = item["caption"]

        metadata = {
            "extractor": "pdf_visual_figure_v2",
            "image_order": item["order"],
            "width": item["width"],
            "height": item["height"],
            "inline_image": item["xref"] is None,
            "source_xrefs": item.get("xrefs", []),
            "native_bbox": item.get("native_bbox"),
            "visual_bbox": item.get("bbox"),
            "ai_used": False,
        }

        # ----------------------------------------------------------------
        # Se consulta por documento/página y se compara XREF+BBOX localmente.
        # Así también se detectan correctamente las imágenes inline (XREF NULL).
        # ----------------------------------------------------------------
        existing_rows = supabase_request(
            "knowledge_figures"
            f"?document_id=eq.{document_id}"
            f"&pdf_page=eq.{page_number}"
            "&select=id,figure_key,source_xref,bbox"
            "&limit=500"
        ).json()
        existing = next(
            (
                row for row in existing_rows
                if (row.get("source_xref") == item["xref"])
                and str(row.get("bbox") or "") == item["bbox_text"]
            ),
            None,
        )

        if existing:
            figure_id = existing["id"]
            figure_key = existing["figure_key"]
            supabase_request(
                f"knowledge_figures?id=eq.{figure_id}",
                "PATCH",
                {
                    "storage_path": storage_path,
                    "figure_number": figure_number,
                    "caption": caption,
                    "confidence": 0.98 if item["xref"] is not None else 0.90,
                    "status": "active",
                    "metadata": metadata,
                    "updated_at": __import__("datetime").datetime.now(
                        __import__("datetime").timezone.utc
                    ).isoformat(),
                },
            )
        else:
            response = supabase_request(
                "knowledge_figures",
                "POST",
                {
                    "document_id": document_id,
                    "figure_key": figure_key,
                    "pdf_page": page_number,
                    "printed_page": None,
                    "figure_number": figure_number,
                    "caption": caption,
                    "storage_path": storage_path,
                    "source_xref": item["xref"],
                    "bbox": item["bbox_text"],
                    "confidence": 0.98 if item["xref"] is not None else 0.90,
                    "status": "active",
                    "reviewed": False,
                    "metadata": metadata,
                },
                {"Prefer": "return=representation"},
            )
            figure_id = response.json()[0]["id"]

        if fragment_id is not None:
            supabase_request(
                "knowledge_fragment_figures",
                "POST",
                {
                    "fragment_id": fragment_id,
                    "figure_id": figure_id,
                    "relation_type": "same_page",
                    "weight": 1.0,
                },
                {"Prefer": "resolution=ignore-duplicates"},
            )

        figure_counter += 1

    return figure_counter


def extract_and_save_figures(pdf_path: Path, document_id: int, page_to_fragment: dict[int, int]) -> int:
    # -----------------------------------------------------------------------
    # Recorre todas las páginas con PyMuPDF. No manda las imágenes a la IA.
    # -----------------------------------------------------------------------
    pdf = fitz.open(str(pdf_path))
    counter = next_figure_key(document_id)

    try:
        for page_index in range(len(pdf)):
            page_number = page_index + 1
            fragment_id = page_to_fragment.get(page_number)
            counter = save_page_figures(
                document_id,
                pdf[page_index],
                page_number,
                fragment_id,
                counter,
            )
    finally:
        pdf.close()

    return counter - 1

def get_or_create_job(document_id: str, file_id: str, file_name: str, fingerprint: str, total_pages: int, chunk_pages: int) -> dict:
    existing = supabase_request(
        f"knowledge_ingest_jobs?drive_file_id=eq.{file_id}&status=in.(pending,running,paused,error)&select=*&order=id.desc&limit=1"
    ).json()
    if existing:
        return existing[0]
    total_chunks = (total_pages + chunk_pages - 1) // chunk_pages
    response = supabase_request(
        "knowledge_ingest_jobs", "POST", {
            "user_id": KNOWLEDGE_USER_ID,
            "document_id": document_id,
            "drive_file_id": file_id,
            "file_name": file_name,
            "file_fingerprint": fingerprint,
            "status": "running",
            "total_pages": total_pages,
            "chunk_pages": chunk_pages,
            "total_chunks": total_chunks,
            "next_chunk": 0,
            "processed_pages": 0,
            "processing_version": "knowledge-v1-worker",
        }, {"Prefer": "return=representation"}
    )
    return response.json()[0]


def update_job(job_id: int, **fields) -> None:
    supabase_request(f"knowledge_ingest_jobs?id=eq.{job_id}", "PATCH", fields)


def require_figure_env() -> None:
    # -----------------------------------------------------------------------
    # Modo exclusivo de figuras: NO requiere OPENAI_API_KEY ni GEMINI_API_KEY.
    # Solo necesita acceso a Supabase y a Google Drive para descargar el PDF.
    # -----------------------------------------------------------------------
    required = [
        ("SUPABASE_URL", SUPABASE_URL),
        ("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY),
    ]
    missing = [name for name, value in required if not value]
    if missing:
        raise SystemExit("Faltan secretos: " + ", ".join(missing))


def extract_figures_only(file_id: str) -> None:
    # -----------------------------------------------------------------------
    # Flujo completamente independiente de IA.
    #
    # - descarga el PDF desde Drive
    # - obtiene las relaciones página -> fragmento ya existentes
    # - extrae imágenes con PyMuPDF
    # - guarda las imágenes en Supabase Storage
    # - registra knowledge_figures y knowledge_fragment_figures
    #
    # NO crea clientes OpenAI/Gemini y NO consume créditos de IA.
    # -----------------------------------------------------------------------
    require_figure_env()
    global GOOGLE_ACCESS_TOKEN
    GOOGLE_ACCESS_TOKEN = google_access_token()

    meta = drive_meta(file_id)
    if meta.get("mimeType") != "application/pdf":
        raise SystemExit(f"El archivo no es PDF: {meta.get('mimeType')}")

    document_rows = supabase_request(
        f"knowledge_documents?drive_file_id=eq.{file_id}"
        "&select=id,processing_status&limit=1"
    ).json()
    if not document_rows:
        raise RuntimeError(
            "No existe knowledge_documents para este archivo. "
            "Primero debe existir el documento en la base de conocimiento."
        )

    document_id = int(document_rows[0]["id"])

    fragment_rows = supabase_request(
        f"knowledge_fragments?document_id=eq.{document_id}"
        "&select=id,page_start,page_end&limit=50000"
    ).json()
    page_to_fragment = {}
    for row in fragment_rows:
        start = row.get("page_start")
        end = row.get("page_end")
        if start is None:
            continue
        for page_number in range(int(start), int(end or start) + 1):
            page_to_fragment[page_number] = int(row["id"])

    with tempfile.TemporaryDirectory(prefix="knowledge-figures-") as tmp:
        source = Path(tmp) / "source.pdf"
        print(
            f"Descargando PDF para extracción local de figuras: "
            f"{meta['name']} ({meta.get('size', '?')} bytes)..."
        )
        drive_download(file_id, source)

        pdf = fitz.open(str(source))
        counter = next_figure_key(document_id)
        extracted_count = 0

        try:
            for page_index in range(len(pdf)):
                page_number = page_index + 1
                before = counter
                counter = save_page_figures(
                    document_id,
                    pdf[page_index],
                    page_number,
                    page_to_fragment.get(page_number),
                    counter,
                )
                extracted_count += counter - before
        finally:
            pdf.close()

    print(
        f"Extracción local de figuras completada: "
        f"documento={document_id}, figuras nuevas/procesadas={extracted_count}. "
        f"No se utilizó IA."
    )



def process_file(file_id: str, chunk_pages: int) -> None:
    require_env()
    global GOOGLE_ACCESS_TOKEN
    GOOGLE_ACCESS_TOKEN = google_access_token()
    meta = drive_meta(file_id)
    if meta.get("mimeType") != "application/pdf":
        raise SystemExit(f"El archivo no es PDF: {meta.get('mimeType')}")

    with tempfile.TemporaryDirectory(prefix="knowledge-source-") as tmp:
        source = Path(tmp) / "source.pdf"
        print(f"Descargando {meta['name']} ({meta.get('size', '?')} bytes) a disco...")
        drive_download(file_id, source)

        reader = PdfReader(str(source), strict=False)
        total_pages = len(reader.pages)
        meta["page_count"] = total_pages
        print(f"Páginas detectadas: {total_pages}")

        document_id, _ = upsert_document(meta)
        fingerprint = (
            f"md5:{meta['md5Checksum']}"
            if meta.get("md5Checksum")
            else f"meta:{meta.get('modifiedTime', '')}|{meta.get('size', '')}"
        )
        job = get_or_create_job(
            document_id, file_id, meta["name"], fingerprint, total_pages, chunk_pages
        )

        if job["status"] == "completed":
            if int(job.get("total_pages") or total_pages) != total_pages:
                raise RuntimeError(
                    f"El job {job['id']} figura completado con {job.get('total_pages')} páginas, "
                    f"pero Drive informa {total_pages}. El documento cambió; no se reutiliza ese job."
                )
            print(f"Job ya completado: {job['id']}")
            return

        existing_total_pages = int(job.get("total_pages") or total_pages)
        if existing_total_pages != total_pages:
            raise RuntimeError(
                f"El job {job['id']} fue creado con {existing_total_pages} páginas, "
                f"pero el PDF actual tiene {total_pages}. No se reanuda automáticamente."
            )

        existing_chunk_pages = int(job.get("chunk_pages") or chunk_pages)
        if existing_chunk_pages != chunk_pages:
            raise RuntimeError(
                f"El job {job['id']} fue creado con chunk_pages={existing_chunk_pages}; "
                f"reanudar con chunk_pages={chunk_pages} no es seguro. "
                "Usá el mismo tamaño de bloque."
            )

        update_job(job["id"], status="running", error_message=None)
        concepts = load_concepts()
        if AI_PROVIDER == "gemini":
            client = genai.Client(api_key=GEMINI_API_KEY)
        else:
            client = OpenAI(api_key=OPENAI_API_KEY)

        start_chunk = int(job.get("next_chunk") or 0)
        processed = int(job.get("processed_pages") or 0)

        try:
            for chunk_index, start in enumerate(range(0, total_pages, chunk_pages)):
                if chunk_index < start_chunk:
                    continue

                end = min(start + chunk_pages, total_pages)
                chunk_path = Path(tmp) / f"chunk-{start + 1}-{end}.pdf"

                try:
                    write_chunk(reader, start, end, chunk_path)
                    print(f"Procesando páginas {start + 1}-{end}...")
                    extracted = extract_chunk_with_retries(
                        client, chunk_path, meta["name"], start + 1, end
                    )
                    pages = validate_extracted_pages(extracted, start + 1, end)
                    page_to_fragment = save_pages(document_id, pages, concepts)

                    # -------------------------------------------------------
                    # Las figuras se extraen del PDF original, no de la IA.
                    # Se vinculan a los fragmentos recién confirmados.
                    # -------------------------------------------------------
                    pdf_for_figures = fitz.open(str(source))
                    try:
                        figure_counter = next_figure_key(document_id)
                        for page_number in range(start + 1, end + 1):
                            page = pdf_for_figures[page_number - 1]
                            figure_counter = save_page_figures(
                                document_id,
                                page,
                                page_number,
                                page_to_fragment.get(page_number),
                                figure_counter,
                            )
                    finally:
                        pdf_for_figures.close()

                    processed += end - start
                    next_chunk = chunk_index + 1
                    finished = next_chunk >= job["total_chunks"]

                    update_job(
                        job["id"],
                        status="completed" if finished else "running",
                        next_chunk=next_chunk,
                        processed_pages=processed,
                        completed_at=(
                            __import__("datetime").datetime.now(
                                __import__("datetime").timezone.utc
                            ).isoformat()
                            if finished
                            else None
                        ),
                        error_message=None,
                    )

                    print(
                        f"Bloque confirmado: páginas={start + 1}-{end}, "
                        f"fragmentos={len(page_to_fragment)}, figuras extraídas en el bloque, "
                        f"avance={processed}/{total_pages}"
                    )
                except Exception as exc:
                    message = str(exc)[:2000]
                    update_job(
                        job["id"],
                        status="error",
                        error_message=message,
                        next_chunk=chunk_index,
                        processed_pages=processed,
                    )
                    raise
                finally:
                    chunk_path.unlink(missing_ok=True)

            supabase_request(
                f"knowledge_documents?id=eq.{document_id}",
                "PATCH",
                {
                    "page_count": total_pages,
                    "processing_status": "completed",
                },
            )
            update_job(
                job["id"],
                status="completed",
                next_chunk=job["total_chunks"],
                processed_pages=total_pages,
            )
            print(f"Documento completado: {document_id}")

        except Exception:
            supabase_request(
                f"knowledge_documents?id=eq.{document_id}",
                "PATCH",
                {"processing_status": "error"},
            )
            raise


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file-id")
    parser.add_argument("--pdf", type=Path)
    parser.add_argument("--chunk-pages", type=int, default=DEFAULT_CHUNK_PAGES)
    parser.add_argument("--process", action="store_true")
    parser.add_argument("--extract-figures", action="store_true")
    args = parser.parse_args()

    if args.chunk_pages < 1 or args.chunk_pages > 10:
        raise SystemExit("chunk-pages debe estar entre 1 y 10")

    if args.pdf:
        reader = PdfReader(str(args.pdf), strict=False)
        print(f"PDF: {args.pdf.name}")
        print(f"Páginas: {len(reader.pages)}")
        return

    if args.extract_figures and args.file_id:
        extract_figures_only(args.file_id)
        return

    if args.process and args.file_id:
        process_file(args.file_id, args.chunk_pages)
        return

    parser.error(
        "Usar --process --file-id FILE_ID para procesamiento completo, "
        "o --extract-figures --file-id FILE_ID para extracción de figuras sin IA."
    )


if __name__ == "__main__":
    main()
