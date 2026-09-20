/**
 * Fragment extraction and concept association for the v1 knowledge base.
 * Input is page-level text already extracted from a source document.
 * No database writes are performed here.
 */
export type SourcePage = { page: number; text: string };
export type Fragment = {
  page_start: number; page_end: number; content: string;
  content_hash: string; extraction_method: string;
};
export type ConceptCandidate = {
  concept_key: string; name: string; normalized_name: string;
};

function normalize(value: string): string {
  return String(value || "")
    .normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ").replace(/\s+/g, " ").trim();
}
function clean(value: string): string {
  return String(value || "").replace(/\s+/g, " ").trim();
}

/** Deterministic lightweight hash; suitable for change detection, not security. */
export function contentHash(value: string): string {
  const text = clean(value);
  let hash = 2166136261;
  for (let i = 0; i < text.length; i++) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, "0");
}

/** Groups consecutive pages while preserving source-page provenance. */
export function extractFragments(
  pages: SourcePage[],
  options: { maxPages?: number; maxChars?: number } = {},
): Fragment[] {
  const maxPages = Math.max(1, options.maxPages ?? 3);
  const maxChars = Math.max(500, options.maxChars ?? 12000);
  const fragments: Fragment[] = [];
  let current: SourcePage[] = [];

  const flush = () => {
    if (!current.length) return;
    const content = clean(current.map((p) => p.text).join("\n\n"));
    if (!content) { current = []; return; }
    fragments.push({
      page_start: current[0].page,
      page_end: current[current.length - 1].page,
      content,
      content_hash: contentHash(content),
      extraction_method: "page_text_v1",
    });
    current = [];
  };

  for (const page of pages) {
    const text = clean(page.text);
    if (!text) continue;
    const candidate = clean([...current.map((p) => p.text), text].join("\n\n"));
    if (current.length && (current.length >= maxPages || candidate.length > maxChars)) flush();
    current.push({ page: page.page, text });
  }
  flush();
  return fragments;
}

/** Deterministic first-pass concept association; semantic matching comes later. */
export function associateConcepts(
  fragment: Pick<Fragment, "content">,
  concepts: ConceptCandidate[],
): Array<{ concept_key: string; relevance: number; evidence_type: string }> {
  const text = normalize(fragment.content);
  if (!text) return [];

  return concepts
    .map((concept) => {
      const term = normalize(concept.name || concept.normalized_name);
      if (!term || !text.includes(term)) return null;
      const occurrences = text.split(term).length - 1;
      const relevance = Math.min(1, 0.65 + Math.min(occurrences, 5) * 0.07);
      return {
        concept_key: concept.concept_key,
        relevance: Number(relevance.toFixed(4)),
        evidence_type: "exact_term",
      };
    })
    .filter(Boolean)
    .sort((a, b) => b!.relevance - a!.relevance) as Array<{
      concept_key: string; relevance: number; evidence_type: string;
    }>;
}
