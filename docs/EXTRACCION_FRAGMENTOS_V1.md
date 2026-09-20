# Extracción de fragmentos v1

## Objetivo
Convertir texto ya extraído de un documento en unidades pequeñas y recuperables, conservando siempre las páginas de origen.

## Primera versión
- Ventana máxima: 3 páginas.
- Límite orientativo: 12.000 caracteres.
- Cada fragmento conserva page_start y page_end.
- Cada fragmento recibe un hash determinista para detectar cambios.
- La asociación inicial concepto-fragmento usa coincidencia textual normalizada.
- La asociación semántica/embeddings queda para una segunda etapa.

## Ejemplo de Anatomía
Consulta: irrigación del corazón

Conceptos esperados:
- corazón
- arterias coronarias
- arteria coronaria derecha
- arteria coronaria izquierda

## Importante
Esta etapa no procesa todavía los PDF completos ni modifica las tablas actuales.

## Próximo paso
Conectar la extracción real de páginas de los documentos de Anatomía y cargar el resultado únicamente en la estructura v1 aislada.
