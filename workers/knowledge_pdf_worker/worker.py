from __future__ import annotations

import argparse
import os
import tempfile
from pathlib import Path

from pypdf import PdfReader, PdfWriter


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
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--chunk-pages", type=int, default=3)
    args = parser.parse_args()
    if args.chunk_pages < 1 or args.chunk_pages > 10:
        raise SystemExit("chunk-pages debe estar entre 1 y 10")
    if not args.pdf.is_file():
        raise SystemExit(f"No existe: {args.pdf}")
    inspect_pdf(args.pdf, args.chunk_pages)


if __name__ == "__main__":
    main()