# Knowledge PDF Worker

Worker externo para procesar PDFs grandes de Google Drive sin cargar el documento completo en memoria.

## Por qué existe

Las Edge Functions de Supabase tienen límites de memoria y tiempo que no son apropiados para abrir PDFs de cientos de MB. Este worker usa almacenamiento de disco temporal y procesa páginas desde un archivo local.

## Estado

El worker usa secretos del entorno y se ejecuta mediante GitHub Actions de forma manual. No hay credenciales en el repositorio.

## Flujo actual

1. recibir un job;
2. descargar el PDF desde Drive a disco;
3. abrirlo desde disco;
4. generar un bloque temporal de 3 páginas;
5. enviarlo al extractor de OpenAI;
6. persistir fragmentos en Supabase;
7. confirmar el bloque;
8. eliminar el temporal;
9. continuar con el siguiente bloque.

## Variables requeridas

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `KNOWLEDGE_USER_ID`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_REFRESH_TOKEN`
- `OPENAI_API_KEY`

Opcional: `OPENAI_MODEL`.

## Ejecución

Local: `python workers/knowledge_pdf_worker/worker.py --pdf archivo.pdf`

Completa: `python workers/knowledge_pdf_worker/worker.py --process --file-id DRIVE_FILE_ID --chunk-pages 3`

El workflow de GitHub Actions solicita el `drive_file_id` y `chunk_pages`. Los secretos deben configurarse previamente.

## Prueba recomendada

Primero usar un PDF pequeño. Verificar extracción, fragmentos, conceptos, avance del job y estado `completed`. Después probar interrupción/reanudación y recién entonces un PDF de 400–450 MB.

## Reanudación

Si un bloque falla, los bloques confirmados permanecen almacenados y el job conserva `next_chunk`, `processed_pages` y `error_message` para continuar posteriormente.

El PDF completo puede permanecer en disco durante el trabajo, pero no debe cargarse completo en un `bytes`/`Uint8Array` de memoria.