-- Fase 1 del plan "figuras en Google Drive" (Prompt Maestro secciones 17-23).
-- Columna opcional: no migra ninguna figura existente, solo habilita el soporte.
alter table public.knowledge_figures
  add column if not exists drive_file_id text;

comment on column public.knowledge_figures.drive_file_id is
  'ID del archivo en Google Drive. Si es NULL, la figura sigue sirviéndose desde storage_path (Supabase Storage). No eliminar storage_path mientras existan figuras que dependan de él.';
