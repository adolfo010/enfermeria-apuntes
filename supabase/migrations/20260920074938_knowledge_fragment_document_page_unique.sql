-- Make page identity deterministic within a document.
-- Keep the newest fragment when a previous worker retry created a duplicate.
delete from knowledge_fragments f
using knowledge_fragments older
where f.document_id = older.document_id
  and f.page_start = older.page_start
  and f.page_end = older.page_end
  and (
    f.created_at > older.created_at
    or (f.created_at = older.created_at and f.id > older.id)
  );

create unique index if not exists uq_knowledge_fragments_document_page
  on knowledge_fragments (document_id, page_start, page_end);
