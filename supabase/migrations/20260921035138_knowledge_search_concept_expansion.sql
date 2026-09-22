create or replace function public.knowledge_search_fragments(term text, limit_count integer default 80)
returns table (
  id bigint, document_id bigint, file_name text, document_title text,
  page_start integer, page_end integer, printed_page_start integer, printed_page_end integer,
  titulo text, ruta text, tipo_contenido text, estado_fragmento text, content text, score numeric
)
language sql stable security definer set search_path=public
as $$
with q as (
 select lower(trim(coalesce(term,''))) as term,
        lower(translate(trim(coalesce(term,'')),'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) as norm
),
matched_concepts as (
 select distinct c.id
 from knowledge_concepts c cross join q
 where lower(translate(c.name,'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%'||q.norm||'%'
 union
 select distinct ca.concept_id
 from knowledge_concept_aliases ca cross join q
 where lower(translate(ca.alias,'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%'||q.norm||'%'
),
concept_fragments as (
 select distinct fc.fragment_id
 from knowledge_fragment_concepts fc join matched_concepts mc on mc.id=fc.concept_id
),
base as (
 select f.*,d.file_name,d.title as document_title,
 lower(translate(coalesce(f.titulo,'')||' '||coalesce(f.ruta,'')||' '||coalesce(f.content,''),
 'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) as haystack,
 q.norm as needle,
 exists(select 1 from concept_fragments cf where cf.fragment_id=f.id) as concept_match
 from knowledge_fragments f join knowledge_documents d on d.id=f.document_id cross join q
 where coalesce(f.estado_fragmento,'')<>'ERROR'
),
scored as (
 select *,(
   case when haystack like '%'||needle||'%' then 100 else 0 end+
   case when lower(translate(coalesce(titulo,''),'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%'||needle||'%' then 80 else 0 end+
   case when lower(translate(coalesce(ruta,''),'áéíóúüñÁÉÍÓÚÑ','aeiouunAEIOUUN')) like '%'||needle||'%' then 60 else 0 end+
   case when concept_match then 90 else 0 end+
   case when lower(translate(coalesce(content,''),'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%'||needle||'%' then 20 else 0 end
 )::numeric score
 from base
 where needle<>''
 and (haystack like '%'||needle||'%' or concept_match)
)
select id,document_id,file_name,document_title,page_start,page_end,pagina_impresa_inicio,pagina_impresa_fin,
titulo,ruta,tipo_contenido,estado_fragmento,content,score
from scored
order by score desc,document_id,page_start,id
limit greatest(1,least(coalesce(limit_count,80),200));
$$;
grant execute on function public.knowledge_search_fragments(text,integer) to authenticated;
