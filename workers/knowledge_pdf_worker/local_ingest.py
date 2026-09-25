from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
from urllib.parse import quote

import fitz

import worker


def local_file_fingerprint(pdf_path: Path) -> str:
    digest = hashlib.sha256()
    with pdf_path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return "sha256:" + digest.hexdigest()


def local_upsert_document(pdf_path: Path, page_count: int, fingerprint: str) -> int:
    file_name = pdf_path.name
    encoded_fp = quote(fingerprint, safe="")
    existing = worker.supabase_request(
        "knowledge_documents?fingerprint=eq." + encoded_fp +
        "&select=id,processing_status&page_count&limit=1"
    ).json()

    if existing:
        document_id = int(existing[0]["id"])
        worker.supabase_request(
            f"knowledge_fragments?document_id=eq.{document_id}", "DELETE"
        )
        worker.supabase_request(
            f"knowledge_figures?document_id=eq.{document_id}", "DELETE"
        )
        worker.supabase_request(
            f"knowledge_documents?id=eq.{document_id}",
            "PATCH",
            {
                "file_name": file_name,
                "title": file_name,
                "page_count": page_count,
                "processing_status": "running",
                "processing_version": "local+visual-figure-v2",
                "source_type": "local_pdf",
                "subject_area": "enfermeria",
                "fingerprint": fingerprint,
            },
        )
        return document_id

    response = worker.supabase_request(
        "knowledge_documents",
        "POST",
        {
            "drive_file_id": None,
            "file_name": file_name,
            "mime_type": "application/pdf",
            "fingerprint": fingerprint,
            "title": file_name,
            "source_type": "local_pdf",
            "subject_area": "enfermeria",
            "page_count": page_count,
            "processing_status": "running",
            "processing_version": "local+visual-figure-v2",
            "metadata": {
                "ai_used": False,
                "text_extraction": "PyMuPDF",
                "figure_extraction": "pdf_visual_figure_v2",
            },
        },
        {"Prefer": "return=representation"},
    )
    return int(response.json()[0]["id"])


def extract_local_pages(pdf_path: Path) -> list[dict]:
    pages = []
    pdf = fitz.open(str(pdf_path))
    try:
        for page_number, page in enumerate(pdf, start=1):
            text = page.get_text("text").strip()
            if not text:
                text = "[Página con figura(s) sin texto académico extraíble]"
            pages.append({"page": page_number, "content": text})
    finally:
        pdf.close()
    return pages


def process_local_pdf(pdf_path: Path) -> None:
    if not pdf_path.exists():
        raise SystemExit(f"No existe el PDF: {pdf_path}")
    if pdf_path.suffix.lower() != ".pdf":
        raise SystemExit("El archivo indicado no es PDF.")

    worker.require_figure_env()

    # Este proceso no crea clientes OpenAI/Gemini ni llama a funciones de IA.
    worker.AI_PROVIDER = "local"

    fingerprint = local_file_fingerprint(pdf_path)
    pdf = fitz.open(str(pdf_path))
    page_count = len(pdf)
    pdf.close()

    print(f"PDF local: {pdf_path.name}")
    print(f"Páginas: {page_count}")
    print("IA: DESACTIVADA")

    document_id = local_upsert_document(pdf_path, page_count, fingerprint)
    print(f"Documento Supabase: {document_id}")

    pages = extract_local_pages(pdf_path)
    page_to_fragment = worker.save_pages(document_id, pages, [])
    print(f"Fragmentos creados/actualizados: {len(page_to_fragment)}")

    figure_count = worker.extract_and_save_figures(
        pdf_path, document_id, page_to_fragment
    )

    worker.supabase_request(
        f"knowledge_documents?id=eq.{document_id}",
        "PATCH",
        {
            "page_count": page_count,
            "processing_status": "completed",
            "processing_version": "local+visual-figure-v2",
            "metadata": {
                "ai_used": False,
                "text_extraction": "PyMuPDF",
                "figure_extraction": "pdf_visual_figure_v2",
                "source": "conversation_local_upload",
            },
        },
    )

    print(
        f"Proceso completado: documento={document_id}, "
        f"páginas={page_count}, fragmentos={len(page_to_fragment)}, "
        f"figuras={figure_count}, IA=0"
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Ingesta local de PDF sin IA para la base de conocimiento."
    )
    parser.add_argument("--pdf", type=Path, required=True)
    args = parser.parse_args()
    process_local_pdf(args.pdf)


if __name__ == "__main__":
    main()
