-- Carga de 13 resúmenes nuevos (esqueleto apendicular/axial, articulaciones, músculos)
-- para reforzar cobertura del programa de Estructura y Función Humana II.
-- Extraídos con Herramienta_Figuras_PDF_Nivel2 v2.10.0 (texto nativo, sin OCR).
-- Figuras candidatas revisadas manualmente antes de esta carga: se excluyeron
-- banners/etiquetas de texto sin contenido anatómico real.

create temp table tmp_doc_map (dirname text, id bigint) on commit drop;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1DszJ4tPuyJ99GQBU51hiOI52Z4bdXfb3', 'ARTICULACIONES.pdf', 'Articulaciones (resumen)', 'resumen', 'Anatomia', 11, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'ARTICULACIONES', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1lNZRx3LrK32NSeGFqkyqZ2Vcv5bFAS6f', 'CINTURA ESCAPULAR.pdf', 'Cintura Escapular (resumen)', 'resumen', 'Anatomia', 30, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'CINTURA_ESCAPULAR', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1d7thM6Ln4nSZLGxebJaUj2sxVyYkW4sE', 'CINTURA PELVIANA.pdf', 'Cintura Pelviana (resumen)', 'resumen', 'Anatomia', 14, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'CINTURA_PELVIANA', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1y2fBFWvNJ6Zf4UzOu1-QdfHAMWM4feTb', 'EL ESQUELETO.pdf', 'El Esqueleto (resumen)', 'resumen', 'Anatomia', 20, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'EL_ESQUELETO', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('17GbbpQcpw3Kta0MOw18eM2U56h2EGVIN', 'FOSAS NASALES Y SENOS PARANASALES.pdf', 'Fosas Nasales y Senos Paranasales (resumen)', 'resumen', 'Anatomia', 6, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'FOSAS_NASALES_Y_SENOS_PARANASALES', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1xT_VOQjzE8SO2GUeR966EvgiP8ecMWud', 'HUESOS DE LA CABEZA.pdf', 'Huesos de la Cabeza (resumen)', 'resumen', 'Anatomia', 13, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'HUESOS_DE_LA_CABEZA', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1rntrH6idwja3FMa1fRHWulRdlbeHaffD', 'MUSCULOS DE LA CABEZA.pdf', 'Músculos de la Cabeza (resumen)', 'resumen', 'Anatomia', 8, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'MUSCULOS_DE_LA_CABEZA', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1wiWSFiWZIaRoNT7MgAHmGVtXIiK-nEQ3', 'MUSCULOS.pdf', 'Músculos (resumen)', 'resumen', 'Anatomia', 11, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'MUSCULOS', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('18Byjx1-fHPvn3xwDE7gykL9wpKuKzKoQ', 'PARED TORACICA.pdf', 'Pared Torácica (resumen)', 'resumen', 'Anatomia', 10, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'PARED_TORACICA', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1IbTwN5gTniPpaV4uqYH37KsFmN15NNoc', 'PIERNA.pdf', 'Pierna (resumen)', 'resumen', 'Anatomia', 10, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'PIERNA', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1fZwFP4q3qvqgwT2yvMXvHtgAaXircDkP', 'RAQUIS I.pdf', 'Raquis I (resumen)', 'resumen', 'Anatomia', 11, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'RAQUIS_I', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1AXdsvRsp9Fmgz2yHwG9emzyN-aQQBY5m', 'RAQUIS II.pdf', 'Raquis II (resumen)', 'resumen', 'Anatomia', 13, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'RAQUIS_II', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1wo4jAqR3ZjdR2Yl2WPgFTTnRVG2h5311', 'REGIONES DE LA CABEZA.pdf', 'Regiones de la Cabeza (resumen)', 'resumen', 'Anatomia', 21, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'REGIONES_DE_LA_CABEZA', id from ins;


-- Fragmentos (una fila por página, texto nativo)

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 1, 1, 1, 1, 'ARTICULACIONES', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 2, 2, 2, 2, '• Las articulaciones son los lugares donde los huesos se encuentran.
• Es el sitio de unión de dos o mas superficies óseas
Habitualmente se dividen en 3 grupos:
1. Sinartrosis: son articulaciones fijas o uniones fibrosas.
2. Anfiartrosis: son articulaciones ligeramente móviles o uniones
cartilaginosas.
3. Diartrosis: son articulaciones móviles.
Para facilitar su estudio y comprensión, es mas conveniente dividirlas
en:
• Articulaciones
no
sinoviales
(incluye
articulaciones
fibrosas
y
cartilaginosas)
• Articulaciones sinoviales', 'texto', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 3, 3, 3, 3, 'ARTICULACIONES NO SINOVIALES:
• Sincondrosis:
incluyen
las
numerosas
uniones
cartilaginosas
transitorias(cartílago de crecimiento) entre la diáfisis y la epífisis del
esqueleto maduro.', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 4, 4, 4, 4, '• Suturas: se encuentran en el cráneo, y tienen lugar dondequiera que
los márgenes o superficies mas anchas de los huesos se encuentran y
articulan.
Cuando el crecimiento de las suturas se detiene, se osifica. Si los
bordes poseen los bordes de una sierra, se denomina sutura aserrada,
y si esta constituida por prolongaciones en forma de diente se trata de
una sutura dentada.', 'texto', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 5, 5, 5, 5, '• Esquindilesis: articulación en la que la cresta de un hueso encaja en la
hendidura de otro vecino. (vo-es)
• Gonfosis: articulación fibrosa restringida a la fijación de los dientes en
los maxilares.', 'texto', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 6, 6, 6, 6, '• Sindesmosis: articulación en las que las superficies óseas están
unidas por un ligamento interóseo que hace posible un pequeño
grado de movimiento entre los huesos contiguos.', 'texto', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 7, 7, 7, 7, '• Sínfisis: articulación fibrocartilaginosa, en la que es posible una
amplitud de movimiento limitada. Las sínfisis son limitadas.', 'texto', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 8, 8, 8, 8, 'ARTICULACIONES SINOVIALES: (concepto: lugar de unión, punto de encuentro)
• Los huesos que intervienen están unidos por una capsula fibrosa y a
menudo por ligamentos accesorios situados dentro o fuera de esta.
• Las superficies articulares están recubiertas por cartílago hialino, y el
verdadero contacto tiene lugar entre superficies cartilaginosas.
• Se caracterizan por tener un coeficiente de fricción muy bajo,
facilitado por un liquido sinovial viscoso que actúa como lubricante.
• Muchas de estas articulaciones poseen solo 2 superficies que se
articulan, si tienen mas de un par de superficies articulares se llama
compuesta.
• Cuando existe un disco intracapsular, o un menisco, se denomina
compleja.', 'texto', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 9, 9, 9, 9, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 10, 10, 10, 10, 'Clasificación:
• Artrodias o planas
(acromioclavicular)
• Tróclea o en bisagra
(humerocubital)
• Trocoide o en pivote
(Radiocubital)', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 11, 11, 11, 11, '• Condileas
(femorotibial)
• En silla de montar
(calcaneocuboidea)
• Esferoideas
(coxofemoral)', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Articulaciones (resumen) > p. 11');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 1, 1, 1, 1, 'CINTURA ESCAPULAR', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 2, 2, 2, 2, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 3, 3, 3, 3, 'Concepto: se denomina cintura escapular a la estructura formada por las dos escapulas, la
clavícula y el esternón, que se articulan formando un cinturón incompleto.
HUESOS:
1. La escapula: es un hueso plano de la región posterior y superior del tórax que se
articula con la clavícula y con el humero.
2. La clavícula es un hueso largo de la región anterior y superior del tórax, se articula con
el acromion y el esternón.
3. El esternón es un hueso plano de la región anterior del tórax que presenta dos carillas
articulares para la clavícula de cada lado y además se articula con el cartílago de las
primeras 7 costillas.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 4, 4, 4, 4, 'CLAVÍCULA
Es un hueso largo, que pertenece tanto a miembro superior y tórax.
Tiene forma de “S” itálica y se extiende desde el esternón hasta el acromion del omóplato.
Presenta para su estudio: Dos caras (superior e inferior), dos bordes (anterior y posterior) y 2 extremos
(externo e interno).
Cara superior: Es lisa.
Cara inferior: Presenta desde adentro hacia afuera los siguientes accidentes:

Rugosidades para el ligamento COSTOCLAVICULAR.

Canal subclavio, para la inserción del músculo SUBCLAVIO.

Rugosidades para la inserción de los ligamentos CORACOCLAVICULARES.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 5, 5, 5, 5, 'Borde anterior: Es convexo y liso hacia dentro (donde se inserta el pectoral mayor) y cóncavo y
rugoso hacia afuera (da inserción al músculo deltoides).
Borde posterior: Cóncavo hacia dentro (dando inserción de afuera hacia dentro a los músculos
esternocleidomastoideo y esternocleidohioideo). Convexo y rugoso hacia afuera (da inserción al
trapecio).
Extremo
interno:
Voluminoso,
presenta
una
superficie
articular
cóncava
en
sentido
anteroposterior y convexa en sentido vertical para articularse con el esternón.
Extremo externo: Aplanado de arriba hacia abajo, presenta una carilla oval que articula con el
acromion del omóplato.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 6, 6, 6, 6, 'ESCAPULA.
Hueso plano de forma triangular de base superior y vértice inferior.
CARA ANTERIOR: Cóncava. CARA POSTERIOR: Convexa.
BORDES
-Superior o cervical
-Lateral interno o espinal
-Lateral externo o axilar.
CARA ANTERIOR DE LA ESCÁPULA
Es cóncava hacia adelante y presenta la FOSA SUBESCAPULAR donde se inserta el MÚSCULO 
SUBESCAPULAR.
CARA POSTERIOR DE LA ESCÁPULA.
En la unión del tercio superior con los dos tercios inferiores, se inserta la ESPINA DE LA ESCÁPULA.
La espina de la escápula se continua con el ACROMIÓN y esté se continua con LA CLAVÍCULA.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 7, 7, 7, 7, 'La inserción de la espina divide a la cara posterior en dos porciones
Por encima: FOSA SUPRAESPINOSA (Da inserción al músculo SUPRAESPINOSO)
Por debajo: FOSA INFRAESPINOSA (Da inserción al músculo INFRAESPINOSO)', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 8, 8, 8, 8, 'CAVIDAD GLENOIDEA.
Cavidad cóncava hacia afuera, ubicada en el borde externo de la escápula. 
Tiene como función recibir a la CABEZA DEL HÚMERO para formar la articulación 
GLENOHUMERAL O ESCAPULOHUMERAL.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 9, 9, 9, 9, 'MUSCULOS:
Deltoides: musculo superficial, que se origina en 3 fascículos, el anterior que
se inserta en la clavícula, el medio en el acromion y el posterior en la espina
de la escapula. Se inserta lateralmente en la cara externa del humero.
Supraespinoso:
es
un
musculo
superficial
que
se
origina
en
la
fosa
supraespinosa de la escapula y se inserta en el troquiter.
infraespinoso: se origina en la fosa infraespinosa y se inserta en el troquiter.
subescapular: tiene su inserción proximal en la fosa subescapular y presta
inserción distalmente en el troquin.
corobraquial: se inserta proximalmente en la apófisis coracoides de la
escapula y distalmente en la cara interna del humero.
Trapecio: musculo superficial que se origina en el hueso occipital y en la
apófisis espinosa. Se inserta distalmente en la clavícula, el acromion y en la
espina de la escapula.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 10, 10, 10, 10, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 11, 11, 11, 11, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 11'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 12, 12, 12, 12, 'Dorsal ancho: es un musculo superficial que se origina en las apófisis
espinosas de las vertebras dorsal 5 y lumbar 5, la cresta sacra, la cresta iliaca
y las cuatro ultimas costillas.
Redondo mayor: se origina en el borde externo de la escapula
Redondo menor: presenta su inserción escapular en la fosa infraespinosa y su
inserción humeral en el troquiter.
Romboides (mayor y menor) se insertan medialmente en las apófisis espinosas
de las cervical 4 y dorsal 5.
Angular de la escapula: se inserta medialmente en las apófisis transversas
desde la cervical 1 a la cervical 4.
Esternocleidomastoideo: es un musculo superficial que se origina en la
clavícula y el esternón.
Subclavio: se inserta medialmente en la cara superior de la primera costilla y
del primer cartílago costal.
Serrato mayor: se origina en la cara anterior de la escapula y de ahí se dirige
a insertarse a las 10 primeras costillas.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 12'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 13, 13, 13, 13, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 13'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 14, 14, 14, 14, 'esternocleidomastoideo', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 14'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 15, 15, 15, 15, 'Pectoral mayor: es un musculo superficial, que se inserta en borde anterior de
la clavícula, a lo largo del esternón y de los cartílagos costales.
Pectoral menor: presenta su origen en el borde anterior de la 3°, 4° y 5°
costilla, para luego dirigirse hacia su inserción escapular en la apófisis
coracoides.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 15'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 16, 16, 16, 16, 'BRAZO:
HUESO:
Humero: es un hueso largo, y presenta para su estudio un cuerpo o diáfisis y
dos extremidades o epífisis, una superior y otra inferior.
La epífisis superior presenta la cabeza del humero que se articula con la
escapula. En esta extremidad se ubican dos protuberancias una lateral: el
troquiter y una anterior, el troquin, separados de la cabeza por un surco
denominado cuello anatómico del humero.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 16'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 17, 17, 17, 17, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 17'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 18, 18, 18, 18, 'En la epífisis inferior predomina su diámetro transversal, se encuentra una
superficie articular, que tiene en su parte medial una polea articular, la
tróclea, para articularse con el cubito, y en su parte lateral una saliente
redondeada, el cóndilo, para articularse con el radio.
A ambos lados de estas superficies articulares se encuentran dos salientes
óseas, lateral al cóndilo se ubica el epicondilo y medial a la tróclea
observamos la epitróclea.
En la cara posterior de la extremidad se encuentra la fosa olecraneana que
aloja el olecranon cubital cuando el brazo se encuentra extendido.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 18'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 19, 19, 19, 19, 'Los músculos del brazo están dispuestos en dos celdas o regiones, divididas
por el humero y los tabiques intermusculares medial y lateral.
En la celda anterior encontraremos a los músculos flexores y en la celda
posterior ubicaremos a los músculos extensores.
MUSCULOS:
REGION ANTERIOR:
Corobraquial: presenta su inserción proximal en la apófisis coracoides de
escapula y su inserción distal en la cara anterior del tercio medio de la
diáfisis humeral.
Braquial anterior: se inserta proximalmente en el borde anterior del humero,
cara interna y externa por debajo del deltoides, distalmente se inserta en la
apófisis coracoides del cubito.
Biceps braquial: posee dos porciones que se insertan proximalmente en
diferentes lugares: la porción corta o interna se inserta en la apófisis
coracoides de la escapula y la porción larga o externa se inserta en el
tubérculo supraglenoideo.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 19'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 20, 20, 20, 20, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 20'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 21, 21, 21, 21, 'REGION POSTERIOR:
Tríceps braquial: en su inserción proximal presenta tres porciones: una porción larga o
subglenoidea, un vasto interno ubicado por dentro y por debajo del canal radial en la cara
posterior del cuerpo del humero y un vasto externo, dispuesto por fuera y por arriba del
canal radial en la cara posterior del cuerpo del humero.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 21'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 22, 22, 22, 22, 'ANTEBRAZO
HUESOS:
En el antebrazo existen 2 huesos largos, el radio que se ubica en la región
lateral y el cubito situado medial a este.
En su extremidad superior el radio presenta su cabeza a través del cual se
articula con el cubito y el humero.
El cubito presenta el olecranon y dos cavidades articulares, una para el
humero y el otra para el radio, en este encontramos la cara articular carpiana
para los huesos del carpo.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 22'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 23, 23, 23, 23, 'MUSCULOS
Se encuentran divididos por la membrana interósea en un compartimiento
anterior y otro posterior.
Compartimiento anterior del brazo se encuentran:
Pronador redondo
Palmar mayor
Palmar menor
Cubital anterior
Flexor común superficial de los dedos
Flexor común profundo de los dedos
Flexor largo propio del pulgar
Pronador cuadrado', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 23'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 24, 24, 24, 24, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 24'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 25, 25, 25, 25, 'En el compartimiento posterior del antebrazo se encuentran:
Supinador largo
Supinador corto
Radial largo
Radial corto
Ancóneo
Extensor común de los dedos
Extensor propio del meñique
Cubital posterior
Abductor largo del pulgar
Extensor corto del pulgar
Extensor largo del pulgar
Extensor propio del dedo índice', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 25'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 26, 26, 26, 26, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 26'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 27, 27, 27, 27, 'MANO
HUESOS: la mano comprende 27 huesos en tres grandes grupos:
1. Huesos del carpo (muñeca)
2. Huesos del metacarpo
3. Huesos de los dedos
1-Huesos del carpo: constituidos por ocho pequeños huesos pares dispuestos en
dos filas transversales de cuatro huesos cada una, una fila superior donde se
encuentran, de externo a interno:

El escafoides

El seminular

El piramidal

El pisciforme
Y una fila inferior o carpiana donde se observan el trapecio, trapezoide, el
grande y el ganchoso.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 27'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 28, 28, 28, 28, 'Huesos
del
metacarpo:
constituido
por
cinco
huesos
en
cada
mano
(metacarpianos), son huesos largos pares, numerados del uno al cinco desde
afuera hacia adentro, que forman la palma de la mano.
Huesos de los dedos: los dedos reciben el nombre de 1°2°3°4°5°, contando de
afuera adentro o bien pulgar, índice, medio, anular y meñique.
Cada dedo esta constituida por tres columnitas óseas llamadas falanges, se
designan con los nombres de 1°2°3° contando de arriba hacia abajo.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 28'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 29, 29, 29, 29, 'MUSCULOS
Los músculos de la mano forman un conjunto de 19 músculos repartidos en tres
regiones distintas:
Músculos de la eminencia tenar
Aductor del pulgar
Flexor largo propio del pulgar
Flexor corto del pulgar
Oponente del pulgar
Abductor corto del pulgar
Músculos de la eminencia hipotenar (interna)
Palmar cutáneo
Aductor del meñique
Flexor corto del meñique
Oponente del meñique', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 29'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 30, 30, 30, 30, 'Músculos de la región palmar media
Lumbricales
Interóseos ventrales
Interóseos dorsales', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Cintura Escapular (resumen) > p. 30');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 1, 1, 1, 1, 'CINTURA PELVIANA
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 2, 2, 2, 2, 'HUESOS:
A la cintura pelviana la conforman los huesos coxales, uno a cada lado,
articulado en la parte posterior con el sacro, y por delante entre ellos
con la sínfisis del pubis.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 3, 3, 3, 3, 'SACRO Y COXIS: son las ultimas porciones del raquis, en su conjunto
tiene la forma de triangulo de base superior y vértice inferior con una
concavidad anterior.
Forma el esqueleto posterior de la pelvis, se articula en superior con la
ultima vertebra lumbar, y hacia los lados con el hueso coxal.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 4, 4, 4, 4, 'COXAL:
Es un hueso par, ubicado en la región inferior del tronco, formando
parte del esqueleto de la pelvis. Esta formado por la unión de tres
huesos: el ilion, el isquion y el pubis.
EL ILION es el hueso mas prominente de los tres, se encuentra en la
región superior del coxal y se articula con el sacro, este hueso posee
accidentes óseos fácilmente palpables en la anatomía de superficie,
como la espina iliaca anterosuperior y la espina iliaca posterosuperior.
El PUBIS esta ubicado en la región anteroinferior y se articula con el
pubis contralateral, formando la sínfisis pubiana.
El pubis se une al ilion por una rama iliopubiana y al isquion por una
rama isquiopubiana, entre estas ramas queda formado un orificio
llamado agujero obturador, en conjunto estos tres huesos forman la
cavidad acetabular, donde el coxal se articula con el fémur, formando
la articulación de la cadera.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 5, 5, 5, 5, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 6, 6, 6, 6, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 7, 7, 7, 7, 'MUSCULOS:
• PIRIFORME:
• PSOAS ILIACO:
• OBTURADOR INTERNO:
• OBTURADOR EXTERNO:
• GEMINOS
• CUADRADO FEMORAL
• GLUTEO MENOR
• GLUTEO MEDIO
• GLUTEO MAYOR
• TENSOR DE LA FASCIA LATA', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 8, 8, 8, 8, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 9, 9, 9, 9, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 10, 10, 10, 10, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 11, 11, 11, 11, 'MUSLO:
El muslo es la región anatómica que se encuentra entre la cadera y la
rodilla. Su esqueleto óseo esta formado por el fémur (el hueso mas
grande del organismo), rodeado por tres grupos musculares.
HUESO:
FEMUR: hueso largo, que tiene en su extremo proximal una cabeza que
se articula con el hueso coxal y un cuello. Posterolateral al cuello
femoral se encuentra un accidente óseo importante llamado trocánter
mayor, medial al cuello se encuentra el trocánter menor.
Distalmente el fémur se articula anteriormente con la rotula e
inferiormente aporta sus dos cóndilos para articularse con los platinos
tibiales.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 11'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 12, 12, 12, 12, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 12'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 13, 13, 13, 13, 'MUSCULOS: el muslo tiene tres grupos musculares: uno anterior, uno
posterior, y uno medial.
COMPORTAMIENTO ANTERIOR:
• Sartorio
• Cuádriceps femoral
• Recto femoral
• Vasto medial vasto lateral
• Vasto intermedio
COMPORTAMIENTO POSTERIOR:
• Bíceps femoral
• Semitendinoso
• semimembranoso', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 13'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 14, 14, 14, 14, 'COMPORTAMIENTO MEDIAL:
• Recto interno
• Pectíneo
• Aductores (largo, corto, mayor)', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Cintura Pelviana (resumen) > p. 14');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 1, 1, 1, 1, 'EL ESQUELETO', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 2, 2, 2, 2, 'GENERALIDADES SOBRE HUESOS
• La OSTEOLOGÍA comprende el estudio de los HUESOS que constituyen el
ESQUELETO.
Los huesos son estructuras duras, blanquecinas y resistentes que dan sostén
a las partes blandas, protegen órganos internos, alojan la médula ósea y
dan inserción a los músculos.
• La ARTROLOGÍA o SINDESMOLOGÍA estudia las articulaciones , es decir el
conjunto de formaciones anatómicas que unen a dos o más huesos entre sí.
• La MIOLOGÍA estudia los músculos órganos con la propiedad de contraerse.', 'texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 3, 3, 3, 3, '• El esqueleto humano es osteocartilaginoso, comprende 206 huesos.
Se presenta como:
• Elementos protectores: un conjunto de huesos se conectan entre sí y forman
cavidades que alojan sistemas y sentidos (cráneo, órbitas, etc.).
• Elementos articulares: en las articulaciones.', 'texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 4, 4, 4, 4, 'Los huesos se agrupan en dos grandes regiones:
• El esqueleto axial, comprende cráneo, cara, raquis, costillas y
esternón.
• El esqueleto apendicular, comprende huesos de los miembros
superiores e inferiores. Y las cinturas escapular y pelvianas.
El esqueleto comienza su formación como formas cartilaginosas que
actúan como molde para la osificación.', 'texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 5, 5, 5, 5, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 6, 6, 6, 6, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 7, 7, 7, 7, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 8, 8, 8, 8, 'FUNCIONES DE LOS HUESOS
Las principales funciones son:
• Sostén y forma del cuerpo
• Protección
• Movimiento
• Formación de células de la sangre
• Mantenimiento del equilibrio de fosforo y calcio entre otros.
Además participan en la alimentación (mandíbula) los movimientos
oculares (inserción de los músculos orbitarios) y la audición (huesecillos
del oído)', 'texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 9, 9, 9, 9, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 10, 10, 10, 10, 'VARIABLES PARA EL ESTUDIO DE UN HUESO:', 'texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 11, 11, 11, 11, 'TIPOS DE HUESOS
HUESOS LARGOS: predomina un eje sobre los otros dos (largo sobre
ancho y espesor) ejemplos:
Hueso del brazo y de la pierna', 'texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 11'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 12, 12, 12, 12, 'HUESOS PLANOS: predominan dos ejes sobre el tercero. Ejemplos la
escapula y algunos huesos del cráneo como los parietales.', 'texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 12'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 13, 13, 13, 13, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 13'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 14, 14, 14, 14, 'HUESOS CORTOS: no tienen predominancia de ningún eje. Ejemplos
Huesos del carpo
Huesos del tarso', 'texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 14'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 15, 15, 15, 15, 'ESTRUCTURA DEL HUESO: (se tomara como ejemplo un hueso largo)
La célula formadora del hueso se llama osteoblasto. osteoclasto
La célula ósea se llama osteocito.
• Las porciones se describen a partir de la FISIS que es un cartílago que
permite el crecimiento en longitud del hueso.
• En cada extremo del hueso se localizan las epífisis cubiertas por un
tejido muy resistente llamado cartílago hialino.
• Hacia la porción medial del hueso se localizan las metafisis (una en
cada extremo).
• En el centro del hueso se encuentra la diáfisis (cuerpo del hueso).
• En la parte del hueso donde no hay cartílago, esta cubierto por una
delgada vaina, denominada periostio.', 'texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 15'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 16, 16, 16, 16, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 16'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 17, 17, 17, 17, 'Una vista de un corte en un hueso largo, permite reconocer un hueso
superficial compacto (cortical) y un hueso trabecular profundo llamado
hueso esponjoso, en los espacios que queda entre las trabéculas se
encuentra la medula ósea.
IRRIGACION DEL HUESO: se lleva a cabo mediante 2 vías
• DIAFISIARIA: la arteria ingresa a través del agujero nutricio, se % en
una rama ascendente y descendente.
• ARTERIAS METAFISIARIAS: irrigan el extremo de la diáfisis y epífisis.', 'texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 17'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 18, 18, 18, 18, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 18'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 19, 19, 19, 19, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 19'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 20, 20, 20, 20, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'El Esqueleto (resumen) > p. 20');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='FOSAS_NASALES_Y_SENOS_PARANASALES'), 1, 1, 1, 1, 'FOSAS NASALES Y SENOS 
PARANASALES
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Fosas Nasales y Senos Paranasales (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='FOSAS_NASALES_Y_SENOS_PARANASALES'), 2, 2, 2, 2, 'MORFOLOGIA:
• Las cavidades paranasales se forman por divertículos o evaginaciones
de las fosas nasales.
• Los senos paranasales están revestidos por una mucosa
• Las cavidades paranasales están constituidas por los senos maxilares y
frontales, las celdas esfenoidales y las celdillas etmoidales.', 'texto', 'nativo_pdf', 'COMPLETO', 'Fosas Nasales y Senos Paranasales (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='FOSAS_NASALES_Y_SENOS_PARANASALES'), 3, 3, 3, 3, '•
Los huesos están neumatizados
•
Revestidos por mucosa 
•
Los SPN producen 2 litros de 
mocos', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Fosas Nasales y Senos Paranasales (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='FOSAS_NASALES_Y_SENOS_PARANASALES'), 4, 4, 4, 4, 'FOSAS NASALES:
• Son dos amplios corredores altos y aplanados en el sentido lateral.
• Su pared medial, es común a ambas fosas nasales esta constituida por
el cartílago nasal, la lamina vertical del etmoides y el vómer.
• El piso esta constituida por la apófisis palatina del hueso maxilar
• El techo parte del hueso etmoides, constituido por pequeños orificios
por donde pasan los filetes nerviosos del nervio olfatorio.
• La pared lateral de cada fosa nasal esta constituida por siete huesos:
el palatino, las apófisis pterigoides del esfenoides, el maxilar superior,
el cornete inferior, el etmoides, los huesos propios de la nariz y el
unguis.
• Se distinguen tres aleros, denominados cornetes: inferior, medio y el
superior (cubren unos espacios denominados los meatos)', 'texto', 'nativo_pdf', 'COMPLETO', 'Fosas Nasales y Senos Paranasales (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='FOSAS_NASALES_Y_SENOS_PARANASALES'), 5, 5, 5, 5, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Fosas Nasales y Senos Paranasales (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='FOSAS_NASALES_Y_SENOS_PARANASALES'), 6, 6, 6, 6, '• En el meato inferior que esta cubierto por el cornete inferior se
encuentra el orificio de drenaje del conducto lacrimonasal, que
comunica la orbita con la fosa nasal.
FUNCIONES DE LAS FOSAS NASALES
• Filtrar el aire
• Calentar el aire
• Humidificar el aire
Conducto lacrimonasal', 'texto', 'nativo_pdf', 'COMPLETO', 'Fosas Nasales y Senos Paranasales (resumen) > p. 6');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 1, 1, 1, 1, 'HUESOS DE LA CABEZA
LIC. MIGUEL MEDINA', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 2, 2, 2, 2, 'ESQUELETO:
• Constituye la estructura ósea de la cabeza
• Aloja y protege al sistema nervioso encefálico, a órganos de los
sentidos, y a la primera parte de los aparatos de la alimentación y de
la respiración.
HUESOS DEL CRANEO:
Se los clasifica en pares e impares
• IMPARES: frontal, etmoides, esfenoides, vómer, occipital y maxilar
inferior (mandíbula)
• PARES: temporal, parietal, unguis, cornete inferior, palatino, huesos
propios de la nariz, malar y maxilar superior.', 'texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 3, 3, 3, 3, '• IMPARES: frontal, etmoides, esfenoides, vómer, occipital y maxilar
inferior (mandíbula)', 'texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 4, 4, 4, 4, '• PARES: temporal, parietal, unguis, cornete inferior, palatino, huesos
propios de la nariz, malar y maxilar superior.', 'texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 5, 5, 5, 5, 'ALGUNAS GENERALIDADES:
• Al nacer quedan entre los huesos de la Calota áreas de tejido
conjuntivo denominadas fontanelas, que se palpan como depresiones
blandas.
• Todos los huesos del cráneo, (excepto la mandíbula y los huesecillos
del oído) terminan soldándose entre si formando suturas.', 'texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 6, 6, 6, 6, 'DIVISIONES:
El cráneo esta constituido por el neurocraneo, que encierra al encéfalo
y sus meninges, y el viscerocraneo que es el esqueleto de la cara.
• NEUROCRANEO: se divide en una porción superior o Calota y en una
porción inferior o base.', 'texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 7, 7, 7, 7, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 8, 8, 8, 8, '• ORIFICIOS DE LA BASE DEL CRANEO: son orificios por donde pasan
vasos y estructuras nerviosas.
Lamina cribosa del etmoides: filetes del nervio olfatorio
Conducto óptico: nervio óptico y arteria oftálmica
Conducto carotideo: (dentro de la pirámide del temporal) arteria
carótida
Hendidura esfenoidal: 3° par oculomotor, 4° par troclear, 6° par
abducens y rama oftálmica del quinto par', 'texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 9, 9, 9, 9, 'Agujero redondo mayor: rama maxilar del quinto par
Agujero oval: rama mandibular del quinto par
Agujero redondo menor: arteria meníngea media
Agujero rasgado anterior: arteria carótida
Conducto auditivo interno: nervio facial y nervio auditivo
Foramen magno: bulbo raquídeo y las arterias vertebrales
Agujero rasgado posterior: vena yugular
Agujero codileo: 12° par hipogloso', 'texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 10, 10, 10, 10, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 11, 11, 11, 11, 'PUNTOS DEL CRANEO:
• Mentoniano: (extremo anteroinferior del mentón)
• Nasion: (raíz de la nariz)
• Glabela: (entre los arcos superciliares, por encima del nasion)
• Inion: (protuberancia occipital externa)
• Gonion: (en el ángulo que forman las ramas horizontal y vertical de la
mandibula)
• Bregma: (donde se unen los 2 parietales con el hueso frontal)
• Lambda(donde se unen los parietales con el hueso occipital)
• Infraorbitario: (en el centro del reborde orbitario inferior)', 'texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 11'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 12, 12, 12, 12, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 12'),
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 13, 13, 13, 13, 'REGIONES:
Las mas importantes son las orbitas, la región selar y las fosas nasales y
senos paranasales.', 'texto', 'nativo_pdf', 'COMPLETO', 'Huesos de la Cabeza (resumen) > p. 13');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='MUSCULOS_DE_LA_CABEZA'), 1, 1, 1, 1, 'MUSCULOS DE LA CABEZA
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Músculos de la Cabeza (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='MUSCULOS_DE_LA_CABEZA'), 2, 2, 2, 2, 'La mayoría de los músculos del cráneo están relacionados con la
mímica (expresión facial) y la masticación.
MUSCULOS DE LA MIMICA
Su característica principal es que su inserción es cutánea
Se dividen por regiones:
• Del epicráneo
• De la hendidura palpebral
• De la región nasal
• De la región auricular de los labios
Su función consiste en la apertura o cierre de los orificios de la cabeza e
intervienen en las modificaciones de la fisonomía', 'texto', 'nativo_pdf', 'COMPLETO', 'Músculos de la Cabeza (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='MUSCULOS_DE_LA_CABEZA'), 3, 3, 3, 3, 'EJEMPLOS DE MUSCULOS FASCIALES
• Corrugador de la ceja
• Orbicular de los ojos
• Nasal
• Elevador del labio superior
• Buccinador
• Orbicular de los labios y de la boca
• Depresor del Angulo de la boca
• Mentoniano
• Depresor del labio inferior
• Platisma
• Risorio
• Cigomático menor y mayor
• Vertiente frontal del occipitofrontal
• Elevador del ala de la nariz', 'texto', 'nativo_pdf', 'COMPLETO', 'Músculos de la Cabeza (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='MUSCULOS_DE_LA_CABEZA'), 4, 4, 4, 4, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Músculos de la Cabeza (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='MUSCULOS_DE_LA_CABEZA'), 5, 5, 5, 5, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Músculos de la Cabeza (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='MUSCULOS_DE_LA_CABEZA'), 6, 6, 6, 6, 'IRRIGACION: arteria facial y la arteria temporal superficial, ambas ramas de la
arteria carótida externa.
MUSCULOS DE LA MASTICACION:
Aseguran con diferentes movimientos el corte y la trituración de los alimentos. Son:
• Masetero
• El temporal
• Pterigoideo interno
• El pterigoideo externo
• Suprahioideos
• Digástrico
• Milohioideo', 'texto', 'nativo_pdf', 'COMPLETO', 'Músculos de la Cabeza (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='MUSCULOS_DE_LA_CABEZA'), 7, 7, 7, 7, 'ARTICULACION TEMPOROMANDIBULAR (ATM)
• Es una articulación sinovial que permite el movimiento de la
mandíbula en tres planos.
• Esta compuesta por el cóndilo mandibular con su cuello, la fosa
mandibular y el tubérculo articular del hueso temporal.
• La articulación se mueve por la acción de los músculos de la
masticación.', 'texto', 'nativo_pdf', 'COMPLETO', 'Músculos de la Cabeza (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='MUSCULOS_DE_LA_CABEZA'), 8, 8, 8, 8, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Músculos de la Cabeza (resumen) > p. 8');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 1, 1, 1, 1, 'MUSCULOS', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 2, 2, 2, 2, 'GENERALIDADES:
Hay mas de 650 músculos en el cuerpo humano que, en forma
voluntaria o involuntaria, producen distintos tipos de movimientos o
estabilizan las articulaciones y otros sectores del esqueleto.
Existen 3 tipos de músculos, según sus características histológicas y su
comportamiento:
1. Musculo esquelético o estriado: (voluntario) es decir las personas
pueden controlar su actividad de forma voluntaria) que es el que
mueve el esqueleto.
2. Musculo visceral o liso: (involuntario) que se encuentra por ejemplo
en las paredes de las arterias y en las vísceras huecas.
3. Musculo cardiaco: denominado miocardio, que forma la mayor
parte de las paredes del corazón (es involuntario y sus fibras son
estriadas)', 'texto', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 3, 3, 3, 3, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 4, 4, 4, 4, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 5, 5, 5, 5, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 6, 6, 6, 6, 'MUSCULO ESTRIADO: su función principal es la contracción voluntaria.
• Los músculos que realizan la misma acción se denominan agonistas
• Los antagonistas son los que realizan movimientos opuestos (cuando
se contrae un musculo se debe relajar el antagonista)
• Se denominan sinergistas a aquellos que complementan la acción de
otros músculos.
En general los músculos están formados por una parte central, carnosa,
que es la que tiene la capacidad de contraerse y dos extremos llamados
tendones, que por regla general se originan e insertan en huesos,
cartílagos y ligamentos.', 'texto', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 7, 7, 7, 7, 'Aponeurosis:
“Es una membrana fibrosa formada principalmente
por fibras de colágeno que tiene la función de
servir
de
inserción
a
algunos
músculos
esqueléticos”.', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 8, 8, 8, 8, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 9, 9, 9, 9, 'La contracción de los músculos estriados se produce por la acción de
los nervios motores (estímulos eléctricos).
Los músculos se denominan con criterios variados, pueden ser por:
• Su localización: el musculo braquial (en el brazo)
• Por su acción: los músculos aductores (muslo) y supinadores (en el
antebrazo).
• Por su forma: músculos trapecios y cuadrado lumbar.
• Por la orientación de sus fibras (músculos rectos del abdomen)
• Por el numero de cabezas o divisiones: bíceps, tríceps y cuádriceps
• Por sus puntos de fijación: (esternotiroideo=inserciones en el
esternón y en el cartílago tiroides).', 'texto', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 10, 10, 10, 10, '• Los músculos están recubiertos por vainas resistentes denominadas
aponeurosis, que permiten el deslizamiento de unos sobre otros.
• Las almohadillas o bolsas (bursas) que contienen una pequeña
cantidad de liquido sinovial, se interponen entre los músculos y las
superficies óseas.
MUSCULO LISO: controla el calibre de las estructuras tubulares
(intestino y vasos sanguíneos).', 'texto', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 11, 11, 11, 11, 'FUNCIONES DE LOS MUSCULOS LISOS Y ESTRIADOS:
• Producir movimientos del cuerpo (caminar, correr, saltar)
• Mantener las posiciones del cuerpo (de pie, sentado)
• Cerrar y abrir orificios (boca)
• Movilizar el contenido visceral
• Mantener la sangre en movimiento (circulando)
• Genera calor', 'texto', 'nativo_pdf', 'COMPLETO', 'Músculos (resumen) > p. 11');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 1, 1, 1, 1, 'PARED TORACICA
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Pared Torácica (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 2, 2, 2, 2, 'ESQUELETO:
El esqueleto de la pared torácica esta constituido por:
• 12 vertebras torácicas
• Discos intervertebrales
• 12 pares de costillas con sus cartílagos costales
• El esternón', 'texto', 'nativo_pdf', 'COMPLETO', 'Pared Torácica (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 3, 3, 3, 3, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Pared Torácica (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 4, 4, 4, 4, 'VERTEBRAS
Las vertebras torácicas se caracterizan por presentar a cada lado, en el
sector posterior del cuerpo superficies articulares para las costillas y en
cada apófisis transversa en las 10 primeras.', 'texto', 'nativo_pdf', 'COMPLETO', 'Pared Torácica (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 5, 5, 5, 5, 'COSTILLAS:
• Son 12 en cada lado, se articulan hacia atrás con las vertebras
torácicas
• Las 10 primeras se continúan en su extremo distal con una porción
cartilaginosa, pueden de forma directa o indirecta articularse con el
esternón.
• Las 2 ultimas no se articulan con el esternón y se denominan
flotantes.
• Se unen al esternón por la articulación condroesternal', 'texto', 'nativo_pdf', 'COMPLETO', 'Pared Torácica (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 6, 6, 6, 6, '• Las costillas son huesos aplanados y curvos
• Están compuestas por una cabeza, un cuello, un tubérculo y un cuerpo', 'texto', 'nativo_pdf', 'COMPLETO', 'Pared Torácica (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 7, 7, 7, 7, 'ESTERNON:
Presenta 3 componentes:
• El manubrio, se articula a ambos lados con la clavícula y el 1°cartílago
costal
• El cuerpo, se articula con los cartílagos costales 2° a 7°
• La apófisis xifoides', 'texto', 'nativo_pdf', 'COMPLETO', 'Pared Torácica (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 8, 8, 8, 8, 'ESPACIOS INTERCOSTALES:
• Contiene el paquete vasculonervioso (vena, arteria y nervio de arriba
hacia abajo) y los músculos intercostales diferenciados en 3 planos.
MUSCULOS:
• Ocupan los espacios entre las costillas, y se encuentran los
intercostales externos, medio e interno.', 'texto', 'nativo_pdf', 'COMPLETO', 'Pared Torácica (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 9, 9, 9, 9, 'FUNCIONES:
• Protege a los órganos torácicos y los órganos del abdomen superior
• Es el esqueleto de la respiración
• Da soporte para varios músculos extratorácicos', 'texto', 'nativo_pdf', 'COMPLETO', 'Pared Torácica (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 10, 10, 10, 10, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Pared Torácica (resumen) > p. 10');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='PIERNA'), 1, 1, 1, 1, 'PIERNA
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Pierna (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 2, 2, 2, 2, '• La pierna es la región anatómica que se extiende desde la articulación
de la rodilla hasta la articulación del tobillo.
• Esta formada por dos huesos largos: la tibia y el peroné en la cara
lateral.', 'texto', 'nativo_pdf', 'COMPLETO', 'Pierna (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 3, 3, 3, 3, 'HUESOS
TIBIA:
• Es un hueso largo, su porción proximal es mas voluminosa y posee
dos platillos tibiales que articulan los cóndilos femorales, formando la
articulación bicondilea de la rodilla.
• En su región anterior encontramos un accidente óseo importante, la
tuberosidad de la tibia, sitio de inserción del tendón rotuliano y
origen del musculo tibial anterior.
• Su extremo inferior es menor y forma parte de la articulación del
tobillo, junto con el peroné y la hilera posterior del tarso (astralago y
calcáneo), a su vez esta porción inferior tiene una apófisis
voluminosa, llamada maléolo interno.', 'texto', 'nativo_pdf', 'COMPLETO', 'Pierna (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 4, 4, 4, 4, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Pierna (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 5, 5, 5, 5, 'PERONE:
• Es el otro hueso largo de la pierna. En su región proximal, presenta
una cabeza, que se articula con la porción posterolateral de la tibia.
Además presenta un ensanchamiento para la articulación del tobillo,
y una apófisis denominada maléolo externo.', 'texto', 'nativo_pdf', 'COMPLETO', 'Pierna (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 6, 6, 6, 6, 'MUSCULOS:
La musculatura de la tibia esta dividida en un compartimiento anterior,
uno posterior y uno lateral:
COMPARTIMIENTO ANTERIOR
• Tibial anterior
• Extensor largo de los dedos
• Extensor largo del primer dedo
• Peroneo anterior', 'texto', 'nativo_pdf', 'COMPLETO', 'Pierna (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 7, 7, 7, 7, 'COMPARTAMIENTO POSTERIOR:
• Poplíteo
• Tibial posterior
• Flexor largo de los dedos
• Flexor largo del primer dedo
• Gemelos
• Soleo
• Plantar delgado', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Pierna (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 8, 8, 8, 8, 'COMPARTIMIENTO LATERAL:
• Peroneo largo
• Peroneo corto', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Pierna (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 9, 9, 9, 9, 'PIE:
• El pie es la región que forma el extremo distal de la extremidad
inferior, por debajo de la articulación del tobillo.
• Su esqueleto óseo esta formado por tres regiones: tarso, metatarso y
falanges.
TARSO: formado por astralago, calcáneo, cuboides, escafoides, cuñas', 'texto', 'nativo_pdf', 'COMPLETO', 'Pierna (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 10, 10, 10, 10, 'METATARSO
Esta formado por 5 huesos largos, que se denomina de interno a
externo, 1°, 2°, 3°, 4° y 5° metatarsianos. Hacia proximal se articulan
con la línea anterior del tarso y entre si y hacia distal con las primeras
falanges.', 'texto', 'nativo_pdf', 'COMPLETO', 'Pierna (resumen) > p. 10');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 1, 1, 1, 1, 'RAQUIS I
LIC. MIGUEL MEDINA', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 2, 2, 2, 2, 'ESQUELETO DEL RAQUIS EN CONJUNTO:
• El raquis en conjunto es una estructura en parte rígida y en parte
flexible.
• Desempeña
una
importante
función
en
la
postura
y
en
la
deambulación.
• Su estuche óseo posterior (conducto raquídeo) es protector del eje
nervioso (medula, raíces, meninges y LCR).', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 3, 3, 3, 3, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 4, 4, 4, 4, 'CURVAS DEL RAQUIS:
• Visto en conjunto de frente el raquis es rectilíneo y se localiza en la
línea media.
• En cambio visto de perfil, presenta curvas que van alternando el lado
de la convexidad.
• El raquis cervical y lumbar presentan una convexidad anterior
denominada lordosis.
• En el raquis dorsal y el sacro-cóccix, presenta una convexidad
posterior o cifosis.', 'texto', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 5, 5, 5, 5, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 6, 6, 6, 6, 'VERTEBRA TIPO:
La unidad morfológica del raquis es la vertebra.
Presenta:
• Un cuerpo: se articula con las vertebras adyacentes a través de los
discos intervertebrales que están constituidos por una porción
central, el núcleo pulposo, y una porción periférica, el anillo fibroso.
• Arco posterior: queda dividido a cada lado por los macizos
articulares: el anterior se denomina pedículo, el posterior constituye
la lamina y se unen por detrás para formar la apófisis espinosa.
A cada lado de los macizos articulares se encuentran las apófisis
transversas.
La cara posterior de un cuerpo vertebral y su arco posterior forman un
orificio denominado foramen vertebral.', 'texto', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 7, 7, 7, 7, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 8, 8, 8, 8, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 9, 9, 9, 9, 'ARTICULACIONES:
• Intervertebrales: (una vertebra con otra a través del cuerpo y las facetas
articulares)
• Craneovertebral: (articulaciones accipito-atloidea y atloideo-axoidea)
• Costovertebrales
• Sacroiliacas
CONDUCTO RAQUIDEO:
• Esta constituido por la cara posterior de los cuerpos vertebrales y discos
intervertebrales, el foramen vertebral y los ligamentos vinculados.
• Contiene a la medula espinal, las raíces de los nervios raquídeos, las
cubierta meníngeas(duramadre, aracnoides y piamadre), además se
encuentran tejido adiposo, arterias y venas.', 'texto', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 10, 10, 10, 10, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 11, 11, 11, 11, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis I (resumen) > p. 11');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 1, 1, 1, 1, 'RAQUIS II
LIC. MIGUEL MEDINA', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 2, 2, 2, 2, 'ESQUELETO: esta constituido por 33 o 34 vertebras
SEGMENTOS:
• Cervical 7 vertebras
• Dorsal 12 vertebras
• Lumbar 5 vertebras
• Sacro 5 vertebras fusionadas
• Cóccix 4 o 5 vertebras fusionadas', 'texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 3, 3, 3, 3, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 4, 4, 4, 4, 'DIFERENCIAS Y SIMILITUDES:
Existen características regionales de las vertebras que permiten
identificar a que segmento pertenecen.
• Una vertebra lumbar es similar a la vertebra tipo.
• Las vertebras cervicales presentan el foramen transverso que es
atravesado a cada lado por la arteria vertebral.
• El atlas y el axis en cuanto a su constitución son vertebras cervicales
atípicas.
• El atlas no tiene cuerpo, esta compuesto por un arco anterior y otro
posterior, y por los macizos laterales articulares.
• El axis presenta una apófisis superior denominada odontoides, que se
articula con la cara posterior del arco anterior del atlas.', 'texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 5, 5, 5, 5, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 6, 6, 6, 6, '• La séptima vertebra cervical suele tener el foramen trasverso
pequeño y una apófisis espinosa prominente.
• La característica principal de las 10 primeras vertebras dorsales o
torácicas, es la presencia de las fositas costales en el cuerpo y en las
apófisis transversas en las que se articulan las costillas.
• El sacro presenta una voluminosa masa lateral a cada lado.', 'texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 7, 7, 7, 7, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 8, 8, 8, 8, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 9, 9, 9, 9, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 10, 10, 10, 10, 'LOS FORAMENES INTERVERTEBRALES: son por los cuales emergen a
cada lado los nervios raquídeos. Cada uno tiene una pared anterior, un
techo, una pared posterior, un piso y dos orificios uno interno y otro
externo.
MEDIOS DE UNION: son los ligamentos que van uniendo una vertebra
con otra aumentando la estabilidad del conjunto vertebral.
Se los puede clasificar en:
• Ligamentos de los cuerpos vertebrales
• Ligamentos de los arcos posteriores
• Otros ligamentos: son los que corresponden a las articulaciones del
complejo base de cráneo-axis los ligamentos costovertebrales y los de
las articulaciones sacroiliacas.', 'texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 11, 11, 11, 11, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 11'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 12, 12, 12, 12, '• En los cuerpos
vertebrales el ligamento longitudinal anterior
desciende como una banda ancha por delante de las vertebras desde
la base del cráneo hasta el sacro.
• Ligamento longitudinal posterior, se extiende por detrás de los
cuerpos vertebrales.
En el arco posterior se encuentran los siguientes ligamentos:
• Amarillo
• Interespinoso
• Intertransverso
• Supraespinoso
• Ligamento nucal', 'texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 12'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 13, 13, 13, 13, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Raquis II (resumen) > p. 13');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 1, 1, 1, 1, 'REGIONES DE LA CABEZA:
Orbitas y Región Selar
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 2, 2, 2, 2, '• Las cavidades orbitarias son las dos cavidades situadas a ambos lados
de la línea media de la cara.
• Destinadas a alojar los globos oculares y sus anexos.
• Las estructuras óseas que las delimitan se denominan órbitas.
• Tiene forma de pirámide con la base anterolateral y el vértice
posteromedial.', 'texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 3, 3, 3, 3, 'ORBITAS:
• Son dos pirámides huecas tumbadas
• Compuestas por 7 huesos y 4 paredes:
Techo, piso, pared medial, pared lateral y un vértice
ORIFICIOS:
• Orificio externo del conducto óptico
• Cisura orbitaria superior
• Cisura orbitaria inferior
• Orificio superior del orificio lacrimonasal', 'texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 4, 4, 4, 4, 'Orifio E.C.O
Hendidura 
Esf.
Cisura O.I
O. Sup del C. L', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 5, 5, 5, 5, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 6, 6, 6, 6, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 7, 7, 7, 7, 'CONTENIDO:
• Globo ocular
• Aparato lacrimal
• Nervios de la orbita
• Músculos extrínsecos del globo ocular
• Arterias y venas', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 8, 8, 8, 8, 'APARATO LACRIMAL: constituido por:
• Glándula lacrimal
• Conductos y conductillos lagrimales
• Conducto lacrimonasal, que lleva el liquido lagrimal a la fosa nasal', 'texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 9, 9, 9, 9, 'NERVIOS:
• Nervio óptico
• Nervios que ingresan a través de la hendidura esfenoidal y que
inervan los músculos extrínsecos del globo ocular
• El tercer par o motor ocular común
• El cuarto par o troclear
• El sexto par o motor ocular externo', 'texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 10, 10, 10, 10, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 11, 11, 11, 11, 'MUSCULOS EXTRINSECOS:
• Elevador de los parpados
• Recto superior
• Oblicuo mayor
• Recto interno
• Oblicuo menor
• Recto inferior
• Recto externo', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 11'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 12, 12, 12, 12, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 12'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 13, 13, 13, 13, 'PARPADOS: funciones
• Proteger al ojo de los agentes externos
• Mantener la humedad de la cornea', 'texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 13'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 14, 14, 14, 14, 'ARTERIAS:
Arteria oftálmica y sus ramas (arteria central de la retina)
VENAS:
• Vena central de la retina
• Venas oftálmicas superior e inferior', 'texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 14'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 15, 15, 15, 15, 'REGION SELAR:
Es una región intracraneal, se asemeja a un cubo con: 
• 6 paredes 
• Un contenido.
PAREDES:
• Pared anterior, piso y pared posterior corresponden a la silla turca
• PERFIL: tiene forma de U
• Por adelante y por fuera de la pared anterior se encuentran las
apófisis clinoides anteriores.
• A cada lado del sector superior del dorso se encuentran las apófisis
clinoides posteriores.', 'texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 15'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 16, 16, 16, 16, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 16'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 17, 17, 17, 17, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 17'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 18, 18, 18, 18, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 18'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 19, 19, 19, 19, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 19'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 20, 20, 20, 20, 'TECHO: denominado diafragma selar, esta constituido por una
expansión de la duramadre, presenta:
Un orificio en el centro, atravesado por el tallo de la glándula hipófisis.
PAREDES LATERALES: corresponden a los senos cavernosos que reciben
sangre
venosa
de
venas
encefálicas,
orbitarias
y
del
seno
esfenoparietal.
Los senos cavernosos contienen parte de la arteria carótida interna y
varios pares craneanos.', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 20'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 21, 21, 21, 21, 'CONTENIDO:
La silla turca aloja a la glándula hipofisiaria y parte de su tallo.', 'texto', 'nativo_pdf', 'COMPLETO', 'Regiones de la Cabeza (resumen) > p. 21');


-- Figuras (revisadas: solo las marcadas 'keep' en el manifiesto)

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 'F00001', 4, 30, '23,13,145,132', 0.9, 'doc' || (select id from tmp_doc_map where dirname='ARTICULACIONES') || '/pdf0004_fig01_xref30.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 'F00002', 4, 30, '26,148,167,265', 0.9, 'doc' || (select id from tmp_doc_map where dirname='ARTICULACIONES') || '/pdf0004_fig02_xref30.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 'F00003', 9, 51, '20,22,259,164', 0.9, 'doc' || (select id from tmp_doc_map where dirname='ARTICULACIONES') || '/pdf0009_fig01_xref51.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 'F00004', 10, 58, '102,23,240,150', 0.9, 'doc' || (select id from tmp_doc_map where dirname='ARTICULACIONES') || '/pdf0010_fig01_xref58.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='ARTICULACIONES'), 'F00005', 11, 62, '0,0,262,148', 0.9, 'doc' || (select id from tmp_doc_map where dirname='ARTICULACIONES') || '/pdf0011_fig01_xref62.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 'F00001', 11, 75, '79,15,935,500', 0.9, 'doc' || (select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR') || '/pdf0011_fig01_xref75.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 'F00002', 20, 76, '61,13,225,206', 0.9, 'doc' || (select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR') || '/pdf0020_fig01_xref76.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR'), 'F00003', 21, 112, '55,0,187,225', 0.9, 'doc' || (select id from tmp_doc_map where dirname='CINTURA_ESCAPULAR') || '/pdf0021_fig01_xref112.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 'F00003', 5, 29, '177,49,591,391', 0.9, 'doc' || (select id from tmp_doc_map where dirname='CINTURA_PELVIANA') || '/pdf0005_fig01_xref29.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 'F00004', 7, 41, '386,27,872,883', 0.9, 'doc' || (select id from tmp_doc_map where dirname='CINTURA_PELVIANA') || '/pdf0007_fig01_xref41.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='CINTURA_PELVIANA'), 'F00007', 8, 48, '453,0,822,720', 0.9, 'doc' || (select id from tmp_doc_map where dirname='CINTURA_PELVIANA') || '/pdf0008_fig01_xref48.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 'F00001', 1, 9, '108,69,764,1262', 0.9, 'doc' || (select id from tmp_doc_map where dirname='EL_ESQUELETO') || '/pdf0001_fig01_xref9.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 'F00002', 5, 84, '79,32,513,387', 0.9, 'doc' || (select id from tmp_doc_map where dirname='EL_ESQUELETO') || '/pdf0005_fig01_xref84.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 'F00003', 5, 84, '422,272,962,646', 0.9, 'doc' || (select id from tmp_doc_map where dirname='EL_ESQUELETO') || '/pdf0005_fig02_xref84.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 'F00004', 5, 84, '67,456,508,877', 0.9, 'doc' || (select id from tmp_doc_map where dirname='EL_ESQUELETO') || '/pdf0005_fig03_xref84.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 'F00006', 12, 106, '55,142,532,634', 0.9, 'doc' || (select id from tmp_doc_map where dirname='EL_ESQUELETO') || '/pdf0012_fig02_xref106.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 'F00007', 12, 106, '757,160,1187,634', 0.9, 'doc' || (select id from tmp_doc_map where dirname='EL_ESQUELETO') || '/pdf0012_fig03_xref106.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='EL_ESQUELETO'), 'F00009', 14, 116, '23,168,621,625', 0.9, 'doc' || (select id from tmp_doc_map where dirname='EL_ESQUELETO') || '/pdf0014_fig02_xref116.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='FOSAS_NASALES_Y_SENOS_PARANASALES'), 'F00001', 2, 56, '0,22,436,287', 0.9, 'doc' || (select id from tmp_doc_map where dirname='FOSAS_NASALES_Y_SENOS_PARANASALES') || '/pdf0002_fig01_xref56.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA'), 'F00001', 1, 11, '19,0,206,225', 0.9, 'doc' || (select id from tmp_doc_map where dirname='HUESOS_DE_LA_CABEZA') || '/pdf0001_fig01_xref11.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='MUSCULOS_DE_LA_CABEZA'), 'F00001', 1, 13, '16,23,242,197', 0.9, 'doc' || (select id from tmp_doc_map where dirname='MUSCULOS_DE_LA_CABEZA') || '/pdf0001_fig01_xref13.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 'F00001', 1, 9, '10,7,272,180', 0.9, 'doc' || (select id from tmp_doc_map where dirname='MUSCULOS') || '/pdf0001_fig01_xref9.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 'F00002', 3, 22, '113,65,1174,788', 0.9, 'doc' || (select id from tmp_doc_map where dirname='MUSCULOS') || '/pdf0003_fig01_xref22.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 'F00004', 5, 30, '95,80,265,235', 0.9, 'doc' || (select id from tmp_doc_map where dirname='MUSCULOS') || '/pdf0005_fig01_xref30.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='MUSCULOS'), 'F00005', 5, 30, '35,247,785,1024', 0.9, 'doc' || (select id from tmp_doc_map where dirname='MUSCULOS') || '/pdf0005_fig02_xref30.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 'F00001', 4, 29, '7,10,489,297', 0.9, 'doc' || (select id from tmp_doc_map where dirname='PARED_TORACICA') || '/pdf0004_fig01_xref29.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 'F00002', 4, 29, '392,130,600,251', 0.9, 'doc' || (select id from tmp_doc_map where dirname='PARED_TORACICA') || '/pdf0004_fig02_xref29.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 'F00003', 4, 29, '39,328,577,600', 0.9, 'doc' || (select id from tmp_doc_map where dirname='PARED_TORACICA') || '/pdf0004_fig03_xref29.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='PARED_TORACICA'), 'F00004', 7, 39, '10,11,401,359', 0.9, 'doc' || (select id from tmp_doc_map where dirname='PARED_TORACICA') || '/pdf0007_fig01_xref39.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='PIERNA'), 'F00001', 2, 21, '95,0,304,500', 0.9, 'doc' || (select id from tmp_doc_map where dirname='PIERNA') || '/pdf0002_fig01_xref21.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 'F00002', 4, 33, '149,0,249,400', 0.9, 'doc' || (select id from tmp_doc_map where dirname='PIERNA') || '/pdf0004_fig01_xref33.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 'F00003', 10, 54, '56,41,360,260', 0.9, 'doc' || (select id from tmp_doc_map where dirname='PIERNA') || '/pdf0010_fig01_xref54.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='PIERNA'), 'F00004', 10, 54, '225,363,400,455', 0.9, 'doc' || (select id from tmp_doc_map where dirname='PIERNA') || '/pdf0010_fig02_xref54.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 'F00001', 5, 31, '109,0,393,314', 0.9, 'doc' || (select id from tmp_doc_map where dirname='RAQUIS_I') || '/pdf0005_fig01_xref31.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='RAQUIS_I'), 'F00002', 7, 39, '0,17,440,293', 0.9, 'doc' || (select id from tmp_doc_map where dirname='RAQUIS_I') || '/pdf0007_fig01_xref39.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 'F00001', 3, 24, '760,10,1291,1249', 0.9, 'doc' || (select id from tmp_doc_map where dirname='RAQUIS_II') || '/pdf0003_fig01_xref24.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='RAQUIS_II'), 'F00002', 3, 24, '9,39,451,1236', 0.9, 'doc' || (select id from tmp_doc_map where dirname='RAQUIS_II') || '/pdf0003_fig02_xref24.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 'F00003', 7, 53, '443,262,926,708', 0.9, 'doc' || (select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA') || '/pdf0007_fig03_xref53.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 'F00004', 8, 58, '17,26,626,596', 0.9, 'doc' || (select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA') || '/pdf0008_fig01_xref58.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 'F00005', 11, 71, '7,8,425,318', 0.9, 'doc' || (select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA') || '/pdf0011_fig01_xref71.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA'), 'F00006', 13, 79, '11,0,250,151', 0.9, 'doc' || (select id from tmp_doc_map where dirname='REGIONES_DE_LA_CABEZA') || '/pdf0013_fig01_xref79.jpg', 'active');


-- Vínculos figura <-> fragmento por página

insert into public.knowledge_fragment_figures (fragment_id, figure_id, relation_type, weight)
select f.id, g.id, 'same_page', 1.0
from public.knowledge_figures g
join public.knowledge_fragments f on f.document_id = g.document_id and f.page_start = g.pdf_page
where g.document_id in (select id from tmp_doc_map)
on conflict (fragment_id, figure_id) do nothing;
