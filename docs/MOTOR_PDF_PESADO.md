# Separación del motor PDF

## Decisión

`knowledge-worker` administra el estado del trabajo, pero no debe asumir la lectura de un PDF de cientos de MB.

## Motivo

El procesamiento físico requiere un entorno con almacenamiento local/temporal suficiente y una librería PDF que pueda trabajar con el archivo sin convertirlo en un gran `Uint8Array` residente en memoria.

## Flujo

1. Drive entrega metadatos y fingerprint.
2. Se crea `knowledge_ingest_jobs` de forma idempotente.
3. Un motor PDF externo al worker de Supabase obtiene el documento.
4. Ese motor genera bloques de 3 páginas.
5. Cada bloque se entrega al extractor IA.
6. Los fragmentos se persisten en Supabase.
7. Se confirma el bloque mediante `complete_knowledge_ingest_chunk`.
8. El trabajo continúa hasta `completed`.

## Ventaja

Supabase queda como coordinador y repositorio de conocimiento; el procesamiento pesado queda desacoplado y puede escalar independientemente.

## Estado

El registro de trabajos y la coordinación ya están preparados. Falta seleccionar y desplegar el motor PDF pesado en un entorno no limitado por la memoria de una Edge Function.