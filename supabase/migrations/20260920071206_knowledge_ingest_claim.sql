create or replace function public.claim_knowledge_ingest_job(p_job_id bigint default null)
returns public.knowledge_ingest_jobs
language plpgsql
security invoker
as $$
declare v_job public.knowledge_ingest_jobs;
begin
  update public.knowledge_ingest_jobs
  set status='running', started_at=coalesce(started_at, now()), updated_at=now(), error_message=null
  where id = coalesce(p_job_id, (
    select id from public.knowledge_ingest_jobs
    where status in ('pending','error')
    order by updated_at asc
    for update skip locked limit 1
  ))
  and status in ('pending','error')
  returning * into v_job;
  return v_job;
end;
$$;
revoke all on function public.claim_knowledge_ingest_job(bigint) from public;
grant execute on function public.claim_knowledge_ingest_job(bigint) to authenticated;
