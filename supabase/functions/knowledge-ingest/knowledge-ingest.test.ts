import { assertEquals, assert } from "jsr:@std/assert";

function normalize(value: string) {
  return String(value || "")
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function conceptMatches(content: string, concept: string): boolean {
  const haystack = normalize(content);
  const needle = normalize(concept);
  return needle.length >= 4 && haystack.includes(needle);
}

Deno.test("recupera concepto exacto dentro del contenido", () => {
  assert(conceptMatches(
    "El corazón recibe irrigación por las arterias coronarias derecha e izquierda.",
    "Arterias coronarias",
  ));
});

Deno.test("la búsqueda ignora acentos", () => {
  assert(conceptMatches(
    "La irrigación del corazón depende de los vasos coronarios.",
    "Irrigación del corazón",
  ));
});

Deno.test("no asocia conceptos que no aparecen en el fragmento", () => {
  assertEquals(
    conceptMatches("El sistema nervioso central.", "Arterias coronarias"),
    false,
  );
});
