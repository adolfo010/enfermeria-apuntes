-- Carga de resúmenes de genitales (Eje 4) y fisiología ovárica/eje
-- hipotálamo-hipofisogonadal masculino, desde carpeta Drive 'Estructura
-- y Función Humana II'. Texto nativo, sin OCR. Figuras capturadas a mano
-- (página completa) porque el detector automático no separa bien los
-- diagramas compuestos por muchas imágenes superpuestas típicos de estas
-- diapositivas -- se revisaron visualmente todas las páginas antes de elegir.

create temp table tmp_doc_map (dirname text, id bigint) on commit drop;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1oZe1ALsGNbn6KKT4FeLTeGnW7Z7TbHsb', 'FISIOLOGIA EJE HIPOTALAMO-HIPOFISOGONADAL MASCULINO.pdf', 'Fisiología Eje Hipotálamo-Hipofisogonadal Masculino (resumen)', 'resumen', 'Anatomia', 8, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1dytBFyOxpsTKbjDPfJM-Qupb2EofDRik', 'FISIOLOGIA OVARICA.pdf', 'Fisiología Ovárica (resumen)', 'resumen', 'Anatomia', 7, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'FISIOLOGIA_OVARICA', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1lV0o9LBcUx-KrH_TvPSPYAGULrbnmHzJ', 'GENITALES EXTERNOS.pdf', 'Genitales Externos (resumen)', 'resumen', 'Anatomia', 11, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'GENITALES_EXTERNOS', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1mpPRYfFBT3OmtCSqYGeFo7rO-WyNe9T7', 'GENITALES INTERNOS FEMENINOS.pdf', 'Genitales Internos Femeninos (resumen)', 'resumen', 'Anatomia', 11, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'GENITALES_INTERNOS_FEMENINOS', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1uAiNmh1UOlSfA4itemjnKyzE_ou46NE3', 'GENITALES INTERNOS MASCULINOS.pdf', 'Genitales Internos Masculinos (resumen)', 'resumen', 'Anatomia', 6, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'GENITALES_INTERNOS_MASCULINOS', id from ins;

with ins as (
  insert into public.knowledge_documents
    (drive_file_id, file_name, title, source_type, subject_area, page_count, processing_status, metadata)
  values
    ('1JHcyrgeRdyyKb4qkfDseZQ3r6eQg4MAM', 'MAMAS.pdf', 'Mamas (resumen)', 'resumen', 'Anatomia', 10, 'completed', '{}'::jsonb)
  returning id
)
insert into tmp_doc_map (dirname, id) select 'MAMAS', id from ins;


-- Fragmentos (una fila por página, texto nativo)

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO'), 1, 1, 1, 1, 'FISIOLOGIA EJE HIPOTALAMO-HIPOFISOGONADAL 
MASCULINO
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Fisiología Eje Hipotálamo-Hipofisogonadal Masculino (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO'), 2, 2, 2, 2, 'GENERALIDADES:
La actividad testicular depende del funcionamiento correcto del 
EJE HIPOTALAMO-HIPOFISO-GONADAL.', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Fisiología Eje Hipotálamo-Hipofisogonadal Masculino (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO'), 3, 3, 3, 3, 'TAXONOMIA HORMONAL
• GnRH= gonadatrofinas
• FSH= folículo estimulante
• LH= luteinizante
• To= testosterona
• DHT= dihidrotestorena', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Fisiología Eje Hipotálamo-Hipofisogonadal Masculino (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO'), 4, 4, 4, 4, 'GnRH
FSH
LH
TETOSTERONA
ESTRADIOL
e-INHIBINA-B 
EJE HIPOTALAMO-HIPOFISO-GONADAL', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Fisiología Eje Hipotálamo-Hipofisogonadal Masculino (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO'), 5, 5, 5, 5, '• El hipotálamo secreta en forma pulsátil la hormona liberadora de
gonadatrofinas, que a través del sistema venoso-porta-hipofisario,
estimulara la glándula hipófisis para la liberación de la hormona
foliculoestimulante y luteinizante.
• Ambas hormonas tienen una acción directa sobre la gónada
masculina.
• La folículo estimulante actúa sobre la célula de Sertoli.
• La luteinizante estimula a la célula de Leydig para la producción de
testosterona.
• Esta hormona es transformada periféricamente es estradiol que
ejercerá un efecto inhibitorio en la liberación de gonadotrofinas y
luteinizante (retroalimentación negativa) mientras que la e inhibina-B
tendrá una acción negativa sobre la secreción de foliculoestimulante.', 'texto', 'nativo_pdf', 'COMPLETO', 'Fisiología Eje Hipotálamo-Hipofisogonadal Masculino (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO'), 6, 6, 6, 6, '• La testosterona es el principal andrógeno circulante en el hombre, se
sintetiza a partir de colesterol.
• Durante las primeras semanas de vida intrauterina la testo favorecerá
el desarrollo de los conductos de Wolf para formar el epidídimo, los
conductos deferentes y las vesículas seminales.
• La Dihidrotestorena (DHT) estimulara la diferenciación masculina de
los genitales externos, la uretra y la próstata.', 'texto', 'nativo_pdf', 'COMPLETO', 'Fisiología Eje Hipotálamo-Hipofisogonadal Masculino (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO'), 7, 7, 7, 7, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Fisiología Eje Hipotálamo-Hipofisogonadal Masculino (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO'), 8, 8, 8, 8, 'La pubertad se inicia por aumento de la GnRH con el incremento de la
To.', 'texto', 'nativo_pdf', 'COMPLETO', 'Fisiología Eje Hipotálamo-Hipofisogonadal Masculino (resumen) > p. 8');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA'), 1, 1, 1, 1, 'FISIOLOGIA OVARICA
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Fisiología Ovárica (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA'), 2, 2, 2, 2, 'La estructura histológica de los ovarios se compone de una corteza, en
la que se ubican los folículos, un hilio, por donde ingresan los vasos
sanguíneos y la medula subcortical.
El ovario tiene dos funciones:
• Gametogenesis: ovocito primario se transforma en ovulo fecundable.
• Producción hormonal: a cargo del folículo, regulada por el eje
hipotálamo-hipofiso-gonadal.', 'texto', 'nativo_pdf', 'COMPLETO', 'Fisiología Ovárica (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA'), 3, 3, 3, 3, 'GAMETOGENESIS:
• El ovario contienen miles de folículos primordiales, compuestos por el
ovocito y una capa de células de la granulosa.
• Muchos folículos son seleccionados todos los meses, pero solo uno va
a madurar lo suficiente.
• El folículo primordial se transforma en folículo primario cuando las
células de la granulosa maduran. Estas células se multiplican
formando muchas hileras y por fuera de la membrana basal aparecen
las células de la teca. Así se forma el folículo secundario.
• Aumentado de tamaño el folículo secundario, aparece liquido entre
las células de la granulosa, lo que se denomina antro, para luego
tomar el nombre de folículo antral.
• Cuando el ovulo esta listo para ser fecundado se llama folículo de
Graaf', 'texto', 'nativo_pdf', 'COMPLETO', 'Fisiología Ovárica (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA'), 4, 4, 4, 4, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Fisiología Ovárica (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA'), 5, 5, 5, 5, 'PRODUCCION HORMONAL Y EJE HIPOTALAMO-HIPOFISO-OVARICO.
CICLO MENSTRUAL: es la serie de cambios cíclicos mensuales que
ocurren simultáneamente en los ovarios, el endometrio, el moco
cervical y los niveles hormonales.
• El hipotálamo produce GnRH, que estimula la hipófisis para producir
FSH y LH.
• La GnRH estimula el crecimiento folicular e induce a las células de la
granulosa a producir estrógenos (Es). Esta fase se denomina fase
folicular.
• Llegando a la mitad del ciclo, los altos niveles de (Es) producen un
incremento en la secreción de (LH), esto induce a la ovulación.
• A partir de la ovulación, la producción hormonal esta a cargo del
cuerpo lúteo, se denomina fase lútea.', 'texto', 'nativo_pdf', 'COMPLETO', 'Fisiología Ovárica (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA'), 6, 6, 6, 6, '• Durante la fase folicular, las glándulas endometriales crecen y
aumentan y la mucosa se hace mas gruesa.
• Durante las fase lútea, las glándulas se transforman en secretoras, se
incrementa su vascularización y aparece el edema del estroma.
• Cuando el estrógeno y la progesterona descienden, se produce
necrosis del endometrio y de los vasos sanguíneos, dando lugar a la
menstruación.', 'texto', 'nativo_pdf', 'COMPLETO', 'Fisiología Ovárica (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA'), 7, 7, 7, 7, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Fisiología Ovárica (resumen) > p. 7');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 1, 1, 1, 1, 'GENITALES EXTERNOS:
Masculinos y Femeninos
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 2, 2, 2, 2, 'GENERALIDADES:
Los órganos genitales en el hombre y en la mujer se dividen en:
• Genitales externos en el hombre: pene, el escroto y las envolturas
testiculares.
• Genitales externos en la mujer: vulva (recubierta por el monte de
venus) los labios mayores y menores, el vestíbulo de la vagina, las
glándulas vestibulares y el clítoris.
GENITALES EXTERNOS EN EL HOMBRE
PENE:
• Órgano de la copulación
• De conducción de orina y semen', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 3, 3, 3, 3, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 4, 4, 4, 4, '• Se divide en raíz, cuerpo y glande
• Compuestos por dos cuerpos cilíndricos dispuestos en forma paralela
(dos arriba que son los cuerpos cavernosos y uno abajo, cuerpo
esponjoso, contiene a la uretra).
• El glande es una expansión anterior del cuerpo esponjoso, en su
extremo se encuentra el meato urinario.
• El glande esta recubierto por un repliegue cutáneo: el prepucio.
IRRIGACION: arterias pudendas internas y externas.', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 5, 5, 5, 5, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 6, 6, 6, 6, 'ESCROTO:
• Es un saco fibromuscular, compuesto por dos capas de piel y el
musculo dartos.
• La contracción del dartos junto con el cremáster eleva los testículos
hacia arriba.
• Un tabique interno divide al escroto en dos bolsas que alojan cada
una un testículo, el epidídimo y el cordón espermático.', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 7, 7, 7, 7, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 8, 8, 8, 8, 'TUNICAS DEL TESTICULO:
• Son varias capas localizadas por dentro del escroto (cremáster) y
otra es la túnica peritoneo vaginal, la misma se divide en una capa
visceral en contacto con el testículo y una capa parietal.
• Existe una cavidad virtual con liquido, permite al testículo moverse
dentro del escroto.
• La túnica testicular mas interna es la albugínea, divide al testículo en
lobulillos que contienen los túbulos seminíferos.', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 9, 9, 9, 9, 'GENITALES EXTERNOS DE LA MUJER
MONTE DEL PUBIS (VENUS):
• Es una almohadilla de tejido adiposo
• Ubicada por delante y arriba del pubis
LABIOS MAYORES:
Son dos pliegues cutáneos prominentes con una hendidura central,
orientada desde el pubis hasta el ano, cubren los orificios uretral y
vaginal.
LABIOS MENORES:
• Se encuentran por dentro de los labios mayores
• Por delante terminan en dos pliegues: el prepucio y el frenillo del
clítoris.', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 10, 10, 10, 10, 'VESTIBULO:
• Es el espacio entre los labios menores
• Contiene los orificios de la uretra y la vagina
• El orificio de la uretra se localiza entre el clítoris y el orificio vaginal
• El himen es una fina membrana que cubre la entrada de la vagina
GLANDULAS VESTIBULARES: mayores y menores
CLITORIS: es un órgano eréctil, con receptores táctiles y sensitivos
IRRIGACION: ramas de las arterias pudendas', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 11, 11, 11, 11, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Genitales Externos (resumen) > p. 11');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 1, 1, 1, 1, 'GENITALES INTERNOS 
FEMENINOS
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 2, 2, 2, 2, 'Los
órganos
genitales
internos
femeninos
están
constituidos por la vagina, el útero, las trompas uterinas y
los ovarios.
VAGINA:
• Es un tubo musculomembranoso, se extiende desde la
hendidura de los labios menores hasta el cuello
uterino.
• Mide de 7 a 10 cm de longitud
• Se relaciona por delante con la vejiga y la uretra
• Por detrás se relaciona con el recto y el ano
• La vagina esta compuesta por una mucosa interna, una
capa muscular y un tejido conjuntivo por fuera.', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 3, 3, 3, 3, 'IRRIGACION DE LA VAGINA
Son ramas que provienen de las arterias uterina,
vesical inferior y pudenda interna.', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 4, 4, 4, 4, 'UTERO:
• Es un órgano muscular hueco con forma de pera invertida
• Compuesto por tres partes: el cuello, el istmo y el cuerpo.
• Mide en promedio 8 cm de longitud, 6 en su parte mas
ancha y 3 cm de espesor.
• El cuello presenta un conducto central con dos orificios uno
externo abierto hacia la vagina y otro interno abierto hacia
la cavidad uterina.
El útero esta compuesto por tres capas:
• Endometrio, capa interna
• Miometrio, capa media
• Perimetrio, serosa externa', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 5, 5, 5, 5, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 6, 6, 6, 6, 'PERITONEO-LIGAMENTOS UTERINOS
• El útero es un órgano relativamente móvil.
• El peritoneo tapiza el fondo, 2/3 de la cara anterior y toda la
cara posterior del cuerpo uterino.
LIGAMENTOS UTERINOS:
• LIGAMENTOS ANCHOS: las hojas peritoneales anterior y
posterior que revisten el útero se prolongan desde los bordes
laterales.
• Se dirigen a las paredes laterales pelvianas.
• De forma cuadrilátera
• Presenta 3 bordes y 1 base:
• Borde interno se fija en el útero (pasa pedículo uterino)
• Borde externo se inserta en la pared de la pelvis
• Borde superior esta ocupado por la trompa
• Base contacta con el piso pélvico (arteria uterina, uréter,
venas, linfáticos y nervios)', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 7, 7, 7, 7, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 8, 8, 8, 8, 'LIGAMENTOS REDONDOS:
• Fijan el útero a la pared abdominal anterior.
• Se origina a la D e I de la cara anterior del cuerno
uterino, por debajo y por delante de las trompas.
LIGAMENTOS UTEROSACROS:
• Fijan el cuello uterino a la cara anterior del sacro.
• Se origina en la cara posterior del cérvix, hasta
perderse en las vertebras sacras.
• El pliegue peritoneal que lo reviste determina el
limite superior del fondo de saco de Douglas.', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 9, 9, 9, 9, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 10, 10, 10, 10, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 10'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 11, 11, 11, 11, 'IRRIGACION DEL UTERO
Procede fundamentalmente de las ramas cervicovaginales de
las arterias uterinas.
TROMPAS UTERINAS
• Son dos tubos que se encuentran a ambos lados del útero
• Se dividen en cuatro segmentos: la porción uterina, el
istmo, la ampolla y el infundíbulo.
• Su medio de fijación mas importante es la continuación con
el fondo uterino y el mesosalpinx.
OVARIOS:
• Son glándulas ovoides intraperitoneales, se localizan en la
pelvis menor
• Producen gametos femeninos y son órganos endocrinos
• Su medio de suspensión es el ligamento suspensorio.
• Irrigado por la arteria ovárica.', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Femeninos (resumen) > p. 11');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_MASCULINOS'), 1, 1, 1, 1, 'GENITALES INTERNOS 
MASCULINOS
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Masculinos (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_MASCULINOS'), 2, 2, 2, 2, 'Los genitales internos del hombre incluyen los testículos, los epidídimos,
los conductos deferentes, las glándulas seminales, los conductos
eyaculadores, las glándulas bulbouretrales y la próstata.
TESTICULOS:
• Se originan en el tejido conectivo extraperitoneal en la región lumbar
• Migran al escroto a través del canal inguinal
• Los testículos son glándulas ovoideas de aproximadamente 4-5 cm
• Suspendidos por el cordón espermático
• Cada testículo presenta una capsula fibrosa (túnica albugínea) que
envía tabiques hacia el interior del testículo.
• Los testículos están irrigados por las arterias testiculares
FUNCIONES:', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Masculinos (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_MASCULINOS'), 3, 3, 3, 3, 'VIA ESPERMATICA:
• Es una vía de 6 cm de longitud
• En el origen dentro de cada testículo se encuentran los túbulos
seminíferos, se reúnen en el polo superior del testículo para constituir la
red testicular
• Los conductos eferentes salen de esa red testicular, penetran en la cabeza
del epidídimo
• El epidídimo se divide en: la cabeza, el cuerpo y la cola. Se continua con el
conducto deferente, ascienden hacia la cavidad abdominal.
• Cerca de la cara posterior de la próstata se ensanchan y se unen con los
conductos
de
las vesículas
seminales,
para
formar
los
conductos
eyaculadores, que desembocan en la cara posterior de la uretra prostática.
• Las vesículas seminales entre la vejiga y el recto, acumulan liquido alcalino
que se mezcla con los espermatozoides en el momento de la eyaculación.', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Masculinos (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_MASCULINOS'), 4, 4, 4, 4, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Masculinos (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_MASCULINOS'), 5, 5, 5, 5, 'CORDON ESPERMATICO:
• Estructura par, se extiende desde el testículo a la pelvis.
• Contiene el conducto deferente, la arteria testicular, la arteria y la vena
cremastéricas, el plexo venoso pampiniforme, vasos y nervios linfáticos.
PROSTATA:
• Tiene la forma de cono invertido
• Atravesada por la primera porción de la uretra y por los conductos
eyaculadores.
RELACIONES DE LA PROSTATA:
Hacia adelante con el pubis, arriba con el piso de la vejiga, atrás con los
conductos deferentes, las vesículas seminales, porción terminal de los
uréteres y el recto, hacia abajo con el diafragma urogenital, hacia las paredes
laterales con el musculo elevador del ano.', 'texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Masculinos (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_MASCULINOS'), 6, 6, 6, 6, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Genitales Internos Masculinos (resumen) > p. 6');

insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, content, tipo_contenido, extraction_method, estado_fragmento, ruta)
values
  ((select id from tmp_doc_map where dirname='MAMAS'), 1, 1, 1, 1, 'MAMAS
Lic. Miguel Medina', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Mamas (resumen) > p. 1'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 2, 2, 2, 2, 'ANATOMIA QUIRURGICA DE LA MAMA
“Las mamas son glándulas cutáneas especializadas”', 'texto', 'nativo_pdf', 'COMPLETO', 'Mamas (resumen) > p. 2'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 3, 3, 3, 3, 'UBICACION: 
• Parte anterior de cada hemitórax
• Entre las líneas paraesternal y axilar anterior
• Delante de los músculos pectoral mayor, pectoral menor y serrato
anterior.
• En extensión va desde la clavícula hasta el reborde costal y desde la
línea media del esternón, hasta el borde anterior del dorsal ancho.
La morfología varia según las razas y según los estados fisiológicos.
• La consistencia es firme y elástica en la nulípara
• Blanda y fláccida en la mujer adulta', 'texto', 'nativo_pdf', 'COMPLETO', 'Mamas (resumen) > p. 3'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 4, 4, 4, 4, 'ESTRUCTURA:
Cara anterior formada por:
• Piel
• Areola
• Papila mamaria', 'posible_lamina', 'nativo_pdf', 'COMPLETO', 'Mamas (resumen) > p. 4'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 5, 5, 5, 5, 'AREOLA
• Zona cutánea pigmentada de 2 a 3 cm de diámetro.
• Su superficie presenta de 12 a 24 elevaciones pequeñas denominadas
tubérculos de Morgagni, constituidos por glándulas sebáceas que se
hipertrofian en el embarazo ( tubérculos de Montgomery)', 'texto', 'nativo_pdf', 'COMPLETO', 'Mamas (resumen) > p. 5'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 6, 6, 6, 6, 'PEZON
• Situado en el centro de la areola
• Posee superficie rugosa
• En su vértice se evidencian 15 a 20 orificios (poros lactíferos) donde
desembocan los conductos lactíferos', 'texto', 'nativo_pdf', 'COMPLETO', 'Mamas (resumen) > p. 6'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 7, 7, 7, 7, 'TEJIDO CELULAR SUBCUTANEO
Se desdobla en la periferia de la glándula en dos capas:
Anterior, constituido por:
• Laminas conjuntivas (ligamento de Cooper) vinculan cara profunda de
la dermis y la cara externa de la glándula donde se insertan las crestas
fibroglandulares.
Posterior, constituido por:
• Fascia superficial, se aplica en la aponeurosis del pectoral mayor y el
borde de la clavícula.', 'texto', 'nativo_pdf', 'COMPLETO', 'Mamas (resumen) > p. 7'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 8, 8, 8, 8, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Mamas (resumen) > p. 8'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 9, 9, 9, 9, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Mamas (resumen) > p. 9'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 10, 10, 10, 10, '', 'sin_texto', 'nativo_pdf', 'COMPLETO', 'Mamas (resumen) > p. 10');


-- Figuras (capturadas y revisadas a mano: página completa del diagrama)

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO'), 'F00001', 4, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO') || '/pdf0004_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO'), 'F00002', 7, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='FISIOLOGIA_EJE_HIPOTALAMO-HIPOFISOGONADAL_MASCULINO') || '/pdf0007_fig01_full.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA'), 'F00003', 2, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA') || '/pdf0002_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA'), 'F00004', 3, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA') || '/pdf0003_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA'), 'F00005', 7, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='FISIOLOGIA_OVARICA') || '/pdf0007_fig01_full.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 'F00006', 3, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_EXTERNOS') || '/pdf0003_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 'F00007', 4, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_EXTERNOS') || '/pdf0004_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 'F00008', 5, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_EXTERNOS') || '/pdf0005_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 'F00009', 7, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_EXTERNOS') || '/pdf0007_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='GENITALES_EXTERNOS'), 'F00010', 11, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_EXTERNOS') || '/pdf0011_fig01_full.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 'F00011', 5, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS') || '/pdf0005_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 'F00012', 7, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS') || '/pdf0007_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 'F00013', 9, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS') || '/pdf0009_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS'), 'F00014', 10, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_INTERNOS_FEMENINOS') || '/pdf0010_fig01_full.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_MASCULINOS'), 'F00015', 4, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_INTERNOS_MASCULINOS') || '/pdf0004_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='GENITALES_INTERNOS_MASCULINOS'), 'F00016', 6, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='GENITALES_INTERNOS_MASCULINOS') || '/pdf0006_fig01_full.jpg', 'active');

insert into public.knowledge_figures
  (document_id, figure_key, pdf_page, source_xref, bbox, confidence, storage_path, status)
values
  ((select id from tmp_doc_map where dirname='MAMAS'), 'F00017', 2, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='MAMAS') || '/pdf0002_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 'F00018', 4, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='MAMAS') || '/pdf0004_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 'F00019', 5, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='MAMAS') || '/pdf0005_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 'F00020', 6, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='MAMAS') || '/pdf0006_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 'F00021', 8, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='MAMAS') || '/pdf0008_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 'F00022', 9, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='MAMAS') || '/pdf0009_fig01_full.jpg', 'active'),
  ((select id from tmp_doc_map where dirname='MAMAS'), 'F00023', 10, null, null, 0.9, 'doc' || (select id from tmp_doc_map where dirname='MAMAS') || '/pdf0010_fig01_full.jpg', 'active');


-- Vínculos figura <-> fragmento por página

insert into public.knowledge_fragment_figures (fragment_id, figure_id, relation_type, weight)
select f.id, g.id, 'same_page', 1.0
from public.knowledge_figures g
join public.knowledge_fragments f on f.document_id = g.document_id and f.page_start = g.pdf_page
where g.document_id in (select id from tmp_doc_map)
on conflict (fragment_id, figure_id) do nothing;
