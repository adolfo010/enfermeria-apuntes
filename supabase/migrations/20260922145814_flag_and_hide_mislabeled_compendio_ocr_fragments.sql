-- Compendio de Anatomía Descriptiva (document_id=2), páginas impresas 362-666:
-- el paso de ingesta "ocr" etiquetó estos 29 fragmentos con solo dos rótulos
-- estáticos ("Angiología" y luego "Neurología") sin detectar los cambios reales
-- de capítulo del libro (que en ese tramo también pasa por Órganos de los
-- sentidos, Aparato de la digestión y Aparato urogenital). Confirmado con texto
-- literal: fragmentos etiquetados "Angiología" que empiezan con "NEUROLOGíA" en
-- el contenido, y fragmentos etiquetados "Neurología" que empiezan con
-- "ÓRGANOS DE LOS SENTIDOS" / "APARATO DE LA DIGESTIÓN" / "APARATO UROGENITAL".
--
-- Se marcan como ETIQUETA_A_REVISAR (no se borra ni se reescribe el contenido)
-- para que la búsqueda deje de mostrarlos con un título de tema incorrecto,
-- hasta que se vuelvan a catalogar con el texto fuente correspondiente.

update public.knowledge_fragments
set estado_fragmento = 'ETIQUETA_A_REVISAR'
where document_id = 2 and id between 263 and 291;

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
 where coalesce(f.estado_fragmento,'') not in ('ERROR','ETIQUETA_A_REVISAR')
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
revoke all on function public.knowledge_search_fragments(text, integer) from public, anon, authenticated;
