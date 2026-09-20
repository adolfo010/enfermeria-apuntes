# Pipeline asíncrono para PDFs grandes

## Motivo

El prototipo actual usa pdf-lib y carga el PDF completo en memoria antes de copiar bloques de 3 páginas. Esto es adecuado para documentos pequeños, pero no para archivos de 400–450 MB.

## Decisión

Los documentos que superen 80 MB quedan fuera del pipeline síncrono actual y devuelven LARGE_PDF_REQUIRES_ASYNC_PIPELINE.

Esto es una protección deliberada: evita que un PDF grande provoque consumo excesivo de memoria o una ejecución abortada de la Edge Function.

## Arquitectura prevista

1. Registrar el documento y su fingerprint en knowledge_documents.
2. Crear un trabajo persistente de ingestión con estado y progreso.
3. Descargar/procesar el documento fuera del ciclo de una única Edge Function.
4. Generar bloques pequeños de páginas.
5. Enviar únicamente cada bloque a extracción.
6. Guardar fragmentos inmediatamente después de cada bloque.
7. Reanudar desde el último bloque confirmado si una ejecución falla.
8. Mantener page_start/page_end para trazabilidad.
9. Marcar completed únicamente cuando todos los bloques fueron confirmados.

## Requisito importante

La futura implementación no debe solucionar el problema simplemente aumentando el límite de memoria. El objetivo es que el tamaño del PDF completo no determine la memoria de una ejecución.

## Caso de 450 MB

Un documento de aproximadamente 450 MB debe procesarse como trabajo asíncrono y reanudable. El usuario no debería tener que volver a subirlo ni dividirlo manualmente para que la aplicación pueda indexarlo.

## Estado

Diseño definido. Implementación pendiente de seleccionar el mecanismo de worker/cola y almacenamiento temporal apropiado para el entorno de producción.