-- Reset completo del sistema de conocimiento, a pedido explícito del usuario,
-- confirmado dos veces (alcance total, incluyendo Rouvière/Testut-Latarjet y
-- el vocabulario de conceptos). Se reconstruye todo desde cero con el flujo
-- normalizado (extractor 2.10.0 con page_text real, sin estimaciones ni
-- parches). El usuario confirmó que conserva los archivos fuente (PDF/OCR y
-- ZIPs de figuras ya revisados) para volver a cargar Rouvière y Testut-Latarjet.
--
-- No se borran los objetos físicos del bucket de Storage "knowledge-figures"
-- (se dejan como red de seguridad); solo los registros de la base.
--
-- ON DELETE CASCADE se encarga de todo lo dependiente:
-- knowledge_documents -> knowledge_fragments, knowledge_document_concepts,
--   knowledge_ingest_jobs, knowledge_figures -> knowledge_fragment_figures
-- knowledge_concepts -> knowledge_concept_aliases, knowledge_concept_relations,
--   knowledge_fragment_concepts

delete from public.knowledge_documents;
delete from public.knowledge_concepts;
