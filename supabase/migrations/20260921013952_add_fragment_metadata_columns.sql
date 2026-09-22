-- 1. Extensión de texto sin acentos (ya instalada, pero se deja por idempotencia)
CREATE EXTENSION IF NOT EXISTS unaccent;

-- 1b. Wrapper IMMUTABLE de unaccent, necesario para usarlo en un índice
CREATE OR REPLACE FUNCTION immutable_unaccent(text)
RETURNS text AS $$
  SELECT public.unaccent($1)
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT;

-- 2. Columnas nuevas, todas opcionales (nullable), no tocan filas existentes
ALTER TABLE knowledge_fragments
  ADD COLUMN IF NOT EXISTS titulo text,
  ADD COLUMN IF NOT EXISTS ruta text,
  ADD COLUMN IF NOT EXISTS pagina_impresa_inicio integer,
  ADD COLUMN IF NOT EXISTS pagina_impresa_fin integer,
  ADD COLUMN IF NOT EXISTS pagina_impresa_inferida boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS tipo_contenido text,
  ADD COLUMN IF NOT EXISTS estado_ocr text DEFAULT 'OK',
  ADD COLUMN IF NOT EXISTS estado_fragmento text DEFAULT 'COMPLETO';

-- 3. Índice de texto completo en español, sobre el contenido
CREATE INDEX IF NOT EXISTS knowledge_fragments_content_fts_idx
  ON knowledge_fragments
  USING gin (to_tsvector('spanish', immutable_unaccent(content)));
