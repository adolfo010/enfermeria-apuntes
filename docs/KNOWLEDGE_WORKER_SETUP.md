# Configuración del Knowledge PDF Worker

## Objetivo

Preparar la primera ejecución controlada del worker que procesa PDFs grandes desde Google Drive y almacena sus fragmentos en la Knowledge Base.

## 1. Secrets de GitHub

En el repositorio, abrir:

**Settings → Secrets and variables → Actions → New repository secret**

Crear estos secrets:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `KNOWLEDGE_USER_ID`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_REFRESH_TOKEN`
- `OPENAI_API_KEY`

No colocar estos valores en archivos del repositorio, commits, issues ni logs.

### KNOWLEDGE_USER_ID

Debe ser el UUID de la cuenta de Supabase que será propietaria de los jobs de conocimiento. Para la instalación actual corresponde utilizar la cuenta destinada al sistema de Enfermería.

## 2. Variable opcional

En:

**Settings → Secrets and variables → Actions → Variables**

se puede crear:

- nombre: `OPENAI_MODEL`
- valor: el modelo aprobado para el proyecto.

Si se omite, el worker utiliza su valor predeterminado.

## 3. Primera ejecución

Abrir:

**Actions → Knowledge PDF Worker → Run workflow**

Parámetros:

- `drive_file_id`: ID real de un PDF pequeño de prueba.
- `chunk_pages`: `3`.

El workflow primero ejecutará las pruebas internas. Solo si estas pasan intentará acceder a Google Drive.

## 4. Qué comprobar después

En Supabase:

### knowledge_documents

Debe existir un documento con:

- nombre correcto;
- cantidad de páginas correcta;
- `processing_status = completed`.

### knowledge_ingest_jobs

Debe quedar:

- `status = completed`;
- `processed_pages = total_pages`;
- `next_chunk = total_chunks`;
- sin `error_message`.

### knowledge_fragments

Debe haber fragmentos con:

- páginas válidas;
- contenido extraído;
- `content_hash`;
- documento de origen.

## 5. Prueba de recuperación

Después de una ejecución correcta, probar una segunda ejecución con el mismo `drive_file_id`.

Resultado esperado:

- no crear fragmentos duplicados;
- detectar el documento ya procesado;
- no volver a consumir innecesariamente el PDF.

## 6. Prueba de reanudación

Una vez validada la primera ejecución, realizar una prueba controlada de interrupción.

El objetivo es comprobar que un job con bloques ya confirmados conserva:

- `next_chunk`;
- `processed_pages`;
- fragmentos existentes.

Al reanudar, el worker debe continuar desde el siguiente bloque.

## 7. PDF grande

No utilizar todavía el PDF de 400–450 MB.

La secuencia recomendada es:

1. PDF pequeño.
2. Verificación de extracción.
3. Verificación de duplicados.
4. Verificación de reanudación.
5. PDF mediano.
6. PDF grande.

El tamaño del PDF grande no debe cambiar el procedimiento: el archivo se descarga a disco y se procesa por bloques.

## 8. Seguridad

Nunca registrar:

- `SUPABASE_SERVICE_ROLE_KEY`;
- `OPENAI_API_KEY`;
- `GOOGLE_CLIENT_SECRET`;
- `GOOGLE_REFRESH_TOKEN`.

Si una credencial aparece accidentalmente en un log o commit, debe revocarse/rotarse inmediatamente.

## Estado

Esta guía pertenece a la rama `architecture/knowledge-base-v1`. No implica despliegue de funciones ni aplicación de migraciones sobre producción.
