# Decisión de almacenamiento para PDFs grandes

## Estado verificado

- El proyecto no tiene actualmente buckets de Supabase Storage.
- El proyecto no tiene habilitadas las extensiones pgmq, pg_cron, pg_net ni http.
- Las funciones knowledge no están desplegadas en producción.

## Consecuencia

No conviene introducir todavía una dependencia de cola o Storage en producción sin diseñar primero sus políticas, retención, límites y costo.

## Ruta recomendada

El componente de procesamiento grande debe quedar desacoplado mediante `knowledge_ingest_jobs`. La implementación podrá usar una cola/worker cuando el entorno esté preparado, pero la base de datos ya conserva el cursor y permite reanudar.

## Protección actual

El ingest síncrono rechaza archivos mayores de 80 MB. Esto evita intentar procesar PDFs de 400–450 MB dentro de una sola ejecución.

## Criterio para habilitar el pipeline grande

Antes de desplegarlo deben quedar definidos:
1. almacenamiento temporal del PDF;
2. mecanismo de worker/cola;
3. expiración y limpieza del temporal;
4. límites de tamaño y tiempo;
5. reintentos idempotentes;
6. monitoreo de progreso;
7. control de costo de extracción IA.