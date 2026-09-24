-- Guarda el progreso de un examen interactivo (rendido dentro de la app),
-- para poder cerrarlo y continuarlo despues, y para tener historial de
-- que preguntas/items fallaron y asi poder reforzarlos en examenes futuros.
create table if not exists public.knowledge_exam_attempts (
  id bigint generated always as identity primary key,
  generation_id bigint references public.knowledge_syllabus_generations(id) on delete set null,
  topic text not null,
  questions jsonb not null,
  answers jsonb not null default '{}'::jsonb,
  graded jsonb,
  nota numeric,
  status text not null default 'in_progress' check (status in ('in_progress','completed')),
  created_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists knowledge_exam_attempts_generation_idx
  on public.knowledge_exam_attempts (generation_id);
create index if not exists knowledge_exam_attempts_status_idx
  on public.knowledge_exam_attempts (status);
create index if not exists knowledge_exam_attempts_updated_idx
  on public.knowledge_exam_attempts (updated_at desc);

alter table public.knowledge_exam_attempts enable row level security;

create policy knowledge_exam_attempts_authenticated_read
  on public.knowledge_exam_attempts
  for select
  to authenticated
  using (true);
