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


from worker import is_transient_ai_error, validate_extracted_pages


def test_extracted_pages_must_match_chunk_exactly() -> None:
    extracted = {"pages": [
        {"page": 4, "content": "a"},
        {"page": 5, "content": "b"},
        {"page": 6, "content": "c"},
    ]}
    pages = validate_extracted_pages(extracted, 4, 6)
    assert [page["page"] for page in pages] == [4, 5, 6]


def test_extracted_pages_reject_missing_page() -> None:
    extracted = {"pages": [
        {"page": 4, "content": "a"},
        {"page": 6, "content": "c"},
    ]}
    try:
        validate_extracted_pages(extracted, 4, 6)
    except RuntimeError as exc:
        assert "4-6" in str(exc)
    else:
        raise AssertionError("Se esperaba rechazar una extracción incompleta")


def test_transient_ai_error_statuses() -> None:
    class FakeError(Exception):
        status_code = 503

    assert is_transient_ai_error(FakeError("temporarily unavailable")) is True


def test_non_transient_ai_error_status() -> None:
    class FakeError(Exception):
        status_code = 400

    assert is_transient_ai_error(FakeError("invalid argument")) is False
