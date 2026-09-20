# Estrategia de procesamiento físico para PDFs grandes

## Problema identificado

Google Drive permite solicitar rangos de bytes de un archivo mediante HTTP Range. Eso permite diseñar un lector por rangos, pero un PDF no es un formato que pueda dividirse correctamente en bloques arbitrarios de bytes: la estructura interna y los objetos pueden cruzar esos límites.

Por lo tanto, **no debemos implementar un falso `Range` que asuma que cada rango de bytes equivale a determinadas páginas PDF**.

## Estrategia correcta

Para PDFs grandes se necesitan dos etapas separadas:

1. **Materialización temporal controlada:** obtener el archivo en un almacenamiento temporal accesible al worker, sin mantenerlo completo en memoria.
2. **Procesamiento incremental:** abrir el archivo desde almacenamiento temporal y producir bloques de páginas pequeños.

El worker debe conservar solamente el bloque actual en memoria y escribir los fragmentos inmediatamente.

## Alternativa de emergencia

Si el entorno elegido no permite lectura aleatoria de un PDF almacenado remotamente, se puede materializar el archivo en disco efímero. La ventaja es que el PDF completo queda fuera de la memoria del proceso; la desventaja es que el almacenamiento efímero y su duración deben verificarse antes de implementarlo.

## Lo que no debemos hacer

- Descargar 450 MB a un `Uint8Array` dentro de una Edge Function.
- Suponer que bytes 0–20 MB corresponden a páginas 1–100.
- Dividir físicamente el PDF por bytes sin reconstruir su estructura.
- Enviar el PDF completo a la IA en cada consulta.

## Objetivo final

Un PDF de 450 MB debe convertirse una sola vez en fragmentos de conocimiento persistentes. Las consultas posteriores deben trabajar sobre esos fragmentos y no volver a procesar el PDF completo.

## Próximo componente

Antes de elegir una implementación concreta, hay que verificar qué almacenamiento temporal, worker/queue y límites de ejecución están disponibles en el proyecto Supabase. La elección debe basarse en esas capacidades reales y no en supuestos.