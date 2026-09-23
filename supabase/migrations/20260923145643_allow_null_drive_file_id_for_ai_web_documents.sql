-- Los documentos generados por la nueva consulta "IA + Web" (action=webSearch en
-- la función knowledge) no tienen un archivo fuente en Drive: se generan al
-- momento a partir de una búsqueda web. drive_file_id pasa a ser opcional.
alter table public.knowledge_documents alter column drive_file_id drop not null;
