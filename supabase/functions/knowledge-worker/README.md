# Knowledge Worker v1

Este worker es deliberadamente pequeño.

## Responsabilidad actual
- autenticar al usuario;
- reclamar un único trabajo pendiente mediante `SKIP LOCKED`;
- devolver el índice del bloque que debe procesarse.

## Lo que todavía no hace
- no descarga PDFs;
- no llama a OpenAI;
- no modifica el cursor;
- no se despliega en producción.

Esta separación es intencional. Primero validamos la exclusión mutua y la reanudación; después conectamos el procesamiento físico del bloque.

## Regla de concurrencia
Dos workers no deben poder reclamar el mismo trabajo simultáneamente. La función SQL utiliza `FOR UPDATE SKIP LOCKED` para evitar esa colisión.