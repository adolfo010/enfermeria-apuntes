from pathlib import Path
import tempfile

from local_ingest import local_file_fingerprint, extract_local_pages


def test_local_fingerprint_is_stable():
    with tempfile.TemporaryDirectory() as tmp:
        pdf = Path(tmp) / "sample.pdf"
        pdf.write_bytes(b"contenido de prueba")
        first = local_file_fingerprint(pdf)
        second = local_file_fingerprint(pdf)
        assert first == second
        assert first.startswith("sha256:")


def test_local_page_extraction_preserves_page_numbers():
    import fitz

    with tempfile.TemporaryDirectory() as tmp:
        pdf = Path(tmp) / "sample.pdf"
        doc = fitz.open()
        page = doc.new_page(width=400, height=300)
        page.insert_text((50, 50), "Anatomía humana")
        doc.new_page(width=400, height=300)
        doc.save(pdf)
        doc.close()

        pages = extract_local_pages(pdf)
        assert [item["page"] for item in pages] == [1, 2]
        assert "Anatomía humana" in pages[0]["content"]
        assert "figura(s)" in pages[1]["content"]


def test_local_ingest_source_is_explicitly_non_ai():
    source = Path(__file__).with_name("local_ingest.py").read_text(
        encoding="utf-8"
    )
    assert 'worker.AI_PROVIDER = "local"' in source
    assert '"ai_used": False' in source
    assert "OpenAI(" not in source
    assert "genai.Client(" not in source
