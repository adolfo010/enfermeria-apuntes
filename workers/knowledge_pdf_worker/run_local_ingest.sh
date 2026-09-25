#!/bin/bash
set -euo pipefail

PDF_PATH="${1:-}"

if [ -z "$PDF_PATH" ]; then
  echo "Uso: ./run_local_ingest.sh /ruta/al/archivo.pdf"
  exit 1
fi

if [ ! -f "$PDF_PATH" ]; then
  echo "No existe el PDF: $PDF_PATH"
  exit 1
fi

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  echo "Faltan SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY."
  echo "Exportalos en la terminal antes de ejecutar este script."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 -m pip install -r "$SCRIPT_DIR/requirements-local.txt"
python3 "$SCRIPT_DIR/local_ingest.py" --pdf "$PDF_PATH"
