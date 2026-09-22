-- Rouvière (knowledge_documents.id=5): el cuerpo de texto OCR es legible y
-- confiable, pero los pies de figura y las etiquetas de diagramas están
-- frecuentemente corruptos (ej: "Foscio revodoodenat" por "Fascia
-- retroduodenal", "Pored del mesostourno dorsal" por "Pared del mesogastrio
-- dorsal"). Se deja el documento tal cual por ahora (no se oculta ni se
-- modifica contenido); solo se agrega una nota para poder decidir en el
-- futuro si conviene reprocesarlo con una copia de mejor calidad.

alter table public.knowledge_documents
  add column if not exists metadata jsonb not null default '{}'::jsonb;

update public.knowledge_documents
set metadata = metadata || jsonb_build_object(
  'quality_notes', jsonb_build_array(
    jsonb_build_object(
      'date', '2026-09-22',
      'tag', 'revisar_calidad_ocr',
      'text', 'Cuerpo del texto OCR legible y confiable. Pies de figura y etiquetas de diagramas frecuentemente corruptos (ej.: "Foscio revodoodenat" en vez de "Fascia retroduodenal", "Pored del mesostourno dorsal" en vez de "Pared del mesogastrio dorsal"). Probable causa: copias de mala calidad. Se deja como está por ahora; evaluar reprocesar con mejor copia en el futuro.'
    )
  )
)
where id = 5;
