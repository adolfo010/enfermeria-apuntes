-- Reemplaza el matching por substring plano (LIKE '%termino%', sin limite de
-- palabra: "pie" matcheaba "piel", "pierna", "propiedad", etc.) por busqueda
-- de texto completo real, usando el indice GIN en español que ya existia
-- (knowledge_fragments_content_fts_idx) pero que esta funcion nunca usaba.
-- Ademas ahora ordena por relevancia real (ts_rank: cuantas veces y donde
-- aparece el termino) en vez de un puntaje binario fijo.
create or replace function public.knowledge_search_fragments(term text, limit_count integer default 80)
returns table(id bigint, document_id bigint, file_name text, document_title text, page_start integer, page_end integer, printed_page_start integer, printed_page_end integer, titulo text, ruta text, tipo_contenido text, estado_fragmento text, content text, score numeric)
language sql
stable security definer
set search_path to 'public'
as $function$
with q as (
  select trim(coalesce(term,'')) as raw_term
),
tsq as (
  select websearch_to_tsquery('spanish', immutable_unaccent(raw_term)) as query
  from q
  where raw_term <> ''
),
matched_concepts as (
  select distinct c.id
  from knowledge_concepts c cross join q
  where q.raw_term <> ''
    and lower(translate(c.name,'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%'||lower(translate(q.raw_term,'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN'))||'%'
  union
  select distinct ca.concept_id
  from knowledge_concept_aliases ca cross join q
  where q.raw_term <> ''
    and lower(translate(ca.alias,'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%'||lower(translate(q.raw_term,'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN'))||'%'
),
concept_fragments as (
  select distinct fc.fragment_id
  from knowledge_fragment_concepts fc join matched_concepts mc on mc.id = fc.concept_id
),
base as (
  select
    f.*, d.file_name, d.title as document_title,
    to_tsvector('spanish', immutable_unaccent(f.content)) as content_tsv,
    to_tsvector('spanish', immutable_unaccent(coalesce(f.titulo,'') || ' ' || coalesce(f.ruta,''))) as meta_tsv,
    exists(select 1 from concept_fragments cf where cf.fragment_id = f.id) as concept_match
  from knowledge_fragments f
  join knowledge_documents d on d.id = f.document_id
  where coalesce(f.estado_fragmento,'') not in ('ERROR','ETIQUETA_A_REVISAR')
),
scored as (
  select
    b.*,
    (
      coalesce(ts_rank(b.content_tsv, t.query), 0) * 100 +
      case when b.meta_tsv @@ t.query then 60 else 0 end +
      case when b.concept_match then 90 else 0 end
    )::numeric as score
  from base b
  cross join tsq t
  where numnode(t.query) > 0
    and (b.content_tsv @@ t.query or b.meta_tsv @@ t.query or b.concept_match)
)
select
  id, document_id, file_name, document_title, page_start, page_end,
  pagina_impresa_inicio, pagina_impresa_fin, titulo, ruta, tipo_contenido,
  estado_fragmento, content, score
from scored
order by score desc, document_id, page_start, id
limit greatest(1, least(coalesce(limit_count,80), 200));
$function$;
