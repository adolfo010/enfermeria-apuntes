-- Anatomía Clínica PRO (document_id=11) y Latarjet-Ruiz Liard T1 (document_id=12)
-- se habían cargado con bloques fijos de 5-6 páginas por fragmento, mezclando
-- páginas de texto corrido con páginas que son solo una lámina con etiquetas
-- sueltas (reportado por el usuario: buscó "miembros inferiores" y vio un
-- bloque de etiquetas de figura en vez de una descripción).
--
-- El texto ya guardado tiene un marcador "[pdf_pag N]" antes del contenido de
-- cada página real (quedó de la extracción original). Se usa ese marcador
-- para partir cada bloque en fragmentos de una sola página real, con su
-- página impresa correcta (mismo desfase que ya tenía el bloque viejo).
--
-- Clasificación: se calcula palabras-por-línea de cada página. Es una pista,
-- no una certeza -- páginas mixtas (texto + una figura chica al pie) pueden
-- quedar marcadas "posible_lamina" aunque tengan buen texto arriba. No se
-- oculta ni se borra contenido, solo se marca para revisar después.

create temp table tmp_new_fragments on commit drop as
with per_fragment as (
  select
    f.id as old_fragment_id, f.document_id,
    (f.pagina_impresa_inicio - f.page_start) as printed_offset,
    regexp_split_to_array(f.content, E'\\[pdf_pag \\d+\\]') as bodies,
    (select array_agg((m[1])::int order by 1) from regexp_matches(f.content, '\[pdf_pag (\d+)\]', 'g') as m) as pagenums
  from knowledge_fragments f
  where f.document_id in (11,12)
),
pages as (
  select old_fragment_id, document_id, printed_offset,
    pagenums[i] as pdf_page_num,
    trim(bodies[i+1]) as page_text
  from per_fragment, generate_subscripts(pagenums,1) as i
  where pagenums is not null
),
scored as (
  select *,
    greatest(array_length(regexp_split_to_array(page_text, E'\\s+'),1),0) as words,
    greatest(array_length(regexp_split_to_array(page_text, E'\n'),1),1) as lines
  from pages
  where length(trim(page_text)) > 0
)
select
  document_id,
  pdf_page_num as page_start,
  pdf_page_num as page_end,
  (pdf_page_num + printed_offset) as printed_page,
  page_text as content,
  case when (words::numeric/greatest(lines,1)) < 4 then 'posible_lamina' else 'texto' end as tipo_contenido
from scored;

delete from public.knowledge_fragments where document_id in (11,12);

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
select
  t.document_id, t.page_start, t.page_end, t.printed_page, t.printed_page, t.content, t.tipo_contenido,
  'ocr_tesseract_spa_paginado', 'COMPLETO',
  d.title || ' > p. ' || coalesce(t.printed_page::text, t.page_start::text)
from tmp_new_fragments t
join public.knowledge_documents d on d.id = t.document_id;

insert into public.knowledge_fragment_figures (fragment_id, figure_id, relation_type, weight)
select f.id, g.id, 'same_page', 1.0
from public.knowledge_figures g
join public.knowledge_fragments f on f.document_id = g.document_id and f.page_start = g.pdf_page
where g.document_id in (11,12)
on conflict (fragment_id, figure_id) do nothing;
