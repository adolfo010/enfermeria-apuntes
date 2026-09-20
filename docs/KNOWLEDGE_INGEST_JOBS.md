# Knowledge Ingest Jobs — diseño

## Objetivo
Persistir el progreso de ingestión de documentos grandes para que una ejecución no tenga que completar todo el documento.

## Estados
- pending: trabajo creado y todavía no iniciado.
- running: un worker está procesando un bloque.
- paused: detenido de forma controlada.
- error: requiere reintento.
- completed: todos los bloques fueron confirmados.
- cancelled: trabajo cancelado.

## Cursor
`next_chunk` identifica el próximo bloque que debe procesarse. `processed_pages` permite mostrar progreso al usuario.

## Regla de consistencia
Un bloque solo debe avanzar el cursor después de que sus fragmentos y relaciones hayan sido confirmados en la base.

## Importante para PDFs de 400–450 MB
La tabla resuelve la persistencia y reanudación, pero por sí sola no resuelve la lectura eficiente del PDF. El siguiente componente debe evitar cargar el archivo completo en memoria en una única Edge Function.

Por eso el límite de 80 MB permanece activo en el ingest síncrono actual.