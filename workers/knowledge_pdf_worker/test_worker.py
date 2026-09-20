from pathlib import Path
import tempfile

from pypdf import PdfReader, PdfWriter


def make_pdf(path: Path, pages: int = 7) -> None:
    writer = PdfWriter()
    for _ in range(pages):
        writer.add_blank_page(width=612, height=792)
    with path.open("wb") as fh:
        writer.write(fh)


def test_local_pdf_is_readable_and_page_count_is_stable() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        pdf = Path(tmp) / "fixture.pdf"
        make_pdf(pdf, 7)
        reader = PdfReader(str(pdf), strict=False)
        assert len(reader.pages) == 7


def test_chunk_ranges_cover_all_pages() -> None:
    total = 7
    chunk_pages = 3
    ranges = [
        (start, min(start + chunk_pages, total))
        for start in range(0, total, chunk_pages)
    ]
    assert ranges == [(0, 3), (3, 6), (6, 7)]
