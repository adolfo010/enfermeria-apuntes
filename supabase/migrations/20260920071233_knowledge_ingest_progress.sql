create or replace function public.complete_knowledge_ingest_chunk(
  p_job_id bigint,
  p_processed_pages integer,
  p_next_chunk integer,
  p_total_pages integer
) returns public.knowledge_ingest_jobs
language plpgsql
security invoker
as $$
declare v_job public.knowledge_ingest_jobs;
begin
  update public.knowledge_ingest_jobs
  set processed_pages = least(greatest(p_processed_pages, processed_pages), coalesce(total_pages,p_total_pages)),
      next_chunk = greatest(p_next_chunk, next_chunk),
      total_pages = coalesce(total_pages,p_total_pages),
      status = case when p_next_chunk >= coalesce(total_chunks, p_next_chunk) then 'completed' else 'running' end,
      completed_at = case when p_next_chunk >= coalesce(total_chunks, p_next_chunk) then now() else completed_at end,
      updated_at = now(),
      error_message = null
  where id=p_job_id and status='running'
  returning * into v_job;
  return v_job;
end;
$$;
revoke all on function public.complete_knowledge_ingest_chunk(bigint,integer,integer,integer) from public;
grant execute on function public.complete_knowledge_ingest_chunk(bigint,integer,integer,integer) to authenticated;
