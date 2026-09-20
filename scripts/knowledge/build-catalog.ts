/**
 * Build a v1 knowledge catalog from the legacy ai_document_indexes export.
 *
 * Input:
 *   JSON array of rows with:
 *   { id, drive_file_id, file_name, page_count, topics: [{title,parent,page_start,page_end,chunk_start,chunk_end}] }
 *
 * Output:
 *   { documents, concepts, aliases, documentConcepts }
 *
 * No database writes are performed by this script.
 */

export type LegacyTopic = {
  title?: string;
  parent?: string | null;
  page_start?: number | null;
  page_end?: number | null;
  chunk_start?: number | null;
  chunk_end?: number | null;
};

export type LegacyIndex = {
  id: number;
  drive_file_id: string;
  file_name: string;
  page_count?: number | null;
  topics?: LegacyTopic[] | null;
};

const SOURCE_ROLE_BY_NAME: Array<[RegExp, string]> = [
  [/atlas|netter/i, "atlas"],
  [/resumen|summary/i, "summary"],
  [/pregunta|exam|test/i, "question_bank"],
  [/caso.?cl[ií]nico/i, "clinical_case"],
];

function normalize(value: string): string {
  return String(value || "")
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function clean(value: string): string {
  return String(value || "").replace(/\s+/g, " ").trim();
}

function sourceType(fileName: string): string {
  for (const [rx, type] of SOURCE_ROLE_BY_NAME) if (rx.test(fileName)) return type;
  const lower = fileName.toLowerCase();
  if (/\.pdf$/.test(lower)) return "primary_text";
  if (/\.docx?$/.test(lower)) return "teaching_note";
  return "other";
}

function aliasCandidates(name: string): string[] {
  const out = new Set<string>();
  const cleaned = clean(name);
  if (!cleaned) return [];
  out.add(cleaned);
  out.add(cleaned.replace(/\([^)]*\)/g, "").replace(/\s+/g, " ").trim());
  out.add(cleaned.replace(/\b(cap[ií]tulo|tema|unidad|m[oó]dulo)\s+\d+\b/gi, "").replace(/\s+/g, " ").trim());
  return [...out].filter(Boolean);
}

function mergeRange(a: { page_start: number | null; page_end: number | null }, b: LegacyTopic) {
  const s = Number.isFinite(b.page_start) ? Number(b.page_start) : null;
  const e = Number.isFinite(b.page_end) ? Number(b.page_end) : null;
  if (s !== null) a.page_start = a.page_start === null ? s : Math.min(a.page_start, s);
  if (e !== null) a.page_end = a.page_end === null ? e : Math.max(a.page_end, e);
}

export function buildCatalog(rows: LegacyIndex[]) {
  const concepts = new Map<string, {
    name: string; normalized_name: string; concept_type: string; parent_key: string | null;
  }>();
  const aliases = new Map<string, { normalized_alias: string; alias: string; concept_key: string }>();
  const documents = new Map<string, {
    drive_file_id: string; file_name: string; title: string; source_type: string; page_count: number;
  }>();
  const documentConcepts = new Map<string, {
    drive_file_id: string; concept_key: string; coverage: number; source_role: string;
    page_start: number | null; page_end: number | null;
  }>();

  for (const row of rows) {
    const fileName = clean(row.file_name);
    const driveId = clean(row.drive_file_id);
    if (!driveId || !fileName) continue;

    documents.set(driveId, {
      drive_file_id: driveId,
      file_name: fileName,
      title: fileName.replace(/\.[^.]+$/, ""),
      source_type: sourceType(fileName),
      page_count: Number(row.page_count || 0),
    });

    for (const topic of row.topics || []) {
      const name = clean(topic.title || "");
      if (!name) continue;

      const normalizedName = normalize(name);
      if (!normalizedName) continue;

      const parentName = clean(topic.parent || "");
      const parentKey = parentName ? normalize(parentName) : null;
      const conceptKey = normalizedName;

      if (!concepts.has(conceptKey)) {
        concepts.set(conceptKey, {
          name,
          normalized_name: normalizedName,
          concept_type: parentName ? "topic" : "subject",
          parent_key: parentKey,
        });
      } else if (parentKey && !concepts.get(conceptKey)!.parent_key) {
        concepts.get(conceptKey)!.parent_key = parentKey;
      }

      for (const alias of aliasCandidates(name)) {
        const na = normalize(alias);
        if (na && na !== normalizedName) {
          aliases.set(na + "::" + conceptKey, {
            normalized_alias: na, alias, concept_key: conceptKey,
          });
        }
      }

      const key = driveId + "::" + conceptKey;
      const existing = documentConcepts.get(key);
      if (!existing) {
        documentConcepts.set(key, {
          drive_file_id: driveId,
          concept_key: conceptKey,
          coverage: 1,
          source_role: sourceType(fileName),
          page_start: Number.isFinite(topic.page_start) ? Number(topic.page_start) : null,
          page_end: Number.isFinite(topic.page_end) ? Number(topic.page_end) : null,
        });
      } else {
        mergeRange(existing, topic);
        existing.coverage = Math.min(1, existing.coverage + 0.05);
      }
    }
  }

  return {
    documents: [...documents.values()],
    concepts: [...concepts.values()].map((c) => ({
      ...c,
      parent_key: c.parent_key && concepts.has(c.parent_key) ? c.parent_key : null,
    })),
    aliases: [...aliases.values()],
    documentConcepts: [...documentConcepts.values()],
  };
}

if (import.meta.main) {
  const input = Deno.args[0];
  if (!input) throw new Error("Uso: deno run scripts/knowledge/build-catalog.ts export.json");
  const rows = JSON.parse(await Deno.readTextFile(input)) as LegacyIndex[];
  console.log(JSON.stringify(buildCatalog(rows), null, 2));
}
