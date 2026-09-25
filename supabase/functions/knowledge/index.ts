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

async function loadFragments(ids:number[], maxCount=40) {
  const clean=[...new Set(ids.map(Number).filter(Number.isFinite))].slice(0,maxCount);
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
  const prompt=`Generá exactamente ${count} preguntas de examen sobre "${cleanTopic}" usando EXCLUSIVAMENTE las fuentes proporcionadas. Tipo solicitado: ${examType}. Dificultad: ${difficulty}/5. No inventes datos. Evitá preguntas redundantes.

Reglas por tipo de pregunta (respetalas estrictamente, NO conviertas todo a opción múltiple):
- "Opción múltiple": options debe tener exactamente 4 alternativas, y answer el índice (0-3) de la correcta. correctAnswer va vacío ("").
- "Verdadero/Falso": options debe ser exactamente ["Verdadero","Falso"], y answer el índice (0 o 1) de la correcta. correctAnswer va vacío ("").
- "Respuesta corta", "Desarrollo" o "Caso clínico": options debe ser un arreglo VACÍO [], answer debe ser null, y correctAnswer debe tener la respuesta modelo completa esperada (no una opción, sino la respuesta real en texto).
- Si el tipo solicitado es "Mixto", elegí para cada pregunta un type de los de arriba (variá entre opción múltiple, verdadero/falso y preguntas abiertas) y aplicá la regla que corresponda a ese type.

Devolvé SOLO JSON válido con esta forma exacta: {"questions":[{"question":"...","type":"...","options":[],"answer":null,"correctAnswer":"...","source":"..."}]}\n\nFUENTES:\n${source}`;
  const r=await callOpenAI(prompt,10000);
  await recordUsage(user,"knowledgeQuestions",cleanTopic,r.raw,selected);
  let parsed:any;
  try { parsed=JSON.parse(r.text.replace(/^\`\`\`json\s*/i,"").replace(/\s*\`\`\`$/,"")); }
  catch { throw new Error("INVALID_QUESTIONS_JSON"); }
  return {questions:Array.isArray(parsed?.questions)?parsed.questions:[],sources:selected.map(sourceMeta)};
}

function topicCacheKey(topic: string, ids: number[], mode: string, examOptions: any) {
  const normTopic = cleanText(topic, 300).trim().toLowerCase().replace(/\s+/g, " ");
  const sortedIds = [...new Set(ids.map(Number).filter(Number.isFinite))].sort((a, b) => a - b).join(",");
  const optionsKey = mode === "questions"
    ? `${Number(examOptions?.count) || 10}|${(cleanText(examOptions?.examType, 80) || "Mixto").toLowerCase()}|${Number(examOptions?.difficulty) || 3}`
    : "";
  return `${mode}|${optionsKey}|${normTopic}|${sortedIds}`;
}

async function generateCached(user: any, mode: string, topic: string, ids: number[], examOptions: any = {}) {
  const hash = await sha256Hex(topicCacheKey(topic, ids, mode, examOptions));

  const found = await rest(`knowledge_topic_generations?cache_hash=eq.${hash}&select=*&limit=1`);
  if (found.ok) {
    const rows = await found.json();
    const row = Array.isArray(rows) ? rows[0] : null;
    if (row) {
      rest(`knowledge_topic_generations?id=eq.${row.id}`, {
        method: "PATCH",
        body: JSON.stringify({ last_used_at: new Date().toISOString(), use_count: (row.use_count || 1) + 1 })
      }).catch(() => {});
      return {
        summary: row.summary ?? undefined,
        questions: row.questions ?? undefined,
        sources: row.sources || [],
        fromCache: true
      };
    }
  }

  const result = await generate(user, mode, topic, ids, examOptions);

  try {
    await rest("knowledge_topic_generations", {
      method: "POST",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify({
        cache_hash: hash,
        mode,
        topic: cleanText(topic, 300) || "tema seleccionado",
        fragment_ids: [...new Set(ids.map(Number).filter(Number.isFinite))],
        exam_options: mode === "questions" ? examOptions : null,
        summary: mode === "summary" ? (result as any).summary : null,
        questions: mode === "questions" ? (result as any).questions : null,
        sources: result.sources,
        created_by: user?.email ?? null
      })
    });
  } catch (_) {}

  return { ...result, fromCache: false };
}

function parseSyllabusItems(raw: string) {
  const lines = String(raw||"").split(/\r?\n/);
  const items: string[] = [];
  for (const line of lines) {
    const cleaned = line
      .replace(/^[\s•·\-–—•✓√●◦‣\*\d\.\)]+/, "")
      .trim();
    if (cleaned.length < 3) continue;
    items.push(cleaned.slice(0, 400));
  }
  return items.slice(0, 20);
}

async function rawSearchFragments(term: string, limitCount: number) {
  const r = await rest("rpc/knowledge_search_fragments", {
    method: "POST",
    body: JSON.stringify({ term, limit_count: limitCount })
  });
  if (!r.ok) return [];
  return await r.json();
}

function splitIntoSubterms(label: string) {
  const parts = label.split(/[.:;]/).map(s => s.trim()).filter(s => s.length >= 3);
  return (parts.length ? parts : [label]).slice(0, 6);
}

const PRIORITY_SOURCE_MATCH = /latarjet/i;

function isPrioritySource(documentTitle: string, fileName: string) {
  return PRIORITY_SOURCE_MATCH.test(documentTitle || "") || PRIORITY_SOURCE_MATCH.test(fileName || "");
}

async function gatherSyllabusFragments(itemLabels: string[]) {
  const perItemLimit = 6;
  const priorityReserved = 2;
  const perSubtermCandidates = 12;
  // Los fragmentos de la fuente prioritaria (Latarjet) suelen rankear muy por
  // debajo de resúmenes cortos que matchean el título/ruta con el término
  // buscado (esos reciben un bonus de score en knowledge_search_fragments).
  // Sin esta segunda búsqueda más amplia, Latarjet directamente no entraría
  // al pool de candidatos y la reserva de prioridad de abajo no tendría nada
  // para elegir.
  const prioritySearchLimit = 200;
  const byItem: { item: string; fragmentIds: number[] }[] = [];
  for (const label of itemLabels) {
    const subterms = splitIntoSubterms(label);
    const best = new Map<number, { score: number; documentId: number; priority: boolean }>();
    for (const sub of subterms) {
      const [rows, priorityRows] = await Promise.all([
        rawSearchFragments(sub, perSubtermCandidates),
        rawSearchFragments(sub, prioritySearchLimit)
      ]);
      const combined = [
        ...(Array.isArray(rows) ? rows : []),
        ...(Array.isArray(priorityRows) ? priorityRows : []).filter((row: any) =>
          isPrioritySource(String(row.document_title || ""), String(row.file_name || ""))
        )
      ];
      for (const row of combined) {
        const id = Number(row.id);
        if (!Number.isFinite(id)) continue;
        const score = Number(row.score) || 0;
        const prev = best.get(id);
        if (!prev || score > prev.score) {
          best.set(id, {
            score,
            documentId: Number(row.document_id),
            priority: isPrioritySource(String(row.document_title || ""), String(row.file_name || ""))
          });
        }
      }
    }

    const candidates = [...best.entries()].map(([id, info]) => ({ id, ...info }));
    candidates.sort((a, b) => b.score - a.score);

    const ids: number[] = [];
    const used = new Set<number>();

    // Prioridad: reservamos los primeros lugares para la fuente prioritaria (Latarjet),
    // si tiene fragmentos relevantes para este ítem.
    for (const c of candidates) {
      if (ids.length >= priorityReserved) break;
      if (c.priority && !used.has(c.id)) { ids.push(c.id); used.add(c.id); }
    }

    // Resto de los lugares: round-robin por libro entre TODOS los candidatos restantes
    // (incluida la fuente prioritaria), para que no lo acapare un solo libro.
    const byDoc = new Map<number, typeof candidates>();
    for (const c of candidates) {
      if (used.has(c.id)) continue;
      const arr = byDoc.get(c.documentId) || [];
      arr.push(c);
      byDoc.set(c.documentId, arr);
    }
    const docGroups = [...byDoc.values()];
    let round = 0;
    while (ids.length < perItemLimit) {
      let addedThisRound = false;
      for (const arr of docGroups) {
        if (ids.length >= perItemLimit) break;
        const c = arr[round];
        if (c && !used.has(c.id)) { ids.push(c.id); used.add(c.id); addedThisRound = true; }
      }
      if (!addedThisRound) break;
      round++;
    }

    byItem.push({ item: label, fragmentIds: ids });
  }
  const seen = new Set<number>();
  const orderedIds: number[] = [];
  let more = true;
  let round = 0;
  while (more && orderedIds.length < 60) {
    more = false;
    for (const entry of byItem) {
      const id = entry.fragmentIds[round];
      if (id != null) {
        more = true;
        if (!seen.has(id)) { seen.add(id); orderedIds.push(id); }
      }
    }
    round++;
  }
  return { byItem, orderedIds };
}

async function sha256Hex(input: string) {
  const data = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(hashBuffer)].map(b => b.toString(16).padStart(2, "0")).join("");
}

function syllabusCacheKey(syllabusText: string, mode: string, examOptions: any) {
  const norm = syllabusText.trim().toLowerCase().replace(/\s+/g, " ");
  const optionsKey = mode === "questions"
    ? `${Number(examOptions?.count) || 10}|${(cleanText(examOptions?.examType, 80) || "Mixto").toLowerCase()}|${Number(examOptions?.difficulty) || 3}`
    : `${Number(examOptions?.detailLevel) || 2}|${(examOptions?.summaryFormat === "bullets" ? "bullets" : "paragraphs")}`;
  return `${mode}|${optionsKey}|${norm}`;
}

async function ensureItemFragmentIds(row: any) {
  const itemsCovered = Array.isArray(row.items_covered) ? row.items_covered : [];
  const needsBackfill = itemsCovered.length > 0 && itemsCovered.some((it: any) => !Array.isArray(it.fragmentIds));
  if (!needsBackfill) return itemsCovered;
  const itemLabels = itemsCovered.map((it: any) => it.item);
  const { byItem } = await gatherSyllabusFragments(itemLabels);
  const idsByItem = new Map(byItem.map((e: any) => [e.item, e.fragmentIds]));
  const updated = itemsCovered.map((it: any) => ({
    item: it.item,
    fragmentCount: it.fragmentCount,
    fragmentIds: it.fragmentIds || idsByItem.get(it.item) || []
  }));
  rest(`knowledge_syllabus_generations?id=eq.${row.id}`, {
    method: "PATCH",
    body: JSON.stringify({ items_covered: updated })
  }).catch(() => {});
  return updated;
}

async function generateFromSyllabus(user: any, mode: string, syllabusText: string, examOptions: any = {}, force = false) {
  const hash = await sha256Hex(syllabusCacheKey(syllabusText, mode, examOptions));

  if (!force) {
    const found = await rest(`knowledge_syllabus_generations?syllabus_hash=eq.${hash}&select=*&limit=1`);
    if (found.ok) {
      const rows = await found.json();
      const row = Array.isArray(rows) ? rows[0] : null;
      if (row) {
        rest(`knowledge_syllabus_generations?id=eq.${row.id}`, {
          method: "PATCH",
          body: JSON.stringify({ last_used_at: new Date().toISOString(), use_count: (row.use_count || 1) + 1 })
        }).catch(() => {});
        const itemsCovered = await ensureItemFragmentIds(row);
        return {
          summary: row.summary ?? undefined,
          questions: row.questions ?? undefined,
          topic: row.topic,
          itemsCovered,
          sources: row.sources || [],
          fromCache: true,
          generationId: row.id
        };
      }
    }
  }

  const result = await generateFromSyllabusCore(user, mode, syllabusText, examOptions);

  let generationId: number | undefined;
  try {
    // Con force=true puede ya existir una fila con este mismo syllabus_hash
    // (de una generación anterior con lógica vieja) — usamos upsert para
    // actualizarla en el lugar en vez de fallar por la restricción unique,
    // así se conserva el mismo id (y con él, los intentos de examen ya
    // guardados que lo referencian).
    const ins = await rest("knowledge_syllabus_generations?on_conflict=syllabus_hash", {
      method: "POST",
      headers: { Prefer: "return=representation,resolution=merge-duplicates" },
      body: JSON.stringify({
        syllabus_hash: hash,
        mode,
        topic: result.topic,
        syllabus_text: syllabusText,
        exam_options: mode === "questions" ? examOptions : null,
        summary: mode === "summary" ? (result as any).summary : null,
        questions: mode === "questions" ? (result as any).questions : null,
        items_covered: result.itemsCovered,
        sources: result.sources,
        created_by: user?.email ?? null,
        last_used_at: new Date().toISOString()
      })
    });
    if (ins.ok) {
      const [row] = await ins.json();
      generationId = row?.id;
    }
  } catch (_) {}

  return { ...result, fromCache: false, generationId };
}

async function deleteSyllabusGeneration(user: any, id: number) {
  const r = await rest(`knowledge_syllabus_generations?id=eq.${id}&select=id,created_by&limit=1`);
  if (!r.ok) throw new Error("DELETE_FETCH_FAILED");
  const rows = await r.json();
  const row = Array.isArray(rows) ? rows[0] : null;
  if (!row) throw new Error("NOT_FOUND");
  if (row.created_by && row.created_by !== (user?.email ?? null)) throw new Error("FORBIDDEN");
  await rest(`knowledge_syllabus_generations?id=eq.${id}`, { method: "DELETE" });
  return { deleted: id };
}

async function listSyllabusGenerations() {
  const r = await rest(`knowledge_syllabus_generations?select=id,mode,topic,items_covered,exam_options,created_at,last_used_at,use_count&order=last_used_at.desc&limit=50`);
  if (!r.ok) throw new Error("SYLLABUS_LIST_FAILED");
  return await r.json();
}

async function getSyllabusGeneration(id: number) {
  const r = await rest(`knowledge_syllabus_generations?id=eq.${id}&select=*&limit=1`);
  if (!r.ok) throw new Error("SYLLABUS_GET_FAILED");
  const rows = await r.json();
  const row = Array.isArray(rows) ? rows[0] : null;
  if (!row) throw new Error("SYLLABUS_NOT_FOUND");
  const itemsCovered = await ensureItemFragmentIds(row);
  return {
    generationId: row.id,
    summary: row.summary ?? undefined,
    questions: row.questions ?? undefined,
    topic: row.topic,
    itemsCovered,
    sources: row.sources || [],
    syllabusText: row.syllabus_text,
    mode: row.mode
  };
}

async function saveExamAttempt(user: any, body: any) {
  const id = body?.id != null ? Number(body.id) : null;
  const status = body?.status === "completed" ? "completed" : "in_progress";
  const payload: any = {
    topic: cleanText(body?.topic, 300) || "Examen",
    questions: Array.isArray(body?.questions) ? body.questions : [],
    answers: body?.answers && typeof body.answers === "object" ? body.answers : {},
    status,
    updated_at: new Date().toISOString()
  };
  if (body?.generationId != null && Number.isFinite(Number(body.generationId))) payload.generation_id = Number(body.generationId);
  if (status === "completed") {
    payload.graded = Array.isArray(body?.graded) ? body.graded : null;
    payload.nota = typeof body?.nota === "number" ? body.nota : null;
  }

  if (id) {
    const r = await rest(`knowledge_exam_attempts?id=eq.${id}`, {
      method: "PATCH",
      headers: { Prefer: "return=representation" },
      body: JSON.stringify(payload)
    });
    if (!r.ok) throw new Error("EXAM_ATTEMPT_SAVE_FAILED");
    const [row] = await r.json();
    return { id: row?.id ?? id };
  }

  payload.created_by = user?.email ?? null;
  const r = await rest("knowledge_exam_attempts", {
    method: "POST",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify(payload)
  });
  if (!r.ok) throw new Error("EXAM_ATTEMPT_SAVE_FAILED");
  const [row] = await r.json();
  return { id: row?.id };
}

async function listExamAttempts(filters: any) {
  const parts: string[] = [];
  if (filters?.generationId != null && Number.isFinite(Number(filters.generationId))) parts.push(`generation_id=eq.${Number(filters.generationId)}`);
  if (filters?.status) parts.push(`status=eq.${encodeURIComponent(String(filters.status))}`);
  const query = parts.length ? "&" + parts.join("&") : "";
  const r = await rest(`knowledge_exam_attempts?select=id,generation_id,topic,status,nota,created_at,updated_at${query}&order=updated_at.desc&limit=50`);
  if (!r.ok) throw new Error("EXAM_ATTEMPTS_LIST_FAILED");
  return await r.json();
}

async function getExamAttempt(id: number) {
  const r = await rest(`knowledge_exam_attempts?id=eq.${id}&select=*&limit=1`);
  if (!r.ok) throw new Error("EXAM_ATTEMPT_GET_FAILED");
  const rows = await r.json();
  const row = Array.isArray(rows) ? rows[0] : null;
  if (!row) throw new Error("EXAM_ATTEMPT_NOT_FOUND");
  return {
    id: row.id,
    generationId: row.generation_id,
    topic: row.topic,
    questions: row.questions || [],
    answers: row.answers || {},
    graded: row.graded || null,
    nota: row.nota,
    status: row.status
  };
}

async function generateReviewExam(user: any, generationId: number, examOptions: any = {}) {
  const genRes = await rest(`knowledge_syllabus_generations?id=eq.${generationId}&select=*&limit=1`);
  if (!genRes.ok) throw new Error("SYLLABUS_GET_FAILED");
  const genRows = await genRes.json();
  const generation = Array.isArray(genRows) ? genRows[0] : null;
  if (!generation) throw new Error("SYLLABUS_NOT_FOUND");
  const topicTitle = cleanText(generation.topic, 200);
  const itemsCovered: { item: string; fragmentCount: number }[] = Array.isArray(generation.items_covered) ? generation.items_covered : [];
  const itemLabels = itemsCovered.map(it => it.item);
  if (!itemLabels.length) throw new Error("NO_ITEMS_TO_REVIEW");

  const attemptsRes = await rest(`knowledge_exam_attempts?generation_id=eq.${generationId}&status=eq.completed&select=questions,graded&order=updated_at.desc&limit=10`);
  const attempts = attemptsRes.ok ? await attemptsRes.json() : [];

  const itemScores = new Map<string, number[]>();
  const askedQuestions = new Set<string>();
  for (const att of attempts) {
    const qs = Array.isArray(att.questions) ? att.questions : [];
    const graded = Array.isArray(att.graded) ? att.graded : [];
    qs.forEach((q: any, i: number) => {
      const qText = cleanText(q?.question, 300);
      if (qText) askedQuestions.add(qText);
      const item = cleanText(q?.item, 400);
      const g = graded[i];
      if (item && g && typeof g.score === "number") {
        const arr = itemScores.get(item) || [];
        arr.push(g.score);
        itemScores.set(item, arr);
      }
    });
  }

  const { byItem, orderedIds } = await gatherSyllabusFragments(itemLabels);
  if (!orderedIds.length) throw new Error("NO_MATCHING_MATERIAL");
  const fragments = await loadFragments(orderedIds, 60);
  const fragmentMap = new Map(fragments.map((f: any) => [Number(f.id), f]));

  let chars = 0;
  const blocks: string[] = [];
  const itemsCoveredNew: { item: string; fragmentCount: number; fragmentIds: number[] }[] = [];
  for (const entry of byItem) {
    const frags = entry.fragmentIds.map((id: number) => fragmentMap.get(id)).filter(Boolean);
    const usedIds: number[] = [];
    const parts: string[] = [];
    for (const f of frags) {
      const n = String((f as any).content || "").length;
      if (chars + n > 140000) continue;
      chars += n;
      parts.push(sourceText(f));
      usedIds.push(Number((f as any).id));
    }
    itemsCoveredNew.push({ item: entry.item, fragmentCount: usedIds.length, fragmentIds: usedIds });
    if (parts.length) blocks.push(`=== ÍTEM DEL EJE: ${entry.item} ===\n${parts.join("\n\n")}`);
  }
  const source = blocks.join("\n\n---\n\n");
  if (!source) throw new Error("NO_MATCHING_MATERIAL");

  const itemsWithMaterial = itemsCoveredNew.filter(it => it.fragmentCount > 0);
  const totalCount = Math.max(1, Math.min(30, Number(examOptions.count) || 10));

  const weightOf = (item: string) => {
    const scores = itemScores.get(item);
    if (!scores || !scores.length) return 60;
    const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
    return Math.max(10, 100 - avg);
  };
  const weights = itemsWithMaterial.map(it => weightOf(it.item));
  const totalWeight = weights.reduce((a, b) => a + b, 0) || 1;
  let assigned = 0;
  const distribution = itemsWithMaterial.map((it, i) => {
    const count = i === itemsWithMaterial.length - 1
      ? Math.max(1, totalCount - assigned)
      : Math.max(1, Math.round((weights[i] / totalWeight) * totalCount));
    assigned += count;
    const scores = itemScores.get(it.item);
    const avg = scores && scores.length ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length) : null;
    return { item: it.item, count, avgScore: avg };
  });
  const distributionText = distribution.map(d => `- "${d.item}": ${d.count} pregunta(s)${d.avgScore != null ? ` (rendimiento previo: ${d.avgScore}% de aciertos — reforzar si es bajo)` : " (sin intentos previos)"}`).join("\n");
  const askedText = [...askedQuestions].slice(0, 80).map(q => `- ${q}`).join("\n");
  const examType = cleanText(examOptions.examType, 80) || "Mixto";
  const difficulty = Math.max(1, Math.min(5, Number(examOptions.difficulty) || 3));

  const prompt = `Generá exactamente ${totalCount} preguntas de examen de REPASO para el eje temático "${topicTitle}" usando EXCLUSIVAMENTE las fuentes proporcionadas, agrupadas por ítem del eje (marcadas con "=== ÍTEM DEL EJE: ... ==="). Tipo solicitado: ${examType}. Dificultad: ${difficulty}/5. No inventes datos. Evitá preguntas redundantes.

Este es un examen de REPASO: el estudiante ya rindió este eje antes. Repartí las preguntas priorizando los ítems con peor rendimiento previo, según esta distribución (respetala lo más posible):
${distributionText}

${askedText ? `Preguntas YA UTILIZADAS en intentos anteriores — NO las repitas, generá preguntas DIFERENTES aunque sean sobre el mismo ítem:\n${askedText}\n\n` : ""}Cada pregunta debe incluir el campo "item" con el texto EXACTO del ítem al que corresponde (de la lista de arriba).

Reglas por tipo de pregunta (respetalas estrictamente, NO conviertas todo a opción múltiple):
- "Opción múltiple": options debe tener exactamente 4 alternativas, y answer el índice (0-3) de la correcta. correctAnswer va vacío ("").
- "Verdadero/Falso": options debe ser exactamente ["Verdadero","Falso"], y answer el índice (0 o 1) de la correcta. correctAnswer va vacío ("").
- "Respuesta corta", "Desarrollo" o "Caso clínico": options debe ser un arreglo VACÍO [], answer debe ser null, y correctAnswer debe tener la respuesta modelo completa esperada (no una opción, sino la respuesta real en texto).
- Si el tipo solicitado es "Mixto", elegí para cada pregunta un type de los de arriba (variá entre opción múltiple, verdadero/falso y preguntas abiertas) y aplicá la regla que corresponda a ese type.

Devolvé SOLO JSON válido con esta forma exacta: {"questions":[{"question":"...","type":"...","item":"...","options":[],"answer":null,"correctAnswer":"...","source":"..."}]}\n\nFUENTES POR ÍTEM:\n${source}`;
  const r = await callOpenAI(prompt, 12000);
  await recordUsage(user, "knowledgeSyllabusReview", topicTitle, r.raw, fragments);
  let parsed: any;
  try { parsed = JSON.parse(r.text.replace(/^\`\`\`json\s*/i, "").replace(/\s*\`\`\`$/, "")); }
  catch { throw new Error("INVALID_QUESTIONS_JSON"); }
  return {
    questions: Array.isArray(parsed?.questions) ? parsed.questions : [],
    topic: topicTitle,
    itemsCovered: itemsCoveredNew,
    sources: fragments.map(sourceMeta),
    generationId,
    isReview: true
  };
}

async function generateFromSyllabusCore(user: any, mode: string, syllabusText: string, examOptions: any = {}) {
  const items = parseSyllabusItems(syllabusText);
  if (!items.length) throw new Error("SYLLABUS_EMPTY");
  const topicTitle = cleanText(items[0], 200);

  const { byItem, orderedIds } = await gatherSyllabusFragments(items);
  if (!orderedIds.length) throw new Error("NO_MATCHING_MATERIAL");

  const fragments = await loadFragments(orderedIds, 60);
  const fragmentMap = new Map(fragments.map((f: any) => [Number(f.id), f]));

  let chars = 0;
  const blocks: string[] = [];
  const itemsCovered: { item: string; fragmentCount: number; fragmentIds: number[] }[] = [];
  for (const entry of byItem) {
    const frags = entry.fragmentIds.map((id: number) => fragmentMap.get(id)).filter(Boolean);
    const usedIds: number[] = [];
    const parts: string[] = [];
    for (const f of frags) {
      const n = String((f as any).content || "").length;
      if (chars + n > 140000) continue;
      chars += n;
      parts.push(sourceText(f));
      usedIds.push(Number((f as any).id));
    }
    itemsCovered.push({ item: entry.item, fragmentCount: usedIds.length, fragmentIds: usedIds });
    if (parts.length) {
      blocks.push(`=== ÍTEM DEL EJE: ${entry.item} ===\n${parts.join("\n\n")}`);
    }
  }
  const source = blocks.join("\n\n---\n\n");
  if (!source) throw new Error("NO_MATCHING_MATERIAL");

  if (mode === "summary") {
    const detailLevel = Math.max(1, Math.min(4, Number(examOptions.detailLevel) || 2));
    const useBullets = examOptions.summaryFormat === "bullets";
    const maxTok = [4000, 10000, 12000, 14000][detailLevel - 1];

    const depthInstructions = [
      /* 1 esquemático */
      `Nivel de detalle: ESQUEMÁTICO. Cada ítem debe quedar en una lista de 3 a 6 puntos clave (los conceptos más importantes, sin desarrollo). No escribas párrafos; usá viñetas cortas.`,
      /* 2 estándar */
      `Nivel de detalle: ESTÁNDAR. Para cada ítem escribí 1 o 2 párrafos cortos que cubran los conceptos principales con algo de desarrollo. No es necesario agotar todos los detalles de las fuentes.`,
      /* 3 detallado */
      `Nivel de detalle: DETALLADO. Para cada ítem desarrollá en profundidad definiciones, mecanismos, relaciones anatómicas o fisiológicas y cualquier dato relevante que aparezca en las fuentes. Usá varios párrafos o subsecciones si el contenido lo justifica.`,
      /* 4 exhaustivo */
      `Nivel de detalle: EXHAUSTIVO. Para cada ítem agotá TODO el contenido disponible en las fuentes: variaciones, relaciones clínicas, datos complementarios, excepciones y cualquier detalle que un estudiante deba conocer. El resultado puede ser extenso; priorizá completitud sobre brevedad.`
    ][detailLevel - 1];

    const formatInstruction = useBullets
      ? `Formato: estructurá cada sección con viñetas y sub-viñetas jerarquizadas (Markdown con - y espacios de indentación). No uses párrafos de texto corrido.`
      : `Formato: escribí en párrafos de texto corrido, en prosa. Podés usar sub-encabezados (###) si el ítem lo justifica, pero el cuerpo debe ser prosa, no listas.`;

    const prompt = `Sos un asistente académico para Licenciatura en Enfermería. Prepará apuntes de estudio para el eje temático "${topicTitle}" usando EXCLUSIVAMENTE las fuentes proporcionadas, que ya vienen agrupadas por ítem del eje (marcadas con "=== ÍTEM DEL EJE: ... ==="). Para cada ítem que tenga fuentes, escribí una sección propia con el título EXACTO del ítem como encabezado (formato "## <título del ítem>"). No agregues conocimiento externo ni completes datos faltantes. Cada afirmación importante debe indicar su fuente y página entre paréntesis. Si un ítem no tiene fuentes en el material provisto, escribí su encabezado igual y anotá "Sin material disponible en la base para este ítem." en vez de inventar contenido. No repitas texto idéntico entre secciones si el mismo contenido aplica a varios ítems: elegí la sección más específica.\n\n${depthInstructions}\n\n${formatInstruction}\n\nFUENTES POR ÍTEM:\n${source}`;
    const r = await callOpenAI(prompt, maxTok);
    await recordUsage(user, "knowledgeSyllabusSummary", topicTitle, r.raw, fragments);
    return { summary: r.text, topic: topicTitle, itemsCovered, sources: fragments.map(sourceMeta) };
  }

  const itemsWithMaterial = itemsCovered.filter(it => it.fragmentCount > 0);
  const totalCount = Math.max(1, Math.min(30, Number(examOptions.count) || 10));
  const n = Math.max(1, itemsWithMaterial.length);
  const base = Math.floor(totalCount / n);
  const remainder = totalCount - base * n;
  const distribution = itemsWithMaterial.map((it, i) => ({ item: it.item, count: base + (i < remainder ? 1 : 0) }));
  const distributionText = distribution.map(d => `- "${d.item}": ${d.count} pregunta(s)`).join("\n");
  const examType = cleanText(examOptions.examType, 80) || "Mixto";
  const difficulty = Math.max(1, Math.min(5, Number(examOptions.difficulty) || 3));

  const prompt = `Generá exactamente ${totalCount} preguntas de examen para el eje temático "${topicTitle}" usando EXCLUSIVAMENTE las fuentes proporcionadas, agrupadas por ítem del eje (marcadas con "=== ÍTEM DEL EJE: ... ==="). Tipo solicitado: ${examType}. Dificultad: ${difficulty}/5. No inventes datos. Evitá preguntas redundantes.

Repartí las preguntas por ítem según esta distribución (respetala lo más posible):
${distributionText}

Cada pregunta debe incluir el campo "item" con el texto EXACTO del ítem al que corresponde (de la lista de arriba).

Reglas por tipo de pregunta (respetalas estrictamente, NO conviertas todo a opción múltiple):
- "Opción múltiple": options debe tener exactamente 4 alternativas, y answer el índice (0-3) de la correcta. correctAnswer va vacío ("").
- "Verdadero/Falso": options debe ser exactamente ["Verdadero","Falso"], y answer el índice (0 o 1) de la correcta. correctAnswer va vacío ("").
- "Respuesta corta", "Desarrollo" o "Caso clínico": options debe ser un arreglo VACÍO [], answer debe ser null, y correctAnswer debe tener la respuesta modelo completa esperada (no una opción, sino la respuesta real en texto).
- Si el tipo solicitado es "Mixto", elegí para cada pregunta un type de los de arriba (variá entre opción múltiple, verdadero/falso y preguntas abiertas) y aplicá la regla que corresponda a ese type.

Devolvé SOLO JSON válido con esta forma exacta: {"questions":[{"question":"...","type":"...","item":"...","options":[],"answer":null,"correctAnswer":"...","source":"..."}]}\n\nFUENTES POR ÍTEM:\n${source}`;
  const r = await callOpenAI(prompt, 12000);
  await recordUsage(user, "knowledgeSyllabusQuestions", topicTitle, r.raw, fragments);
  let parsed: any;
  try { parsed = JSON.parse(r.text.replace(/^\`\`\`json\s*/i, "").replace(/\s*\`\`\`$/, "")); }
  catch { throw new Error("INVALID_QUESTIONS_JSON"); }
  return { questions: Array.isArray(parsed?.questions) ? parsed.questions : [], topic: topicTitle, itemsCovered, sources: fragments.map(sourceMeta) };
}

async function gradeAnswers(user:any, topic:string, items:any[]) {
  const clean=(Array.isArray(items)?items:[]).slice(0,30).map((it:any)=>({
    question:cleanText(it?.question,1000),
    correctAnswer:cleanText(it?.correctAnswer,2000),
    userAnswer:cleanText(it?.userAnswer,2000)
  })).filter((it:any)=>it.question);
  if(!clean.length) return {results:[]};
  const cleanTopic=cleanText(topic,300)||"tema seleccionado";
  const list=clean.map((it:any,i:number)=>`${i+1}) PREGUNTA: ${it.question}\nRESPUESTA MODELO: ${it.correctAnswer||"(sin respuesta modelo)"}\nRESPUESTA DEL ESTUDIANTE: ${it.userAnswer||"(sin responder)"}`).join("\n\n");
  const prompt=`Sos un profesor de Enfermería corrigiendo un examen sobre "${cleanTopic}". Para cada pregunta de abajo, comparé la respuesta del estudiante con la respuesta modelo y asigná un puntaje de 0 a 100 según qué tan correcta y completa es. No hace falta texto idéntico, pero el contenido debe ser correcto; una respuesta vacía o sin relación con el tema vale 0. Agregá una devolución breve (1-2 oraciones) explicando qué está bien o qué falta. Devolvé SOLO JSON válido con esta forma exacta, en el mismo orden y cantidad que las preguntas: {"results":[{"score":0,"feedback":"..."}]}\n\n${list}`;
  const r=await callOpenAI(prompt,6000);
  await recordUsage(user,"knowledgeGradeExam",cleanTopic,r.raw,[]);
  let parsed:any;
  try { parsed=JSON.parse(r.text.replace(/^\`\`\`json\s*/i,"").replace(/\s*\`\`\`$/,"")); }
  catch { throw new Error("INVALID_GRADING_JSON"); }
  const results=Array.isArray(parsed?.results)?parsed.results:[];
  return {results:clean.map((_:any,i:number)=>({
    score:Math.max(0,Math.min(100,Number(results[i]?.score)||0)),
    feedback:cleanText(results[i]?.feedback,500)
  }))};
}

const WEB_IA_WARNING = "⚠️ Contenido generado por IA a partir de una búsqueda web en el momento de la consulta. No es un libro de cátedra verificado: puede contener errores o imprecisiones. Usar como apoyo y confirmar con la bibliografía oficial.";

async function webResearch(user: any, topic: string) {
  const cleanTopic = cleanText(topic, 1200);
  if (!cleanTopic) throw new Error("TOPIC_REQUIRED");
  const shortTopic = cleanTopic.length > 150 ? cleanTopic.slice(0, 150).trim() + "…" : cleanTopic;
  const prompt = `Sos un asistente académico que ayuda a una estudiante de Licenciatura en Enfermería a armar un apunte de estudio sobre los siguientes temas/ítems (anatomía/fisiología humana, contexto de una materia introductoria de estructura y función del cuerpo humano):\n\n"${cleanTopic}"\n\nBuscá información en la web en fuentes confiables (universidades, sociedades científicas, portales médicos/enfermería reconocidos) sobre CADA uno de esos temas/ítems. Redactá un apunte claro y organizado en español, con un título o subtítulo por cada tema/ítem cubierto, en tus propias palabras (no copies texto textual de ninguna fuente). Si hay datos que no encontrás con confianza, decilo en vez de inventarlos. No le pidas al usuario que te aclare o complete la información: trabajá directamente con lo que se te dio arriba.`;
  const r = await callOpenAI(prompt, 6000, [{ type: "web_search" }]);
  if (!r.text.trim()) throw new Error("EMPTY_WEB_RESEARCH");
  await recordUsage(user, "knowledgeWebResearch", shortTopic, r.raw, []);

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
      file_name: `${shortTopic} (IA + Web)`,
      title: `${shortTopic} (IA + Web, no verificado)`,
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
      ruta: `${shortTopic} (IA + Web, no verificado)`
    })
  });
  if (!fragRes.ok) throw new Error("WEB_FRAGMENT_SAVE_FAILED");
  const [frag] = await fragRes.json();

  return { documentId: doc.id, fragmentId: frag.id, title: doc.title, content, citations };
}

function stripHtml(s: unknown) {
  return String(s ?? "").replace(/<[^>]*>/g, "").replace(/&nbsp;/g, " ").replace(/\s+/g, " ").trim();
}

const IMAGE_EXT_RE = /\.(jpe?g|png|gif|webp|svg)$/i;

async function commonsSearchRaw(query: string, limit: number) {
  const params = new URLSearchParams({
    action: "query",
    format: "json",
    generator: "search",
    gsrsearch: query,
    gsrnamespace: "6",
    gsrlimit: String(limit),
    prop: "imageinfo",
    iiprop: "url|extmetadata",
    iiurlwidth: "320"
  });
  const r = await fetch(`https://commons.wikimedia.org/w/api.php?${params.toString()}`, {
    headers: { "User-Agent": "EnfermeriaRoxyApp/1.0 (uso educativo; contacto: soporte de la app)" }
  });
  if (!r.ok) return [];
  const j = await r.json();
  const pages = j?.query?.pages ? Object.values(j.query.pages) as any[] : [];
  return pages;
}

function mapCommonsPage(p: any) {
  const info = p?.imageinfo?.[0];
  if (!info?.thumburl) return null;
  const meta = info.extmetadata || {};
  return {
    title: stripHtml(meta.ObjectName?.value || String(p.title || "").replace(/^File:/, "")),
    thumbUrl: info.thumburl,
    fullUrl: info.url,
    descriptionUrl: info.descriptionurl,
    width: info.thumbwidth,
    height: info.thumbheight,
    license: stripHtml(meta.LicenseShortName?.value || meta.License?.value || ""),
    licenseUrl: meta.LicenseUrl?.value || "",
    artist: stripHtml(meta.Artist?.value || ""),
    credit: stripHtml(meta.Credit?.value || ""),
    source: "wikimedia"
  };
}

async function searchCommonsImages(term: string, limit = 12) {
  const cleanTerm = cleanText(term, 200);
  if (!cleanTerm) return [];

  const seen = new Set<string>();
  const images: any[] = [];

  const filteredPages = await commonsSearchRaw(`${cleanTerm} filetype:bitmap|drawing`, limit * 2);
  for (const p of filteredPages) {
    const img = mapCommonsPage(p);
    if (img && !seen.has(img.thumbUrl)) { seen.add(img.thumbUrl); images.push(img); }
    if (images.length >= limit) break;
  }

  if (images.length < limit) {
    const rawPages = await commonsSearchRaw(cleanTerm, limit * 3);
    for (const p of rawPages) {
      if (!IMAGE_EXT_RE.test(String(p?.title || ""))) continue;
      const img = mapCommonsPage(p);
      if (img && !seen.has(img.thumbUrl)) { seen.add(img.thumbUrl); images.push(img); }
      if (images.length >= limit) break;
    }
  }

  return images;
}

const OPENI_BASE = "https://openi.nlm.nih.gov";

async function searchOpenIImages(term: string, limit = 6) {
  const cleanTerm = cleanText(term, 200);
  if (!cleanTerm) return [];
  const params = new URLSearchParams({ query: cleanTerm, it: "g", m: "1", n: String(Math.max(1, limit)) });
  let r: Response;
  try {
    r = await fetch(`${OPENI_BASE}/api/search?${params.toString()}`);
  } catch (_) {
    return [];
  }
  if (!r.ok) return [];
  const j = await r.json().catch(() => null);
  const list = Array.isArray(j?.list) ? j.list : [];
  const images: any[] = [];
  for (const it of list) {
    const img = it?.image || {};
    const thumb = it?.imgGrid150 || it?.imgThumbLarge || it?.imgThumb;
    if (!thumb) continue;
    images.push({
      title: stripHtml(img.caption || it.title || "Imagen médica").slice(0, 250),
      thumbUrl: `${OPENI_BASE}${thumb}`,
      fullUrl: `${OPENI_BASE}${it.imgLarge || thumb}`,
      descriptionUrl: it.pmc_url || it.pubMed_url || `${OPENI_BASE}${it.detailedQueryURL || ""}`,
      license: "Artículo científico de acceso abierto (PMC)",
      licenseUrl: "",
      artist: cleanText(it.authors || "", 200),
      credit: cleanText(it.journal_title || "", 200),
      source: "openi"
    });
    if (images.length >= limit) break;
  }
  return images;
}

// Muchos términos anatómicos de un solo término en español son ambiguos en
// bases mayormente en inglés (ej. "brazo" matchea "Brazo Oriental" -
// Uruguay -, "mano" matchea una ciudad japonesa y una cantante). Traducir a
// un término anatómico en inglés antes de buscar evita ese ruido.
const ANATOMY_ES_EN: Record<string, string> = {
  "esqueleto": "human skeleton",
  "hueso": "human bone anatomy",
  "huesos": "human bones anatomy",
  "articulacion": "human joint anatomy",
  "articulaciones": "human joints anatomy",
  "ligamento": "ligament anatomy",
  "ligamentos": "ligaments anatomy",
  "musculo": "human muscle anatomy",
  "musculos": "human muscles anatomy",
  "musculo estriado": "skeletal muscle anatomy",
  "musculo liso": "smooth muscle anatomy",
  "sistema nervioso": "nervous system anatomy",
  "sistema nervioso central": "central nervous system anatomy",
  "sistema nervioso autonomo": "autonomic nervous system anatomy",
  "sistema nervioso periferico": "peripheral nervous system anatomy",
  "cerebro": "human brain anatomy",
  "cerebelo": "cerebellum anatomy",
  "medula espinal": "spinal cord anatomy",
  "medula": "spinal cord anatomy",
  "tronco encefalico": "brainstem anatomy",
  "hemisferios cerebrales": "cerebral hemispheres anatomy",
  "craneo": "human skull anatomy",
  "cabeza": "human head anatomy",
  "cuello": "human neck anatomy",
  "torax": "human thorax anatomy",
  "pared toracica": "thoracic wall anatomy",
  "columna vertebral": "vertebral column anatomy",
  "raquis": "vertebral column anatomy",
  "cintura escapular": "shoulder girdle anatomy",
  "cintura pelvica": "pelvic girdle anatomy",
  "cintura pelviana": "pelvic girdle anatomy",
  "hombro": "human shoulder anatomy",
  "brazo": "human arm anatomy",
  "antebrazo": "human forearm anatomy",
  "codo": "human elbow anatomy",
  "muñeca": "human wrist anatomy",
  "mano": "human hand anatomy",
  "cadera": "human hip anatomy",
  "pierna": "human leg anatomy",
  "muslo": "human thigh anatomy",
  "rodilla": "human knee anatomy",
  "tibia": "tibia bone anatomy",
  "peroné": "fibula bone anatomy",
  "pie": "human foot anatomy",
  "tobillo": "human ankle anatomy",
  "piel": "human skin anatomy",
  "sangre": "human blood cells",
  "corazon": "human heart anatomy",
  "pulmon": "human lung anatomy",
  "pulmones": "human lungs anatomy",
  "sistema respiratorio": "respiratory system anatomy",
  "sistema circulatorio": "circulatory system anatomy",
  "arteria": "artery anatomy",
  "vena": "vein anatomy",
  "nervio": "nerve anatomy",
  "sistema digestivo": "digestive system anatomy",
  "estomago": "human stomach anatomy",
  "higado": "human liver anatomy",
  "intestino": "human intestine anatomy",
  "pancreas": "human pancreas anatomy",
  "riñon": "human kidney anatomy",
  "riñones": "human kidneys anatomy",
  "sistema urinario": "urinary system anatomy",
  "vejiga": "urinary bladder anatomy",
  "utero": "uterus anatomy",
  "ovario": "human ovary anatomy",
  "testiculo": "human testis anatomy",
  "prostata": "prostate anatomy",
  "genitales": "human genitalia anatomy",
  "mamas": "human breast anatomy",
  "celula": "human cell diagram",
  "tejido": "human tissue diagram",
  "sistema endocrino": "endocrine system anatomy",
  "glandula": "gland anatomy",
  "fosas nasales": "nasal cavity anatomy",
  "senos paranasales": "paranasal sinuses anatomy"
};

const COMBINING_DIACRITICS_RE = new RegExp("[\\u0300-\\u036f]", "g");

function normalizeEs(s: string) {
  return String(s || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(COMBINING_DIACRITICS_RE, "")
    .trim();
}

function translateAnatomyTerm(term: string) {
  const norm = normalizeEs(term);
  return ANATOMY_ES_EN[norm] || null;
}

async function imagesForTerm(term: string, limit: number) {
  const searchTerm = translateAnatomyTerm(term) || term;
  const half = Math.max(2, Math.ceil(limit / 2));
  const [wiki, openi] = await Promise.all([
    searchCommonsImages(searchTerm, half),
    searchOpenIImages(searchTerm, half)
  ]);
  const merged: any[] = [];
  const maxLen = Math.max(wiki.length, openi.length);
  for (let i = 0; i < maxLen; i++) {
    if (wiki[i]) merged.push(wiki[i]);
    if (openi[i]) merged.push(openi[i]);
  }
  return merged.slice(0, limit);
}

async function searchImagesSingle(term: string, limit = 12) {
  const cleanTerm = cleanText(term, 200);
  if (!cleanTerm) return { images: [] };
  return { images: await imagesForTerm(cleanTerm, limit) };
}

async function searchImagesMulti(terms: string[], limitTotal = 12) {
  const cleanTerms = [...new Set(terms.map(t => cleanText(t, 200)).filter(Boolean))].slice(0, 6);
  if (!cleanTerms.length) return { images: [] };
  const perTerm = Math.max(3, Math.ceil(limitTotal / cleanTerms.length));
  const results: any[][] = [];
  for (const t of cleanTerms) {
    results.push(await imagesForTerm(t, perTerm));
  }
  const seen = new Set<string>();
  const merged: any[] = [];
  let round = 0;
  let more = true;
  while (more && merged.length < limitTotal) {
    more = false;
    for (const arr of results) {
      const img = arr[round];
      if (img) {
        more = true;
        if (!seen.has(img.thumbUrl)) { seen.add(img.thumbUrl); merged.push(img); }
      }
    }
    round++;
  }
  return { images: merged };
}

async function appendSyllabusWebResearch(generationId: number, content: string) {
  const clean = String(content || "").trim();
  if (!clean) throw new Error("CONTENT_REQUIRED");
  const r = await rest(`knowledge_syllabus_generations?id=eq.${generationId}&select=summary&limit=1`);
  if (!r.ok) throw new Error("SYLLABUS_GET_FAILED");
  const rows = await r.json();
  const row = Array.isArray(rows) ? rows[0] : null;
  if (!row) throw new Error("SYLLABUS_NOT_FOUND");
  const base = String(row.summary || "").trim();
  const newSummary = `${base}\n\n## Información adicional (búsqueda web con IA)\n\n${clean}`;
  const patch = await rest(`knowledge_syllabus_generations?id=eq.${generationId}`, {
    method: "PATCH",
    headers: { Prefer: "return=representation" },
    body: JSON.stringify({ summary: newSummary })
  });
  if (!patch.ok) throw new Error("SYLLABUS_UPDATE_FAILED");
  const [updated] = await patch.json();
  return { summary: updated.summary };
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
      return json({ok:true,mode,topic,...await generateCached(user,mode,topic,ids,examOptions)});
    }
    if(action==="webSearch"){
      const topic=cleanText(body.topic,300);
      return json({ok:true,...await webResearch(user,topic)});
    }
    if(action==="searchImages"){
      const terms=Array.isArray(body.terms)?body.terms.map((t:any)=>cleanText(t,200)).filter(Boolean):[];
      if(terms.length){
        return json({ok:true,...await searchImagesMulti(terms)});
      }
      const term=cleanText(body.term,200);
      return json({ok:true,...await searchImagesSingle(term)});
    }
    if(action==="gradeAnswers"){
      const topic=cleanText(body.topic,300);
      const items=Array.isArray(body.items)?body.items:[];
      return json({ok:true,...await gradeAnswers(user,topic,items)});
    }
    if(action==="generateFromSyllabus"){
      const mode=body.mode==="questions"?"questions":"summary";
      const syllabusText=String(body.syllabusText||"").slice(0,20000);
      const examOptions={count:body.count,examType:body.examType,difficulty:body.difficulty,detailLevel:body.detailLevel,summaryFormat:body.summaryFormat};
      const force=!!body.force;
      return json({ok:true,mode,...await generateFromSyllabus(user,mode,syllabusText,examOptions,force)});
    }
    if(action==="listSyllabusGenerations"){
      return json({ok:true,items:await listSyllabusGenerations()});
    }
    if(action==="getSyllabusGeneration"){
      const id=Number(body.id);
      if(!Number.isFinite(id)) throw new Error("SYLLABUS_ID_REQUIRED");
      return json({ok:true,...await getSyllabusGeneration(id)});
    }
    if(action==="saveExamAttempt"){
      return json({ok:true,...await saveExamAttempt(user,body)});
    }
    if(action==="listExamAttempts"){
      return json({ok:true,items:await listExamAttempts({generationId:body.generationId,status:body.status})});
    }
    if(action==="getExamAttempt"){
      const id=Number(body.id);
      if(!Number.isFinite(id)) throw new Error("ATTEMPT_ID_REQUIRED");
      return json({ok:true,...await getExamAttempt(id)});
    }
    if(action==="deleteSyllabusGeneration"){
      const id=Number(body.id);
      if(!Number.isFinite(id)) throw new Error("SYLLABUS_ID_REQUIRED");
      return json({ok:true,...await deleteSyllabusGeneration(user,id)});
    }
    if(action==="appendSyllabusWebResearch"){
      const generationId=Number(body.generationId);
      if(!Number.isFinite(generationId)) throw new Error("GENERATION_ID_REQUIRED");
      const content=String(body.content||"");
      return json({ok:true,...await appendSyllabusWebResearch(generationId,content)});
    }
    if(action==="generateReviewExam"){
      const generationId=Number(body.generationId);
      if(!Number.isFinite(generationId)) throw new Error("GENERATION_ID_REQUIRED");
      const examOptions={count:body.count,examType:body.examType,difficulty:body.difficulty};
      return json({ok:true,mode:"questions",...await generateReviewExam(user,generationId,examOptions)});
    }
    return json({error:"INVALID_ACTION"},400);
  } catch(e:any) {
    const msg=String(e?.message||e);
    const status=msg==="UNAUTHORIZED"?401:400;
    return json({error:msg},status);
  }
});
