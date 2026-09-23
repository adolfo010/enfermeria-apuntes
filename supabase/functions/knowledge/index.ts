import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL = Deno.env.get("OPENAI_MODEL") ?? "gpt-5.6-luna";
const OPENAI_TIMEOUT_MS = Number(Deno.env.get("OPENAI_TIMEOUT_MS") ?? "180000");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json"
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: corsHeaders });
}

async function getUser(req: Request) {
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) throw new Error("UNAUTHORIZED");
  const r = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { apikey: ANON_KEY || SERVICE_KEY, Authorization: auth }
  });
  if (!r.ok) throw new Error("UNAUTHORIZED");
  return await r.json();
}

async function rest(path: string, init: RequestInit = {}) {
  return fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      "Content-Type": "application/json",
      ...(init.headers || {})
    }
  });
}

function cleanText(v: unknown, max = 160) {
  return String(v ?? "").trim().slice(0, max);
}

function extractOutput(j: any) {
  return (j?.output || [])
    .flatMap((o: any) => o?.content || [])
    .map((p: any) => p?.text || "")
    .join("\n")
    .trim();
}

async function callOpenAI(input: string, maxOutputTokens: number, tools?: any[]) {
  if (!OPENAI_API_KEY) throw new Error("OPENAI_NOT_CONFIGURED");
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), OPENAI_TIMEOUT_MS);
  try {
    const r = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        input,
        max_output_tokens: maxOutputTokens,
        ...(tools ? { tools } : {})
      })
    });
    const j = await r.json();
    if (!r.ok) throw new Error(j?.error?.message || "OPENAI_ERROR");
    return { text: extractOutput(j), citations: extractCitations(j), raw: j };
  } finally {
    clearTimeout(timer);
  }
}

function extractCitations(j: any) {
  const seen = new Map<string, string>();
  for (const o of j?.output || []) {
    for (const p of o?.content || []) {
      for (const a of p?.annotations || []) {
        if (a?.type === "url_citation" && a.url && !seen.has(a.url)) {
          seen.set(a.url, cleanText(a.title || a.url, 200));
        }
      }
    }
  }
  return [...seen.entries()].map(([url, title]) => ({ url, title }));
}

async function recordUsage(user: any, action: string, topic: string, response: any, fragments: any[]) {
  try {
    const u = response?.usage || {};
    const inputTokens = Number(u.input_tokens || 0);
    const cached = Number(u.input_tokens_details?.cached_tokens || 0);
    const outputTokens = Number(u.output_tokens || 0);
    const total = Number(u.total_tokens || inputTokens + outputTokens);
    const inputPrice = Number(Deno.env.get("OPENAI_INPUT_PRICE_PER_MILLION") ?? (OPENAI_MODEL === "gpt-5.6-luna" ? "0.20" : "0"));
    const cachedPrice = Number(Deno.env.get("OPENAI_CACHED_INPUT_PRICE_PER_MILLION") ?? (OPENAI_MODEL === "gpt-5.6-luna" ? "0.02" : "0"));
    const outputPrice = Number(Deno.env.get("OPENAI_OUTPUT_PRICE_PER_MILLION") ?? (OPENAI_MODEL === "gpt-5.6-luna" ? "1.25" : "0"));
    const cost = ((Math.max(0,inputTokens-cached)*inputPrice)+(cached*cachedPrice)+(outputTokens*outputPrice))/1000000;
    await rest("ai_usage", {
      method:"POST",
      headers:{Prefer:"return=minimal"},
      body:JSON.stringify({
        user_id:user?.id ?? null,
        user_email:user?.email ?? null,
        action,
        stage:"knowledge",
        model:OPENAI_MODEL,
        input_tokens:inputTokens,
        cached_input_tokens:cached,
        output_tokens:outputTokens,
        total_tokens:total,
        estimated_cost_usd:cost,
        response_id:response?.id ?? null,
        topic,
        file_count:new Set(fragments.map((f:any)=>f.document_id)).size,
        file_names:[...new Set(fragments.map((f:any)=>f.file_name))]
      })
    });
  } catch (_) {}
}


async function loadFiguresForFragments(fragmentIds:number[]) {
  const ids=[...new Set(fragmentIds.map(Number).filter(Number.isFinite))].slice(0,200);
  if(!ids.length) return new Map<number,any[]>();
  const lr=await rest(`knowledge_fragment_figures?fragment_id=in.(${ids.join(",")})&select=fragment_id,figure_id,relation_type,weight`);
  if(!lr.ok) return new Map<number,any[]>();
  const links=await lr.json();
  const figIds=[...new Set(links.map((x:any)=>Number(x.figure_id)).filter(Number.isFinite))];
  if(!figIds.length) return new Map<number,any[]>();
  const fr=await rest(`knowledge_figures?id=in.(${figIds.join(",")})&status=eq.active&select=id,document_id,figure_key,pdf_page,printed_page,figure_number,caption,storage_path,confidence,status,metadata`);
  if(!fr.ok) return new Map<number,any[]>();
  const figs=await fr.json();
  const fm=new Map(figs.map((x:any)=>[Number(x.id),x]));
  const out=new Map<number,any[]>();
  for(const link of links){
    const f=fm.get(Number(link.figure_id));
    if(!f) continue;
    const item={...f,relationType:link.relation_type,weight:Number(link.weight||0)};
    const arr=out.get(Number(link.fragment_id))||[];
    arr.push(item);
    out.set(Number(link.fragment_id),arr);
  }
  return out;
}

async function search(term: string) {
  const r = await rest("rpc/knowledge_search_fragments", {
    method:"POST",
    body:JSON.stringify({term, limit_count:200})
  });
  if (!r.ok) throw new Error("KNOWLEDGE_SEARCH_FAILED");
  const rows = await r.json();

  const figureMap = await loadFiguresForFragments(rows.map((x:any)=>Number(x.id)));
  const groups = new Map<string, any>();
  for (const x of rows) {
    const route = cleanText(x.ruta || x.titulo || "Sin clasificación", 500);
    const parts = route.split(">").map((p:string)=>p.trim()).filter(Boolean);
    const key = parts.length > 1 ? parts.slice(0,-1).join(" > ") : route;
    if (!groups.has(key)) {
      groups.set(key, {
        id:"route:"+key,
        title:parts.length > 1 ? parts[parts.length-2] : (parts[0] || x.titulo || "Sin título"),
        route,
        levels:parts.length > 1 ? parts.slice(0,-1) : parts,
        sources:new Map<string,any>(),
        fragments:[]
      });
    }
    const g=groups.get(key);
    g.fragments.push({
      id:x.id,
      title:x.titulo || "Fragmento",
      pages:x.page_start===x.page_end ? String(x.page_start) : `${x.page_start}–${x.page_end}`,
      printedPages:x.printed_page_start==null ? null : (x.printed_page_start===x.printed_page_end ? String(x.printed_page_start) : `${x.printed_page_start}–${x.printed_page_end}`),
      type:x.tipo_contenido,
      preview:String(x.content||"").slice(0,420),
      score:Number(x.score||0),
      documentId:x.document_id,
      fileName:x.file_name,
      documentTitle:x.document_title,
      figures:(figureMap.get(Number(x.id))||[]).map((f:any)=>({
        id:f.id,
        figureKey:f.figure_key,
        pdfPage:f.pdf_page,
        printedPage:f.printed_page,
        figureNumber:f.figure_number,
        caption:f.caption,
        storagePath:f.storage_path,
        confidence:f.confidence,
        relationType:f.relationType,
        weight:f.weight
      }))
    });
    const sk=String(x.document_id);
    g.sources.set(sk,{documentId:x.document_id,fileName:x.file_name,title:x.document_title});
  }
  const items=[...groups.values()].map(g=>({
    id:g.id,title:g.title,route:g.route,levels:g.levels,
    sources:[...g.sources.values()],
    fragments:g.fragments.sort((a:any,b:any)=>b.score-a.score)
  }));
  items.sort((a:any,b:any)=>Math.max(...b.fragments.map((x:any)=>x.score))-Math.max(...a.fragments.map((x:any)=>x.score)));
  return { term, count:rows.length, groups:items };
}

async function loadFragments(ids:number[]) {
  const clean=[...new Set(ids.map(Number).filter(Number.isFinite))].slice(0,40);
  if (!clean.length) throw new Error("NO_FRAGMENTS_SELECTED");
  const filter=clean.join(",");
  const r=await rest(`knowledge_fragments?id=in.(${filter})&select=id,document_id,page_start,page_end,pagina_impresa_inicio,pagina_impresa_fin,titulo,ruta,tipo_contenido,content&order=id.asc`);
  if (!r.ok) throw new Error("FRAGMENTS_LOAD_FAILED");
  const rows=await r.json();
  const docIds=[...new Set(rows.map((x:any)=>x.document_id))];
  const dr=await rest(`knowledge_documents?id=in.(${docIds.join(",")})&select=id,file_name,title`);
  const docs=dr.ok?await dr.json():[];
  const dm=new Map(docs.map((d:any)=>[d.id,d]));
  return rows.map((x:any)=>({...x,file_name:dm.get(x.document_id)?.file_name || "Fuente",document_title:dm.get(x.document_id)?.title || dm.get(x.document_id)?.file_name || "Fuente"}));
}

function sourceText(f:any) {
  const pages=f.pagina_impresa_inicio != null
    ? (f.pagina_impresa_inicio===f.pagina_impresa_fin ? `p. impresa ${f.pagina_impresa_inicio}` : `pp. impresas ${f.pagina_impresa_inicio}–${f.pagina_impresa_fin}`)
    : (f.page_start===f.page_end ? `p. ${f.page_start}` : `pp. ${f.page_start}–${f.page_end}`);
  return `[Fuente: ${f.document_title}; ${f.ruta || f.titulo || "sin ruta"}; ${pages}]\n${f.content}`;
}

async function askQuestion(user:any, question:string, topic:string, ids:number[]) {
  const fragments=await loadFragments(ids);
  if (!fragments.length) throw new Error("NO_FRAGMENTS_FOUND");
  let chars=0;
  const selected=fragments.filter((f:any)=>{
    const n=String(f.content||"").length;
    if(chars+n>140000) return false;
    chars+=n; return true;
  });
  const source=selected.map(sourceText).join("\n\n---\n\n");
  const cleanQuestion=cleanText(question,1000);
  if(!cleanQuestion) throw new Error("QUESTION_REQUIRED");
  const cleanTopic=cleanText(topic,300)||"tema seleccionado";
  const prompt=`Respondé la pregunta "${cleanQuestion}" usando EXCLUSIVAMENTE las fuentes proporcionadas y dentro del contexto de "${cleanTopic}". No agregues conocimiento externo ni completes datos faltantes. Explicá con claridad y conservá la terminología de las fuentes. Cuando corresponda, indicá fuente y página. Si las fuentes no permiten responder, decilo expresamente.\n\nFUENTES:\n${source}`;
  const r=await callOpenAI(prompt,7000);
  await recordUsage(user,"knowledgeQuestion",cleanTopic,r.raw,selected);
  return {answer:r.text,sources:selected.map(sourceMeta)};
}

async function generate(user:any, mode:string, topic:string, ids:number[], examOptions:any = {}) {
  const fragments=await loadFragments(ids);
  if (!fragments.length) throw new Error("NO_FRAGMENTS_FOUND");
  let chars=0;
  const selected=fragments.filter((f:any)=>{
    const n=String(f.content||"").length;
    if(chars+n>140000) return false;
    chars+=n; return true;
  });
  const source=selected.map(sourceText).join("\n\n---\n\n");
  const cleanTopic=cleanText(topic,300) || "tema seleccionado";

  if(mode==="summary"){
    const prompt=`Sos un asistente académico para Licenciatura en Enfermería. Prepará un resumen sobre "${cleanTopic}" usando EXCLUSIVAMENTE las fuentes proporcionadas. No agregues conocimiento externo ni completes datos faltantes. Integrá las fuentes sin ocultar diferencias entre ellas. Conservá terminología anatómica y relaciones relevantes. Cada afirmación importante debe indicar su fuente y página entre paréntesis. Si las fuentes seleccionadas no alcanzan para una afirmación, no la inventes.\n\nFUENTES:\n${source}`;
    const r=await callOpenAI(prompt,10000);
    await recordUsage(user,"knowledgeSummary",cleanTopic,r.raw,selected);
    return {summary:r.text,sources:selected.map(sourceMeta)};
  }

  const count=Math.max(1,Math.min(20,Number(examOptions.count)||10));
  const examType=cleanText(examOptions.examType,80)||"Mixto";
  const difficulty=Math.max(1,Math.min(5,Number(examOptions.difficulty)||3));
  const prompt=`Generá exactamente ${count} preguntas de examen sobre "${cleanTopic}" usando EXCLUSIVAMENTE las fuentes proporcionadas. Tipo solicitado: ${examType}. Dificultad: ${difficulty}/5. Cada pregunta debe incluir enunciado, opciones cuando corresponda, respuesta correcta y fuente/página. No inventes datos. Evitá preguntas redundantes. Devolvé SOLO JSON válido con esta forma: {"questions":[{"question":"...","options":["...","...","...","..."],"answer":0,"source":"..."}]}. Para tipos que no sean opción múltiple, mantené igualmente una estructura compatible con options/answer cuando sea posible.\n\nFUENTES:\n${source}`;
  const r=await callOpenAI(prompt,10000);
  await recordUsage(user,"knowledgeQuestions",cleanTopic,r.raw,selected);
  let parsed:any;
  try { parsed=JSON.parse(r.text.replace(/^\`\`\`json\s*/i,"").replace(/\s*\`\`\`$/,"")); }
  catch { throw new Error("INVALID_QUESTIONS_JSON"); }
  return {questions:Array.isArray(parsed?.questions)?parsed.questions:[],sources:selected.map(sourceMeta)};
}

const WEB_IA_WARNING = "⚠️ Contenido generado por IA a partir de una búsqueda web en el momento de la consulta. No es un libro de cátedra verificado: puede contener errores o imprecisiones. Usar como apoyo y confirmar con la bibliografía oficial.";

async function webResearch(user: any, topic: string) {
  const cleanTopic = cleanText(topic, 300);
  if (!cleanTopic) throw new Error("TOPIC_REQUIRED");
  const prompt = `Sos un asistente académico que ayuda a una estudiante de Licenciatura en Enfermería a armar un apunte de estudio sobre "${cleanTopic}" (anatomía/fisiología humana, contexto de una materia introductoria de estructura y función del cuerpo humano).\n\nBuscá información en la web en fuentes confiables (universidades, sociedades científicas, portales médicos/enfermería reconocidos). Redactá un apunte claro y organizado en español, con títulos y viñetas, en tus propias palabras (no copies texto textual de ninguna fuente). Si hay datos que no encontrás con confianza, decilo en vez de inventarlos.`;
  const r = await callOpenAI(prompt, 6000, [{ type: "web_search" }]);
  if (!r.text.trim()) throw new Error("EMPTY_WEB_RESEARCH");
  await recordUsage(user, "knowledgeWebResearch", cleanTopic, r.raw, []);

  const citations = r.citations || [];
  const citationsText = citations.length
    ? "\n\nFuentes consultadas:\n" + citations.map((c: any) => `- ${c.title}: ${c.url}`).join("\n")
    : "";
  const content = `${WEB_IA_WARNING}\n\n${r.text.trim()}${citationsText}`;

  const docRes = await rest("knowledge_documents", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      drive_file_id: null,
      file_name: `${cleanTopic} (IA + Web)`,
      title: `${cleanTopic} (IA + Web, no verificado)`,
      source_type: "ia_web",
      subject_area: "Anatomia",
      page_count: 1,
      processing_status: "completed",
      metadata: { citations, generated_at: new Date().toISOString(), generated_by: user?.email ?? null }
    })
  });
  if (!docRes.ok) throw new Error("WEB_DOCUMENT_SAVE_FAILED");
  const [doc] = await docRes.json();

  const fragRes = await rest("knowledge_fragments", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({
      document_id: doc.id,
      page_start: 1,
      page_end: 1,
      content,
      tipo_contenido: "texto",
      extraction_method: "ia_web_search",
      estado_fragmento: "COMPLETO",
      ruta: `${cleanTopic} (IA + Web, no verificado)`
    })
  });
  if (!fragRes.ok) throw new Error("WEB_FRAGMENT_SAVE_FAILED");

  return { documentId: doc.id, title: doc.title, content, citations };
}

function sourceMeta(f:any) {
  return {
    documentId:f.document_id,
    fileName:f.file_name,
    title:f.document_title,
    route:f.ruta,
    pageStart:f.page_start,
    pageEnd:f.page_end,
    printedPageStart:f.pagina_impresa_inicio,
    printedPageEnd:f.pagina_impresa_fin
  };
}

Deno.serve(async (req:Request)=>{
  if(req.method==="OPTIONS") return new Response("ok",{headers:corsHeaders});
  try {
    const user=await getUser(req);
    const body=await req.json().catch(()=>({}));
    const action=String(body.action||"");
    if(action==="search"){
      const term=cleanText(body.term,300);
      if(term.length<2) return json({ok:true,term,groups:[],count:0});
      return json({ok:true,...await search(term)});
    }
    if(action==="ask"){
      const ids=Array.isArray(body.fragmentIds)?body.fragmentIds:[];
      const question=cleanText(body.question,1000);
      const topic=cleanText(body.topic,300);
      return json({ok:true,...await askQuestion(user,question,topic,ids)});
    }
    if(action==="generate"){
      const ids=Array.isArray(body.fragmentIds)?body.fragmentIds:[];
      const mode=body.mode==="questions"?"questions":"summary";
      const topic=cleanText(body.topic,300);
      const examOptions={count:body.count,examType:body.examType,difficulty:body.difficulty};
      return json({ok:true,mode,topic,...await generate(user,mode,topic,ids,examOptions)});
    }
    if(action==="webSearch"){
      const topic=cleanText(body.topic,300);
      return json({ok:true,...await webResearch(user,topic)});
    }
    return json({error:"INVALID_ACTION"},400);
  } catch(e:any) {
    const msg=String(e?.message||e);
    const status=msg==="UNAUTHORIZED"?401:400;
    return json({error:msg},status);
  }
});
