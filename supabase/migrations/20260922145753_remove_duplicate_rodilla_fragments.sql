-- Compendio de Anatomía Descriptiva (document_id=2): páginas impresas 131-143
-- (Articulación coxofemoral / de la rodilla) quedaron extraídas dos veces
-- durante el paso "OCR corregido", con dos numeraciones de página PDF distintas.
-- Se conserva el conjunto más completo y específico (241,242,243,244, que cubre
-- 131-143 sin huecos) y se elimina el conjunto incompleto y más genérico
-- (226,227,228,229,230, que tiene un hueco en la página 140 y nunca llega a la 142-143).
-- Verificado: ninguno de los 9 fragmentos tiene figuras vinculadas (knowledge_fragment_figures).
delete from public.knowledge_fragments where id in (226,227,228,229,230);
