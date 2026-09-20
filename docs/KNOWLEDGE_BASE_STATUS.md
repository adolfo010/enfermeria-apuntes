# Knowledge base v1 — implementation status

## Implemented in branch

- Isolated database schema migration:
  `supabase/migrations/20260920030000_knowledge_base_v1.sql`
- Retrieval Edge Function prototype:
  `supabase/functions/knowledge/index.ts`
- Retrieval function documentation:
  `supabase/functions/knowledge/README.md`
- Migration strategy:
  `docs/MIGRACION_KNOWLEDGE_BASE_V1.md`

## Next implementation step

Build the importer/transformer that reads existing `ai_document_indexes.topics` and produces:
- knowledge_documents
- knowledge_concepts
- knowledge_document_concepts

Then add fragment extraction and knowledge_fragment_concepts.

Do not deploy or apply migrations to production yet.
