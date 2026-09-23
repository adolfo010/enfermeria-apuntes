-- Documentos 36 y 37 eran pruebas repetidas de la función "IA + Web" (misma
-- consulta "rodilla") hechas mientras se depuraba el feature. Se deja el 38
-- (el más reciente, generado ya con el fix aplicado) y se borran los otros.
delete from public.knowledge_documents where id in (36,37);
