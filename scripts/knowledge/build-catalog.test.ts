import { assertEquals, assert } from "jsr:@std/assert";
import { buildCatalog } from "./build-catalog.ts";

Deno.test("deduplicates the same concept across documents", () => {
  const result = buildCatalog([
    { id: 1, drive_file_id: "a", file_name: "Anatomia.pdf", page_count: 10,
      topics: [{ title: "Corazón", parent: "Sistema cardiovascular", page_start: 1, page_end: 3 }] },
    { id: 2, drive_file_id: "b", file_name: "Atlas Netter.pdf", page_count: 20,
      topics: [{ title: "Corazón", parent: "Sistema cardiovascular", page_start: 5, page_end: 8 }] },
  ]);

  assertEquals(result.concepts.length, 2);
  assertEquals(result.documents.length, 2);
  assertEquals(result.documentConcepts.length, 2);
  assertEquals(result.documents[1].source_type, "atlas");
});

Deno.test("preserves page ranges and creates aliases", () => {
  const result = buildCatalog([
    { id: 1, drive_file_id: "a", file_name: "Notas.docx", page_count: 5,
      topics: [{ title: "Capítulo 3 (Parte 1)", parent: null, page_start: 2, page_end: 4 }] },
  ]);

  assertEquals(result.documentConcepts[0].page_start, 2);
  assertEquals(result.documentConcepts[0].page_end, 4);
  assert(result.aliases.some((a) => a.alias === "Capítulo 3"));
});
