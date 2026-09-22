-- Piloto de catalogación del Atlas de Netter (document_id=7), Láminas 2-5.
-- El texto OCR de este libro no trae número de página PDF por lámina (es un
-- atlas: cada lámina es una imagen con decenas de etiquetas sueltas, sin
-- marcador de página en el texto). Se estimó la página PDF cruzando el orden
-- de láminas con las páginas reales que sí tienen figuras extraídas en el ZIP
-- (17, 19, 20, 25, 27...). pagina_impresa_inferida=true marca que es una
-- estimación sin confirmar, no un dato verificado.
insert into public.knowledge_fragments
  (document_id, page_start, page_end, pagina_impresa_inicio, pagina_impresa_fin, pagina_impresa_inferida,
   titulo, ruta, tipo_contenido, content, extraction_method, estado_fragmento)
values
(7, 19, 19, 19, 19, true,
 'Lámina 2 — Arterias y venas superficiales de la cara y cuero cabelludo',
 'Netter > Sección 1. Cabeza y cuello > Anatomía topográfica > Cabeza y cuello, plano superficial',
 'enumeración',
 'Cabeza y cuello, plano superficial. Arterias y venas superficiales de la cara y cuero cabelludo (véanse también láminas 33, 39, 69, 70).

Estructuras: Piel y tejido subcutáneo. Cuero cabelludo. Aponeurosis epicraneal (galea aponeurótica). Vena emisaria parietal (cortada para mostrar el cráneo). Ramas frontal y parietal de la arteria y vena temporales superficiales. Arteria cigomaticoorbitaria. Arteria y vena transversas de la cara. Arterias auriculares anteriores. Arteria y vena supraorbitarias. Arteria y vena supratrocleares. Vena nasofrontal. Arteria y vena dorsales de la nariz. Arteria y vena angulares. Arteria y vena cigomaticofaciales. Arteria y vena cigomaticotemporales. Vena emisaria mastoidea. Rama meníngea de la arteria occipital (arteria meníngea posterior). Vena facial profunda (del plexo pterigoideo). Arteria y vena occipitales (cortadas). Arteria y vena auriculares posteriores. Arteria y vena faciales. Vena yugular externa (cortada). Vena retromandibular. Vena yugular interna. Arteria carótida interna. Arteria carótida externa. Arteria carótida común. Arteria y vena linguales.

Nota del original: Vascularización arterial de la cara. Negro: de la arteria carótida interna (vía arteria oftálmica). Rojo: de la arteria carótida externa.

[Fuente: reconstrucción a partir de OCR desordenado, cruzado con conocimiento anatómico estándar de esta lámina. Página PDF estimada, sin confirmar.]',
 'manual_chat_modo_a', 'COMPLETO'),

(7, 20, 20, 20, 20, true,
 'Lámina 3 — Cráneo: visión anterior (incluye órbita derecha)',
 'Netter > Sección 1. Cabeza y cuello > Anatomía topográfica > Huesos y ligamentos',
 'enumeración',
 'Cráneo: visión anterior.

Estructuras: Hueso frontal. Sutura coronal. Glabela. Hueso parietal. Escotadura (agujero) supraorbitaria. Nasión. Cara orbitaria. Hueso esfenoides (ala menor). Hueso nasal. Ala mayor del esfenoides. Hueso lagrimal. Hueso temporal. Hueso etmoides. Hueso cigomático. Apófisis frontal del cigomático. Lámina perpendicular del etmoides. Concha nasal media. Apófisis temporal del cigomático. Concha nasal inferior. Agujero cigomaticofacial. Vómer. Maxilar. Mandíbula. Apófisis cigomática. Cara orbitaria del maxilar. Agujero infraorbitario. Agujero mentoniano. Apófisis frontal del maxilar. Apófisis alveolar. Protuberancia mentoniana. Espina nasal anterior. [Un término del original resultó ilegible: "Cuemo" — no se pudo identificar con certeza.]

Recuadro — Órbita derecha: visión frontal y ligeramente lateral. Cara orbitaria del hueso frontal. Escotadura supraorbitaria. Cara orbitaria del ala menor del esfenoides. Agujeros etmoidales (anterior y posterior). Fisura orbitaria superior. Lámina orbitaria del hueso etmoides. Conducto (agujero) óptico. Cara orbitaria del ala mayor del esfenoides. Hueso lagrimal. Cara orbitaria del hueso cigomático. Fosa del saco lagrimal. Apófisis orbitaria del hueso palatino. Agujero cigomaticofacial. Fisura orbitaria inferior. Cara orbitaria del maxilar. Surco infraorbitario. Agujero infraorbitario.

[Fuente: reconstrucción a partir de OCR desordenado, cruzado con conocimiento anatómico estándar de esta lámina. Página PDF estimada, sin confirmar.]',
 'manual_chat_modo_a', 'COMPLETO'),

(7, 25, 25, 25, 25, true,
 'Lámina 4 — Cráneo: radiografía anteroposterior',
 'Netter > Sección 1. Cabeza y cuello > Anatomía topográfica > Huesos y ligamentos',
 'enumeración',
 'Cráneo: radiografía anteroposterior.

Estructuras señaladas: Senos frontales. Alas menores del esfenoides. Crista galli. Alas mayores del esfenoides. Celdillas etmoidales. Senos maxilares. Ramas de la mandíbula. Ángulo de la mandíbula.

[Fuente: reconstrucción a partir de OCR desordenado, cruzado con conocimiento anatómico estándar de esta lámina. Página PDF estimada, sin confirmar.]',
 'manual_chat_modo_a', 'COMPLETO'),

(7, 27, 27, 27, 27, true,
 'Lámina 5 — Cráneo: visión lateral',
 'Netter > Sección 1. Cabeza y cuello > Anatomía topográfica > Huesos y ligamentos',
 'enumeración',
 'Cráneo: visión lateral.

Estructuras: Hueso esfenoides. Hueso parietal. Fosa temporal. Hueso temporal. Ala mayor del esfenoides. Línea temporal superior. Porción escamosa del temporal. Hueso frontal. Apófisis cigomática del temporal. Escotadura (agujero) supraorbitaria. Línea temporal inferior. Pterión. Tubérculo articular. Glabela. Surco para la arteria temporal profunda posterior. Hueso etmoides. Cresta supramastoidea. Conducto auditivo externo. Lámina orbitaria del etmoides. Hueso lagrimal. Apófisis mastoides. Sutura lambdoidea. Fosa del saco lagrimal. Hueso occipital. Hueso nasal. Hueso sutural (wormiano). Maxilar. Apófisis frontal del maxilar. Protuberancia occipital externa (inión). Agujero infraorbitario. Espina nasal anterior. Asterión. Apófisis alveolar. Mandíbula. Hueso cigomático. Cabeza de la apófisis condilar. Escotadura mandibular. Agujero cigomaticofacial. Apófisis coronoides. Rama de la mandíbula. Apófisis temporal del cigomático. Línea oblicua. Cuerpo de la mandíbula. Arco cigomático. Agujero mentoniano. Fosa infratemporal (expuesta por extirpación del arco cigomático y la mandíbula). Fisura pterigomaxilar. Lámina lateral de la apófisis pterigoides. Fisura orbitaria inferior. Gancho de la pterigoides (de la lámina medial de la apófisis pterigoides). Cara infratemporal del maxilar. Agujeros alveolares. Agujero oval. Tuberosidad del maxilar. Fosa mandibular. Fosa pterigopalatina. Apófisis estiloides. Agujero esfenopalatino.

Nota al pie (incompleta en el original, continúa en Lámina 6): "Superficialmente, la apófisis mastoides forma el límite..."

[Dos fragmentos del original resultaron ilegibles y no se incluyeron: una nota corta junto al arco cigomático, y un rótulo de una línea.]

[Fuente: reconstrucción a partir de OCR desordenado, cruzado con conocimiento anatómico estándar de esta lámina. Página PDF estimada, sin confirmar.]',
 'manual_chat_modo_a', 'COMPLETO');
