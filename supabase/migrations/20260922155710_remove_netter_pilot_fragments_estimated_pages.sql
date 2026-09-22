-- Las 4 láminas piloto de Netter (Láminas 2-5) se cargaron con página PDF
-- estimada (pagina_impresa_inferida=true), antes de agregar la exportación
-- de texto por página real al extractor. Se borran para recargarlas con el
-- número de página verdadero una vez que se vuelva a procesar el PDF con
-- "Exportar texto completo por página" (Nivel 2.10.0). El documento
-- knowledge_documents.id=7 (Netter) se conserva.
delete from public.knowledge_fragments where document_id = 7;
