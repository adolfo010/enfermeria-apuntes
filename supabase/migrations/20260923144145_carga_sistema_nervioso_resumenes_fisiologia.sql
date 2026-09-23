-- Carga de material de Sistema Nervioso (Eje 5) desde carpeta Drive
-- 'Estructura y Función Humana II': resúmenes puntuales + doc de fisiología
-- (bioelectricidad/sinapsis) que llenaba el hueco detectado en el programa.
-- Sistema-NerviosoII.pdf quedó fuera: es un PDF de fotos escaneadas sin texto
-- nativo, y esta Mac no tiene Tesseract instalado (bloqueador ya documentado).
-- Figuras candidatas revisadas manualmente antes de esta carga.

create temp table tmp_doc_map (dirname text, id bigint) on commit drop;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1P9PTpgcwa_kI47yZ_cIMOqHlssSqtO_o', 'SISTEMA NERVIOSO.pdf', 'Sistema Nervioso (resumen)', 'resumen', 'Anatomia', 11, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'SISTEMA_NERVIOSO', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('149fOyEDmLgZSehmuU-V74hv19hD1DxlI', 'hemisferios cerebrales. configuracion interna.pdf', 'Hemisferios Cerebrales - Configuración Interna (resumen)', 'resumen', 'Anatomia', 12, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'hemisferios_cerebrales__configuracion_interna', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1cPq3fPDQU4KqSjwA8Ikp0kgFs87mabUY', 'HEMISFERIOS CEREBRALES.pdf', 'Hemisferios Cerebrales (resumen)', 'resumen', 'Anatomia', 8, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'HEMISFERIOS_CEREBRALES', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1HiCleDH4hX1qbtiMLcPEK-j5WMLIj_dJ', 'TRONCO DEL ENCEFALO.pdf', 'Tronco del Encéfalo (resumen)', 'resumen', 'Anatomia', 6, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'TRONCO_DEL_ENCEFALO', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1oV-CXHbN-EnWf-Qozo6kahbrq9OXEZoK', 'CEREBELO Y MEDULA ESPINAL.pdf', 'Cerebelo y Médula Espinal (resumen)', 'resumen', 'Anatomia', 5, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'CEREBELO_Y_MEDULA_ESPINAL', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1C-Sm9DVhYpRiNVOOzoZ9mi5zjhDbOMp9', 'VASCULARIZACION DEL SISTEMA NERVIOSO CENTRAL.pdf', 'Vascularización del Sistema Nervioso Central (resumen)', 'resumen', 'Anatomia', 2, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'VASCULARIZACION_DEL_SISTEMA_NERVIOSO_CENTRAL', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1NLHh-ArFJqbQICkmJJRKAUxCqU3TMI36', 'SISTEMA NERVIOSO AUTONOMO.pdf', 'Sistema Nervioso Autónomo (resumen)', 'resumen', 'Anatomia', 2, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'SISTEMA_NERVIOSO_AUTONOMO', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1KcwBiHtAY4qDXMo_YYLMnS3NDjHP8v7q', 'Anatomia_Fisiologia_SN.doc', 'Anatomía y Fisiología del Sistema Nervioso (resumen)', 'resumen', 'Anatomia', 37, 'completed', '{"nota":"Documento Word convertido a texto plano con textutil; la paginación es por sección temática, no por página real de Word."}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'ANATOMIA_FISIOLOGIA_SN', id from ins;


-- Fragmentos (una fila por página, texto nativo)

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 1, 1, 1, 1, 'SISTEMA NERVIOSO
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 2, 2, 2, 2, 'SISTEMA NERVIOSO: SISTEMA NERVIOSO CENTRAL Y PERIFERICO
Generalidades:
El SN se encuentra constituido por varios tipos de células, la mas
importante la NEURONA.
Es altamente excitable, recibe estimulo, 
conduce y produce una respuesta', 'texto', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 3, 3, 3, 3, 'CELULAS GLIALES
Mantienen el medio ambiente de 
las NEURONAS', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 4, 4, 4, 4, 'SISTEMA SOMATOSENSORIAL
Las estructuras que lo conforman tienen receptores específicos y
responden a estímulos determinados.', 'texto', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 5, 5, 5, 5, 'SISTEMA SOMATOVISCERAL
Se encarga de la relación con el mundo interior
• Cuenta con receptores diferentes
• Existe una doble regulación
SISTEMA NERVIOSO 
AUTONOMO', 'texto', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 6, 6, 6, 6, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 7, 7, 7, 7, 'MENINGES', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 8, 8, 8, 8, 'GANGLIOS
Constituyen una masa de 
sustancia nerviosa situada en 
el trayecto de un nervio.', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 9, 9, 9, 9, 'BIOELECTRICIDAD:
La estructura encargada de producirla y conducirla es la MEMBRANA
NEURONAL. -65 mV
PERMEABILIDAD SELECTIVA', 'texto', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 10, 10, 10, 10, 'SINAPSIS
“Es el sitio de interacción entre dos células especializadas para la
transmisión del impulso nervioso”.
Las sinapsis pueden dividirse funcionalmente en dos tipos:
• SINAPSIS ELECTRICAS=conexones', 'texto', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 11, 11, 11, 11, '• SINAPSIS QUIMICA=neurotransmisores', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso (resumen) > p. 11');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 1, 1, 1, 1, 'HEMISFERIOS CEREBRALES: 
Configuración interna. 
Ganglios de la base. 
Diencéfalo 
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 2, 2, 2, 2, 'SISTEMA NERVIOSO: 
Generalidades:
El SN se encuentra constituido por varios tipos de células, la mas
importante la NEURONA.
Es altamente excitable, recibe 
estimulo, conduce y produce 
una respuesta.
¿Dónde se pueden producir los 
estímulos?', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 3, 3, 3, 3, 'CELULAS GLIALES
Mantienen el medio ambiente de 
las NEURONAS', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 4, 4, 4, 4, 'SISTEMA SOMATOSENSORIAL
Las estructuras que lo conforman tienen receptores específicos y
responden a estímulos determinados.', 'texto', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 5, 5, 5, 5, 'SISTEMA SOMATOVISCERAL
Se encarga de la relación con el mundo interior
• Cuenta con receptores diferentes
• Existe una doble regulación
SISTEMA NERVIOSO 
AUTONOMO', 'texto', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 6, 6, 6, 6, 'En cada hemisferio existe:
•
Un lóbulo frontal
•
Un lóbulo parietal
•
Un lóbulo temporal
•
Un lóbulo occipital
•
Lóbulo de la Ínsula', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 7, 7, 7, 7, 'CONFIGURACION INTERNA DE LOS H.C: Los núcleos neuronales se
encuentran distribuidos de la siguiente manera:
• En la superficie de las circunvoluciones, constituyen la corteza
cerebral
• En masas de neuronas en la profundidad de los hemisferios,
constituyen una serie de núcleos: los ganglios de la base, el tálamo y
el hipotálamo.', 'texto', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 8, 8, 8, 8, 'La corteza y los núcleos constituyen la llamada sustancia gris, mientras que
la porción de tejido comprendido entre ambos se llama sustancia blanca.', 'texto', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 9, 9, 9, 9, 'VENTRICULOS:
A nivel de los hemisferios cerebrales se encuentran tres grandes
ventrículos:
• 2 ventrículos laterales
• 3° ventrículo', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 10, 10, 10, 10, 'En las paredes laterales del tercer ventrículo encontramos:
• El hipotálamo
• Los dos talamos', 'texto', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 11, 11, 11, 11, 'GANGLIOS DE LA BASE: conformados por
• Putamen
• El globo pálido
• El núcleo caudado
• La amígdala', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 11'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 12, 12, 12, 12, 'SUSTANCIA BLANCA:
• Esta conformada por los axones de la neuronas
• Se reúnen en grupos de fibras que comparten un origen o un destino
anatómico común
Estas fibras se dividen en tres tipos según las estructuras que conectan:
• Las fibras de asociación (fsm)
• Las fibras comisurales (ac)
• Las fibras de proyección', 'texto', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales - Configuración Interna (resumen) > p. 12');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='HEMISFERIOS_CEREBRALES'), 1, 1, 1, 1, 'HEMISFERIOS CEREBRALES
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='HEMISFERIOS_CEREBRALES'), 2, 2, 2, 2, 'GENERALIDADES
•
Los hemisferios cerebrales se 
encuentran contenidos dentro del 
NEUROCRANEO
•
Los huesos que lo recubren permiten 
crear una subdivisión, conocidos 
como LOBULOS CEREBRALES', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='HEMISFERIOS_CEREBRALES'), 3, 3, 3, 3, 'En cada hemisferio existe:
•
Un lóbulo frontal
•
Un lóbulo parietal
•
Un lóbulo temporal
•
Un lóbulo occipital
•
Lóbulo de la Ínsula', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='HEMISFERIOS_CEREBRALES'), 4, 4, 4, 4, 'CARAS DE LOS HEMISFERIOS CEREBRALES', 'texto', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='HEMISFERIOS_CEREBRALES'), 5, 5, 5, 5, 'CONFIGURACION EXTERNA DE LOS HEMISFERIOS CEREBRALES:
CARA LATERAL: presenta el
• Surco Central
• Cisura de Silvio', 'texto', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='HEMISFERIOS_CEREBRALES'), 6, 6, 6, 6, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='HEMISFERIOS_CEREBRALES'), 7, 7, 7, 7, 'Encontramos en la cara medial:
• El cuerpo calloso
• El surco pericalloso (circunvolucion del cuerpo calloso)
• El surco callosomarginal (circunvolucion frontal mesial)
• Surco parietooccipital
• Cisura Calcarina', 'texto', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='HEMISFERIOS_CEREBRALES'), 8, 8, 8, 8, 'CARA BASAL:
Presenta 3 circunvoluciones:
• Temporal inferior
• Temporooccipital
• Parahipocampal', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Hemisferios Cerebrales (resumen) > p. 8');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='TRONCO_DEL_ENCEFALO'), 1, 1, 1, 1, 'TRONCO DEL ENCEFALO:
mesencéfalo, protuberancia y 
bulbo
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Tronco del Encéfalo (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='TRONCO_DEL_ENCEFALO'), 2, 2, 2, 2, '• El tronco del encéfalo se encuentra ubicado en la fosa posterior del
cráneo, por delante del cerebelo.
• El mesencéfalo se continua anatómicamente con el diencéfalo, se
continua por debajo del tálamo.
• El bulbo se continua se continua con la medula espinal.', 'texto', 'nativo_pdf', 'COMPLETO', 'Tronco del Encéfalo (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='TRONCO_DEL_ENCEFALO'), 3, 3, 3, 3, 'El tronco del encéfalo brinda un lugar de paso para todas las fibras de
proyección aferentes y eferentes del encéfalo.
Es el lugar donde se regula el estado de conciencia, la vigilia y el sueño,
la función respiratoria.
Tienen origen los 12 pares de nervios craneales', 'texto', 'nativo_pdf', 'COMPLETO', 'Tronco del Encéfalo (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='TRONCO_DEL_ENCEFALO'), 4, 4, 4, 4, 'MESENCEFALO: se divide en 3 porciones
Los pies de los pedúnculos cerebrales
El tegmentum
tectum', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Tronco del Encéfalo (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='TRONCO_DEL_ENCEFALO'), 5, 5, 5, 5, 'LA PROTUBERANCIA:
Caracterizada por una porción anterior que da paso a la via
corticoespinal.
Contiene una importante cantidad de fibras que pasan hacia el
cerebelo.
Estas fibras provienen de las áreas motoras cerebrales e informan al
cerebelo sobre los movimientos que se están por realizar para su
coordinación.', 'texto', 'nativo_pdf', 'COMPLETO', 'Tronco del Encéfalo (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='TRONCO_DEL_ENCEFALO'), 6, 6, 6, 6, 'BULBO RAQUIDEO
Separado de la protuberancia por el surco bulbo protuberancial
A cada lado presenta las pirámides bulbares, contienen la vía
corticoespinal.
Por detrás se encuentra el surco preolivar, la oliva, el surco retrolivar y
los pedúnculos cerebelosos inferiores que unen el bulbo con el
cerebelo.', 'texto', 'nativo_pdf', 'COMPLETO', 'Tronco del Encéfalo (resumen) > p. 6');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='CEREBELO_Y_MEDULA_ESPINAL'), 1, 1, 1, 1, 'CEREBELO Y MEDULA 
ESPINAL
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Cerebelo y Médula Espinal (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='CEREBELO_Y_MEDULA_ESPINAL'), 2, 2, 2, 2, 'CEREBELO:
• El cerebelo es un órgano único ubicado en la línea media.
• Detrás del tronco del encéfalo, se comunica con el mismo a través de
los
pedúnculos
cerebelosos:
los
superiores
lo
conectan
al
mesencéfalo, los medios a la protuberancia y los inferiores al bulbo
raquídeo.
• Presenta dos hemisferios, con circunvoluciones llamadas FOLIAS
• El cerebelo contiene el 50 % de las neuronas del encéfalo
• Los dos hemisferios se fusionan en la línea media por medio de una
zona llamada VERMIS
• Los hemisferios del cerebelo presentan 3 caras: una anteroinferior,
una superior separada por el tentorio y una cara posteroinferior.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cerebelo y Médula Espinal (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='CEREBELO_Y_MEDULA_ESPINAL'), 3, 3, 3, 3, '• La sustancia blanca del cerebelo tiene la siguiente estructura de tres
pares
de
núcleos
grises:
EL
NUCLEO
DENTADO,
EL
NUCLEO
INTERPOSITO compuesto por los núcleos emboliforme y globoso y el
núcleo fastigio.
• La neurona mas importante del cerebelo se llama neurona de
PURKINJE.
• El cerebelo tiene la función de la coordinación de los movimientos del
cuerpo.
• Juega un papel en la regulación del tono muscular, el equilibrio y el
aprendizaje motor modificado por la experiencia.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cerebelo y Médula Espinal (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='CEREBELO_Y_MEDULA_ESPINAL'), 4, 4, 4, 4, 'MEDULA ESPINAL:
• Localizada en el canal vertebral, se continua por debajo del bulbo raquídeo.
• Se extiende hasta el borde inferior de la vertebra L1.
• La medula tiene forma cilíndrica heterogénea.
• Presenta ensanchamientos (visibles a nivel cervical y lumbar, se relacionan
con los plexos nerviosos que inervan los miembros superiores e inferiores)
y a nivel terminal un estrechamiento conocido como cono medular.
• En la medula se describen tres caras: una anterior donde se halla el surco
anterior, y dos surcos anterolaterales simétricos y uno posterior.
• A nivel de los surcos antero y posterolaterales se originan raíces anteriores
y posteriores.
• Las anteriores son motoras y las posteriores sensitivas.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cerebelo y Médula Espinal (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='CEREBELO_Y_MEDULA_ESPINAL'), 5, 5, 5, 5, '• La medula tiene una organización segmentaria y se divide en
unidades funcionales llamadas MIELOMERAS.
• La medula esta formada por sustancia gris y sustancia blanca.', 'texto', 'nativo_pdf', 'COMPLETO', 'Cerebelo y Médula Espinal (resumen) > p. 5');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='VASCULARIZACION_DEL_SISTEMA_NERVIOSO_CENTRAL'), 1, 1, 1, 1, 'VASCULARIZACION DEL 
SISTEMA NERVIOSO CENTRAL
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Vascularización del Sistema Nervioso Central (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='VASCULARIZACION_DEL_SISTEMA_NERVIOSO_CENTRAL'), 2, 2, 2, 2, 'CIRCUITO ARTERIAL DEL CEREBRO: (Polígono de Willis)', 'texto', 'nativo_pdf', 'COMPLETO', 'Vascularización del Sistema Nervioso Central (resumen) > p. 2');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO_AUTONOMO'), 1, 1, 1, 1, 'SISTEMA NERVIOSO 
AUTONOMO
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso Autónomo (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO_AUTONOMO'), 2, 2, 2, 2, 'DIVISION Y FUNCION GENERAL:
• Es la parte del sistema nervioso que controla funciones viscerales del
organismo.
• Su función es la de mantener un equilibrio en respuesta tanto a las
alteraciones del medio interno como a los estímulos exteriores.
• Se divide en simpático, parasimpático y entérico.', 'texto', 'nativo_pdf', 'COMPLETO', 'Sistema Nervioso Autónomo (resumen) > p. 2');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 1, 1, 1, 1, 'ANATOMÍA Y FISIOLOGÍA DEL SISTEMA NERVIOSO

Funciones del SN

- Da las respuestas involuntarias
- Da las conductas voluntarias

SN deriva del:
- Ectodermo

Se distinguen 2 tipos de células en el SN:

- Neuronas
- Células gliales o neuroglia', 'posible_lamina', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ANATOMÍA Y FISIOLOGÍA DEL SISTEMA NERVIOSO'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 2, 2, 2, 2, 'NEURONA

Unidad morfológica
Unidad trófica
Unidad funcional:    - excitabilidad ( se excita ante agentes físicos y químicos)
                                       - conductibilidad ( transmite la excitación )

Partes de la neurona:
El cuerpo neuronal que tiene núcleo y citoplasma con los diferentes orgánulos. Incluidos los cuerpos de  Nissl que son cúmulos del REG donde se hace síntesis de proteínas.
Dendritas, que tienen citoesqueleto y cuerpos de Nissl.
Axón, no tiene cuerpos de Nissl, está envuelto por mielina y transmite el impulso nervioso.

     

Tipos de neuronas:

- Neurona bipolar ( se encuentra en vías olfativas visuales, auditivas y vestibulares)
- Neurona Multipolar ( se encuentran en las vías motoras y sensitivas)
- Neurona Unipolar ( típica de los ganglios espinales)', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > NEURONA'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 3, 3, 3, 3, 'MIELINA

Envuelve a los axones, está producida por:
Oligodendrocitos producen la mielina del SNC
Las células Schwamn producen la mielina del SNP.

Funciones de la mielina:

- Permite mejorar la conducción del impulso
- Mantiene la vida del axón', 'posible_lamina', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > MIELINA'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 4, 4, 4, 4, 'SUSTANCIA GRIS

Se encuentra en los cuerpos neuronales y las dendritas.', 'posible_lamina', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > SUSTANCIA GRIS'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 5, 5, 5, 5, 'SUSTANCIA BLANCA

Son células de sostenimiento. Hay tres tipos de células gliales:
Astrositos
Oligodendrocitos
Células de la microglia
Células ependimarias

Astrositos
- Mantienen la estructura del SNC
- Función reparadora del SNC
-  Regulación de la composición del líquido intersticial. Los pies terminales de los astrositos envuelven los capilares y ayudan a limitar el paso de determinadas sustancias.

Oligodendrocitos
- Productores de la mielina del SNC
- Cada Célula puede envolver axones de diferentes neuronas a la vez

Microglia
- Son macrófagos especializados', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > SUSTANCIA BLANCA'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 6, 6, 6, 6, 'POTENCIAL DE REPOSO Y DE ACCIÓN

Situación de reposo: en esta situación de reposo la membrana de la neurona está polarizada de forma que es 90 milivoltios más negativa en el interior que en el exterior. El potencial de reposo es de –90mv debido a la concentración de sodio y potasio.
Despolarización: se abren los canales de sodio y el sodio entra en el interior de la célula.
Repolarización: los canales de sodio se cierran, se abren los canales de potasio y el potasio sale de la célula para reponer la negatividad.
Bomba sodio/potasio: expulsa tres sodios por cada dos potasios.
Recuperación del potencial de reposo', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > POTENCIAL DE REPOSO Y DE ACCIÓN'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 7, 7, 7, 7, 'NIVEL DE DESPOLARIZACIÓN

Es el nivel de elevación del potencial de membrana necesario para el inicio del PA.

Cafeína,  teofilina, teobromuro disminuyen el nivel de despolarización y por tanto aumentan la excitabilidad de la neurona.
Anestésicos aumentan el nivel de despolarización y por tanto disminuyen la excitabilidad neuronal.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > NIVEL DE DESPOLARIZACIÓN'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 8, 8, 8, 8, 'PROPAGACIÓN DEL IMPULSO NERVIOSO

El potencial de acción (PA) de una neurona se transmite a las otras provocando un cambio de paso iónico.
El PA se propagará por toda la membrana de la célula si está en condiciones normales. Si hay alguna dificultad no se propagará. Es la ley del todo o nada.

* Los anestésicos cierran los canales de sodio y se bloquea el PA.

El flujo iónico solo se produce en los nodos de Ranvier de las fibras mielinizadas. Esto es la conducción saltatoria.
La conducción saltatoria de las fibras mielinizadas:
- aumentan la velocidad de conducción de los impulsos nerviosos de 5 a 50 veces.
- ahorro de energía

La velocidad de la conducción de la fibra mielínica es de 100m/seg
La velocidad de conducción de la fibra amielínica es de 0,5m/seg', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > PROPAGACIÓN DEL IMPULSO NERVIOSO'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 9, 9, 9, 9, 'SINAPSIS

Química
Eléctrica

Sinápsis química
En la membrana presináptica hay neurotransmisores que se almacenan en vesículas y cuando llega un PA los neurotransmisores son liberados al espacio sináptico por exocitosis de las vesículas. En este mecanismo interviene el calcio.
Los neurotransmisores del espacio sináptico que se encuentran en la membrana postsináptica.

Neurotransmisores más frecuentes:
- Acetilcolina
- Noradrenalina
- Dopamina
- Serotonina
- Histamina
-GABA
- Glutamato
- Aspartato


Sinápsis eléctrica
Existen conexiones tubulares que transmiten el impulso de una neurona a la otra.

Agonistas: fármacos que imitan la acción del neurotransmisor (NT)
Antagonistas: fármacos que se oponen a la acción del neurotransmisor

Ejemplos:
Atropina antagonista de la acetilcolina
Curare antagonista de la acetilcolina
Salbutamol agonista de receptores beta 2 adrenérgicos.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > SINAPSIS'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 10, 10, 10, 10, 'SISTEMA NERVIOSO

SN esta formado por: SNC, SNA

SNC está formado por :
Encéfalo: - cerebro
                        - tronco cerebral
                        - cerebelo 

Médula espinal

CEREBRO: Está separado del resto del encéfalo por la Tienda del cerebelo o Tentorio', 'posible_lamina', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > SISTEMA NERVIOSO'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 11, 11, 11, 11, 'HEMISFERIOS CEREBRALES

Hay 2 hemisferios; uno derecho y otro izquierdo que están separados por la hendidura interhemisférica.
Los hemisferios cerebrales están recubiertos por corteza cerebral y sustancia gris.
La corteza cerebral tiene circunvalaciones y surcos que aumentan la superficie cortical.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > HEMISFERIOS CEREBRALES'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 12, 12, 12, 12, 'CORTEZA CEREBRAL

- Se elaboran movimientos voluntarios
- Se hacen conscientes las sensaciones
- Se almacena información
- Se elaboran las funciones psíquicas

CISURAS ( son surcos más profundos)

- Cisura Rolando: está en dirección cráneo-caudal
- Cisura Silvio o lateral: está en dirección dorsal y paralela

Estas cisuras separan 4 lóbulos cerebrales:

Lóbulo frontal: está delante de la cisura de Rolando y de Silvio
Lóbulo parietal: está detrás de la cisura de Rolando y sobre la de Silvio
Lóbulo temporal: está debajo de la cisura de Silvio
Lóbulo occipital: ocupan los polos posteriores cerebrales.

*En la cara medial de los hemisferios hay el cuerpo calloso que conecta los dos hemisferios.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > CORTEZA CEREBRAL'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 13, 13, 13, 13, 'ÁREA DE LA SENSIBILIDAD SOMÁTICA

- Área situada detrás de la cisura de Rolando
- Le llega la sensibilidad del hemicuerpo contralateral
-Zona extensa para la mano, labios, faringe y lengua.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ÁREA DE LA SENSIBILIDAD SOMÁTICA'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 14, 14, 14, 14, 'ÁREA AUDITIVA

- Está en la primera circunvalación temporal', 'posible_lamina', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ÁREA AUDITIVA'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 15, 15, 15, 15, 'ÁREA VISUAL

- Ocupa los polos posteriores del lóbulo occipital
- Cada región occipital recibe los impulsos visuales del campo visual contralateral', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ÁREA VISUAL'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 16, 16, 16, 16, 'ÁREA MOTORA

- Situada en la circunvalación precentral en el lóbulo frontal.
-Se originan las ordenes del movimiento de los músculos voluntarios del hemicuerpo contralateral
- Las fibras que se originan forman la vía piramidal', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ÁREA MOTORA'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 17, 17, 17, 17, 'ÁREA PREMOTORA

- Está por delante de el área motora
- Está área programa los movimientos
- Tiene muchas conexiones con los núcleos estriados y el tálamo que actuaran como centros de control', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ÁREA PREMOTORA'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 18, 18, 18, 18, 'ÁREA OCULOCEFALOGIRIA

- Está en el lóbulo frontal contralateral
- Se dan los movimientos voluntarios de los ojos y la cabeza

ÁREA PARA EL CÁLCULO, EL RECONOCIMIENTO DEL ESQUEMA CORPORAL, RECONOCIMIENTO DEL TACTO Y LECTURA

- Región situada al final de la cisura de Silvio', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ÁREA OCULOCEFALOGIRIA'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 19, 19, 19, 19, 'ÁREA DEL LENGUAJE

- Está casi siempre en el hemisferio izquierdo
- Repartida en varias zonas:
Área Broca ( a nivel frontal)
Área Wernicke ( a nivel temporal y delante del occipital)

- Si falla el mecanismo se puede provocar:

Afasia: fallo de los mecanismos de comprensión o expresión del lenguaje
Disartria: error en el mecanismo motor de los órganos del habla', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ÁREA DEL LENGUAJE'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 20, 20, 20, 20, 'SISTEMA LÍMBICO

- Región que controla las emociones, motivaciones, comportamiento afectivo
- Está envolviendo al cuerpo calloso, a la zona del lóbulo frontal, parietal y temporal', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > SISTEMA LÍMBICO'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 21, 21, 21, 21, 'ÁREA DE LA MEMORIA

- No hay una zona determinada
- Se le ha dado mucha importancia al hipocampo', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ÁREA DE LA MEMORIA'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 22, 22, 22, 22, 'DOMINANCIA HEMISFÉRICA

Hemisferio izquierdo: se encarga del lenguaje y del habla manual
Hemisferio derecho: reconoce las formas espaciales y el propio cuerpo', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > DOMINANCIA HEMISFÉRICA'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 23, 23, 23, 23, 'GANGLIOS DE LA BASE

El conjunto de ganglios de la base lo forman el tálamo y los núcleos estriados.

Tálamo
- Agrupación de núcleos
- Está al lado del III ventrículo
- Llega información sensitiva
- Participa en el control motor
- Mantiene la alerta

Núcleos estriados

- Formados por el núcleo caudado, putámen y pálido
- Hacen control motor', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > GANGLIOS DE LA BASE'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 24, 24, 24, 24, 'HIPOTÁLAMO

- Región formada por sustancia gris
- Está al lado del III ventrículo por delante del tálamo
- Es el principal centro vegetativo', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > HIPOTÁLAMO'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 25, 25, 25, 25, 'TRONCO CEREBRAL

El tronco cerebral está formado por:
Mesencéfalo             
Protuberancia                       
Bulbo

Mesencéfalo
- Sustancia negra, donde se produce la dopamina necesaria en el control del movimiento
- Esta zona funciona en coordinación con los ganglios de la base
- Núcleo del MOC (III par craneal)
- Centros responsables del estado de conciencia y el ritmo de vigilia

Protuberancia
- Núcleo del MOE (VI par craneal) y del MOC
- Es la salida de los núcleos facial y trigémino               

Bulbo
- Zona donde se cruza la vía piramidal
- Centro respiratorio
- Salida de los nervios hipogloso y vago
- Centros vestibulares del equilibrio', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > TRONCO CEREBRAL'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 26, 26, 26, 26, 'CEREBELO

- Formado por la corteza cerebelosa, sustancia blanca y núcleos grises
- Presenta 2 hemisferios cerebelosos ( derecho e izquierdo) y una zona central (vermis)
- Es un centro coordinador de movimientos

Lesiones del cerebelo:
Disimetría: Errores en la distancia de los movimientos         
Ataxia: Movimientos no coordinados                                           
Hipotonía: Disminución del tono', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > CEREBELO'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 27, 27, 27, 27, 'MÉDULA ESPINAL

-La parte superior acaba en el bulbo
- Por la parte inferior forma el cono medular y acaba en la cola de caballo
- Metámera: es cada segmento de la médula espinal
- Dermatoma: Región cutánea correspondiente a una metámera

- La médula está formada por dos mitades: la derecha y la izquierda.
- Las raíces sensitivas entran a nivel postero-lateral
- Las raíces motoras salen a nivel antero-lateral
- En la médula espinal hay dos astas posteriores y dos anteriores. Tienen cuerpos neuronales.
- La sustancia blanca tiene tres cordones: cordón anterior, cordón posterior, cordón lateral.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > MÉDULA ESPINAL'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 28, 28, 28, 28, 'VÍAS SENSITIVAS

Sensibilidad superficial o exteroceptiva ( incluye tacto, temperatura y dolor)
Sensibilidad profunda o propioceptiva ( informa sobre la posición articular, el grado de estiramiento del tendón y el grado de contracción muscular)

A) Vía espinotalámica ( la siguen las fibras exteroceptivas)

1ª neurona: está en el ganglio raquídeo de la médula espinal
                                               
  
                    2ª neurona: está en el asta posterior 

                                   3ª neurona: tálamo

B) Vía cordón posterior ( la siguen las fibras propioceptivas)

                 1ª neurona: ganglio raquídeo de la médula espinal

                                    Fascículos de Coll y Burdach

                                       2ª neurona: está en el bulbo

                              3ª neurona: se decusa hacia el tálamo contralateral', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > VÍAS SENSITIVAS'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 29, 29, 29, 29, 'VÍAS MOTORAS

Vía piramidal, directa o corticoespinal

                            1ª neurona: circunvolución precentral

                                    Va a la cápsula interna

                             Pasa por el Mesencéfalo y protuberancia

                               En el bulbo el haz piramidal se decusa

                                   
                                      Va a los cordones laterales
 

                                   2ª neurona: está en el asta anterior

                                     Forma la raíz anterior motora

Vía motora indirecta

Son fascículos que ascienden y descienden por los cordones laterales y anteriores

Alteraciones de la sensibilidad

Agnosias: falta de reconocimiento de un objeto por el tacto

Hipoalgesias: descenso de la sensibilidad del dolor

Analgésia: ausencia de sensibilidad de dolor

Hipoestesia: perdida parcial de la sensibilidad

Anestesia: perdida total de la sensibilidad

Parestesia: “hormigueos”

Alteraciones de la motilidad

Paresia: debilidad del movimiento

Plégia: no hay movimiento

Hemiparesia o hemiplejia: afectación de la mitad del cuerpo derecho o izquierdo

Paraplejia: afectación de las dos extremidades inferiores

Monoplejia: afectación de una sola extremidad', 'posible_lamina', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > VÍAS MOTORAS'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 30, 30, 30, 30, 'SISTEMA NERVIOSO AUTÓNOMO

- Es un sistema relacionado con la regulación y control de la homeostasis
- Son funciones involuntarias y funcionan con relativa independencia del SNC
- Neuronas del SNA:
La primera neurona o neurona preganglionar ( está en la médula o núcleos del tronco)
La segunda neurona o neurona postganglionar ( está en los ganglios o en los órganos diana)

 SNA  se puede dividir en dos partes:

SN Simpático
SN parasimpático

Sistema Simpático

Sus neuronas preganglionares están en la sustancia gris medular y bajan des de la región cervical asta la región lumbar alta.
Las respuestas simpáticas de la cabeza y del cuello salen de la región cervical, la de las piernas de la región lumbar. El resto lo hace desde la porción torácica.
Las fibras preganglionares salen de la médula por la raíz anterior y llegan a los ganglios paravertebrales. Aquí hacen sinápsis con la neurona postganglionar que a través de diferentes nervios, inervan el órgano determinado.
* Se acostumbra a interpretar que el sistema simpático tiene funciones catabólicas y que preparan al individuo para la acción. Suponiendo un desgaste más grande de energía. 

Sistema parasimpático

Sus neuronas pregangluionares están en la médula sacra y en el tronco cerebral. Sus fibras saldrán sobretodo por el nervio vago que inervará el corazón, los pulmones, parte del tubo digestivo y de las vías urinarias.
Las fibras del ojo irán a parar al III par craneal. 

* El sistema parasimpático disminuye la actividad del organismo y restablece las reservas energéticas ( frena al corazón, produce jugos digestivos...)', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > SISTEMA NERVIOSO AUTÓNOMO'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 31, 31, 31, 31, 'REFLEJOS

Los reflejos se pueden definir como respuestas involuntarias ( motoras o no) a estímulos sensitivos.

Por ejemplo tenemos:
Reflejos vegetativos: un cambio de frío o calor sobre la piel producirá un aumento o descenso del tono vascular.
Reflejos de defensa: la irritación o inflamación del peritoneo provocan una contracción mantenida de los músculos de la pared abdominal. Cuando notamos dolor apartamos la mano de la fuente de dolor sin darnos cuenta.
Reflejos profundos: En este apartado se incluyen los reflejos miotáticos y de tensión.
* Un reflejo elemental o simple está formado por dos neuronas: una neurona sensitiva que recoge el estímulo y lo transporta asta la médula. La segunda es una neurona motora que recibe el impulso y envía una respuesta por la raíz anterior. Este circuito forma un arco reflejo.

Reflejo miotático o de estiramiento muscular

En el interior de los músculos existe una zona llamada Huso muscular donde hay unos receptores que informan de:
la longitud del músculo
de los cambios de esta longitud

      Si el músculo de estira. Se estira el huso y se estimulan los receptores. Esta información llega a la médula por la raíz posterior, entra en el asta posterior y llega hasta el asta anterior donde conecta con una neurona motora. La fibra motora saldrá por la raíz anterior e irá a inervar este músculo para que se contraiga. La función resultante es provocar una resistencia al estiramiento y amortizar el movimiento.
Este arco reflejo funciona continuamente manteniendo un cierto grado de contracción muscular o tono muscular. Si este es excesivo o insuficiente se llamará hipertonía o hipotonía respectivamente.
De la misma manera que unas fibras llegan a ala médula otras fibras que provienen del huso muscular ascenderán para informar al cerebelo y a la corteza cerebral. Des de estas estructuras se enviaran ordenes a la médula para regular el movimiento.

Reflejo de tensión

Se debe a la presencia de receptores ( Órganos de Golgi) en los tendones musculares de inserción. Detectan los aumentos o disminuciones de la tensión del músculo. Si la tensión del músculo aumenta se enviarán a la médula impulsos que inhibirán las neuronas motoras para que el músculo no se contraiga más.
Se considera que este reflejo pretende evitar un exceso de tensión que pudiera desgarrar el músculo o arrancar el tendón.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > REFLEJOS'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 32, 32, 32, 32, 'MENINGES

El SNC ( encéfalo y médula espinal) está envuelto por tres capas llamadas meninges. Son de tejido conjuntivo y tienen algunas células epiteliales.

Distinguimos tres meninges:
Duramadre: es la capa más externa y la más fuerte. Está adherida al hueso. Presenta unas proyecciones, en forma de repliegues hacia la profundidad que separan zonas del SNC. Dos de estas proyecciones son:
                            Hoz del cerebro: se encuentra en la hendidura interhemisférica                           
                            separando ambos hemisferios. 
                           Tentorio o tienda del cerebelo: se encuentra en un plano                                                                                          horizontal, perpendicular a la hoz. Separa el cerebro de las estructuras de las fosa  posterior ( tronco cerebral y cerebelo). Lo que hay por encima se llama supratentorial y por debajo se llama infratentorial.

Aracnoide: está por encima de la duramadre. Emite hacia adentro unas trabéculas fibrosas y así deja un espacio por debajo. Este espacio es el espacio subaracnoidal, que está relleno de un líquido céfalo-raquídeo (LCR). Por este espacio también pasan las arterias y venas que entran o salen del SNC.
Piamadre: es una fina y delicada capa que recubre el SNC, está adherida a él          ( incluso en el interior de surcos y cisuras)

Espacio epidural: espacio situado entre el hueso y la duramadre.
Espacio subdural: espacio situado entre la duramadre y la aracnoides.
Espacio subaracnoidal: espacio que se sitúa por debajo de la aracnoides.

*Meningitis: es una infección o inflamación del LCR, que se encuentra en el espacio subaracnoidal.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > MENINGES'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 33, 33, 33, 33, 'SISTEMA VENTRICULAR

En el interior del SNC hay unos espacios o cavidades comunicadas entre si donde circula el líquido cefalo-raquídeo ( LCR) y se produce o fabrica.
Los  ventrículos laterales se comunican a través del agujero de Monro, con III ventrículo. Por detrás del tercer ventrículo sale un conducto que es el acueducto de Silvio el cual baja por el interior del tronco cerebral asta el IV ventrículo, situado entre el bulbo y la protuberancia. El IV ventrículo continua hacia abajo por el epéndima            ( canal que está en el interior de la médula).
A nivel del dorso del IV ventrículo existen unos orificios para la salida del LCR del sistema ventricular en el espacio subaracnoidal.
El LCR que se encuentra en el interior del sistema ventricular y del espacio subaracnoidal se produce básicamente en los ventrículos laterales. Aquí hay una red de capilares por donde se filtra y produce el LCR.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > SISTEMA VENTRICULAR'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 34, 34, 34, 34, 'LIQUIDO CEFALO-RAQUIDEO

LCR está bañando al SNC para protegerlo de golpes. Este líquido se reabsorbe hacia la sangre a través de válvulas que hay en el interior de los senos venosos del SNC.
LCR se renueva totalmente cada 6 horas y se encuentra a una presión de 7 a 18 cm/agua
Este líquido se puede obtener por una punción lumbar, esta punción se realiza hasta el espacio subaracnoidal.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > LIQUIDO CEFALO-RAQUIDEO'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 35, 35, 35, 35, 'ARTERIAS Y VENAS DEL SNC

Al encéfalo llegan 4 arterias:
2 arterias carótidas internas: que irrigan los 2/3 anteriores de cada hemisferio (lóbulo frontal, parietal y parte del temporal). La carótida interna al entrar al cráneo se dividirás en dos ramas:
arteria cerebral anterior ( va al lóbulo frontal)
arteria cerebral mediana (va hacia la cisura silviana, lóbulo frontal, parietal y temporal)
2 arterias vertebrales: que irrigan el resto del cerebro ( parte del lóbulo                                                                              temporal y los lóbulos occipitales, el tronco cerebral y el cerebelo). La arterias vertebrales al entrar en el cráneo se unen formando la arteria basilar que asciende y de la cual saldrán las ramas del tronco y del cerebelo. Al llegar al cerebro se dividen en dos ramas, una arteria cerebral posterior por cada lado.
Justo por debajo del cerebro, estas arterias de los dos sistemas se interconectan por arterias comunicantes y anastomosis formando un anillo llamado polígono de Willis.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ARTERIAS Y VENAS DEL SNC'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 36, 36, 36, 36, 'VENAS Y SENOS VENOSOS

La sangre venosa es recogida por venas que drenan a los llamados senos venosos que son canales en el interior de la duramadre, que al final drenan a la vena yugular que llevará la sangre al corazón.

Los principales senos venosos son:

Senos longitudinales superior e inferior: van a parar a los bordes superiores e inferiores de la hoz del cerebro.
Seno transverso: va por el borde posterior del tentorio
Senos sigmoides: van des del transverso hasta la vena yugular.
Senos cavernosos: situados detrás de las orbitas, al lado de la silla turca.', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > VENAS Y SENOS VENOSOS'),
  ((select id from tmp_doc_map where dirname='ANATOMIA_FISIOLOGIA_SN'), 37, 37, 37, 37, '¿ ME LO SE? ¿ O NO ME LO SE?   ESA ES LA CUESTIÓN

(Espero que estos apuntes os ayuden a estudiar el sistema nervioso)', 'texto', 'doc_word_textutil', 'COMPLETO', 'Anatomía y Fisiología del Sistema Nervioso (resumen) > ¿ ME LO SE? ¿ O NO ME LO SE?   ESA ES LA CUESTIÓN');


-- Figuras (revisadas: solo las marcadas 'keep' en el manifiesto)

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 'F00001', 3, 44, '67,43,914,631', 0.9, 'doc' || (select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO') || '/pdf0003_fig01_xref44.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO'), 'F00002', 7, 71, '43,103,518,443', 0.9, 'doc' || (select id from tmp_doc_map where dirname='SISTEMA_NERVIOSO') || '/pdf0007_fig01_xref71.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 'F00001', 3, 66, '67,43,914,631', 0.9, 'doc' || (select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna') || '/pdf0003_fig01_xref66.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 'F00002', 11, 240, '50,241,1045,791', 0.9, 'doc' || (select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna') || '/pdf0011_fig01_xref240.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 'F00004', 11, 240, '0,800,1080,1107', 0.9, 'doc' || (select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna') || '/pdf0011_fig03_xref240.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna'), 'F00006', 12, 271, '0,15,456,279', 0.9, 'doc' || (select id from tmp_doc_map where dirname='hemisferios_cerebrales__configuracion_interna') || '/pdf0012_fig01_xref271.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='TRONCO_DEL_ENCEFALO'), 'F00001', 1, 20, '15,19,265,164', 0.9, 'doc' || (select id from tmp_doc_map where dirname='TRONCO_DEL_ENCEFALO') || '/pdf0001_fig01_xref20.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='TRONCO_DEL_ENCEFALO'), 'F00002', 2, 30, '38,19,706,552', 0.9, 'doc' || (select id from tmp_doc_map where dirname='TRONCO_DEL_ENCEFALO') || '/pdf0002_fig01_xref30.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='CEREBELO_Y_MEDULA_ESPINAL'), 'F00001', 1, 15, '44,0,193,123', 0.9, 'doc' || (select id from tmp_doc_map where dirname='CEREBELO_Y_MEDULA_ESPINAL') || '/pdf0001_fig01_xref15.jpg', 'active');


-- Vínculos figura <-> fragmento por página

insert into public.knowledge_fragment_figures (fragment_id, figure_id, relation_type, weight)
select f.id, g.id, 'same_page', 1.0
from public.knowledge_figures g
join public.knowledge_fragments f on f.document_id = g.document_id and f.page_start = g.pdf_page
where g.document_id in (select id from tmp_doc_map)
on conflict (fragment_id, figure_id) do nothing;
