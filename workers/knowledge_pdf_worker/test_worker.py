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


# ---------------------------------------------------------------------------
# PRUEBAS DE EXTRACCIÓN NATIVA DE FIGURAS
# ---------------------------------------------------------------------------

import fitz

from worker import extract_page_figures, figure_bbox_string


def test_figure_bbox_format_is_stable() -> None:
    assert figure_bbox_string((1, 2, 300.5, 400.75)) == "1.00,2.00,300.50,400.75"


def test_page_without_images_returns_no_figures() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        pdf = Path(tmp) / "empty.pdf"
        doc = fitz.open()
        doc.new_page(width=612, height=792)
        doc.save(pdf)
        doc.close()

        opened = fitz.open(pdf)
        try:
            assert extract_page_figures(opened[0], 1) == []
        finally:
            opened.close()


def test_figure_only_mode_has_no_direct_ai_calls() -> None:
    # Guardrail: el modo exclusivo de figuras no debe crear ni invocar
    # clientes o funciones de extracción de texto mediante IA.
    from worker import extract_figures_only

    names = set(extract_figures_only.__code__.co_names)
    assert "OpenAI" not in names
    assert "genai" not in names
    assert "extract_chunk" not in names
    assert "extract_chunk_with_retries" not in names


def test_visual_figure_keeps_reference_text_without_ai() -> None:
    # El texto de referencia se crea como objeto PDF independiente de la imagen.
    # La extracción debe reconstruir visualmente ambos elementos.
    import fitz

    with tempfile.TemporaryDirectory() as tmp:
        pdf = Path(tmp) / "figure.pdf"
        doc = fitz.open()
        page = doc.new_page(width=400, height=300)

        source = fitz.Pixmap(fitz.csRGB, fitz.IRect(0, 0, 120, 80), 0)
        source.clear_with(0x88AACC)
        page.insert_image(fitz.Rect(100, 80, 300, 200), pixmap=source)
        page.insert_text((305, 120), "Cromosoma")
        page.insert_text((100, 55), "Figura 1 Anatomía de prueba")
        doc.save(pdf)
        doc.close()
        source = None

        opened = fitz.open(pdf)
        try:
            figures = extract_page_figures(opened[0], 1)
            assert len(figures) == 1
            assert figures[0]["caption"].startswith("Figura 1")
            bbox = figures[0]["bbox"]
            assert bbox[2] >= 305
            assert bbox[1] <= 55
        finally:
            opened.close()
