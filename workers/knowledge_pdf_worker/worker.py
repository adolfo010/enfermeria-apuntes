from __future__ import annotations

import argparse
import hashlib
import os
import tempfile
from pathlib import Path

import requests
from openai import OpenAI
from pypdf import PdfReader, PdfWriter

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
GOOGLE_ACCESS_TOKEN = os.environ.get("GOOGLE_ACCESS_TOKEN", "")
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "")
OPENAI_MODEL = os.environ.get("OPENAI_MODEL", "gpt-5.6-luna")
KNOWLEDGE_USER_ID = os.environ.get("KNOWLEDGE_USER_ID", "")
DEFAULT_CHUNK_PAGES = 3


def require_env() -> None:
    missing = [
        name for name, value in (
            ("SUPABASE_URL", SUPABASE_URL),
            ("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY),
            ("OPENAI_API_KEY", OPENAI_API_KEY),
            ("KNOWLEDGE_USER_ID", KNOWLEDGE_USER_ID),
        ) if not value
    ]
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
                raise RuntimeError(
                    "El access token de Google está vencido. "
                    "Para esta prueba debe renovarse desde el OAuth existente."
                )
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


def extract_chunk(client: OpenAI, chunk_path: Path, file_name: str, page_start: int, page_end: int) -> dict:
    with chunk_path.open("rb") as chunk_file:
        uploaded = client.files.create(file=chunk_file, purpose="user_data")
    try:
        prompt = (
            "Extraé el contenido académico de estas páginas para una base de conocimiento. "
            "Conservá definiciones, explicaciones, relaciones, listas y datos relevantes. "
            "NO resumas, NO agregues conocimiento externo y NO inventes contenido. "
            "Devolvé exclusivamente JSON con pages; cada elemento debe tener page "
            "(número de página original) y content (texto académico de esa página). "
            f"Las páginas originales son {page_start}-{page_end}. "
            "Si una página no contiene contenido académico recuperable, usá content vacío."
        )
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
                    "schema": {
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
                    },
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


def save_pages(document_id: str, pages: list[dict], concepts: list[dict]) -> int:
    saved = 0
    for page in pages:
        content = str(page.get("content") or "").strip()
        if not content:
            continue
        page_number = int(page["page"])
        response = supabase_request(
            "knowledge_fragments",
            "POST",
            {
                "document_id": document_id,
                "page_start": page_number,
                "page_end": page_number,
                "content": content,
                "content_hash": content_hash(content),
                "extraction_method": "openai_page_extraction_v1",
            },
            {"Prefer": "resolution=ignore-duplicates,return=representation"},
        )
        rows = response.json()
        if not rows:
            continue
        fragment_id = rows[0]["id"]
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
        saved += 1
    return saved


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
                    extracted = extract_chunk(
                        client, chunk_path, meta["name"], start + 1, end
                    )
                    saved = save_pages(
                        document_id, extracted.get("pages", []), concepts
                    )

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
                        f"fragmentos={saved}, avance={processed}/{total_pages}"
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
    args = parser.parse_args()

    if args.chunk_pages < 1 or args.chunk_pages > 10:
        raise SystemExit("chunk-pages debe estar entre 1 y 10")

    if args.pdf:
        reader = PdfReader(str(args.pdf), strict=False)
        print(f"PDF: {args.pdf.name}")
        print(f"Páginas: {len(reader.pages)}")
        return

    if args.process and args.file_id:
        process_file(args.file_id, args.chunk_pages)
        return

    parser.error("Usar --process --file-id FILE_ID para procesamiento completo.")


if __name__ == "__main__":
    main()
