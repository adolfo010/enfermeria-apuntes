# Prototipo Anatomía — estado

## Fuente real detectada

En el índice actual existen documentos de Anatomía, entre ellos:

- anatomia_descriptiva-m_de_la_hera.pdf
- Anatomía-1.pdf
- Anatomia_con_oritacion_clinica_8a_edicio.pdf
- ATLAS FOTOGRÁFICO DE OSTEOLOGÍA CON ORIENTACIÓN PALPATORIA.pdf
- GRAY_Anatomia_Capitulo_1_pag_1-12.pdf
- GRAY_Anatomia_Capitulo_2_pag_13-100.pdf
- GRAY_Anatomia_Capitulo_3_Parte_01_pag_101-200.pdf

El índice ya contiene conceptos útiles para validar el modelo. En particular aparecen:

- Corazón
- Vasos coronarios
- Arterias coronarias
- Arteria coronaria derecha
- Arteria coronaria izquierda
- Venas cardíacas
- Seno coronario
- Irrigación, drenaje venoso e inervación del pericardio

## Validación objetivo

Consulta:

> irrigación del corazón

El nuevo recuperador debe resolver progresivamente:

1. corazón
2. arterias coronarias
3. arteria coronaria derecha
4. arteria coronaria izquierda
5. vasos coronarios
6. venas cardíacas / seno coronario cuando corresponda

y recuperar fragmentos con páginas y documento de origen.

## Estado

La capa concepto está alimentada por los índices actuales.

La capa fragmento todavía requiere texto de página real. No se fabrican fragmentos a partir de títulos del índice porque eso degradaría la calidad de recuperación.

## Siguiente implementación

Conectar el extractor real de páginas de los PDF de Anatomía al módulo `extract-fragments.ts`.

No se modifica producción ni se aplican las tablas v1 al proyecto activo.
