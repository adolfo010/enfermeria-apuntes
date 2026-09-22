create or replace function public.knowledge_search_fragments(term text, limit_count integer default 80)
returns table (
  id bigint,
  document_id bigint,
  file_name text,
  document_title text,
  page_start integer,
  page_end integer,
  printed_page_start integer,
  printed_page_end integer,
  titulo text,
  ruta text,
  tipo_contenido text,
  estado_fragmento text,
  content text,
  score numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with q as (
    select lower(trim(coalesce(term,''))) as term
  ),
  base as (
    select
      f.*,
      d.file_name,
      d.title as document_title,
      lower(translate(coalesce(f.titulo,'') || ' ' || coalesce(f.ruta,'') || ' ' || coalesce(f.content,''),
        'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) as haystack,
      lower(translate((select term from q),
        'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) as needle
    from public.knowledge_fragments f
    join public.knowledge_documents d on d.id=f.document_id
    where coalesce(f.estado_fragmento,'') <> 'ERROR'
  ),
  scored as (
    select *,
      (
        case when haystack like '%' || needle || '%' then 100 else 0 end +
        case when lower(translate(coalesce(titulo,''),'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%' || needle || '%' then 80 else 0 end +
        case when lower(translate(coalesce(ruta,''),'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%' || needle || '%' then 60 else 0 end +
        case when lower(translate(coalesce(content,''),'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%' || needle || '%' then 20 else 0 end
      )::numeric as score
    from base
    where needle <> ''
      and (
        haystack like '%' || needle || '%'
        or exists (
          select 1
          from public.knowledge_fragment_concepts fc
          join public.knowledge_concepts c on c.id=fc.concept_id
          where fc.fragment_id=base.id
            and (
              lower(translate(c.name,'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%' || needle || '%'
              or exists (
                select 1 from public.knowledge_concept_aliases ca
                where ca.concept_id=c.id
                  and lower(translate(ca.alias,'áéíóúüñÁÉÍÓÚÜÑ','aeiouunAEIOUUN')) like '%' || needle || '%'
              )
            )
        )
      )
  )
  select id,document_id,file_name,document_title,page_start,page_end,
         pagina_impresa_inicio,pagina_impresa_fin,titulo,ruta,tipo_contenido,
         estado_fragmento,content,score
  from scored
  order by score desc, document_id, page_start, id
  limit greatest(1,least(coalesce(limit_count,80),200));
$$;

grant execute on function public.knowledge_search_fragments(text,integer) to authenticated;
