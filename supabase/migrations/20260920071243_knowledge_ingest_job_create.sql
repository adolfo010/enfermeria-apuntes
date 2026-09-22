create unique index if not exists uq_knowledge_ingest_active_drive
on public.knowledge_ingest_jobs(drive_file_id)
where status in ('pending','running','paused','error');

create or replace function public.create_knowledge_ingest_job(
  p_user_id uuid,
  p_drive_file_id text,
  p_file_name text,
  p_file_fingerprint text,
  p_total_pages integer,
  p_chunk_pages integer default 3
) returns public.knowledge_ingest_jobs
language plpgsql
security invoker
as $$
declare v_job public.knowledge_ingest_jobs;
begin
  if p_chunk_pages < 1 or p_chunk_pages > 10 then raise exception 'INVALID_CHUNK_PAGES'; end if;
  insert into public.knowledge_ingest_jobs(
    user_id,drive_file_id,file_name,file_fingerprint,status,total_pages,chunk_pages,total_chunks,next_chunk,processed_pages
  ) values (
    p_user_id,p_drive_file_id,p_file_name,p_file_fingerprint,'pending',p_total_pages,p_chunk_pages,
    ceil(p_total_pages::numeric / p_chunk_pages)::integer,0,0
  )
  on conflict (drive_file_id) where status in ('pending','running','paused','error') do update
    set file_name=excluded.file_name,file_fingerprint=excluded.file_fingerprint,total_pages=excluded.total_pages,
        chunk_pages=excluded.chunk_pages,total_chunks=excluded.total_chunks,updated_at=now()
  returning * into v_job;
  return v_job;
end;
$$;
revoke all on function public.create_knowledge_ingest_job(uuid,text,text,text,integer,integer) from public;
grant execute on function public.create_knowledge_ingest_job(uuid,text,text,text,integer,integer) to authenticated;
