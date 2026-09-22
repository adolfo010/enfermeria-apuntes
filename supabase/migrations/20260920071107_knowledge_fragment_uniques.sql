-- Prevent duplicate fragments when an ingestion is retried.
create unique index if not exists uq_knowledge_fragments_page_hash
  on public.knowledge_fragments(document_id, page_start, page_end, content_hash);
