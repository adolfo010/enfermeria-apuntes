# Knowledge PDF Worker

Worker de prueba para PDFs grandes.

## Por qué existe

Las Edge Functions de Supabase tienen límites de memoria y tiempo que no son apropiados para abrir PDFs de cientos de MB. Este worker usa almacenamiento de disco temporal y procesa páginas desde un archivo local.

## Estado

Actualmente es un componente de infraestructura preparado para pruebas. No contiene credenciales ni se ejecuta automáticamente.

## Flujo previsto

1. recibir un job;
2. descargar el PDF desde Drive a disco;
3. abrirlo desde disco;
4. generar un bloque temporal de 3 páginas;
5. enviarlo al extractor;
6. persistir fragmentos;
7. confirmar el bloque;
8. eliminar el temporal;
9. continuar con el siguiente bloque.

El PDF completo puede permanecer en disco durante el trabajo, pero no debe cargarse completo en un `bytes`/`Uint8Array` de memoria.