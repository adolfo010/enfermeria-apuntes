from __future__ import annotations

import hashlib
import os
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote

import fitz
import requests

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
FIGURES_BUCKET = os.environ.get("KNOWLEDGE_FIGURES_BUCKET", "knowledge-figures")


def require_env() -> None:
    required = [
        ("SUPABASE_URL", SUPABASE_URL),
        ("SUPABASE_SERVICE_ROLE_KEY", SUPABASE_SERVICE_ROLE_KEY),
    ]
    missing = [name for name, value in required if not value]
    if missing:
        raise SystemExit("Faltan secretos: " + ", ".join(missing))


def supabase_request(
    path: str,
    method: str = "GET",
    body: object | None = None,
    headers: dict | None = None,
):
    merged = {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
    }
    if headers:
        merged.update(headers)
    last_error = None
    for attempt in range(5):
        try:
            response = requests.request(
                method,
                f"{SUPABASE_URL}/rest/v1/{path}",
                headers=merged,
                json=body,
                timeout=(30, 120),
            )
            if response.status_code not in (429, 502, 503, 504):
                response.raise_for_status()
                return response
            last_error = RuntimeError(f"Supabase HTTP {response.status_code}")
        except requests.RequestException as exc:
            last_error = exc
        if attempt < 4:
            delay = 2 ** attempt
            print(f"\nReintentando Supabase en {delay}s ({attempt + 1}/4)...", flush=True)
            time.sleep(delay)
    raise last_error


def storage_request(
    path: str,
    method: str = "GET",
    body: bytes | None = None,
    headers: dict | None = None,
):
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
    storage_request(
        f"object/{FIGURES_BUCKET}/{storage_path}",
        method="POST",
        body=image_bytes,
        headers={
            "Content-Type": content_type,
            "x-upsert": "true",
        },
    )


def local_file_fingerprint(pdf_path: Path) -> str:
    digest = hashlib.sha256()
    with pdf_path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return "sha256:" + digest.hexdigest()


def content_hash(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def figure_bbox_string(bbox) -> str:
    return ",".join(f"{float(v):.2f}" for v in bbox)


def figure_number_from_text(text: str, image_order: int) -> int | None:
    match = re.search(
        r"(?i)\b(?:figura|fig\.?|lámina|lamina|ilustración|ilustracion)\s*"
        r"(?:n[°º.]?\s*)?(\d+)\b",
        text or "",
    )
    return int(match.group(1)) if match else None


def figure_caption_from_text(text: str, figure_number: int | None) -> str | None:
    lines = [re.sub(r"\s+", " ", x).strip() for x in (text or "").splitlines()]
    for i, line in enumerate(lines):
        if not re.search(
            r"(?i)\b(?:figura|fig\.?|lámina|lamina|ilustración|ilustracion)\b",
            line,
        ):
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
    captions = []
    pattern = re.compile(
        r"(?i)^\s*(?:figura|fig\.?|lámina|lamina|ilustración|ilustracion)\s*"
        r"(?:n[°º.]?\s*)?(\d+(?:[.:-]\d+)*)\b"
    )
    for block in page.get_text("blocks"):
        text = str(block[4] or "").strip()
        match = pattern.search(text)
        if not match:
            continue
        captions.append(
            {
                "bbox": fitz.Rect(block[:4]),
                "text": re.sub(r"\s+", " ", text).strip(),
                "number": match.group(1),
            }
        )
    return captions


def _expanded_figure_bbox(page, bbox, padding: float = 42.0) -> fitz.Rect:
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

        candidates.append(
            {
                "order": order,
                "xref": xref if xref else None,
                "bbox": fitz.Rect(bbox),
                "width": width,
                "height": height,
            }
        )

    if not candidates:
        return []

    captions = _figure_captions(page)
    groups = []
    assigned = set()

    if captions:
        for caption in captions:
            if len(captions) == 1:
                pool = list(candidates)
            else:
                nearby = []
                for candidate in candidates:
                    center_y = (
                        candidate["bbox"].y0 + candidate["bbox"].height / 2
                    )
                    distance = abs(center_y - caption["bbox"].y0)
                    if distance <= max(page.rect.height * 0.55, 180):
                        nearby.append((distance, candidate))

                if not nearby:
                    continue

                min_distance = min(x[0] for x in nearby)
                pool = [
                    x[1]
                    for x in nearby
                    if x[0] <= min_distance + 220
                ]

            if pool:
                group_bbox = fitz.Rect(pool[0]["bbox"])
                for candidate in pool[1:]:
                    group_bbox |= candidate["bbox"]

                groups.append(
                    {
                        "order": min(x["order"] for x in pool),
                        "xref": pool[0]["xref"],
                        "xrefs": [
                            x["xref"] for x in pool if x["xref"] is not None
                        ],
                        "bbox": group_bbox,
                        "caption": caption["text"],
                        "figure_number": caption["number"],
                    }
                )
                assigned.update(id(x) for x in pool)

    for candidate in candidates:
        if id(candidate) in assigned:
            continue
        groups.append(
            {
                "order": candidate["order"],
                "xref": candidate["xref"],
                "xrefs": (
                    [candidate["xref"]]
                    if candidate["xref"] is not None
                    else []
                ),
                "bbox": candidate["bbox"],
                "caption": None,
                "figure_number": None,
            }
        )

    groups.sort(
        key=lambda x: (x["bbox"].y0, x["bbox"].x0, x["order"])
    )

    figures = []
    for figure_order, group in enumerate(groups, start=1):
        native_bbox = group["bbox"]
        visual_bbox = _expanded_figure_bbox(
            page, native_bbox, padding=42.0
        )

        try:
            pix = page.get_pixmap(
                clip=visual_bbox,
                dpi=180,
                alpha=False,
            )
            image_bytes = pix.tobytes("png")
            render_dpi = 180
        except Exception as first_error:
            # Some PDFs contain unusual page/image dimensions that make
            # MuPDF's PNG writer reject the raster dimensions. Retry at a
            # lower resolution before falling back to the native image.
            try:
                pix = page.get_pixmap(
                    clip=visual_bbox,
                    dpi=120,
                    alpha=False,
                )
                image_bytes = pix.tobytes("png")
                render_dpi = 120
            except Exception:
                try:
                    raw = page.parent.extract_image(group["xref"]) if group["xref"] else None
                except Exception:
                    raw = None
                if not raw or not raw.get("image"):
                    print(
                        f"\\nAdvertencia: no se pudo rasterizar figura "
                        f"página {page_number}, orden {figure_order}: {first_error}",
                        flush=True,
                    )
                    continue
                image_bytes = raw["image"]
                render_dpi = None
                pix = None

        figures.append(
            {
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
                "width": int(pix.width) if pix is not None else None,
                "height": int(pix.height) if pix is not None else None,
                "render_dpi": render_dpi,
                "caption": group["caption"],
                "figure_number": group["figure_number"],
            }
        )

    return figures


def next_figure_key(document_id: int) -> int:
    rows = supabase_request(
        f"knowledge_figures?document_id=eq.{document_id}"
        "&select=figure_key&limit=50000"
    ).json()
    numbers = []
    for row in rows:
        match = re.fullmatch(
            r"F(\d+)", str(row.get("figure_key") or "")
        )
        if match:
            numbers.append(int(match.group(1)))
    return max(numbers, default=0) + 1


def save_page_figures(
    document_id: int,
    page,
    page_number: int,
    fragment_id: int | None,
    figure_counter: int,
) -> int:
    extracted = extract_page_figures(page, page_number)
    page_text = page.get_text("text") or ""

    for item in extracted:
        figure_key = f"F{figure_counter:05d}"
        storage_path = (
            f"doc{document_id}/pdf{page_number:04d}_"
            f"fig{item['order']:02d}_xref{item['xref'] or 'inline'}."
            f"{item['extension']}"
        )

        upload_figure(
            storage_path,
            item["bytes"],
            item["content_type"],
        )

        figure_number = figure_number_from_text(
            page_text, item["order"]
        )
        caption = figure_caption_from_text(
            page_text, figure_number
        )

        if item.get("figure_number") is not None:
            raw_number = str(item["figure_number"])
            if re.fullmatch(r"\d+", raw_number):
                figure_number = int(raw_number)

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

        existing_rows = supabase_request(
            "knowledge_figures"
            f"?document_id=eq.{document_id}"
            f"&pdf_page=eq.{page_number}"
            "&select=id,figure_key,source_xref,bbox"
            "&limit=500"
        ).json()

        existing = next(
            (
                row
                for row in existing_rows
                if row.get("source_xref") == item["xref"]
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
                    "confidence": (
                        0.98 if item["xref"] is not None else 0.90
                    ),
                    "status": "active",
                    "metadata": metadata,
                    "updated_at": datetime.now(timezone.utc).isoformat(),
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
                    "confidence": (
                        0.98 if item["xref"] is not None else 0.90
                    ),
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


def extract_and_save_figures(
    pdf_path: Path,
    document_id: int,
    page_to_fragment: dict[int, int],
) -> int:
    pdf = fitz.open(str(pdf_path))
    counter = next_figure_key(document_id)
    extracted_count = 0
    started = time.time()
    total_pages = len(pdf)

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
            page_number = page_index + 1
            elapsed = max(time.time() - started, 0.001)
            rate = page_number / elapsed
            eta = (total_pages - page_number) / rate if rate else 0
            print(f"\rFiguras: página {page_number}/{total_pages} | figuras {extracted_count} | {rate:.2f} pág/s | ETA {eta/60:.1f} min", end="", flush=True)
    finally:
        pdf.close()
    print()

    return extracted_count


def save_pages(
    document_id: int,
    pages: list[dict],
) -> dict[int, int]:
    page_to_fragment: dict[int, int] = {}

    for page in pages:
        content = str(page.get("content") or "").strip()
        page_number = int(page["page"])

        if not content:
            content = "[Página con figura(s) sin texto académico extraíble]"

        page_hash = content_hash(content)
        existing = supabase_request(
            "knowledge_fragments?document_id=eq."
            + str(document_id)
            + "&page_start=eq."
            + str(page_number)
            + "&page_end=eq."
            + str(page_number)
            + "&select=id,content_hash&limit=1"
        ).json()

        if existing:
            fragment_id = existing[0]["id"]
            if existing[0].get("content_hash") != page_hash:
                supabase_request(
                    f"knowledge_fragments?id=eq.{fragment_id}",
                    "PATCH",
                    {
                        "content": content,
                        "content_hash": page_hash,
                        "extraction_method": "pymupdf_page_extraction_v1",
                    },
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
                    "extraction_method": "pymupdf_page_extraction_v1",
                },
                {"Prefer": "return=representation"},
            )
            fragment_id = response.json()[0]["id"]

        page_to_fragment[page_number] = int(fragment_id)

    return page_to_fragment
