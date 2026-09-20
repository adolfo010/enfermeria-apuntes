# Knowledge PDF Worker

Worker externo para procesar PDFs grandes de Google Drive sin cargar el documento completo en memoria.

## Arquitectura

Google Drive → GitHub Actions → worker Python → OpenAI → Supabase Knowledge Base.

El PDF completo se descarga al disco temporal del runner. El procesamiento de IA se realiza únicamente sobre bloques pequeños de páginas. Supabase conserva el estado del trabajo y los fragmentos ya confirmados.

## Seguridad

No guardar credenciales en el repositorio.

En GitHub, configurar los siguientes **Repository secrets**:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `KNOWLEDGE_USER_ID`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_REFRESH_TOKEN`
- `OPENAI_API_KEY`

Opcional, como **Repository variable**:

- `OPENAI_MODEL`

`SUPABASE_SERVICE_ROLE_KEY` y `OPENAI_API_KEY` nunca deben aparecer en commits, logs ni parámetros del workflow.

## Flujo actual

1. recibir un `drive_file_id`;
2. renovar el acceso OAuth de Google;
3. obtener metadatos del PDF;
4. descargarlo en streaming a disco;
5. abrirlo desde disco con `pypdf`;
6. dividirlo lógicamente en bloques de 3 páginas;
7. crear un PDF temporal únicamente con el bloque actual;
8. enviarlo al extractor de OpenAI;
9. validar y persistir los fragmentos de cada página;
10. confirmar el avance del job en Supabase;
11. eliminar el temporal;
12. continuar con el siguiente bloque.

## Reanudación

El estado se guarda en `knowledge_ingest_jobs` mediante:

- `status`
- `next_chunk`
- `processed_pages`
- `error_message`

Si el worker se interrumpe después de confirmar un bloque, la siguiente ejecución continúa desde `next_chunk`. Los fragmentos ya persistidos no se vuelven a duplicar gracias a la restricción de unicidad.

Esto permite que un PDF de cientos de MB se procese por etapas sin exigir que una sola ejecución complete todo el trabajo.

## Prueba escalonada recomendada

### 1. Prueba interna

El workflow ejecuta primero:

`pytest -q workers/knowledge_pdf_worker/test_worker.py`

Si falla, no se inicia el procesamiento de Drive.

### 2. PDF pequeño

Usar un PDF de anatomía de unas pocas decenas de páginas.

Comprobar:

- documento creado en `knowledge_documents`;
- fragmentos creados en `knowledge_fragments`;
- conceptos asociados;
- job en `completed`;
- `processed_pages = total_pages`;
- `next_chunk = total_chunks`.

### 3. Prueba de recuperación

Interrumpir una ejecución durante el procesamiento y volver a ejecutarla con el mismo `drive_file_id`.

Resultado esperado:

- no borrar los fragmentos confirmados;
- continuar desde `next_chunk`;
- completar el documento;
- no generar duplicados.

### 4. PDF grande

Después de validar las etapas anteriores, utilizar el PDF de 400–450 MB.

El tamaño del archivo deja de ser un límite de memoria de la Edge Function: el worker lo maneja desde disco y procesa bloques pequeños. El tiempo total dependerá principalmente del número de páginas y de las llamadas a OpenAI.

## Ejecución manual

En GitHub:

1. abrir **Actions**;
2. seleccionar **Knowledge PDF Worker**;
3. seleccionar **Run workflow**;
4. indicar `drive_file_id`;
5. dejar `chunk_pages = 3` para la primera prueba;
6. ejecutar.

No modificar `main` ni desplegar las Edge Functions de producción como parte de esta prueba.

## Ejecución local

Inspección local:

`python workers/knowledge_pdf_worker/worker.py --pdf archivo.pdf`

Procesamiento completo:

`python workers/knowledge_pdf_worker/worker.py --process --file-id DRIVE_FILE_ID --chunk-pages 3`

Para una primera prueba real, mantener `chunk_pages=3`. Más adelante podemos comparar 3, 5 y 10 páginas según tamaño del PDF y costo/tiempo de extracción.
