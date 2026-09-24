-- La busqueda de texto completo (websearch_to_tsquery) une las palabras del
-- termino con AND: si el usuario escribe varias palabras y UNA sola tiene un
-- error real de tipeo (no una variante gramatical, que el stemmer 'spanish'
-- ya resuelve solo: plural/singular, genero, conjugaciones), la busqueda
-- estricta no encuentra nada aunque el resto de las palabras sean correctas.
-- Se agrega una segunda pasada mas permisiva (OR entre las mismas raices)
-- que solo se usa cuando la busqueda estricta no devolvio ningun resultado,
-- para no perder precision en el caso normal.
create or replace function public.knowledge_search_fragments(term text, limit_count integer default 80)
returns table(id bigint, document_id bigint, file_name text, document_title text, page_start integer, page_end integer, printed_page_start integer, printed_page_end integer, titulo text, ruta text, tipo_contenido text, estado_fragmento text, content text, score numeric)
language sql
stable security definer
set search_path to 'public'
as $function$
with q as (
  select trim(coalesce(term,'')) as raw_term
),
tsq_and as (
  select websearch_to_tsquery('spanish', immutable_unaccent(raw_term)) as query
  from q
  where raw_term <> ''
),
term_lexemes as (
  select array_agg(distinct lex) as lex
  from q, unnest(tsvector_to_array(to_tsvector('spanish', immutable_unaccent(q.raw_term)))) as lex
  where q.raw_term <> ''
),
tsq_or as (
  select to_tsquery('spanish', array_to_string(lex, ' | ')) as query
  from term_lexemes
  where lex is not null and array_length(lex,1) > 0
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
scored_and as (
  select
    b.*,
    (
      coalesce(ts_rank(b.content_tsv, t.query), 0) * 100 +
      case when b.meta_tsv @@ t.query then 60 else 0 end +
      case when b.concept_match then 90 else 0 end
    )::numeric as score
  from base b
  cross join tsq_and t
  where numnode(t.query) > 0
    and (b.content_tsv @@ t.query or b.meta_tsv @@ t.query or b.concept_match)
),
scored_or as (
  select
    b.*,
    (
      coalesce(ts_rank(b.content_tsv, t.query), 0) * 60 +
      case when b.meta_tsv @@ t.query then 40 else 0 end +
      case when b.concept_match then 90 else 0 end
    )::numeric as score
  from base b
  cross join tsq_or t
  where not exists (select 1 from scored_and)
    and numnode(t.query) > 0
    and (b.content_tsv @@ t.query or b.meta_tsv @@ t.query or b.concept_match)
),
combined as (
  select * from scored_and
  union all
  select * from scored_or
)
select
  id, document_id, file_name, document_title, page_start, page_end,
  pagina_impresa_inicio, pagina_impresa_fin, titulo, ruta, tipo_contenido,
  estado_fragmento, content, score
from combined
order by score desc, document_id, page_start, id
limit greatest(1, least(coalesce(limit_count,80), 200));
$function$;
