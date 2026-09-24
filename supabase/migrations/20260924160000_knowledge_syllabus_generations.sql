-- Guarda cada resumen/examen generado a partir de "Desde un temario",
-- indexado por un hash del texto normalizado + modo + opciones de examen.
-- Sirve para dos cosas:
-- 1) Historial: poder reabrir un resumen/examen ya generado sin repetir el
--    proceso ni gastar tokens de IA de nuevo.
-- 2) Cache automatico: si se pide exactamente el mismo eje (mismo texto,
--    mismo modo, mismas opciones de examen), se devuelve lo ya guardado en
--    vez de volver a buscar fragmentos y llamar a la IA.
create table if not exists public.knowledge_syllabus_generations (
  id bigint generated always as identity primary key,
  syllabus_hash text not null unique,
  mode text not null check (mode in ('summary','questions')),
  topic text not null,
  syllabus_text text not null,
  exam_options jsonb,
  summary text,
  questions jsonb,
  items_covered jsonb not null default '[]'::jsonb,
  sources jsonb not null default '[]'::jsonb,
  created_by text,
  created_at timestamptz not null default now(),
  last_used_at timestamptz not null default now(),
  use_count integer not null default 1
);

create index if not exists knowledge_syllabus_generations_last_used_idx
  on public.knowledge_syllabus_generations (last_used_at desc);

alter table public.knowledge_syllabus_generations enable row level security;

-- Solo lectura directa para usuarios autenticados (mismo criterio que el
-- resto de la base de conocimiento, compartida entre Adolfo y Rossana).
-- Las escrituras (insert/update de cache) se hacen exclusivamente desde la
-- Edge Function "knowledge" con la Service Role Key.
create policy knowledge_syllabus_generations_authenticated_read
  on public.knowledge_syllabus_generations
  for select
  to authenticated
  using (true);
