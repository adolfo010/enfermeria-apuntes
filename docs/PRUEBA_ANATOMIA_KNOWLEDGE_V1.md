# Prueba real de Knowledge Base v1 — Anatomía

## Objetivo

Validar con un PDF real que la arquitectura:

1. descarga el PDF desde Drive;
2. lo divide en bloques de 3 páginas;
3. extrae contenido académico conservando la página original;
4. crea fragmentos;
5. vincula conceptos existentes;
6. recupera fragmentos mediante una consulta temática.

## Documento de validación

- Archivo: `Anatomia_con_oritacion_clinica_8a_edicio.pdf`
- Páginas esperadas: 28
- Conceptos ya presentes en el índice temático:
  - Corazón
  - Vasos coronarios
  - Arterias coronarias
  - Arteria coronaria derecha
  - Arteria coronaria izquierda
  - Venas cardíacas
  - Seno coronario
  - Irrigación, drenaje venoso e inervación del pericardio
  - Estructuras del corazón

## Consultas de aceptación

### Consulta 1
`irrigación del corazón`

Debe recuperar fragmentos cuyo contenido corresponda realmente al tema y devolver documento + página.

### Consulta 2
`arteria coronaria derecha`

Debe recuperar fragmentos asociados a ese concepto y conservar la procedencia de páginas.

### Consulta 3
`sistema nervioso central`

No debe recuperar fragmentos cardíacos solamente porque pertenezcan al mismo PDF.

## Criterio de éxito

La prueba se considera válida si los resultados proceden del contenido extraído de las páginas y no de los títulos del índice.

## Estado

Pendiente de ejecutar en un entorno Supabase donde estén aplicadas las migraciones `knowledge_base_v1` y desplegadas las funciones del prototipo.

**Importante:** esta prueba no debe ejecutarse sobre producción hasta revisar el consumo de IA y confirmar que el presupuesto interno permite procesar el documento.
