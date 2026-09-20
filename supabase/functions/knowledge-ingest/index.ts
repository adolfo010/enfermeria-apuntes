import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { PDFDocument } from "npm:pdf-lib@1.17.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const OPENAI_MODEL = Deno.env.get("OPENAI_MODEL") ?? "gpt-5.6-luna";

function cors(r: Response) {
  r.headers.set("Access-Control-Allow-Origin", "*");
  r.headers.set("Access-Control-Allow-Headers", "authorization, x-client-info, apikey, content-type");
  return r;
}
async function rest(path: string, init: RequestInit = {}) {
  return fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}`, "Content-Type": "application/json", ...(init.headers || {}) },
  });
}
async function driveToken(): Promise<string> {
  const r = await rest("oauth_tokens?id=eq.rossana&select=*");
  const rows = await r.json();
  if (!rows?.[0]) throw new Error("NOT_CONNECTED");
  return rows[0].access_token;
}
async function driveMeta(id: string, token: string) {
  const r = await fetch(`https://www.googleapis.com/drive/v3/files/${encodeURIComponent(id)}?fields=id,name,mimeType,size,modifiedTime,md5Checksum`, {headers:{Authorization:`Bearer ${token}`}});
  const j = await r.json(); if (!r.ok) throw new Error(j?.error?.message || "DRIVE_META_ERROR"); return j;
}
async function driveBytes(id: string, token: string): Promise<Uint8Array> {
  const r = await fetch(`https://www.googleapis.com/drive/v3/files/${encodeURIComponent(id)}?alt=media`, {headers:{Authorization:`Bearer ${token}`}});
  if (!r.ok) throw new Error("DRIVE_DOWNLOAD_ERROR"); return new Uint8Array(await r.arrayBuffer());
}
function hash(s:string){let h=2166136261;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)}return (h>>>0).toString(16).padStart(8,"0")}
function norm(s:string){return String(s||"").normalize("NFD").replace(/\p{Diacritic}/gu,"").toLowerCase().replace(/[^a-z0-9\s]/g," ").replace(/\s+/g," ").trim()}
async function extractChunk(bytes: Uint8Array, fileName: string, pageStart: number, pageEnd: number) {
  const form = new FormData();
  form.append("purpose","user_data");
  form.append("file",new Blob([bytes],{type:"application/pdf"}),`${fileName} — páginas ${pageStart}-${pageEnd}.pdf`);
  const fr=await fetch("https://api.openai.com/v1/files",{method:"POST",headers:{Authorization:`Bearer ${OPENAI_API_KEY}`},body:form});
  const fj=await fr.json(); if(!fr.ok) throw new Error(fj?.error?.message||"OPENAI_FILE_ERROR");
  try {
    const prompt=`Extraé el contenido académico de estas páginas para una base de conocimiento. Conservá definiciones, explicaciones, relaciones, listas y datos relevantes. NO resumas, NO agregues conocimiento externo y NO inventes contenido. Devolvé exclusivamente JSON con pages, donde cada elemento tenga page (número de página original) y content (texto académico de esa página). Si una página no contiene contenido académico recuperable, usá content vacío. Páginas originales: ${pageStart}-${pageEnd}.`;
    const rr=await fetch("https://api.openai.com/v1/responses",{method:"POST",headers:{Authorization:`Bearer ${OPENAI_API_KEY}`,"Content-Type":"application/json"},body:JSON.stringify({model:OPENAI_MODEL,input:[{role:"user",content:[{type:"input_file",file_id:fj.id},{type:"input_text",text:prompt}]}],text:{format:{type:"json_schema",name:"page_extraction",strict:true,schema:{type:"object",properties:{pages:{type:"array",items:{type:"object",properties:{page:{type:"integer"},content:{type:"string"}},required:["page","content"],additionalProperties:false}}},required:["pages"],additionalProperties:false}}},max_output_tokens:9000})});
    const j=await rr.json(); if(!rr.ok) throw new Error(j?.error?.message||"OPENAI_EXTRACTION_ERROR");
    return JSON.parse(String(j.output_text||"{}"));
  } finally { await fetch(`https://api.openai.com/v1/files/${fj.id}`,{method:"DELETE",headers:{Authorization:`Bearer ${OPENAI_API_KEY}`}).catch(()=>{}); }
}

Deno.serve(async(req)=>{
  if(req.method==="OPTIONS") return cors(new Response("ok"));
  if(req.method!=="POST") return cors(new Response("Method not allowed",{status:405}));
  try{
    const body=await req.json();
    if(body.action!=="ingest") return cors(Response.json({error:"UNKNOWN_ACTION"},{status:400}));
    if(!OPENAI_API_KEY) throw new Error("OPENAI_NOT_CONFIGURED");
    const fileId=String(body.fileId||"").trim(); if(!fileId) return cors(Response.json({error:"Falta fileId"},{status:400}));
    const token=await driveToken(), meta=await driveMeta(fileId,token), bytes=await driveBytes(fileId,token);
    const pdf=await PDFDocument.load(bytes,{ignoreEncryption:true}), pageCount=pdf.getPageCount();
    const fp=meta.md5Checksum?`md5:${meta.md5Checksum}`:`meta:${meta.modifiedTime||""}|${meta.size||""}`;
    const docRes=await rest("knowledge_documents",{method:"POST",headers:{Prefer:"resolution=merge-duplicates,return=representation"},body:JSON.stringify({drive_file_id:fileId,file_name:meta.name,mime_type:meta.mimeType,fingerprint:fp,page_count:pageCount,processing_status:"running",processing_version:"knowledge-v1"})});
    if(!docRes.ok) throw new Error(await docRes.text());
    const doc=(await docRes.json())[0];
    for(let start=1;start<=pageCount;start+=3){
      const end=Math.min(pageCount,start+2), chunk=await PDFDocument.create(), source=pdf;
      const pages=await source.copyPages(source,Array.from({length:end-start+1},(_,i)=>start-1+i));
      pages.forEach(p=>chunk.addPage(p));
      const extracted=await extractChunk(await chunk.save(),meta.name,start,end);
      for(const p of extracted.pages||[]){
        const content=String(p.content||"").trim(); if(!content) continue;
        const ins=await rest("knowledge_fragments",{method:"POST",body:JSON.stringify({document_id:doc.id,page_start:Number(p.page),page_end:Number(p.page),content,content_hash:hash(content),extraction_method:"openai_page_extraction_v1"})});
        if(!ins.ok) throw new Error(await ins.text());
      }
    }
    await rest(`knowledge_documents?id=eq.${doc.id}`,{method:"PATCH",body:JSON.stringify({processing_status:"completed",updated_at:new Date().toISOString()})});
    return cors(Response.json({ok:true,document_id:doc.id,file_name:meta.name,page_count:pageCount}));
  }catch(e){console.error("[knowledge-ingest]",e);return cors(Response.json({error:String(e?.message||e)},{status:500}));}
});