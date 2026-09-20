-- Knowledge base v1 seed/prototype from existing indexed topics.
-- Migration helper only; not executed against production.

create or replace function public.normalize_knowledge_term(v text)
returns text
language sql
immutable
as $$
  select regexp_replace(lower(trim(coalesce(v,''))), '[^[:alnum:][:space:]]+', ' ', 'g');
$$;

-- Rebuild-safe indexes for lookup.
create index if not exists idx_kd_fingerprint on public.knowledge_documents(fingerprint);
create index if not exists idx_kc_normalized_name on public.knowledge_concepts(normalized_name);

-- Import strategy:
-- 1. one knowledge_documents row per source document/fingerprint
-- 2. one knowledge_concepts row per normalized academic concept
-- 3. map source topics to concepts
-- 4. retain original page_start/page_end/chunk metadata during extraction
-- 5. do not delete existing ai_document_indexes until validation completes
