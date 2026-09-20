import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

async function rest(path: string, init: RequestInit = {}) {
  return fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json", ...(init.headers || {}) },
  });
}
async function authenticatedUser(req: Request) {
  const auth = req.headers.get("Authorization") || "";
  if (!auth.startsWith("Bearer ")) throw new Error("UNAUTHORIZED");
  const r = await fetch(`${SUPABASE_URL}/auth/v1/user`, {headers:{apikey:SERVICE_KEY,Authorization:auth}});
  if (!r.ok) throw new Error("UNAUTHORIZED");
  const u = await r.json();
  if (!u?.id) throw new Error("UNAUTHORIZED");
  return u.id;
}

Deno.serve(async req => {
  if (req.method !== "POST") return Response.json({error:"Method not allowed"},{status:405});
  try {
    const userId = await authenticatedUser(req);
    const body = await req.json().catch(()=>({}));
    const jobId = body.jobId == null ? null : Number(body.jobId);
    if (jobId !== null && !Number.isInteger(jobId)) return Response.json({error:"INVALID_JOB_ID"},{status:400});
    const claimed = await rest("rpc/claim_knowledge_ingest_job", {
      method:"POST",
      body: JSON.stringify({p_job_id:jobId})
    });
    if (!claimed.ok) throw new Error(await claimed.text());
    const job = await claimed.json();
    if (!job?.id) return Response.json({ok:true,claimed:false,message:"NO_PENDING_JOB"});
    if (job.user_id !== userId) {
      await rest(`knowledge_ingest_jobs?id=eq.${job.id}`,{method:"PATCH",body:JSON.stringify({status:"error",error_message:"JOB_OWNER_MISMATCH",updated_at:new Date().toISOString()})});
      throw new Error("JOB_OWNER_MISMATCH");
    }
    const chunk = Number(job.next_chunk);
    const total = Number(job.total_chunks || 0);
    if (body.dryRun === true) return Response.json({ok:true,claimed:true,job_id:job.id,chunk_index:chunk,total_chunks:total,status:"running",message:"Dry run: bloque reclamado, sin modificar progreso."});
    return Response.json({ok:true,claimed:true,job_id:job.id,chunk_index:chunk,total_chunks:total,status:"running",message:"Bloque reclamado; la confirmación solo debe ejecutarse después de persistir sus fragmentos."});
  } catch (e) {
    return Response.json({error:String(e?.message||e)},{status:500});
  }
});