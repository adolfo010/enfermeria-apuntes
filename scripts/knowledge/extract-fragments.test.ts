import { assertEquals } from "jsr:@std/assert";
import { associateConcepts, contentHash, extractFragments } from "./extract-fragments.ts";

Deno.test("contentHash is deterministic", () => {
  assertEquals(contentHash("Corazón"), contentHash("Corazón"));
  assertEquals(contentHash("Corazón"), contentHash("Corazón "));
});

Deno.test("extractFragments keeps page provenance", () => {
  const fragments = extractFragments([
    { page: 10, text: "Anatomía del corazón." },
    { page: 11, text: "Las arterias coronarias irrigan el miocardio." },
    { page: 12, text: "La circulación coronaria." },
  ], { maxPages: 2 });

  assertEquals(fragments.length, 2);
  assertEquals(fragments[0].page_start, 10);
  assertEquals(fragments[0].page_end, 11);
  assertEquals(fragments[1].page_start, 12);
});

Deno.test("associateConcepts finds explicit concepts", () => {
  const matches = associateConcepts(
    { content: "Las arterias coronarias irrigan el corazón." },
    [
      { concept_key: "corazon", name: "corazón", normalized_name: "corazon" },
      { concept_key: "arterias coronarias", name: "arterias coronarias", normalized_name: "arterias coronarias" },
    ],
  );
  assertEquals(matches.map((m) => m.concept_key), ["corazon", "arterias coronarias"]);
  assertEquals(matches.every((m) => m.evidence_type === "exact_term"), true);
});
