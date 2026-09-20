# Nueva arquitectura de conocimiento académico

## Objetivo

Reemplazar progresivamente el modelo centrado en archivos/PDF por una capa de conocimiento académico que permita consultar por temas y recuperar automáticamente las fuentes y fragmentos relevantes.

Los índices actuales `ai_document_indexes` y `ai_index_jobs` se consideran **material de referencia/migración**, no el modelo objetivo.

## Principios

1. Los documentos originales de Google Drive permanecen como fuente de verdad.
2. La base de conocimiento es una representación derivada y reconstruible.
3. Un concepto académico es independiente de un documento concreto.
4. Un documento puede aportar muchos conceptos y un concepto puede aparecer en muchos documentos.
5. Las páginas/fragmentos conservan siempre la procedencia.
6. No se debe enviar un PDF completo a la IA si el sistema puede recuperar fragmentos pertinentes.
7. Los libros, atlas, apuntes y resúmenes tienen distinto tipo de fuente y peso.
8. La interfaz debe trabajar principalmente con áreas/temas/conceptos, no con selección manual de PDFs.
9. Los documentos modificados se detectan mediante fingerprint y se reprocesan.
10. La implementación debe poder convivir temporalmente con el sistema actual.

## Modelo lógico propuesto

### knowledge_documents

Representa una fuente original.

Campos previstos:
- id
- drive_file_id
- file_name
- mime_type
- fingerprint
- title
- source_type
- subject_area
- page_count
- processing_status
- processing_version
- created_at
- updated_at

### knowledge_fragments

Unidad recuperable de contenido.

Campos previstos:
- id
- document_id
- page_start
- page_end
- content
- content_hash
- extraction_method
- created_at

### knowledge_concepts

Conceptos académicos normalizados.

Campos previstos:
- id
- name
- description
- concept_type
- parent_id
- status
- created_at
- updated_at

### knowledge_concept_aliases

Variantes terminológicas.

Campos previstos:
- id
- concept_id
- alias
- normalized_alias

### knowledge_fragment_concepts

Relación entre contenido y conceptos.

Campos previstos:
- fragment_id
- concept_id
- relevance
- evidence_type

### knowledge_concept_relations

Relaciones semánticas entre conceptos.

Campos previstos:
- id
- concept_id
- related_concept_id
- relation_type
- weight

Ejemplos de relation_type:
- contains
- part_of
- related_to
- causes
- supplied_by
- innervated_by
- irrigated_by
- associated_with

### knowledge_document_concepts

Relación agregada documento/concepto.

Campos previstos:
- document_id
- concept_id
- coverage
- source_role
- page_start
- page_end

## Tipos de fuente

Valores iniciales:

- primary_text
- complementary_text
- atlas
- teaching_note
- summary
- clinical_case
- question_bank
- other

## Flujo de procesamiento

Google Drive
-> documento original
-> detección de fingerprint
-> extracción estructural
-> extracción de fragmentos
-> detección/normalización de conceptos
-> relaciones concepto-fragmento
-> relaciones concepto-concepto
-> catálogo disponible para recuperación

## Flujo de consulta

Usuario selecciona o busca un concepto
-> resolver concepto y alias
-> ampliar relaciones relevantes
-> recuperar fragmentos
-> aplicar filtros por área/nivel/tipo de fuente
-> construir contexto acotado
-> IA
-> respuesta
-> citas de fuente y páginas

## Exámenes

La generación de preguntas deberá recibir conceptos/temas y no depender de que el usuario seleccione PDFs.

Ejemplo:

Tema: Sistema cardiovascular
Concepto: Corazón
Nivel: Enfermería
Cantidad: 20

El backend recuperará automáticamente las fuentes autorizadas.

## Migración

No eliminar inmediatamente las tablas actuales.

Primera etapa:
- crear modelo nuevo aislado;
- construir un importador desde `ai_document_indexes`;
- validar resultados con Anatomía;
- comparar recuperación nueva vs. índice actual;
- solamente después migrar las funciones de resumen/examen/consulta.

## Criterio de éxito

Una consulta como:

"Explicame la irrigación del corazón"

debe recuperar automáticamente conceptos como:
- corazón
- arterias coronarias
- arteria coronaria derecha
- arteria coronaria izquierda

y devolver fragmentos con documento y páginas, sin que el usuario seleccione manualmente los libros.

## Restricción

No modificar producción ni eliminar los índices actuales durante esta fase.
