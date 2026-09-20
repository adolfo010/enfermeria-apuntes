from __future__ import annotations

import argparse
import os
import tempfile

import requests
from pathlib import Path

from pypdf import PdfReader, PdfWriter

SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
GOOGLE_ACCESS_TOKEN = os.environ.get("GOOGLE_ACCESS_TOKEN", "")

def require_env() -> None:
    missing = [n for n,v in (("SUPABASE_URL",SUPABASE_URL),("SUPABASE_SERVICE_ROLE_KEY",SUPABASE_SERVICE_ROLE_KEY),("GOOGLE_ACCESS_TOKEN",GOOGLE_ACCESS_TOKEN)) if not v]
    if missing: raise SystemExit("Faltan secretos: " + ", ".join(missing))

def drive_download(file_id: str, destination: Path) -> None:
    with requests.get(f"https://www.googleapis.com/drive/v3/files/{file_id}", params={"alt":"media"}, headers={"Authorization":f"Bearer {GOOGLE_ACCESS_TOKEN}"}, stream=True, timeout=(30,300)) as response:
        response.raise_for_status()
        with destination.open("wb") as fh:
            for part in response.iter_content(chunk_size=1024 * 1024):
                if part: fh.write(part)



def write_chunk(reader: PdfReader, start: int, end: int, output: Path) -> None:
    writer = PdfWriter()
    for index in range(start, end):
        writer.add_page(reader.pages[index])
    with output.open("wb") as fh:
        writer.write(fh)


def inspect_pdf(pdf_path: Path, chunk_pages: int) -> None:
    reader = PdfReader(str(pdf_path), strict=False)
    total = len(reader.pages)
    print(f"PDF: {pdf_path.name}")
    print(f"Páginas: {total}")
    print(f"Bloques de {chunk_pages}: {(total + chunk_pages - 1) // chunk_pages}")

    with tempfile.TemporaryDirectory(prefix="knowledge-chunk-") as tmp:
        tmpdir = Path(tmp)
        start = 0
        block = 0
        while start < total:
            end = min(start + chunk_pages, total)
            chunk = tmpdir / f"chunk-{block:06d}.pdf"
            write_chunk(reader, start, end, chunk)
            print(f"bloque={block} paginas={start + 1}-{end} bytes={chunk.stat().st_size}")
            chunk.unlink()
            start = end
            block += 1


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pdf", type=Path, nargs="?")
    parser.add_argument("--file-id")
    parser.add_argument("--chunk-pages", type=int, default=3)
    parser.add_argument("--download-drive", action="store_true")
    args = parser.parse_args()
    if args.chunk_pages < 1 or args.chunk_pages > 10:
        raise SystemExit("chunk-pages debe estar entre 1 y 10")
    if args.pdf and not args.pdf.is_file():
        raise SystemExit(f"No existe: {args.pdf}")
    
    if args.pdf:
        inspect_pdf(args.pdf, args.chunk_pages)
        return
    if args.download_drive and args.file_id:
        require_env()
        with tempfile.TemporaryDirectory(prefix="knowledge-source-") as tmp:
            pdf = Path(tmp) / "source.pdf"
            print(f"Descargando Drive file {args.file_id} a disco temporal...")
            drive_download(args.file_id, pdf)
            print(f"Descarga finalizada: {pdf.stat().st_size} bytes")
            inspect_pdf(pdf, args.chunk_pages)
        return
    parser.error("Indicar un PDF local o usar --download-drive --file-id.")


if __name__ == "__main__":
    main()