import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function cors(res: Response) {
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

function normalize(value: string) {
  return String(value || "")
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return cors(new Response("ok"));
  if (req.method !== "POST") return cors(new Response("Method not allowed", { status: 405 }));

  try {
    const body = await req.json();
    const action = String(body.action || "");

    if (action === "searchConcepts") {
      const term = normalize(String(body.term || ""));
      if (!term) return cors(Response.json({ ok: true, concepts: [] }));

      const q = encodeURIComponent(`or=(normalized_name.ilike.*${term}*,name.ilike.*${term}*)&status=eq.active&order=name.asc&limit=50`);
      const res = await rest(`knowledge_concepts?select=id,name,description,concept_type,parent_id&${q}`);
      if (!res.ok) throw new Error(await res.text());
      return cors(Response.json({ ok: true, concepts: await res.json() }));
    }

    if (action === "concept") {
      const id = Number(body.conceptId);
      if (!id) return cors(Response.json({ error: "Falta conceptId" }, { status: 400 }));

      const conceptRes = await rest(`knowledge_concepts?id=eq.${id}&select=id,name,description,concept_type,parent_id,status&limit=1`);
      if (!conceptRes.ok) throw new Error(await conceptRes.text());
      const concepts = await conceptRes.json();
      if (!concepts.length) return cors(Response.json({ error: "CONCEPT_NOT_FOUND" }, { status: 404 }));

      const [childrenRes, aliasesRes, relationsRes, sourcesRes] = await Promise.all([
        rest(`knowledge_concepts?parent_id=eq.${id}&status=eq.active&select=id,name,description,concept_type,parent_id&order=name.asc`),
        rest(`knowledge_concept_aliases?concept_id=eq.${id}&select=alias,normalized_alias&order=alias.asc`),
        rest(`knowledge_concept_relations?or=(concept_id.eq.${id},related_concept_id.eq.${id})&select=concept_id,related_concept_id,relation_type,weight`),
        rest(`knowledge_document_concepts?concept_id=eq.${id}&select=document_id,coverage,source_role,page_start,page_end,knowledge_documents(id,file_name,title,source_type,subject_area)&order=source_role.asc,page_start.asc`),
      ]);

      const [children, aliases, relations, sources] = await Promise.all([
        childrenRes.json(), aliasesRes.json(), relationsRes.json(), sourcesRes.json()
      ]);

      return cors(Response.json({
        ok: true,
        concept: concepts[0],
        children: childrenRes.ok ? children : [],
        aliases: aliasesRes.ok ? aliases : [],
        relations: relationsRes.ok ? relations : [],
        sources: sourcesRes.ok ? sources : [],
      }));
    }

    // Resolve a natural-language query into concepts, then expand one relation hop.
    if (action === "retrieveByQuery") {
      const query = normalize(String(body.query || ""));
      if (!query) return cors(Response.json({ ok: true, concepts: [], fragments: [] }));

      const tokens = [...new Set(query.split(" ").filter((token) => token.length >= 4))].slice(0, 8);
      const searchTerms = [query, ...tokens].slice(0, 9);
      const matched = new Map<number, { id: number; name: string; score: number }>();

      for (const term of searchTerms) {
        const encoded = encodeURIComponent(
          `or=(normalized_name.ilike.*${term}*,name.ilike.*${term}*)&status=eq.active&order=name.asc&limit=30`,
        );
        const res = await rest(`knowledge_concepts?select=id,name&${encoded}`);
        if (!res.ok) continue;
        for (const concept of await res.json()) {
          const id = Number(concept.id);
          if (!id) continue;
          const score = term === query ? 1 : 0.6;
          const current = matched.get(id);
          matched.set(id, { id, name: concept.name, score: Math.max(current?.score || 0, score) });
        }
      }

      let conceptIds = [...matched.values()]
        .sort((a, b) => b.score - a.score)
        .slice(0, 12)
        .map((c) => c.id);

      if (conceptIds.length) {
        const ids = conceptIds.join(",");
        const relRes = await rest(
          `knowledge_concept_relations?concept_id=in.(${ids})&select=concept_id,related_concept_id,relation_type,weight&limit=50`,
        );
        if (relRes.ok) {
          const relations = await relRes.json();
          conceptIds = [...new Set([
            ...conceptIds,
            ...relations.map((r: { related_concept_id: number }) => Number(r.related_concept_id)),
          ])].filter(Boolean).slice(0, 20);
        }
      }

      if (!conceptIds.length) return cors(Response.json({ ok: true, concepts: [], fragments: [] }));

      const ids = conceptIds.join(",");
      const rel = await rest(
        `knowledge_fragment_concepts?concept_id=in.(${ids})&select=fragment_id,concept_id,relevance,evidence_type,knowledge_fragments(id,document_id,page_start,page_end,content,knowledge_documents(id,file_name,title,source_type,subject_area))&order=relevance.desc.nullslast&limit=100`,
      );
      if (!rel.ok) throw new Error(await rel.text());

      return cors(Response.json({
        ok: true,
        concepts: [...matched.values()].sort((a, b) => b.score - a.score),
        fragments: await rel.json(),
      }));
    }

    if (action === "retrieve") {
      const conceptIds = Array.isArray(body.conceptIds)
        ? body.conceptIds.map(Number).filter(Boolean).slice(0, 20)
        : [];

      if (!conceptIds.length) return cors(Response.json({ ok: true, fragments: [] }));

      const ids = conceptIds.join(",");
      const rel = await rest(
        `knowledge_fragment_concepts?concept_id=in.(${ids})&select=fragment_id,concept_id,relevance,evidence_type,knowledge_fragments(id,document_id,page_start,page_end,content,knowledge_documents(id,file_name,title,source_type,subject_area))&order=relevance.desc.nullslast&limit=100`
      );
      if (!rel.ok) throw new Error(await rel.text());

      return cors(Response.json({ ok: true, fragments: await rel.json() }));
    }

    return cors(Response.json({ error: "UNKNOWN_ACTION" }, { status: 400 }));
  } catch (error) {
    console.error("[knowledge]", error);
    return cors(Response.json({ error: String(error?.message || error) }, { status: 500 }));
  }
});
