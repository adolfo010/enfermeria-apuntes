-- Seed the v1 knowledge graph from the existing thematic indexes.
-- This migration is intentionally isolated and is NOT applied to production.

insert into public.knowledge_concepts (name, normalized_name, concept_type)
select distinct on (lower(trim(t->>'title')))
  trim(t->>'title'),
  regexp_replace(lower(translate(trim(t->>'title'), 'áéíóúüñÁÉÍÓÚÜÑ', 'aeiouunAEIOUUN')), '[^a-z0-9\\s]', ' ', 'g'),
  'topic'
from public.ai_document_indexes i
cross join lateral jsonb_array_elements(coalesce(i.topics, '[]'::jsonb)) t
where trim(coalesce(t->>'title','')) <> ''
on conflict (normalized_name) do nothing;

insert into public.knowledge_concept_aliases (concept_id, alias, normalized_alias)
select c.id, c.name, c.normalized_name
from public.knowledge_concepts c
where c.concept_type = 'topic'
on conflict (concept_id, normalized_alias) do nothing;
