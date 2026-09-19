import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { PDFDocument } from "npm:pdf-lib@1.17.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CLIENT_ID = Deno.env.get("GOOGLE_CLIENT_ID") ?? "";
const CLIENT_SECRET = Deno.env.get("GOOGLE_CLIENT_SECRET") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
const OPENAI_MODEL = Deno.env.get("OPENAI_MODEL") ?? "gpt-5.6-luna";
const OPENAI_TIMEOUT_MS = Number(Deno.env.get("OPENAI_TIMEOUT_MS") ?? "180000");
const MAX_SUMMARIZE_BYTES = 64 * 1024 * 1024;
const MAX_EXTRACT_TOKENS = 12000;
const MAX_FINAL_TOKENS = 10000;
const OPENAI_INPUT_PRICE_PER_MILLION = Number(
  Deno.env.get("OPENAI_INPUT_PRICE_PER_MILLION") ??
  (OPENAI_MODEL === "gpt-5.6-luna" ? "0.20" : "0")
);
const OPENAI_CACHED_INPUT_PRICE_PER_MILLION = Number(
  Deno.env.get("OPENAI_CACHED_INPUT_PRICE_PER_MILLION") ??
  (OPENAI_MODEL === "gpt-5.6-luna" ? "0.02" : "0")
);
const AI_INTERNAL_BUDGET_USD = Number(Deno.env.get("AI_INTERNAL_BUDGET_USD") ?? "4.50");
const OPENAI_OUTPUT_PRICE_PER_MILLION = Number(
  Deno.env.get("OPENAI_OUTPUT_PRICE_PER_MILLION") ??
  (OPENAI_MODEL === "gpt-5.6-luna" ? "1.20" : "0")
);
const FACULTAD_ID = "19Go-oFV3lYOCMT1a970raxoI69MnmX6v";
const APUNTES_ROOT_ID = "1AXHMkLiXFqn2c8gg8bfMSl7L7AOJ1U3S";
const CATALOGO_FILE_ID = "1fq1vXF_KrE3qvSu4wfiPcU-IzvCiUgiE";
const IMG_EXT = new Set(["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "webp"]);
const AÑOS = ["1° Año", "2° Año", "3° Año", "4° Año", "5° Año"];

function cors(res: Response): Response {
  res.headers.set("Access-Control-Allow-Origin", "*");
  res.headers.set("Access-Control-Allow-Headers", "authorization, x-client-info, apikey, content-type");
  return res;
}

async function rest(path: string, init: RequestInit = {}) {
  return fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
  });
}

// Igual que fetch(), pero aborta con AbortError si no hay respuesta dentro de
// timeoutMs. Sin esto, un fetch colgado (ej. Gemini sin responder) deja la
// función esperando para siempre y el usuario ve "Generando..." eternamente.
async function fetchWithTimeout(url: string, init: RequestInit, timeoutMs: number): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

async function getAccessToken(): Promise<string> {
  const res = await rest("oauth_tokens?id=eq.rossana&select=*");
  const rows = await res.json();
  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error("NOT_CONNECTED");
  }
  const row = rows[0];
  const expiresAt = new Date(row.expires_at).getTime();
  if (Date.now() < expiresAt - 60_000) {
    return row.access_token;
  }
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: row.refresh_token,
      grant_type: "refresh_token",
    }),
  });
  const tokenJson = await tokenRes.json();
  if (!tokenRes.ok) {
    throw new Error("REAUTH_REQUIRED");
  }
  const expires_at = new Date(Date.now() + tokenJson.expires_in * 1000).toISOString();
  await rest("oauth_tokens", {
    method: "POST",
    headers: { Prefer: "resolution=merge-duplicates" },
    body: JSON.stringify({ id: "rossana", access_token: tokenJson.access_token, expires_at, updated_at: new Date().toISOString() }),
  });
  return tokenJson.access_token;
}

async function driveFetch(path: string, accessToken: string, init: RequestInit = {}) {
  const res = await fetch(`https://www.googleapis.com/drive/v3/${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
  });
  const json = await res.json();
  if (!res.ok) throw new Error(json?.error?.message || "Error de Google Drive");
  return json;
}

function base64ToBytes(base64: string): Uint8Array {
  const bin = atob(base64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

function bytesToBase64(bytes: Uint8Array): string {
  let bin = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    bin += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(bin);
}

const GOOGLE_NATIVE_PREFIX = "application/vnd.google-apps.";
const DIRECT_MIME = new Set(["application/pdf", "text/plain", "image/png", "image/jpeg", "image/webp", "image/heic", "image/heif"]);
// Formatos de Office/OpenDocument que Drive puede convertir a un tipo nativo de Google
// (y de ahí exportar a PDF) antes de mandárselo a Gemini, que no entiende .docx/.pptx/.xlsx directo.
const CONVERTIBLE_TO_GOOGLE: Record<string, string> = {
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "application/vnd.google-apps.document",
  "application/msword": "application/vnd.google-apps.document",
  "application/vnd.oasis.opendocument.text": "application/vnd.google-apps.document",
  "application/rtf": "application/vnd.google-apps.document",
  "application/vnd.openxmlformats-officedocument.presentationml.presentation": "application/vnd.google-apps.presentation",
  "application/vnd.ms-powerpoint": "application/vnd.google-apps.presentation",
  "application/vnd.ms-powerpoint.presentation.macroenabled.12": "application/vnd.google-apps.presentation",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "application/vnd.google-apps.spreadsheet",
  "application/vnd.ms-excel": "application/vnd.google-apps.spreadsheet",
};

async function downloadBytes(fileId: string, accessToken: string): Promise<Uint8Array> {
  const res = await fetch(`https://www.googleapis.com/drive/v3/files/${fileId}?alt=media`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) throw new Error("No se pudo descargar el archivo desde Drive");
  return new Uint8Array(await res.arrayBuffer());
}

async function exportBytes(fileId: string, mime: string, accessToken: string): Promise<Uint8Array> {
  const res = await fetch(`https://www.googleapis.com/drive/v3/files/${fileId}/export?mimeType=${encodeURIComponent(mime)}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) throw new Error("No se pudo convertir el archivo a PDF para poder resumirlo");
  return new Uint8Array(await res.arrayBuffer());
}

// Deja el contenido de cualquier archivo de Drive en un formato que Gemini pueda leer
// (PDF, texto plano o imagen). Si hace falta pasar por una copia temporal en formato
// Google para convertirlo, devuelve su id para borrarla después de usarla.
async function splitPdfIntoChunks(
  bytes: Uint8Array,
  maxPagesPerChunk = 5,
): Promise<Uint8Array[]> {
  const source = await PDFDocument.load(bytes, { ignoreEncryption: true });
  const pageCount = source.getPageCount();
  if (pageCount <= maxPagesPerChunk) return [bytes];
  const chunks: Uint8Array[] = [];
  for (let start = 0; start < pageCount; start += maxPagesPerChunk) {
    const end = Math.min(start + maxPagesPerChunk, pageCount);
    const chunkDoc = await PDFDocument.create();
    const pages = await chunkDoc.copyPages(source, Array.from({ length: end - start }, (_, i) => start + i));
    pages.forEach(page => chunkDoc.addPage(page));
    chunks.push(await chunkDoc.save({ useObjectStreams: true }));
  }
  return chunks;
}

async function getSummarizableContent(
  fileId: string, mimeType: string, accessToken: string,
): Promise<{ bytes: Uint8Array; mime: string; tempCopyId: string | null }> {
  if (DIRECT_MIME.has(mimeType)) {
    return { bytes: await downloadBytes(fileId, accessToken), mime: mimeType, tempCopyId: null };
  }
  if (mimeType.startsWith(GOOGLE_NATIVE_PREFIX)) {
    return { bytes: await exportBytes(fileId, "application/pdf", accessToken), mime: "application/pdf", tempCopyId: null };
  }
  const targetMime = CONVERTIBLE_TO_GOOGLE[mimeType];
  if (targetMime) {
    const copy = await driveFetch(`files/${fileId}/copy?fields=id`, accessToken, {
      method: "POST",
      body: JSON.stringify({ name: `_tmp_resumen_${Date.now()}`, mimeType: targetMime }),
    });
    const bytes = await exportBytes(copy.id, "application/pdf", accessToken);
    return { bytes, mime: "application/pdf", tempCopyId: copy.id };
  }
  throw new Error("UNSUPPORTED_TYPE");
}


function normalizeForTopic(s: string): string {
  return String(s || "")
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function extractTopLevelSectionByTopic(text: string, topic: string): string | null {
  const normalizedTopic = normalizeForTopic(topic);
  if (!normalizedTopic || !text) return null;

  const lines = text.split(/\r?\n/);
  const headings: { index: number; title: string }[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith("# ") && !line.startsWith("## ")) {
      headings.push({ index: i, title: line.slice(2).trim() });
    }
  }

  const topicWords = normalizedTopic.split(" ").filter(w => w.length > 2);
  const match = headings.find(h => {
    const title = normalizeForTopic(h.title);
    return title === normalizedTopic ||
      title.includes(normalizedTopic) ||
      (topicWords.length > 0 && topicWords.every(w => title.includes(w)));
  });

  if (!match) return null;

  const next = headings.find(h => h.index > match.index);
  return lines.slice(match.index, next ? next.index : lines.length).join("\n").trim() || null;
}

function safeDownloadFileName(name: string): string {
  return String(name || "archivo")
    .replace(/[\\/:*?"<>|\x00-\x1F]/g, "_")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 180) || "archivo";
}

const GOOGLE_EXPORT_MIMES: Record<string, { mime: string; ext: string }> = {
  "application/vnd.google-apps.document": {
    mime: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ext: ".docx",
  },
  "application/vnd.google-apps.spreadsheet": {
    mime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ext: ".xlsx",
  },
  "application/vnd.google-apps.presentation": {
    mime: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ext: ".pptx",
  },
};

async function downloadDriveFile(
  fileId: string,
  accessToken: string,
  requestedMime?: string,
): Promise<Response> {
  const metaRes = await fetch(
    `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}?fields=id,name,mimeType,size,capabilities(canDownload)&supportsAllDrives=true`,
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
  const metaJson = await metaRes.json();
  if (!metaRes.ok) {
    throw new Error(metaJson?.error?.message || "No se pudo consultar el archivo en Google Drive");
  }
  if (metaJson?.capabilities?.canDownload === false) {
    throw new Error("DRIVE_DOWNLOAD_NOT_ALLOWED");
  }

  const native = GOOGLE_EXPORT_MIMES[metaJson.mimeType];
  let url: string;
  let outputName = safeDownloadFileName(metaJson.name);

  if (native) {
    const exportMime = requestedMime && requestedMime === native.mime ? requestedMime : native.mime;
    url = `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}/export?mimeType=${encodeURIComponent(exportMime)}`;
    outputName = /\.[A-Za-z0-9]{1,6}$/.test(outputName)
      ? outputName.replace(/\.[A-Za-z0-9]{1,6}$/, native.ext)
      : outputName + native.ext;
  } else {
    url = `https://www.googleapis.com/drive/v3/files/${encodeURIComponent(fileId)}?alt=media&supportsAllDrives=true`;
  }

  const fileRes = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!fileRes.ok) {
    let detail = "";
    try {
      const j = await fileRes.json();
      detail = j?.error?.message || "";
    } catch (_e) {}
    throw new Error(detail || "No se pudo descargar el archivo desde Drive");
  }

  const headers = new Headers();
  headers.set("Content-Type", fileRes.headers.get("content-type") || metaJson.mimeType || "application/octet-stream");
  headers.set("Content-Disposition", `attachment; filename*=UTF-8''${encodeURIComponent(outputName)}`);
  const contentLength = fileRes.headers.get("content-length");
  if (contentLength) headers.set("Content-Length", contentLength);
  headers.set("Cache-Control", "private, no-store");
  return cors(new Response(fileRes.body, { status: 200, headers }));
}

async function driveUpload(fileName: string, mimeType: string, base64: string, accessToken: string, parentId: string) {
  const bytes = base64ToBytes(base64);
  const uploadRes = await fetch("https://www.googleapis.com/upload/drive/v3/files?uploadType=media", {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": mimeType || "application/octet-stream" },
    body: bytes,
  });
  const uploaded = await uploadRes.json();
  if (!uploadRes.ok) throw new Error(uploaded?.error?.message || "No se pudo subir el archivo");

  const patchRes = await fetch(
    `https://www.googleapis.com/drive/v3/files/${uploaded.id}?addParents=${parentId}&fields=id,name,mimeType,size,webViewLink`,
    { method: "PATCH", headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" }, body: JSON.stringify({ name: fileName }) },
  );
  const patched = await patchRes.json();
  if (!patchRes.ok) throw new Error(patched?.error?.message || "No se pudo mover el archivo a Facultad");
  return patched;
}

interface CatalogRow {
  pathParts: string[];
  name: string;
  folderId: string;
}

async function walkFolder(folderId: string, pathParts: string[], accessToken: string, out: CatalogRow[]): Promise<void> {
  let pageToken: string | undefined;
  const subfolders: { id: string; name: string }[] = [];
  do {
    const params = new URLSearchParams({
      q: `'${folderId}' in parents and trashed = false`,
      pageSize: "1000",
      fields: "nextPageToken, files(id,name,mimeType)",
    });
    if (pageToken) params.set("pageToken", pageToken);
    const data = await driveFetch(`files?${params.toString()}`, accessToken);
    for (const f of data.files || []) {
      if (f.mimeType === "application/vnd.google-apps.folder") {
        subfolders.push({ id: f.id, name: f.name });
      } else {
        out.push({ pathParts, name: f.name, folderId });
      }
    }
    pageToken = data.nextPageToken;
  } while (pageToken);
  // Recorre las subcarpetas en paralelo para que todo el árbol (~160 carpetas)
  // termine en segundos y no se quede esperando de a una.
  await Promise.all(subfolders.map((sf) => walkFolder(sf.id, [...pathParts, sf.name], accessToken, out)));
}

function csvField(v: string): string {
  if (/[",\n]/.test(v)) return '"' + v.replace(/"/g, '""') + '"';
  return v;
}

async function refreshCatalog(accessToken: string): Promise<number> {
  const rows: CatalogRow[] = [];
  await walkFolder(APUNTES_ROOT_ID, [], accessToken, rows);
  const csv = buildCatalogCsv(rows);
  const uploadRes = await fetch(
    `https://www.googleapis.com/upload/drive/v3/files/${CATALOGO_FILE_ID}?uploadType=media`,
    { method: "PATCH", headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "text/csv" }, body: csv },
  );
  const uploaded = await uploadRes.json();
  if (!uploadRes.ok) throw new Error(uploaded?.error?.message || "No se pudo actualizar el catálogo");
  return rows.length;
}

function buildCatalogCsv(rows: CatalogRow[]): string {
  const lines = ["Año,Materia/Categoría,Subcarpeta,Archivo,Tipo,Es imagen (sin texto buscable),Link a la carpeta"];
  const dataRows: string[][] = [];
  for (const r of rows) {
    const top = r.pathParts[0];
    let año: string, materia: string, subcarpeta: string;
    if (AÑOS.includes(top)) {
      año = top;
      materia = r.pathParts[1] || "";
      subcarpeta = r.pathParts.slice(2).join("/");
    } else if (top === "Administrativo" || top === "Biblioteca General") {
      año = "General";
      materia = top;
      subcarpeta = r.pathParts.slice(1).join("/");
    } else if (top === undefined) {
      continue; // archivo suelto en la raíz (el propio catálogo, Correlativas): no se indexa
    } else {
      año = "General";
      materia = top;
      subcarpeta = r.pathParts.slice(1).join("/");
    }
    const ext = r.name.includes(".") ? r.name.split(".").pop()!.toLowerCase() : "";
    const esImagen = IMG_EXT.has(ext) ? "Sí" : "";
    const link = `https://drive.google.com/drive/folders/${r.folderId}`;
    dataRows.push([año, materia, subcarpeta, r.name, ext, esImagen, link]);
  }
  dataRows.sort((a, b) => a[0].localeCompare(b[0]) || a[1].localeCompare(b[1]) || a[2].localeCompare(b[2]) || a[3].localeCompare(b[3]));
  for (const row of dataRows) lines.push(row.map(csvField).join(","));
  return lines.join("\n") + "\n";
}


async function getAuthenticatedUser(req: Request): Promise<{ id: string; email?: string; role: string }> {
  const auth = req.headers.get("Authorization") || "";
  if (!auth.startsWith("Bearer ")) throw new Error("UNAUTHORIZED");
  const token = auth.slice(7).trim();
  if (!token) throw new Error("UNAUTHORIZED");
  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new Error("UNAUTHORIZED");
  const user = await res.json();
  if (!user?.id) throw new Error("UNAUTHORIZED");
  const p = await rest(`profiles?id=eq.${encodeURIComponent(user.id)}&select=role&limit=1`);
  const rows = await p.json();
  return { id: user.id, email: user.email, role: rows?.[0]?.role || "USER" };
}
function requireAdmin(user: { role: string }) {
  if (user.role !== "ADMIN") throw new Error("ADMIN_REQUIRED");
}

async function recordOpenAIUsage(
  responseJson: any,
  meta: {
    user: { id: string; email?: string; role: string };
    action: string;
    stage: string;
    topic?: string;
    files?: { fileName?: string }[];
  },
) {
  try {
    const usage = responseJson?.usage;
    if (!usage) return;
    const inputTokens = Number(usage.input_tokens ?? 0);
    const cachedInputTokens = Number(
      usage.input_tokens_details?.cached_tokens ??
      usage.prompt_tokens_details?.cached_tokens ??
      0
    );
    const outputTokens = Number(usage.output_tokens ?? usage.completion_tokens ?? 0);
    const totalTokens = Number(usage.total_tokens ?? (inputTokens + outputTokens));
    const uncachedInputTokens = Math.max(0, inputTokens - cachedInputTokens);
    const estimatedCostUsd =
      (uncachedInputTokens / 1_000_000) * OPENAI_INPUT_PRICE_PER_MILLION +
      (cachedInputTokens / 1_000_000) * OPENAI_CACHED_INPUT_PRICE_PER_MILLION +
      (outputTokens / 1_000_000) * OPENAI_OUTPUT_PRICE_PER_MILLION;
    await rest("ai_usage", {
      method: "POST",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify({
        user_id: meta.user.id,
        user_email: meta.user.email || null,
        action: meta.action,
        stage: meta.stage,
        model: responseJson?.model || OPENAI_MODEL,
        input_tokens: inputTokens,
        cached_input_tokens: cachedInputTokens,
        output_tokens: outputTokens,
        total_tokens: totalTokens,
        estimated_cost_usd: estimatedCostUsd,
        response_id: responseJson?.id || null,
        topic: meta.topic || null,
        file_count: Array.isArray(meta.files) ? meta.files.length : 0,
        file_names: Array.isArray(meta.files) ? meta.files.map(f => f.fileName || "apunte") : [],
      }),
    });
  } catch (e) {
    console.error("[ai_usage] no se pudo registrar el consumo:", e);
  }
}


async function assertAiBudget():Promise<void>{
 const now=new Date(),m=new Date(Date.UTC(now.getUTCFullYear(),now.getUTCMonth(),1)).toISOString();
 const r=await rest(`ai_usage?select=estimated_cost_usd&created_at=gte.${encodeURIComponent(m)}&limit=10000`);if(!r.ok)return;
 const rows=await r.json(),spent=(rows||[]).reduce((a:number,x:any)=>a+Number(x.estimated_cost_usd||0),0);
 if(spent>=AI_INTERNAL_BUDGET_USD)throw new Error(`AI_BUDGET_EXCEEDED: Se alcanzó el límite interno de consumo de IA de USD ${AI_INTERNAL_BUDGET_USD.toFixed(2)} para este mes.`);
}
function parseJsonObject(raw:string):any{
 const t=String(raw||"").trim();try{return JSON.parse(t);}catch(_){}
 const c=t.replace(/^\s*```(?:json)?\s*/i,"").replace(/\s*```\s*$/i,"").trim();try{return JSON.parse(c);}catch(_){}
 const a=c.indexOf("{"),b=c.lastIndexOf("}");if(a>=0&&b>a)try{return JSON.parse(c.slice(a,b+1));}catch(_){}
 throw new Error("INDEX_JSON_INVALID");
}
function mergeIndexTopics(ex:any[],inc:any[],ps:number,pe:number):any[]{
 const m=new Map<string,any>();
 for(const raw of [...(Array.isArray(ex)?ex:[]),...(Array.isArray(inc)?inc:[])]){
  const title=String(raw?.title||"").trim().replace(/\s+/g," "),parent=String(raw?.parent||"").trim().replace(/\s+/g," ");if(!title||title.length>160)continue;
  const key=normalizeForTopic(parent+" | "+title);if(!key)continue;
  const it={title,parent,page_start:Math.max(1,Number(raw?.page_start||ps)),page_end:Math.max(1,Number(raw?.page_end||pe)),chunk_start:Math.max(0,Number(raw?.chunk_start??Math.floor((ps-1)/3))),chunk_end:Math.max(0,Number(raw?.chunk_end??Math.floor((pe-1)/3)))};
  const old=m.get(key);if(!old)m.set(key,it);else{old.page_start=Math.min(old.page_start,it.page_start);old.page_end=Math.max(old.page_end,it.page_end);old.chunk_start=Math.min(old.chunk_start,it.chunk_start);old.chunk_end=Math.max(old.chunk_end,it.chunk_end);}
 }
 return Array.from(m.values()).sort((a,b)=>(a.page_start-b.page_start)||String(a.parent).localeCompare(String(b.parent),"es")||String(a.title).localeCompare(String(b.title),"es")).slice(0,500);
}
async function getDriveMetaForIndex(fileId:string,token:string):Promise<any>{return await driveFetch(`files/${encodeURIComponent(fileId)}?fields=id,name,mimeType,size,modifiedTime,md5Checksum,webViewLink`,token);}
function indexFingerprint(meta:any):string{return meta?.md5Checksum?`md5:${meta.md5Checksum}`:`meta:${meta?.modifiedTime||""}|${meta?.size||""}`;}
function isDocumentRootTopic(topic:string,fileName:string):boolean{const nt=normalizeForTopic(topic),base=String(fileName||"").replace(/\.[^.]+$/,"");const nf=normalizeForTopic(base);return !!nt&&!!nf&&nt===nf;}
// Dado un tema exacto del índice, devuelve los índices de chunk (bloques de 3
// páginas) que le corresponden a él y a todos sus descendientes en el árbol.
// Usado para acotar qué partes de un PDF indexado hace falta subirle a la IA.
function selectChunkIndexesForTopic(topics:any[],topicTitle:string,totalChunks:number):number[]{
  const nt=normalizeForTopic(topicTitle);
  if(!nt) return [];
  const selected=new Set<string>([nt]);
  let changed=true;
  while(changed){
    changed=false;
    for(const t of topics){
      const title=normalizeForTopic(t.title||""),parent=normalizeForTopic(t.parent||"");
      if(parent&&selected.has(parent)&&!selected.has(title)){selected.add(title);changed=true;}
    }
  }
  const set=new Set<number>();
  for(const t of topics){
    const title=normalizeForTopic(t.title||""),parent=normalizeForTopic(t.parent||"");
    if(selected.has(title)||selected.has(parent)){
      const a=Math.max(0,Number(t.chunk_start||0)),b=Math.min(totalChunks-1,Number(t.chunk_end??a));
      for(let c=a;c<=b;c++) set.add(c);
    }
  }
  return Array.from(set).sort((a,b)=>a-b);
}
// El índice temático es del ARCHIVO, no del usuario que lo generó: los apuntes
// son material institucional compartido entre las cuentas admin, así que una
// vez que alguien indexa un archivo queda disponible para cualquier admin sin
// tener que volver a gastar presupuesto de IA reindexándolo. Por eso estas dos
// consultas ya no filtran por user_id (se sigue guardando quién lo generó,
// solo que no se usa para restringir la búsqueda).
async function getCurrentIndex(uid:string,fid:string,fp:string):Promise<any|null>{const r=await rest(`ai_document_indexes?select=id,user_id,drive_file_id,file_name,file_fingerprint,page_count,topics,model,created_at,updated_at&drive_file_id=eq.${encodeURIComponent(fid)}&file_fingerprint=eq.${encodeURIComponent(fp)}&order=updated_at.desc&limit=1`);if(!r.ok)return null;return (await r.json())?.[0]||null;}
async function getLatestIndexJob(uid:string,fid:string):Promise<any|null>{const r=await rest(`ai_index_jobs?select=id,user_id,drive_file_id,file_name,mime_type,file_fingerprint,status,total_pages,chunk_pages,total_chunks,next_chunk,processed_pages,topics,error_message,model,created_at,updated_at,completed_at&drive_file_id=eq.${encodeURIComponent(fid)}&order=updated_at.desc&limit=1`);if(!r.ok)return null;return (await r.json())?.[0]||null;}
async function runIndexJob(jobId:number,user:{id:string;email?:string;role:string},token:string,initial?:{bytes:Uint8Array;mime:string;tempCopyId:string|null}|null):Promise<void>{
 let tempCopyId:string|null=initial?.tempCopyId||null;
 try{
  const jr=await rest(`ai_index_jobs?select=*&id=eq.${jobId}&limit=1`);if(!jr.ok)throw new Error("INDEX_JOB_NOT_FOUND");const job=(await jr.json())?.[0];if(!job||job.status!=="running")return;
  const content=initial||await getSummarizableContent(job.drive_file_id,job.mime_type,token);tempCopyId=content.tempCopyId||tempCopyId;if(content.bytes.length>MAX_SUMMARIZE_BYTES)throw new Error("TOO_LARGE");
  const pdf=content.mime==="application/pdf"?await PDFDocument.load(content.bytes,{ignoreEncryption:true}):null;const pages=pdf?pdf.getPageCount():1;const chunks=content.mime==="application/pdf"?await splitPdfIntoChunks(content.bytes,3):[content.bytes];const total=chunks.length;
  await rest(`ai_index_jobs?id=eq.${jobId}`,{method:"PATCH",headers:{Prefer:"return=minimal"},body:JSON.stringify({total_pages:pages,total_chunks:total,updated_at:new Date().toISOString()})});
  let current=Number(job.next_chunk||0),topics=Array.isArray(job.topics)?job.topics:[];
  for(let n=0;n<4&&current<total;n++,current++){
   const st=await rest(`ai_index_jobs?select=status&id=eq.${jobId}&limit=1`);if(!st.ok)throw new Error("INDEX_JOB_STATE_ERROR");if((await st.json())?.[0]?.status!=="running")return;
   const ps=current*3+1,pe=Math.min(pages,ps+2),chunk=chunks[current],name=`${job.file_name} — índice parte ${current+1} de ${total}.pdf`;
   const form=new FormData();form.append("purpose","user_data");form.append("file",new Blob([chunk],{type:content.mime}),name);
   const fr=await fetchWithTimeout("https://api.openai.com/v1/files",{method:"POST",headers:{Authorization:`Bearer ${OPENAI_API_KEY}`},body:form},OPENAI_TIMEOUT_MS);const fj=await fr.json();if(!fr.ok)throw new Error(fj?.error?.message||"No se pudo enviar el bloque del índice a OpenAI");
   try{
    await assertAiBudget();
    const existingTopicsList = topics.slice(0,60).map((t:any)=>`- "${t.title}"${t.parent?` (dentro de: "${t.parent}")`:""}`).join("\n");
    const continuityBlock = existingTopicsList
      ? `\nTEMAS YA IDENTIFICADOS EN FRAGMENTOS ANTERIORES DEL MISMO DOCUMENTO:\n${existingTopicsList}\nSi el contenido de este fragmento continúa, profundiza o pertenece a alguno de estos temas, usá EXACTAMENTE el mismo título (carácter por carácter) en "title" o en "parent" según corresponda, en vez de crear un título nuevo o parecido. Creá un tema nuevo únicamente si realmente no continúa ninguno de los ya listados.\n`
      : "";
    const prompt=`Analizá VISUAL Y TEXTUALMENTE ÚNICAMENTE las páginas del archivo PDF adjunto. Construí un ÍNDICE TEMÁTICO DE ESTUDIO del contenido académico que realmente está desarrollado en estas páginas. NO hagas un resumen. El objetivo del índice es permitir que un estudiante seleccione un tema y obtenga después un resumen o preguntas de examen únicamente sobre ese tema.
PRIORIZÁ la estructura académica real del material: títulos de capítulos o apartados, unidades, sistemas, órganos, procesos, conceptos y subtemas que tengan desarrollo explicativo propio. Conservá la terminología del material. NO inventes, no completes con conocimiento externo y no agregues temas solo porque sean habituales en la materia. Si una página contiene texto escaneado o imágenes, inspeccioná igualmente su contenido visible.
${continuityBlock}REGLAS IMPORTANTES:
- Un elemento SOLO debe entrar al índice si tiene DESARROLLO ACADÉMICO suficiente en el fragmento: definición, explicación, características, estructura, función, clasificación, procedimiento, relación con otros conceptos o contenido equivalente.
- NO indexes una palabra o concepto que aparezca solamente como mención, etiqueta de una figura, ejemplo aislado, lista incidental o pregunta introductoria sin desarrollo.
- NO conviertas cada término anatómico o palabra destacada de un esquema en un subtema. Si el esquema solo etiqueta partes, indexá el tema que desarrolla el esquema, no cada etiqueta.
- Si un concepto aparece primero como mención y posteriormente tiene desarrollo propio, indexá el concepto por su desarrollo, no por la mención inicial.
- Evitá fragmentar excesivamente el índice. Preferí un subtema que agrupe contenido estrechamente relacionado cuando el material lo presenta como una misma explicación.
- "title" debe ser el nombre del tema o subtema tal como aparece o se desprende directamente del material.
- "parent" debe ser el tema padre; para temas principales usar cadena vacía.
- No repitas el mismo tema dentro del fragmento.
- Si el fragmento contiene solamente menciones, etiquetas, portada, índice o material sin desarrollo académico identificable, devolvé topics=[].
- Un bloque vacío NO es un error: puede corresponder a portada, índice, separadores o páginas sin contenido académico.
PERSONAS MENCIONADAS: además de los temas académicos, indexá también a las personas sobre las que el material desarrolla contenido real: qué dijo, qué hizo, su teoría o su aporte, o un caso clínico descripto sobre esa persona.
- Solo indexá una persona si el fragmento explica algo concreto sobre ella. No alcanza con que su nombre aparezca una vez sin desarrollo.
- NO indexes como persona a quien solo figura como autor/firma del material (ej: "Lic. Juan Pérez" al pie de una diapositiva) si el contenido no desarrolla nada sobre ella.
- Para una persona, usá "title": su nombre tal como figura en el material, y "parent": "Personas mencionadas".
- IMPORTANTE: si ya creaste un tema de concepto cuyo título incluye el nombre de una persona (por ejemplo "Modelo de Virginia Henderson", "Teoría de Dorothea Orem", "Caso clínico de Juan Pérez"), eso NO reemplaza la entrada de persona: creá TAMBIÉN una entrada aparte con "title" el nombre de la persona sola y "parent": "Personas mencionadas", si el desarrollo del fragmento lo justifica según las reglas de arriba. Un mismo desarrollo puede generar el tema de concepto y la entrada de persona a la vez.
Devolvé exclusivamente el objeto JSON solicitado.`;
    const makeIndexResponse=async(promptText:string,maxTokens:number)=>await fetchWithTimeout("https://api.openai.com/v1/responses",{method:"POST",headers:{Authorization:`Bearer ${OPENAI_API_KEY}`,"Content-Type":"application/json"},body:JSON.stringify({model:OPENAI_MODEL,input:[{role:"user",content:[{type:"input_text",text:"Archivo: "+name},{type:"input_file",file_id:fj.id},{type:"input_text",text:promptText}]}],text:{format:{type:"json_schema",name:"topic_index",description:"Índice temático extraído exclusivamente del PDF adjunto.",strict:true,schema:{type:"object",properties:{topics:{type:"array",items:{type:"object",properties:{title:{type:"string"},parent:{type:"string"}},required:["title","parent"],additionalProperties:false}}},required:["topics"],additionalProperties:false}}},max_output_tokens:maxTokens})},OPENAI_TIMEOUT_MS);
    const rr=await makeIndexResponse(prompt,1800);
    const rj=await rr.json();
    await recordOpenAIUsage(rj,{user,action:"index",stage:"topics",topic:job.file_name,files:[{fileName:job.file_name}]});
    if(!rr.ok)throw new Error(rj?.error?.message||"Error al generar el índice");
    const rawIndexText=String(rj.output_text||((rj.output||[]).flatMap((o)=>o.content||[]).map((p)=>p.text||"").join(""))||"").trim();
    const parsed=parseJsonObject(rawIndexText);
    const incoming=Array.isArray(parsed?.topics)?parsed.topics:[];
    if(incoming.length>0) topics=mergeIndexTopics(topics,incoming,ps,pe);
   }finally{try{await fetch(`https://api.openai.com/v1/files/${fj.id}`,{method:"DELETE",headers:{Authorization:`Bearer ${OPENAI_API_KEY}`}});}catch(_){}}
   await rest(`ai_index_jobs?id=eq.${jobId}`,{method:"PATCH",headers:{Prefer:"return=minimal"},body:JSON.stringify({next_chunk:current+1,processed_pages:pe,topics,updated_at:new Date().toISOString(),error_message:null})});
  }
  const lr=await rest(`ai_index_jobs?select=*&id=eq.${jobId}&limit=1`);const latest=lr.ok?(await lr.json())?.[0]:null;if(!latest)throw new Error("INDEX_JOB_NOT_FOUND");if(latest.status!=="running")return;
  if(Number(latest.next_chunk||0)>=total){
   await rest("ai_document_indexes",{method:"POST",headers:{Prefer:"resolution=merge-duplicates,return=minimal"},body:JSON.stringify({user_id:user.id,drive_file_id:latest.drive_file_id,file_name:latest.file_name,file_fingerprint:latest.file_fingerprint,page_count:pages,topics:latest.topics||topics,model:OPENAI_MODEL,updated_at:new Date().toISOString()})});
   await rest(`ai_index_jobs?id=eq.${jobId}`,{method:"PATCH",headers:{Prefer:"return=minimal"},body:JSON.stringify({status:"completed",processed_pages:pages,updated_at:new Date().toISOString(),completed_at:new Date().toISOString()})});
  }else{
   await rest(`ai_index_jobs?id=eq.${jobId}`,{method:"PATCH",headers:{Prefer:"return=minimal"},body:JSON.stringify({status:"pending",updated_at:new Date().toISOString()})});
  }
 }catch(e:any){const msg=String(e?.message||e);await rest(`ai_index_jobs?id=eq.${jobId}`,{method:"PATCH",headers:{Prefer:"return=minimal"},body:JSON.stringify({status:msg.startsWith("AI_BUDGET_EXCEEDED")?"paused":"error",error_message:msg,updated_at:new Date().toISOString()})});
 }finally{if(tempCopyId){try{await driveFetch(`files/${tempCopyId}`,token,{method:"DELETE"});}catch(_){}}}
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return cors(new Response("ok"));
  if (req.method !== "POST") return cors(new Response("Method not allowed", { status: 405 }));

  try {
    const body = await req.json();
    const action = body.action;
    const user = await getAuthenticatedUser(req);
    const accessToken = await getAccessToken();


    if(action==="indexStatus"){const fileId=String(body.fileId||"").trim();if(!fileId)return cors(new Response(JSON.stringify({error:"Falta fileId"}),{status:400}));const meta=await getDriveMetaForIndex(fileId,accessToken),fp=indexFingerprint(meta);return cors(new Response(JSON.stringify({ok:true,fingerprint:fp,index:await getCurrentIndex(user.id,fileId,fp),job:await getLatestIndexJob(user.id,fileId)}),{headers:{"Content-Type":"application/json"}}));}
    if(action==="indexStart"){
      if(!OPENAI_API_KEY)throw new Error("OPENAI_NOT_CONFIGURED");
      const fileId=String(body.fileId||"").trim();
      if(!fileId)return cors(new Response(JSON.stringify({error:"Falta fileId"}),{status:400}));
      const force=body.force===true;
      const meta=await getDriveMetaForIndex(fileId,accessToken),fp=indexFingerprint(meta);
      if(force){
        // Regenerar a pedido: requiere ADMIN porque descarta el índice
        // compartido actual (y el gasto de IA que costó generarlo) para
        // todos los admins, no solo para quien lo pide.
        requireAdmin(user);
        await rest(`ai_document_indexes?drive_file_id=eq.${encodeURIComponent(fileId)}`,{method:"DELETE"});
        await rest(`ai_index_jobs?drive_file_id=eq.${encodeURIComponent(fileId)}`,{method:"DELETE"});
      }else{
        const existing=await getCurrentIndex(user.id,fileId,fp);
        if(existing)return cors(new Response(JSON.stringify({ok:true,reused:true,index:existing,job:null}),{headers:{"Content-Type":"application/json"}}));
        const latest=await getLatestIndexJob(user.id,fileId);
        if(latest&&["pending","running","paused"].includes(latest.status)&&latest.file_fingerprint===fp)return cors(new Response(JSON.stringify({ok:true,resumed:true,index:null,job:latest}),{headers:{"Content-Type":"application/json"}}));
      }
      const content=await getSummarizableContent(fileId,meta.mimeType,accessToken);
      if(content.bytes.length>MAX_SUMMARIZE_BYTES)throw new Error("TOO_LARGE");
      const pdf=content.mime==="application/pdf"?await PDFDocument.load(content.bytes,{ignoreEncryption:true}):null;
      const pages=pdf?pdf.getPageCount():1,total=content.mime==="application/pdf"?Math.ceil(pages/3):1;
      const ir=await rest("ai_index_jobs",{method:"POST",headers:{Prefer:"return=representation"},body:JSON.stringify({user_id:user.id,drive_file_id:fileId,file_name:meta.name||"apunte",mime_type:meta.mimeType||"application/pdf",file_fingerprint:fp,status:"running",total_pages:pages,chunk_pages:3,total_chunks:total,next_chunk:0,processed_pages:0,topics:[],model:OPENAI_MODEL})});
      if(!ir.ok)throw new Error("No se pudo crear el trabajo de indexación: "+await ir.text());
      const job=(await ir.json())?.[0];
      if(!job)throw new Error("No se pudo crear el trabajo de indexación");
      EdgeRuntime.waitUntil(runIndexJob(job.id,user,accessToken,content));
      return cors(new Response(JSON.stringify({ok:true,index:null,job}),{headers:{"Content-Type":"application/json"}}));
    }
    if(action==="indexRun"){const jobId=Number(body.jobId);if(!jobId)return cors(new Response(JSON.stringify({error:"Falta jobId"}),{status:400}));const jr=await rest(`ai_index_jobs?select=*&id=eq.${jobId}&limit=1`);if(!jr.ok)throw new Error("No se pudo consultar el trabajo de indexación");const job=(await jr.json())?.[0];if(!job)throw new Error("INDEX_JOB_NOT_FOUND");if(["completed","cancelled","paused","running"].includes(job.status))return cors(new Response(JSON.stringify({ok:true,job,alreadyRunning:job.status==="running"}),{headers:{"Content-Type":"application/json"}}));await rest(`ai_index_jobs?id=eq.${jobId}`,{method:"PATCH",headers:{Prefer:"return=minimal"},body:JSON.stringify({status:"running",error_message:null,updated_at:new Date().toISOString()})});EdgeRuntime.waitUntil(runIndexJob(jobId,user,accessToken));return cors(new Response(JSON.stringify({ok:true,started:true,job}),{headers:{"Content-Type":"application/json"}}));}
    if(action==="indexControl"){const jobId=Number(body.jobId),control=String(body.control||"");if(!jobId||!["pause","resume","cancel"].includes(control))return cors(new Response(JSON.stringify({error:"Datos de control inválidos"}),{status:400}));const jr=await rest(`ai_index_jobs?select=*&id=eq.${jobId}&limit=1`);if(!jr.ok)throw new Error("No se pudo consultar el trabajo de indexación");const job=(await jr.json())?.[0];if(!job)throw new Error("INDEX_JOB_NOT_FOUND");const st=control==="pause"?"paused":control==="cancel"?"cancelled":"pending";await rest(`ai_index_jobs?id=eq.${jobId}`,{method:"PATCH",headers:{Prefer:"return=minimal"},body:JSON.stringify({status:st,error_message:control==="cancel"?"Cancelado por el usuario.":null,updated_at:new Date().toISOString()})});if(control==="resume")EdgeRuntime.waitUntil(runIndexJob(jobId,user,accessToken));return cors(new Response(JSON.stringify({ok:true,status:st}),{headers:{"Content-Type":"application/json"}}));}

    if (action === "aiUsage") {
      requireAdmin(user);
      const rowsRes = await rest("ai_usage?select=id,created_at,user_id,user_email,action,stage,model,input_tokens,cached_input_tokens,output_tokens,total_tokens,estimated_cost_usd,response_id,topic,file_count,file_names&order=created_at.desc&limit=1000");
      if (!rowsRes.ok) {
        const txt = await rowsRes.text();
        throw new Error("No se pudo consultar el consumo de IA: " + txt);
      }
      const rows = await rowsRes.json();
      const now = new Date();
      const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
      const currentMonthRows = (rows || []).filter((r: any) => new Date(r.created_at) >= monthStart);
      const sum = (items: any[]) => items.reduce((acc, r) => ({
        requests: acc.requests + 1,
        inputTokens: acc.inputTokens + Number(r.input_tokens || 0),
        cachedInputTokens: acc.cachedInputTokens + Number(r.cached_input_tokens || 0),
        outputTokens: acc.outputTokens + Number(r.output_tokens || 0),
        totalTokens: acc.totalTokens + Number(r.total_tokens || 0),
        estimatedCostUsd: acc.estimatedCostUsd + Number(r.estimated_cost_usd || 0),
      }), { requests: 0, inputTokens: 0, cachedInputTokens: 0, outputTokens: 0, totalTokens: 0, estimatedCostUsd: 0 });
      const currentMonth = sum(currentMonthRows);
      const allTime = sum(rows || []);
      const byAction: Record<string, any> = {};
      currentMonthRows.forEach((r: any) => {
        const key = r.action || "otros";
        if (!byAction[key]) byAction[key] = sum([]);
        const x = byAction[key];
        x.requests += 1;
        x.inputTokens += Number(r.input_tokens || 0);
        x.cachedInputTokens += Number(r.cached_input_tokens || 0);
        x.outputTokens += Number(r.output_tokens || 0);
        x.totalTokens += Number(r.total_tokens || 0);
        x.estimatedCostUsd += Number(r.estimated_cost_usd || 0);
      });
      return cors(new Response(JSON.stringify({
        ok: true,
        pricing: { model: OPENAI_MODEL, inputPerMillion: OPENAI_INPUT_PRICE_PER_MILLION, cachedInputPerMillion: OPENAI_CACHED_INPUT_PRICE_PER_MILLION, outputPerMillion: OPENAI_OUTPUT_PRICE_PER_MILLION },
        currentMonth, allTime, byAction, rows: rows || []
      }), { headers: { "Content-Type": "application/json" } }));
    }

    if (action === "download") {
      const fileId = String(body.fileId || "").trim();
      const requestedMime = body.mimeType ? String(body.mimeType) : undefined;
      if (!fileId) return cors(new Response(JSON.stringify({ error: "Falta fileId" }), { status: 400, headers: { "Content-Type": "application/json" } }));
      return await downloadDriveFile(fileId, accessToken, requestedMime);
    }

    if (action === "search") {
      const term = String(body.term || "").replace(/'/g, "\\'");
      if (!term) return cors(new Response(JSON.stringify({ files: [] }), { headers: { "Content-Type": "application/json" } }));
      const q = `(name contains '${term}' or fullText contains '${term}') and mimeType != 'application/vnd.google-apps.folder' and trashed = false`;
      const params = new URLSearchParams({ q, pageSize: "25", orderBy: "modifiedTime desc", fields: "files(id,name,mimeType,size,webViewLink,md5Checksum,modifiedTime)" });
      const data = await driveFetch(`files?${params.toString()}`, accessToken);
      return cors(new Response(JSON.stringify(data), { headers: { "Content-Type": "application/json" } }));
    }

    if (action === "checkName") {
      const name = String(body.name || "").replace(/'/g, "\\'");
      if (!name) return cors(new Response(JSON.stringify({ files: [] }), { headers: { "Content-Type": "application/json" } }));
      const q = `name = '${name}' and trashed = false`;
      const params = new URLSearchParams({ q, pageSize: "10", fields: "files(id,name,mimeType,parents,webViewLink,owners,capabilities(canTrash,canDelete))" });
      const data = await driveFetch(`files?${params.toString()}`, accessToken);
      return cors(new Response(JSON.stringify(data), { headers: { "Content-Type": "application/json" } }));
    }

    if (action === "facultad") {
      const params = new URLSearchParams({ q: `'${FACULTAD_ID}' in parents and trashed = false`, pageSize: "100", fields: "files(id,name,mimeType,size,webViewLink)" });
      const data = await driveFetch(`files?${params.toString()}`, accessToken);
      const files = data.files || [];
      const ids = files.map((f: any) => `"${f.id}"`).join(",");
      let tracked: Record<string, any> = {};
      if (files.length) {
        const tRes = await rest(`facultad_tracking?file_id=in.(${ids})`);
        const tRows = await tRes.json();
        for (const t of tRows) tracked[t.file_id] = t;
      }
      const pending = files.filter((f: any) => !tracked[f.id]);

      // Buscar, para cada pendiente, si ya existe otro archivo con el mismo nombre
      // en otro lado del Drive (posible duplicado a cotejar antes de clasificar).
      await Promise.all(pending.map(async (f: any) => {
        try {
          const nq = String(f.name).replace(/'/g, "\\'");
          const dparams = new URLSearchParams({ q: `name = '${nq}' and trashed = false`, pageSize: "5", fields: "files(id,name,parents,webViewLink)" });
          const ddata = await driveFetch(`files?${dparams.toString()}`, accessToken);
          const match = (ddata.files || []).find((m: any) => m.id !== f.id && !(m.parents || []).includes(FACULTAD_ID));
          if (match) {
            f.duplicate = { id: match.id, parentId: (match.parents || [])[0] || null, webViewLink: match.webViewLink };
          }
        } catch (_e) { /* si falla la comprobación, no bloqueamos el listado */ }
      }));

      return cors(new Response(JSON.stringify({ pending, total: files.length }), { headers: { "Content-Type": "application/json" } }));
    }

    if (action === "classify" || action === "skip") {
      requireAdmin(user);
      const { fileId, fileName, destFolderId, destNombre } = body;
      if (!fileId || !fileName) return cors(new Response(JSON.stringify({ error: "Faltan datos" }), { status: 400 }));
      if (action === "classify") {
        if (!destFolderId) return cors(new Response(JSON.stringify({ error: "Falta destino" }), { status: 400 }));
        await driveFetch(`files/${fileId}/copy`, accessToken, { method: "POST", body: JSON.stringify({ parents: [destFolderId] }) });
        await driveFetch(`files/${fileId}`, accessToken, { method: "PATCH", body: JSON.stringify({ trashed: true }) });
      }
      await rest("facultad_tracking", {
        method: "POST",
        headers: { Prefer: "resolution=merge-duplicates" },
        body: JSON.stringify({
          file_id: fileId, file_name: fileName,
          status: action === "classify" ? "clasificado" : "ignorado",
          destino_folder_id: destFolderId || null, destino_nombre: destNombre || null,
          updated_at: new Date().toISOString(),
        }),
      });
      if (action === "classify") await refreshCatalog(accessToken);
      return cors(new Response(JSON.stringify({ ok: true }), { headers: { "Content-Type": "application/json" } }));
    }

    if (action === "regenerateCatalog") {
      requireAdmin(user);
      const start = Date.now();
      const count = await refreshCatalog(accessToken);
      return cors(new Response(JSON.stringify({ ok: true, count, tookMs: Date.now() - start }), { headers: { "Content-Type": "application/json" } }));
    }

    if (action === "summarize") {
      const { fileId, mimeType, topic } = body;
      const summaryLevel = Math.min(5, Math.max(1, Number(body.summaryLevel) || 3));
      const technicalLevel = Math.min(5, Math.max(1, Number(body.technicalLevel) || 3));
      const filesInput: { fileId: string; mimeType: string; fileName?: string }[] =
        Array.isArray(body.files) && body.files.length ? body.files : (fileId && mimeType ? [{ fileId, mimeType }] : []);
      if (!filesInput.length) return cors(new Response(JSON.stringify({ error: "Faltan datos" }), { status: 400 }));
      if (!OPENAI_API_KEY) throw new Error("OPENAI_NOT_CONFIGURED");

      const summaryLevels = [
        "muy breve: solo conceptos imprescindibles, en pocas viñetas",
        "breve: síntesis de los puntos principales, evitando detalles secundarios",
        "equilibrado: conceptos principales con explicaciones suficientes para estudiar",
        "detallado: desarrollo amplio de conceptos, relaciones, ejemplos y datos relevantes",
        "muy detallado: cobertura exhaustiva del material, conservando los detalles relevantes para un examen"
      ];
      const technicalLevels = [
        "lenguaje introductorio, claro y accesible, explicando los términos técnicos",
        "lenguaje claro con terminología básica de enfermería y explicaciones breves",
        "nivel académico de enfermería, usando terminología técnica cuando corresponda",
        "nivel técnico alto, con terminología profesional y precisión conceptual",
        "nivel profesional avanzado, conservando la terminología especializada del material y evitando simplificaciones innecesarias"
      ];
      const requestedStyle = `Nivel de extensión del resumen: ${summaryLevel}/5 — ${summaryLevels[summaryLevel - 1]}.
Nivel de tecnicismo: ${technicalLevel}/5 — ${technicalLevels[technicalLevel - 1]}.`;
      const cleanTopic = String(topic || "").trim();
      console.log("[summarize] topic=", JSON.stringify(cleanTopic), "files=", filesInput.map(f => f.fileName));

      const extractionPrompt = cleanTopic
        ? `Analizá el material adjunto de la carrera de Licenciatura en Enfermería y extraé ÚNICAMENTE la información que trate de forma directa o necesaria el tema: "${cleanTopic}".

REGLAS ESTRICTAS:
- Incluí solamente contenido que responda directamente al tema solicitado.
- No incluyas capítulos, conceptos, procedimientos, enfermedades, medicamentos, definiciones ni ejemplos que pertenezcan a otros temas, aunque aparezcan en el mismo archivo.
- Podés incluir contexto únicamente cuando sea indispensable para comprender el tema.
- No completes huecos con conocimiento externo.
- Conservá datos, terminología, relaciones y definiciones presentes en el material.
- Si NO encontrás información suficiente y específica sobre "${cleanTopic}", devolvé EXACTAMENTE: NO_RELEVANT_CONTENT
- Conservá el orden y los subtítulos del material cuando sea posible.
- Incluí TODOS los apartados del tema solicitado que aparezcan en el material, aunque sean extensos.
- No detengas la extracción por haber encontrado suficiente información; recorré todo el archivo antes de responder.
- Devolvé los fragmentos relevantes completos y en el orden en que aparecen.`
        : `Prepará el contenido del material adjunto para ser resumido posteriormente. Conservá la información académicamente relevante del archivo y no agregues conocimiento externo.`;

      const fileIds: string[] = [];
      const tempCopyIds: string[] = [];
      try {
        const extracted: { fileName: string; text: string }[] = [];
        const filesWithoutIndex: string[] = [];

        for (const f of filesInput) {
          const content = await getSummarizableContent(f.fileId, f.mimeType, accessToken);
          if (content.tempCopyId) tempCopyIds.push(content.tempCopyId);
          if (content.bytes.length > MAX_SUMMARIZE_BYTES) {
            throw new Error(`TOO_LARGE: el archivo ${f.fileName || "seleccionado"} supera el límite de 64 MB para procesamiento con IA.`);
          }

          // Los PDFs grandes se dividen físicamente por páginas antes de enviarlos a OpenAI.
          // Tres páginas por petición mantiene cada carga muy por debajo del límite de TPM
          // incluso cuando el PDF contiene mucho texto, tablas o imágenes.
          const allPdfChunks=content.mime==="application/pdf"?await splitPdfIntoChunks(content.bytes,3):[content.bytes];
          let selectedChunkIndexes:number[]|null=null;
          let isRootTopic=false;
          if(cleanTopic){
            const meta=await getDriveMetaForIndex(f.fileId,accessToken),fp=indexFingerprint(meta),idx=await getCurrentIndex(user.id,f.fileId,fp);
            isRootTopic=isDocumentRootTopic(cleanTopic,f.fileName||meta.name||"");
            if(isRootTopic){
              selectedChunkIndexes=allPdfChunks.map((_,i)=>i);
            }else if(idx&&Array.isArray(idx.topics)){
              const nt=normalizeForTopic(cleanTopic),set=new Set<number>(),topics=idx.topics as any[];const selected=new Set<string>([nt]);let changed=true;
              while(changed){changed=false;for(const t of topics){const title=normalizeForTopic(t.title||""),parent=normalizeForTopic(t.parent||"");if(parent&&selected.has(parent)&&!selected.has(title)){selected.add(title);changed=true;}}}
              for(const t of topics){const title=normalizeForTopic(t.title||""),parent=normalizeForTopic(t.parent||"");if(selected.has(title)||selected.has(parent)){const a=Math.max(0,Number(t.chunk_start||0)),b=Math.min(allPdfChunks.length-1,Number(t.chunk_end??a));for(let c=a;c<=b;c++)set.add(c);}}
              if(set.size)selectedChunkIndexes=Array.from(set).sort((a,b)=>a-b);
            }
          }
          if(cleanTopic&&!isRootTopic&&selectedChunkIndexes===null){filesWithoutIndex.push(f.fileName||"apunte");}
          const chunkIndexes=selectedChunkIndexes||allPdfChunks.map((_,i)=>i);
          for(const chunkIndex of chunkIndexes){
            const chunkBytes = allPdfChunks[chunkIndex];
            if(!chunkBytes) throw new Error(`INDEX_CHUNK_NOT_FOUND: no se pudo recuperar el bloque ${chunkIndex + 1} del PDF`);
            const chunkName = allPdfChunks.length > 1
              ? `${(f.fileName || "apunte").replace(/\.pdf$/i, "")} — parte ${chunkIndex + 1} de ${allPdfChunks.length}.pdf`
              : (f.fileName || "apunte");

            const form = new FormData();
            form.append("purpose", "user_data");
            form.append("file", new Blob([chunkBytes], { type: content.mime }), chunkName);

            const fr = await fetchWithTimeout("https://api.openai.com/v1/files", {
              method: "POST",
              headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
              body: form,
            }, OPENAI_TIMEOUT_MS);
            const fj = await fr.json();
            await recordOpenAIUsage(fj, { user, action: "summarize", stage: "upload", topic: cleanTopic, files: [f] });
            if (!fr.ok) throw new Error(fj?.error?.message || "No se pudo enviar el archivo a OpenAI");
            fileIds.push(fj.id);

            await assertAiBudget();
        const rr = await fetchWithTimeout("https://api.openai.com/v1/responses", {
              method: "POST",
              headers: { Authorization: `Bearer ${OPENAI_API_KEY}`, "Content-Type": "application/json" },
              body: JSON.stringify({
                model: OPENAI_MODEL,
                input: [{
                  role: "user",
                  content: [
                    { type: "input_text", text: `Archivo fuente: ${chunkName}` },
                    { type: "input_file", file_id: fj.id },
                    { type: "input_text", text: extractionPrompt }
                  ]
                }],
                max_output_tokens: cleanTopic ? MAX_EXTRACT_TOKENS : 9000
              }),
            }, OPENAI_TIMEOUT_MS);

            const rj = await rr.json();
            await recordOpenAIUsage(rj, { user, action: "summarize", stage: "extract", topic: cleanTopic, files: [f] });
            if (!rr.ok) throw new Error(rj?.error?.message || "Error al analizar el archivo con OpenAI");
            const extractedText = (rj.output || []).flatMap((o: any) => o.content || []).map((p: any) => p.text || "").join("\n").trim();

            if (cleanTopic && extractedText === "NO_RELEVANT_CONTENT") continue;
            if (extractedText) extracted.push({
              fileName: allPdfChunks.length > 1 ? chunkName : (f.fileName || "apunte"),
              text: extractedText
            });
          }
        }
        const indexWarning = filesWithoutIndex.length
          ? `No se encontró índice temático para: ${filesWithoutIndex.join(", ")}. Se analizó el documento completo para buscar el tema, lo que puede tardar más y ser menos preciso. Generá el índice del archivo ("Analizar y crear índice 📑") para acotar la búsqueda la próxima vez.`
          : undefined;
        if (cleanTopic && extracted.length === 0) {
          return cors(new Response(JSON.stringify({
            ok: true,
            summary: `No se encontró información suficiente y específica sobre "${cleanTopic}" en los apuntes seleccionados.`,
            ...(indexWarning ? { indexWarning } : {})
          }), { headers: { "Content-Type": "application/json" } }));
        }

        const sourceText = extracted.map(x => `===== ${x.fileName} =====\n${x.text}`).join("\n\n");
        let filteredSourceText = sourceText;
        if (cleanTopic) {
          // Si el tema coincide con el nombre raíz del documento, todos los fragmentos
          // seleccionados pertenecen al tema. No aplicar extracción por encabezado aquí:
          // cada bloque puede repetir el encabezado raíz y el filtro determinístico podría
          // quedarse accidentalmente solo con el primer bloque.
          if (isDocumentRootTopic(cleanTopic, filesInput[0]?.fileName || "")) {
            filteredSourceText = sourceText;
          } else {
          // Primero intentamos una extracción determinística por capítulo.
          // Esto evita que el modelo vuelva a incorporar capítulos ajenos cuando
          // el material tiene encabezados de nivel 1 claramente delimitados.
          const deterministicSection = extractTopLevelSectionByTopic(sourceText, cleanTopic);
          if (deterministicSection) {
            filteredSourceText = deterministicSection;
          } else {
          const filterPrompt = `Filtrá el texto fuente para el tema solicitado: "${cleanTopic}".
REGLA PRINCIPAL: devolvé ÚNICAMENTE contenido perteneciente al tema solicitado.
Si existe un capítulo o sección con un encabezado que corresponde claramente al tema, conservá desde ese encabezado hasta antes del siguiente capítulo/sección de igual nivel que ya no pertenezca al tema. Para "Sistema nervioso", por ejemplo, debe conservarse todo el capítulo "VII. Sistema nervioso: neurología", incluidos sus nueve apartados, y excluir completamente los capítulos anteriores y posteriores.
Si el tema es un subtema, conservá solamente el apartado correspondiente y el contexto estrictamente necesario.
No resumas ni reformules: conservá el contenido fuente relevante, en su orden.
No incluyas contenido de otros sistemas o capítulos aunque aparezca inmediatamente antes o después.
Si no hay contenido específico, devolvé EXACTAMENTE: NO_RELEVANT_CONTENT.

TEXTO FUENTE:
${sourceText}`;
          const fr = await fetchWithTimeout("https://api.openai.com/v1/responses", {
            method: "POST",
            headers: { Authorization: `Bearer ${OPENAI_API_KEY}`, "Content-Type": "application/json" },
            body: JSON.stringify({
              model: OPENAI_MODEL,
              input: [{ role: "user", content: [{ type: "input_text", text: filterPrompt }] }],
              max_output_tokens: 12000
            })
          }, OPENAI_TIMEOUT_MS);
          const fj = await fr.json();
          await recordOpenAIUsage(fj, { user, action: "summarize", stage: "filter", topic: cleanTopic, files: filesInput });
          if (!fr.ok) throw new Error(fj?.error?.message || "Error al filtrar el contenido por tema");
          const ft = (fj.output || []).flatMap((o:any)=>o.content||[]).map((p:any)=>p.text||"").join("\n").trim();
          if (ft === "NO_RELEVANT_CONTENT" || !ft) {
            return cors(new Response(JSON.stringify({ok:true, summary:`No se encontró información suficiente y específica sobre "${cleanTopic}" en los apuntes seleccionados.`}), {headers:{"Content-Type":"application/json"}}));
          }
          filteredSourceText = ft;
          }
          }
        }

        const finalPrompt = cleanTopic
          ? `Armá un resumen académico para una estudiante de Licenciatura en Enfermería sobre el tema "${cleanTopic}" usando EXCLUSIVAMENTE los fragmentos previamente extraídos.

REGLAS:
- El tema central debe ser exclusivamente "${cleanTopic}".
- No agregues información que no esté en los fragmentos.
- No desarrolles otros temas del material aunque los conozcas.
- Podés relacionar fragmentos si ambos hablan del tema solicitado.
- Si un fragmento no aporta información relevante al tema, ignoralo.
- Conservá todos los subtemas relevantes presentes en los fragmentos; no omitas capítulos o apartados por falta de espacio.
- Mantené, en lo posible, el orden en que aparecen en la fuente.
- Organizá el resultado con subtítulos, viñetas y párrafos breves según corresponda.
- Priorizá la información útil para estudiar para un examen.
- El resumen debe terminar de forma completa. No cortes una sección, oración o lista por falta de espacio.

${requestedStyle}`
          : `Armá un resumen académico para una estudiante de Licenciatura en Enfermería usando EXCLUSIVAMENTE el contenido proporcionado. No agregues información externa. Organizá el resultado con subtítulos, viñetas y párrafos breves según corresponda.

${requestedStyle}`;

        const sr = await fetchWithTimeout("https://api.openai.com/v1/responses", {
          method: "POST",
          headers: { Authorization: `Bearer ${OPENAI_API_KEY}`, "Content-Type": "application/json" },
          body: JSON.stringify({
            model: OPENAI_MODEL,
            input: [{ role: "user", content: [
              { type: "input_text", text: `Estos fragmentos son la ÚNICA fuente permitida para el resumen:\n\n${filteredSourceText}` },
              { type: "input_text", text: finalPrompt }
            ]}],
            max_output_tokens: MAX_FINAL_TOKENS
          })
        }, OPENAI_TIMEOUT_MS);

        const sj = await sr.json();
        await recordOpenAIUsage(sj, { user, action: "summarize", stage: "final", topic: cleanTopic, files: filesInput });
        if (!sr.ok) throw new Error(sj?.error?.message || "Error al generar el resumen con OpenAI");
        const summary = (sj.output || []).flatMap((o: any) => o.content || []).map((p: any) => p.text || "").join("\n").trim();
        if (!summary) throw new Error("OpenAI no devolvió texto para este archivo.");

        return cors(new Response(JSON.stringify({ ok: true, summary, ...(indexWarning ? { indexWarning } : {}) }), {
          headers: { "Content-Type": "application/json" }
        }));
      } finally {
        for (const id of fileIds) {
          try {
            await fetch(`https://api.openai.com/v1/files/${id}`, {
              method: "DELETE",
              headers: { Authorization: `Bearer ${OPENAI_API_KEY}` }
            });
          } catch (_e) {}
        }
        for (const id of tempCopyIds) {
          try { await driveFetch(`files/${id}`, accessToken, { method: "DELETE" }); } catch (_e) {}
        }
      }
    }

    if (action === "generateQuestions") {
      const { fileId, mimeType, topic, questionCount, questionType, difficulty, includeAnswers } = body;
      const filesInput: { fileId: string; mimeType: string; fileName?: string }[] =
        Array.isArray(body.files) && body.files.length ? body.files : (fileId && mimeType ? [{ fileId, mimeType }] : []);
      if (!filesInput.length) return cors(new Response(JSON.stringify({ error: "Faltan datos" }), { status: 400 }));
      if (!OPENAI_API_KEY) throw new Error("OPENAI_NOT_CONFIGURED");

      const count = Math.min(20, Math.max(1, Number(questionCount) || 10));
      const type = String(questionType || "Mixto");
      const level = Math.min(5, Math.max(1, Number(difficulty) || 3));
      const answers = includeAnswers !== false;
      const cleanTopic = String(topic || "").trim();
      const difficultyText = [
        "básica, reconocimiento de conceptos",
        "básica-intermedia, comprensión",
        "intermedia, aplicación de conceptos",
        "avanzada, análisis y aplicación",
        "muy avanzada, integración y casos"
      ][level - 1];

      const prompt = `Generá un cuestionario de examen para una estudiante de Licenciatura en Enfermería usando EXCLUSIVAMENTE la información contenida en los archivos adjuntos.
Cantidad: ${count}.
Tipo solicitado: ${type}.
Dificultad: ${difficultyText}.
${cleanTopic ? `Tema específico: "${cleanTopic}". Las preguntas deben centrarse en ese tema.` : "Si no se indicó tema, cubrí los conceptos relevantes del material."}
No inventes datos, conceptos, tratamientos, valores ni definiciones que no aparezcan en los archivos.

MODO DE PLANIFICACIÓN OBLIGATORIO:
Antes de redactar preguntas, construí un PLAN DE COBERTURA amplio.

FASE 1 — DESCUBRIMIENTO:
Identificá al menos ${Math.max(count * 3, 20)} candidatos cuando el contenido lo permita. Para cada candidato registrá:
- objective: un único objetivo principal;
- centralFact: el dato, relación o contenido central que el estudiante debe recuperar para responder;
- perspectiveKey: perspectiva de evaluación;
- evidence: evidencia concreta de la fuente;
- subtopic y category;
- cluster: bloque conceptual.

FASE 2 — CONTROL DE INFORMACIÓN CENTRAL:
La variedad se determina principalmente por el contenido que el estudiante debe recuperar, no por el formato de la pregunta.
Antes de seleccionar candidatos compará sus centralFact.
- Si dos candidatos exigen recuperar esencialmente el mismo dato, relación, función, identificación o respuesta central, son DUPLICADOS aunque tengan distinto formato, redacción, contexto o perspectiveKey.
- Cambiar opción múltiple por V/F, identificación, aplicación o respuesta breve NO crea diversidad si la respuesta central sigue siendo la misma.
- Una perspectiva distinta SÍ es válida cuando exige recuperar información central diferente.
- Varias preguntas pueden pertenecer al mismo tema o cluster, siempre que su centralFact sea sustancialmente diferente.
- Detalles puramente gráficos como color, posición o una etiqueta repetida no cuentan como nuevo contenido académico salvo que la fuente les atribuya explícitamente significado.

FASE 3 — SELECCIÓN:
Seleccioná EXACTAMENTE ${count} objetivos cuando existan suficientes centralFact distintos y respaldados.
Buscá primero en todo el contenido disponible antes de reducir la cantidad.
Priorizá variedad de información central y, dentro de ella, variedad de enfoques cognitivos.
UNA PREGUNTA = UN OBJETIVO PRINCIPAL.

Ejemplo:
- "función general de las células gliales" y "efecto de rodear a las neuronas" pueden ser distintos si exigen respuestas centrales distintas.
- "función general de las células gliales" y "qué función dejaría de representarse si se eliminan" son el mismo centralFact y no deben ocupar dos posiciones.

REGLAS:
- No inventes variedad ni uses conocimiento externo.
- Cada centralFact debe poder verificarse directamente en la fuente.
- Si existen ${count} centralFact distintos defendibles, el plan DEBE contener ${count}.
- Solo devolvé menos si realmente no existen ${count} contenidos centrales distintos tras revisar todo el material seleccionado.
- No combines dos objetivos independientes en una misma pregunta salvo que la relación entre ellos sea precisamente el objetivo.
- Mantenete dentro del tema y del árbol seleccionado.

El plan debe tener esta estructura:
{"objectives":[{"key":"clave específica","objective":"un único objetivo principal","centralFact":"información central que se evalúa","perspectiveKey":"perspectiva evaluativa","cluster":"bloque conceptual","category":"definición|estructura|característica|función|clasificación|relación|proceso|identificación|aplicación|consecuencia","subtopic":"subtema","sourceBasis":"evidencia concreta de la fuente"}]}

No redactes preguntas en esta fase. Devolvé ÚNICAMENTE JSON válido.

REGLAS:
- No hagas dos preguntas que evalúen esencialmente el mismo concepto, estructura, función, relación o dato, aunque cambies la redacción.
- Si dos preguntas pueden responderse con la misma frase central del material, consideralas repetidas salvo que evalúen una relación adicional claramente diferente.
- No uses coverageKey diferentes para disfrazar el mismo objetivo.
- Cada coverageKey debe representar un objetivo concreto y distinto.
- Distribuí las preguntas entre los subtemas y estructuras realmente presentes.
- Priorizá comprensión, aplicación y relaciones explícitas antes que repetir definiciones.
- No infieras mecanismos, causas o relaciones que la fuente no explique.
- Los distractores deben ser plausibles y basados en conceptos presentes en la fuente.
- Si el tipo es "Mixto", combiná formatos cuando el material lo permita.
- En "relación de conceptos", evaluá una relación que no haya sido evaluada por otra pregunta.
- La respuesta correcta y la explicación deben estar respaldadas directamente por el material.
- Permanecé dentro del árbol temático seleccionado.

Devolvé ÚNICAMENTE un JSON válido:
{"questions":[{"number":1,"type":"...","coverageKey":"...","question":"...","options":["..."],"correctAnswer":"...","explanation":"..."}]}
Para preguntas que no sean de opción múltiple, options debe ser [].
Si se solicitan respuestas, completá correctAnswer y explanation. Si no se solicitan, dejalos como "".
${answers ? "Incluí respuesta correcta y una explicación breve basada en el material." : "No incluyas respuestas ni explicaciones."}`;

      const fileIds: string[] = [];
      const fileLabels: string[] = [];
      const tempCopyIds: string[] = [];
      const filesWithoutIndex: string[] = [];
      try {
        for (const f of filesInput) {
          const content = await getSummarizableContent(f.fileId, f.mimeType, accessToken);
          if (content.tempCopyId) tempCopyIds.push(content.tempCopyId);
          if (content.bytes.length > MAX_SUMMARIZE_BYTES) throw new Error("TOO_LARGE");
          const allChunks = content.mime === "application/pdf" ? await splitPdfIntoChunks(content.bytes, 3) : [content.bytes];
          let selectedIndexes: number[] | null = null;
          let isRootTopic = false;

          if (cleanTopic) {
            const meta = await getDriveMetaForIndex(f.fileId, accessToken);
            const fp = indexFingerprint(meta);
            const idx = await getCurrentIndex(user.id, f.fileId, fp);
            isRootTopic = isDocumentRootTopic(cleanTopic, f.fileName || meta.name || "");
            if (isRootTopic) {
              selectedIndexes = allChunks.map((_, i) => i);
            } else if (idx && Array.isArray(idx.topics)) {
              const nt = normalizeForTopic(cleanTopic);
              const set = new Set<number>();
              const topics = idx.topics;
              const selected = new Set<string>([nt]);
              let changed = true;
              while (changed) {
                changed = false;
                for (const t of topics) {
                  const title = normalizeForTopic(t.title || "");
                  const parent = normalizeForTopic(t.parent || "");
                  if (parent && selected.has(parent) && !selected.has(title)) {
                    selected.add(title);
                    changed = true;
                  }
                }
              }
              for (const t of topics) {
                const title = normalizeForTopic(t.title || "");
                const parent = normalizeForTopic(t.parent || "");
                if (selected.has(title) || selected.has(parent)) {
                  const a = Math.max(0, Number(t.chunk_start || 0));
                  const b = Math.min(allChunks.length - 1, Number(t.chunk_end ?? a));
                  for (let c = a; c <= b; c++) set.add(c);
                }
              }
              if (set.size) selectedIndexes = Array.from(set).sort((a,b)=>a-b);
            }
          }
          if (cleanTopic && !isRootTopic && selectedIndexes === null) {
            filesWithoutIndex.push(f.fileName || "apunte");
          }

          const indexes = selectedIndexes || allChunks.map((_,i)=>i);
          for (const chunkIndex of indexes) {
            const chunkBytes = allChunks[chunkIndex];
            const label = allChunks.length > 1
              ? `${f.fileName || "apunte"} — parte ${chunkIndex + 1} de ${allChunks.length}.pdf`
              : (f.fileName || "apunte");
            const form = new FormData();
            form.append("purpose", "user_data");
            form.append("file", new Blob([chunkBytes], { type: content.mime }), label);
            const fr = await fetchWithTimeout("https://api.openai.com/v1/files", {
              method: "POST",
              headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
              body: form,
            }, OPENAI_TIMEOUT_MS);
            const fj = await fr.json();
            if (!fr.ok) throw new Error(fj?.error?.message || "No se pudo enviar el archivo a OpenAI");
            fileIds.push(fj.id);
            fileLabels.push(label);
          }
        }

        const contentParts: any[] = [];
        for (let i=0;i<fileIds.length;i++) {
          contentParts.push({ type:"input_text", text:`Archivo: ${fileLabels[i]}` });
          contentParts.push({ type:"input_file", file_id:fileIds[i] });
        }
        // v76: plan de cobertura previo a la redacción. La IA primero agrupa
        // objetivos relacionados y selecciona objetivos suficientemente independientes.
        const planningPrompt = `ANALIZÁ EXCLUSIVAMENTE LOS ARCHIVOS ADJUNTOS PARA PLANIFICAR UN EXAMEN.
Tema: ${cleanTopic || "material completo"}
Cantidad solicitada: ${count}
Tipo: ${type}
Dificultad: ${difficultyText}

NO REDACTES PREGUNTAS. Construí solamente el plan.

Identificá al menos ${Math.max(count * 3, 20)} candidatos cuando el contenido lo permita. Para cada uno indicá objective, centralFact, perspectiveKey, cluster, subtopic, category y sourceBasis.
centralFact es la información central que el estudiante debe recuperar para responder.

RESTRICCIÓN TEMÁTICA OBLIGATORIA:
- Si el tema seleccionado es un subtema (por ejemplo, "Neurona"), cada objetivo debe pertenecer directamente a ese tema o a uno de sus subtemas descendientes.
- No conviertas una mención incidental de un concepto padre, vecino o de otro tema en un objetivo.
- Si el material contiene una frase general sobre "tejido nervioso", "sistema nervioso" u otro concepto más amplio dentro del bloque de "Neurona", esa frase no habilita una pregunta sobre el concepto general.
- El objetivo debe poder justificarse como contenido específico del tema seleccionado, no solamente como una frase que aparece en las páginas seleccionadas.

Seleccioná EXACTAMENTE ${count} objetivos si existen suficientes contenidos defendibles. Un mismo tema puede tener varias preguntas válidas.
Dos candidatos son duplicados si exigen recuperar esencialmente el mismo dato, función, relación, identificación o respuesta central, aunque cambien formato, redacción, contexto o perspectiveKey.
Cambiar opción múltiple por verdadero/falso, identificación, aplicación o respuesta breve NO crea un objetivo nuevo si la respuesta central es la misma.
Sí son válidos varios objetivos del mismo tema cuando exigen información central diferente.
No uses color, posición o una etiqueta repetida del dibujo como contenido académico nuevo salvo significado explícito en la fuente.
No combines dos objetivos independientes en una sola pregunta salvo que la relación entre ellos sea precisamente el objetivo.
No uses conocimiento externo.

VERIFICACIÓN FINAL:
- Si existen ${count} centralFact distintos respaldados, el plan DEBE contener ${count}.
- No debe contener dos centralFact esencialmente iguales.
- Cada centralFact debe tener evidencia en sourceBasis.
- No reduzcas la cantidad por el simple hecho de que varios objetivos pertenezcan al mismo tema.
- Solo devolvé menos si realmente no existen ${count} contenidos centrales distintos.
- Antes de entregar el plan, eliminá cualquier objetivo que corresponda a un tema padre, vecino o incidental y no al tema seleccionado.

Devolvé ÚNICAMENTE JSON válido:
{"objectives":[{"key":"clave específica","objective":"un único objetivo principal","centralFact":"información central evaluada","perspectiveKey":"perspectiva evaluativa","cluster":"bloque conceptual","category":"definición|estructura|característica|función|clasificación|relación|proceso|identificación|aplicación|consecuencia","subtopic":"subtema","sourceBasis":"evidencia concreta de la fuente"}]}`;

        const planningParts = [...contentParts, { type:"input_text", text: planningPrompt }];
        await assertAiBudget();
        const planRes = await fetchWithTimeout("https://api.openai.com/v1/responses", {
          method:"POST",
          headers:{ Authorization:`Bearer ${OPENAI_API_KEY}`, "Content-Type":"application/json" },
          body:JSON.stringify({
            model:OPENAI_MODEL,
            input:[{role:"user",content:planningParts}],
            max_output_tokens:5000,
            text:{
              format:{
                type:"json_schema",
                name:"exam_coverage_plan",
                description:"Plan de objetivos de evaluación extraído exclusivamente de los archivos adjuntos.",
                strict:true,
                schema:{
                  type:"object",
                  properties:{
                    objectives:{
                      type:"array",
                      items:{
                        type:"object",
                        properties:{
                          key:{type:"string"},
                          objective:{type:"string"},
                          centralFact:{type:"string"},
                          perspectiveKey:{type:"string"},
                          cluster:{type:"string"},
                          category:{type:"string"},
                          subtopic:{type:"string"},
                          sourceBasis:{type:"string"}
                        },
                        required:["key","objective","centralFact","perspectiveKey","cluster","category","subtopic","sourceBasis"],
                        additionalProperties:false
                      }
                    }
                  },
                  required:["objectives"],
                  additionalProperties:false
                }
              }
            }
          }),
        }, OPENAI_TIMEOUT_MS);
        const planJson = await planRes.json();
        await recordOpenAIUsage(planJson, { user, action: "generateQuestions", stage: "planning", topic: cleanTopic, files: filesInput });
        if(!planRes.ok) throw new Error(planJson?.error?.message || "Error al planificar la cobertura del examen");
        const planRaw = (planJson.output || []).flatMap((o:any)=>o.content||[]).map((p:any)=>p.text||"").join("").trim();
        if(!planRaw) throw new Error("La IA no devolvió el plan de cobertura.");
        let coveragePlan;
        try {
          coveragePlan = JSON.parse(planRaw.replace(/^\`\`\`json\s*/i,"").replace(/\s*\`\`\`$/,""));
        } catch(_e) {
          throw new Error("La IA devolvió un plan de cobertura no válido.");
        }
        if(!coveragePlan?.objectives || !Array.isArray(coveragePlan.objectives)) {
          throw new Error("El plan de cobertura no tiene un formato válido.");
        }
        // Conservar hasta 3x candidatos en memoria: la generación recibe únicamente
        // los objetivos seleccionados, pero nunca se queda corta por truncamiento prematuro.
        const rawObjectives = coveragePlan.objectives.filter((o:any) =>
          o?.objective && o?.centralFact && o?.sourceBasis
        );
        const selectedObjectives:any[] = [];
        const normalizeFact = (s:any) => normalizeForTopic(String(s || ""));
        const factWords = (s:any) => new Set(normalizeFact(s).split(" ").filter((w:string)=>w.length>=4));
        const factSimilarity = (a:any,b:any) => {
          const A=factWords(a), B=factWords(b); if(!A.size||!B.size) return 0;
          let inter=0; for(const x of A) if(B.has(x)) inter++;
          return inter/(A.size+B.size-inter);
        };
        for(const o of rawObjectives){
          if(selectedObjectives.length>=count) break;
          const duplicate = selectedObjectives.some((x:any) =>
            normalizeFact(x.centralFact)===normalizeFact(o.centralFact) ||
            factSimilarity(x.centralFact,o.centralFact)>=0.90
          );
          if(!duplicate) selectedObjectives.push(o);
        }
        coveragePlan.objectives = selectedObjectives.slice(0,count);

        // Si el planificador no produjo suficientes objetivos distintos, pedir una
        // ampliación antes de redactar. Esto evita que un filtro de redundancia
        // reduzca silenciosamente un examen solicitado a 10 preguntas a 7 u 8.
        if (coveragePlan.objectives.length < count) {
          const missing = count - coveragePlan.objectives.length;
          const existingFacts = coveragePlan.objectives.map((o:any) => String(o.centralFact || "")).join("\n");
          const expansionPrompt = `AMPLIÁ EL PLAN DE COBERTURA DEL EXAMEN.
Tema: ${cleanTopic || "material completo"}
Necesitamos ${missing} objetivos adicionales realmente distintos.
Ya seleccionados:
${existingFacts || "(ninguno)"}

Buscá en los archivos adjuntos otros contenidos académicos desarrollados que todavía no estén representados.
Un nuevo objetivo debe exigir recuperar una información central diferente; cambiar solamente la redacción, el formato, el orden, una etiqueta, un color o una posición NO sirve.
Podés usar el mismo tema o subtema si el centralFact es diferente.
No uses conocimiento externo.
Devolvé exactamente los campos del esquema y solo objetivos nuevos.`;
          const expansionParts = [...contentParts];
          expansionParts[expansionParts.length - 1] = { type:"input_text", text: expansionPrompt };
          await assertAiBudget();
          const expansionRes = await fetchWithTimeout("https://api.openai.com/v1/responses", {
            method:"POST",
            headers:{ Authorization:`Bearer ${OPENAI_API_KEY}`, "Content-Type":"application/json" },
            body:JSON.stringify({
              model:OPENAI_MODEL,
              input:[{role:"user",content:expansionParts}],
              max_output_tokens:4000,
              text:{
                format:{
                  type:"json_schema",
                  name:"exam_coverage_expansion",
                  description:"Objetivos adicionales de evaluación basados exclusivamente en la fuente.",
                  strict:true,
                  schema:{
                    type:"object",
                    properties:{
                      objectives:{
                        type:"array",
                        items:{
                          type:"object",
                          properties:{
                            key:{type:"string"},
                            objective:{type:"string"},
                            centralFact:{type:"string"},
                            perspectiveKey:{type:"string"},
                            cluster:{type:"string"},
                            category:{type:"string"},
                            subtopic:{type:"string"},
                            sourceBasis:{type:"string"}
                          },
                          required:["key","objective","centralFact","perspectiveKey","cluster","category","subtopic","sourceBasis"],
                          additionalProperties:false
                        }
                      }
                    },
                    required:["objectives"],
                    additionalProperties:false
                  }
                }
              }
            })
          }, OPENAI_TIMEOUT_MS);
          const expansionJson = await expansionRes.json();
          await recordOpenAIUsage(expansionJson, { user, action: "generateQuestions", stage: "planning_expansion", topic: cleanTopic, files: filesInput });
          if (expansionRes.ok) {
            const extra = Array.isArray(expansionJson?.output)
              ? expansionJson.output.flatMap((o:any)=>o.content||[]).map((p:any)=>p.text||"").join("").trim()
              : "";
            try {
              const parsedExtra = JSON.parse(extra);
              for (const o of (parsedExtra?.objectives || [])) {
                if (coveragePlan.objectives.length >= count) break;
                if (!o?.objective || !o?.centralFact || !o?.sourceBasis) continue;
                const duplicate = coveragePlan.objectives.some((x:any) =>
                  normalizeFact(x.centralFact)===normalizeFact(o.centralFact) ||
                  factSimilarity(x.centralFact,o.centralFact)>=0.90
                );
                if (!duplicate) coveragePlan.objectives.push(o);
              }
            } catch (_e) {}
          }
        }
        coveragePlan.objectives = coveragePlan.objectives.slice(0,count);

        const plannedObjectives = coveragePlan.objectives.map((o:any, i:number) =>
          `${i + 1}. [${o?.category || "otro"}] objetivo: ${o?.objective || ""} | centralFact: ${o?.centralFact || ""} | perspectiva: ${o?.perspectiveKey || ""} | bloque: ${o?.cluster || ""} | evidencia: ${o?.sourceBasis || ""}`
        )
        const promptWithPlan = prompt + `

PLAN DE COBERTURA PREVIAMENTE SELECCIONADO:
${plannedObjectives}

REGLA CRÍTICA: generá una pregunta por cada objetivo del plan, en el mismo orden. Podés generar varias preguntas del mismo bloque si evalúan centralFact diferentes. No combines objetivos independientes y no cambies el objetivo del plan.
REGLA TEMÁTICA: la pregunta debe evaluar exclusivamente el tema seleccionado y el contenido específico representado por su objetivo. No introduzcas preguntas sobre conceptos generales del material solo porque aparecen en los mismos archivos o páginas. El coverageKey de cada pregunta debe corresponder al objetivo que evalúa.`;

        contentParts[contentParts.length - 1] = { type:"input_text", text: promptWithPlan };

        await assertAiBudget();
        const rr = await fetchWithTimeout("https://api.openai.com/v1/responses", {
          method:"POST",
          headers:{ Authorization:`Bearer ${OPENAI_API_KEY}`, "Content-Type":"application/json" },
          body:JSON.stringify({
            model:OPENAI_MODEL,
            input:[{role:"user",content:contentParts}],
            max_output_tokens:7000,
            text:{
              format:{
                type:"json_schema",
                name:"exam_questions",
                description:"Preguntas de examen basadas exclusivamente en los archivos adjuntos y en el plan de cobertura.",
                strict:true,
                schema:{
                  type:"object",
                  properties:{
                    questions:{
                      type:"array",
                      items:{
                        type:"object",
                        properties:{
                          number:{type:"integer"},
                          type:{type:"string"},
                          coverageKey:{type:"string"},
                          question:{type:"string"},
                          options:{type:"array",items:{type:"string"}},
                          correctAnswer:{type:"string"},
                          explanation:{type:"string"}
                        },
                        required:["number","type","coverageKey","question","options","correctAnswer","explanation"],
                        additionalProperties:false
                      }
                    }
                  },
                  required:["questions"],
                  additionalProperties:false
                }
              }
            }
          }),
        }, OPENAI_TIMEOUT_MS);
        const rj=await rr.json();
        await recordOpenAIUsage(rj, { user, action: "generateQuestions", stage: "questions", topic: cleanTopic, files: filesInput });
        if(!rr.ok) throw new Error(rj?.error?.message || "Error al generar las preguntas con OpenAI");
        const raw = (rj.output || []).flatMap((o:any)=>o.content||[]).map((p:any)=>p.text||"").join("").trim();
        if(!raw) throw new Error("OpenAI no devolvió preguntas.");
        let questions;
        try {
          questions = JSON.parse(raw);
        } catch(_e) {
          const cleaned = raw.replace(/^\`\`\`json\s*/i,"").replace(/\s*\`\`\`$/,"");
          questions = JSON.parse(cleaned);
        }
        if(!questions?.questions || !Array.isArray(questions.questions)) throw new Error("La IA devolvió un formato de preguntas no válido.");

        // Control de diversidad en dos capas:
        // 1) coverageKey repetido.
        // 2) similitud léxica alta entre preguntas/Respuestas, para detectar
        //    redundancias semánticas sencillas aunque la IA haya usado claves distintas.
        const normalizeCoverage = (s: any) => normalizeForTopic(String(s || ""));
        const coverageCounts = new Map<string, number>();
        for (const q of questions.questions) {
          const key = normalizeCoverage(q?.coverageKey);
          if (key) coverageCounts.set(key, (coverageCounts.get(key) || 0) + 1);
        }
        const duplicateCoverage = Array.from(coverageCounts.entries()).filter(([, n]) => n > 1);

        const stopWords = new Set([
          "que","cual","cuales","como","segun","material","fuente","tema","indique","indica",
          "señale","señala","corresponde","correcta","correcto","siguiente","respecto",
          "principalmente","principal","una","uno","unos","unas","los","las","del","de",
          "la","el","y","o","en","por","para","con","al","un"
        ]);
        const semanticTokens = (s: any): Set<string> => {
          const n = normalizeCoverage(s);
          return new Set(n.split(" ").filter((w:string) => w.length >= 4 && !stopWords.has(w)));
        };
        const jaccard = (a: Set<string>, b: Set<string>): number => {
          if (!a.size || !b.size) return 0;
          let intersection = 0;
          for (const x of a) if (b.has(x)) intersection++;
          return intersection / (a.size + b.size - intersection);
        };
        const similarPairs: string[] = [];
        for (let i = 0; i < questions.questions.length; i++) {
          const a = questions.questions[i];
          const aTokens = semanticTokens(`${a?.question || ""} ${a?.correctAnswer || ""}`);
          for (let j = i + 1; j < questions.questions.length; j++) {
            const b = questions.questions[j];
            const bTokens = semanticTokens(`${b?.question || ""} ${b?.correctAnswer || ""}`);
            if (jaccard(aTokens, bTokens) >= 0.62) {
              similarPairs.push(`P${i + 1}-P${j + 1}`);
            }
          }
        }

        if (duplicateCoverage.length > 0 || similarPairs.length > 0) {
          const duplicateKeys = duplicateCoverage.map(([k]) => k).join(", ") || "ninguno";
          const repairPrompt = `REPARÁ ESTE EXAMEN PARA ELIMINAR REPETICIONES CONCEPTUALES.

Tema: ${cleanTopic || "material completo"}
Cantidad exacta: ${count}
Tipo solicitado: ${type}
Dificultad: ${difficultyText}

El control automático detectó:
- coverageKey repetidos: ${duplicateKeys}
- pares con alta similitud léxica: ${similarPairs.join(", ") || "ninguno"}

Conservá las preguntas que evalúan objetivos claramente distintos y reemplazá SOLO las redundantes por preguntas nuevas basadas EXCLUSIVAMENTE en los archivos adjuntos.

REGLAS DE REPARACIÓN:
- Cada pregunta debe evaluar un objetivo concreto diferente.
- No reemplaces una pregunta repetida simplemente cambiando su redacción: cambiá el concepto evaluado.
- Si dos preguntas tratan la misma cadena funcional, estructura, función o dato, dejá solo una y usá el espacio para otro contenido desarrollado en la fuente.
- Distribuí las preguntas entre distintos subtemas, estructuras, características, funciones y relaciones disponibles.
- No inventes contenido ni salgas del tema seleccionado.
- Cada coverageKey debe ser específico y distinto cuando exista contenido suficiente.
- Mantené el tipo de pregunta solicitado y la dificultad indicada.
- Si el tipo es Mixto, combiná formatos cuando el material permita hacerlo.
- No elimines una pregunta solamente porque comparte una palabra con otra; la redundancia debe ser conceptual.

EXAMEN ACTUAL:
${JSON.stringify(questions.questions)}

Devolvé ÚNICAMENTE un JSON válido con esta estructura:
{"questions":[{"number":1,"type":"...","coverageKey":"...","question":"...","options":[],"correctAnswer":"...","explanation":"..."}]}`;

          const repairParts = [...contentParts];
          repairParts[repairParts.length - 1] = { type:"input_text", text: repairPrompt };
          await assertAiBudget();
          const repairRes = await fetchWithTimeout("https://api.openai.com/v1/responses", {
            method:"POST",
            headers:{ Authorization:`Bearer ${OPENAI_API_KEY}`, "Content-Type":"application/json" },
            body:JSON.stringify({
              model:OPENAI_MODEL,
              input:[{role:"user",content:repairParts}],
              max_output_tokens:7000,
              text:{
                format:{
                  type:"json_schema",
                  name:"exam_questions",
                  description:"Preguntas de examen basadas exclusivamente en los archivos adjuntos y en el plan de cobertura.",
                  strict:true,
                  schema:{
                    type:"object",
                    properties:{
                      questions:{
                        type:"array",
                        items:{
                          type:"object",
                          properties:{
                            number:{type:"integer"},
                            type:{type:"string"},
                            coverageKey:{type:"string"},
                            question:{type:"string"},
                            options:{type:"array",items:{type:"string"}},
                            correctAnswer:{type:"string"},
                            explanation:{type:"string"}
                          },
                          required:["number","type","coverageKey","question","options","correctAnswer","explanation"],
                          additionalProperties:false
                        }
                      }
                    },
                    required:["questions"],
                    additionalProperties:false
                  }
                }
              }
            }),
          }, OPENAI_TIMEOUT_MS);
          const repairJson = await repairRes.json();
          await recordOpenAIUsage(repairJson, { user, action: "generateQuestions", stage: "repair", topic: cleanTopic, files: filesInput });
          if (repairRes.ok) {
            const repairRaw = (repairJson.output || []).flatMap((o:any)=>o.content||[]).map((p:any)=>p.text||"").join("").trim();
            try {
              const repaired = JSON.parse(repairRaw.replace(/^\`\`\`json\s*/i,"").replace(/\s*\`\`\`$/,""));
              if (repaired?.questions && Array.isArray(repaired.questions)) questions = repaired;
            } catch (_e) {}
          }
        }

        const indexWarning = filesWithoutIndex.length
          ? `No se encontró índice temático para: ${filesWithoutIndex.join(", ")}. Se analizó el documento completo para buscar el tema, lo que puede tardar más y ser menos preciso. Generá el índice del archivo ("Analizar y crear índice 📑") para acotar la búsqueda la próxima vez.`
          : undefined;
        return cors(new Response(JSON.stringify({ok:true, questions:questions.questions, ...(indexWarning ? { indexWarning } : {})}),{headers:{"Content-Type":"application/json"}}));
      } finally {
        for (const id of fileIds) {
          try { await fetch(`https://api.openai.com/v1/files/${id}`,{method:"DELETE",headers:{Authorization:`Bearer ${OPENAI_API_KEY}`}}); } catch(_e){}
        }
        for (const id of tempCopyIds) {
          try { await driveFetch(`files/${id}`, accessToken, { method: "DELETE" }); } catch (_e) {}
        }
      }
    }

    if (action === "askQuestion") {
      const { fileId, mimeType, question } = body;
      const filesInput: { fileId: string; mimeType: string; fileName?: string }[] =
        Array.isArray(body.files) && body.files.length ? body.files : (fileId && mimeType ? [{ fileId, mimeType }] : []);
      if (!filesInput.length) return cors(new Response(JSON.stringify({ error: "Faltan datos" }), { status: 400 }));
      const cleanQuestion = String(question || "").trim();
      if (!cleanQuestion) return cors(new Response(JSON.stringify({ error: "Falta la pregunta" }), { status: 400 }));
      if (!OPENAI_API_KEY) throw new Error("OPENAI_NOT_CONFIGURED");

      // "Preguntá algo puntual" solo trabaja sobre archivos con índice temático ya
      // generado: sin eso no hay forma de acotar qué parte del material leer, y
      // subirle el documento entero a la IA para una sola pregunta puede agotar
      // los recursos de la Edge Function en archivos grandes.
      const missingIndex: string[] = [];
      const fileIndexes: any[] = [];
      for (const f of filesInput) {
        const meta = await getDriveMetaForIndex(f.fileId, accessToken);
        const fp = indexFingerprint(meta);
        const idx = await getCurrentIndex(user.id, f.fileId, fp);
        if (!idx || !Array.isArray(idx.topics) || !idx.topics.length) {
          missingIndex.push(f.fileName || meta?.name || "apunte");
          continue;
        }
        fileIndexes.push({ file: f, meta, idx });
      }
      if (missingIndex.length) {
        return cors(new Response(JSON.stringify({
          error: `NO_INDEX: "Preguntá algo puntual" solo funciona sobre archivos con índice generado. Generá primero el índice de: ${missingIndex.join(", ")} (botón "Índice 📑" → "Analizar y crear índice").`
        }), { status: 400 }));
      }

      // Paso 1: con un llamado liviano de solo texto (sin subir archivos), le
      // pedimos a la IA que identifique cuál de los temas ya indexados es el
      // más relevante para responder la pregunta.
      const combinedTopics: { fileLabel: string; title: string; parent: string; fi: number }[] = [];
      fileIndexes.forEach((entry: any, fi: number) => {
        for (const t of entry.idx.topics) {
          combinedTopics.push({ fileLabel: entry.file.fileName || entry.meta?.name || "apunte", title: String(t.title || ""), parent: String(t.parent || ""), fi });
        }
      });

      const classifyPrompt = `Tenés el índice temático de uno o más apuntes de Licenciatura en Enfermería. Elegí el tema MÁS relevante para responder la siguiente pregunta de una estudiante.

Pregunta: "${cleanQuestion}"

TEMAS DISPONIBLES:
${combinedTopics.map((t, i) => `${i}. [${t.fileLabel}] "${t.title}"${t.parent ? ` (dentro de: "${t.parent}")` : ""}`).join("\n")}

Devolvé ÚNICAMENTE JSON con el índice numérico del tema más relevante para responder la pregunta, o -1 si ningún tema de la lista permite responder la pregunta.`;

      await assertAiBudget();
      const classifyRes = await fetchWithTimeout("https://api.openai.com/v1/responses", {
        method: "POST",
        headers: { Authorization: `Bearer ${OPENAI_API_KEY}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          model: OPENAI_MODEL,
          input: [{ role: "user", content: [{ type: "input_text", text: classifyPrompt }] }],
          max_output_tokens: 200,
          text: {
            format: {
              type: "json_schema",
              name: "topic_pick",
              description: "Índice del tema más relevante para responder la pregunta.",
              strict: true,
              schema: { type: "object", properties: { index: { type: "integer" } }, required: ["index"], additionalProperties: false }
            }
          }
        }),
      }, OPENAI_TIMEOUT_MS);
      const classifyJson = await classifyRes.json();
      await recordOpenAIUsage(classifyJson, { user, action: "askQuestion", stage: "classify", topic: cleanQuestion, files: filesInput });
      if (!classifyRes.ok) throw new Error(classifyJson?.error?.message || "Error al identificar el tema de la pregunta");
      const classifyRaw = (classifyJson.output || []).flatMap((o: any) => o.content || []).map((p: any) => p.text || "").join("").trim();
      let pickedIndex = -1;
      try { pickedIndex = Number(JSON.parse(classifyRaw)?.index); } catch (_e) {}

      if (!Number.isInteger(pickedIndex) || pickedIndex < 0 || pickedIndex >= combinedTopics.length) {
        return cors(new Response(JSON.stringify({
          ok: true,
          answer: "El material indexado seleccionado no parece contener información específica sobre esta pregunta. Probá reformularla o seleccioná otro apunte."
        }), { headers: { "Content-Type": "application/json" } }));
      }

      const picked = combinedTopics[pickedIndex];
      const entry = fileIndexes[picked.fi];
      const f = entry.file;

      // Paso 2: subimos ÚNICAMENTE los bloques del tema elegido (y sus
      // descendientes) y respondemos la pregunta usando solo ese contenido.
      const fileIds: string[] = [];
      let tempCopyId: string | null = null;
      try {
        const content = await getSummarizableContent(f.fileId, f.mimeType, accessToken);
        tempCopyId = content.tempCopyId;
        if (content.bytes.length > MAX_SUMMARIZE_BYTES) {
          throw new Error(`TOO_LARGE: el archivo ${f.fileName || "seleccionado"} supera el límite de 64 MB para procesamiento con IA.`);
        }
        const allChunks = content.mime === "application/pdf" ? await splitPdfIntoChunks(content.bytes, 3) : [content.bytes];
        const selectedIndexes = selectChunkIndexesForTopic(entry.idx.topics, picked.title, allChunks.length);
        const indexes = selectedIndexes.length ? selectedIndexes : allChunks.map((_: any, i: number) => i);

        const contentParts: any[] = [];
        for (const chunkIndex of indexes) {
          const chunkBytes = allChunks[chunkIndex];
          const label = allChunks.length > 1
            ? `${(f.fileName || "apunte").replace(/\.pdf$/i, "")} — parte ${chunkIndex + 1} de ${allChunks.length}.pdf`
            : (f.fileName || "apunte");
          const form = new FormData();
          form.append("purpose", "user_data");
          form.append("file", new Blob([chunkBytes], { type: content.mime }), label);
          const fr = await fetchWithTimeout("https://api.openai.com/v1/files", {
            method: "POST",
            headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
            body: form,
          }, OPENAI_TIMEOUT_MS);
          const fj = await fr.json();
          if (!fr.ok) throw new Error(fj?.error?.message || "No se pudo enviar el archivo a OpenAI");
          fileIds.push(fj.id);
          contentParts.push({ type: "input_text", text: `Archivo: ${label}` });
          contentParts.push({ type: "input_file", file_id: fj.id });
        }

        const prompt = `Respondé la siguiente pregunta de una estudiante de Licenciatura en Enfermería usando EXCLUSIVAMENTE la información de los archivos adjuntos (corresponden al tema "${picked.title}" de "${picked.fileLabel}").

Pregunta: "${cleanQuestion}"

REGLAS:
- El/los archivo(s) adjuntos SÍ contienen texto legible sobre este tema (ya fueron seleccionados específicamente porque el índice del documento indica que lo desarrollan) — no asumas que están vacíos o ilegibles sin haberlos revisado con atención.
- Basate únicamente en el contenido de los archivos adjuntos. No completes con conocimiento externo ni inventes datos.
- Si, tras revisar el contenido adjunto, el material no alcanza para responder del todo, respondé con lo que SÍ esté disponible y aclará qué parte no se puede responder con este material, en vez de rechazar la pregunta por completo.
- Respondé en español, de forma clara y directa, con el desarrollo necesario para que se entienda bien.`;

        contentParts.push({ type: "input_text", text: prompt });

        await assertAiBudget();
        const rr = await fetchWithTimeout("https://api.openai.com/v1/responses", {
          method: "POST",
          headers: { Authorization: `Bearer ${OPENAI_API_KEY}`, "Content-Type": "application/json" },
          body: JSON.stringify({
            model: OPENAI_MODEL,
            input: [{ role: "user", content: contentParts }],
            max_output_tokens: 4000
          }),
        }, OPENAI_TIMEOUT_MS);
        const rj = await rr.json();
        await recordOpenAIUsage(rj, { user, action: "askQuestion", stage: "answer", topic: cleanQuestion, files: [f] });
        if (!rr.ok) throw new Error(rj?.error?.message || "Error al responder la pregunta con OpenAI");
        const answer = (rj.output || []).flatMap((o: any) => o.content || []).map((p: any) => p.text || "").join("\n").trim();
        if (!answer) throw new Error("OpenAI no devolvió una respuesta.");

        return cors(new Response(JSON.stringify({ ok: true, answer, matchedTopic: picked.title, matchedFile: picked.fileLabel }), { headers: { "Content-Type": "application/json" } }));
      } finally {
        for (const id of fileIds) {
          try { await fetch(`https://api.openai.com/v1/files/${id}`, { method: "DELETE", headers: { Authorization: `Bearer ${OPENAI_API_KEY}` } }); } catch (_e) {}
        }
        if (tempCopyId) {
          try { await driveFetch(`files/${tempCopyId}`, accessToken, { method: "DELETE" }); } catch (_e) {}
        }
      }
    }

    if (action === "upload") {
      requireAdmin(user);
      const { fileName, mimeType, base64 } = body;
      if (!fileName || !base64) return cors(new Response(JSON.stringify({ error: "Faltan datos" }), { status: 400 }));
      const file = await driveUpload(fileName, mimeType, base64, accessToken, FACULTAD_ID);
      await refreshCatalog(accessToken);
      return cors(new Response(JSON.stringify({ ok: true, file }), { headers: { "Content-Type": "application/json" } }));
    }

    if (action === "rename") {
      requireAdmin(user);
      const { fileId, newName } = body;
      if (!fileId || !newName) return cors(new Response(JSON.stringify({ error: "Faltan datos" }), { status: 400 }));
      const data = await driveFetch(`files/${fileId}?fields=id,name,mimeType,size,webViewLink`, accessToken, {
        method: "PATCH", body: JSON.stringify({ name: newName }),
      });
      await refreshCatalog(accessToken);
      return cors(new Response(JSON.stringify({ ok: true, file: data }), { headers: { "Content-Type": "application/json" } }));
    }

    if (action === "trash") {
      requireAdmin(user);
      const { fileId } = body;
      if (!fileId) return cors(new Response(JSON.stringify({ error: "Faltan datos" }), { status: 400 }));
      const meta = await driveFetch(`files/${fileId}?fields=id,parents,capabilities(canTrash)`, accessToken);
      if (meta.capabilities && meta.capabilities.canTrash === false) {
        // No es propietaria de este archivo (se lo compartió otra persona): Drive no
        // deja enviarlo a la papelera. Como alternativa, probamos sacarlo de la
        // carpeta donde está organizado (igual que hace la web de Drive), sin tocar
        // el archivo original del dueño real. Si tampoco se puede (comparte con
        // permisos muy restringidos, ej. sin ver siquiera la lista de permisos),
        // avisamos que no hay forma de quitarlo desde acá.
        const parents = (meta.parents || []).join(",");
        if (parents) {
          try {
            await driveFetch(`files/${fileId}?removeParents=${parents}`, accessToken, { method: "PATCH", body: JSON.stringify({}) });
            await refreshCatalog(accessToken);
            return cors(new Response(JSON.stringify({ ok: true, removedOnly: true }), { headers: { "Content-Type": "application/json" } }));
          } catch (_e) { /* sigue al mensaje de "no se puede" de abajo */ }
        }
        throw new Error("NOT_REMOVABLE");
      }
      await driveFetch(`files/${fileId}`, accessToken, { method: "PATCH", body: JSON.stringify({ trashed: true }) });
      await refreshCatalog(accessToken);
      await refreshCatalog(accessToken);
      return cors(new Response(JSON.stringify({ ok: true }), { headers: { "Content-Type": "application/json" } }));
    }

    return cors(new Response(JSON.stringify({ error: "Acción desconocida" }), { status: 400 }));
  } catch (e: any) {
    const msg = String(e?.message || e);
    const status = msg === "NOT_CONNECTED" || msg === "REAUTH_REQUIRED" || msg === "UNAUTHORIZED" ? 401 : (msg === "ADMIN_REQUIRED" ? 403 : 500);
    return cors(new Response(JSON.stringify({ error: msg }), { status, headers: { "Content-Type": "application/json" } }));
  }
});