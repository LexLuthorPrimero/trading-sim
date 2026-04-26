#!/usr/bin/env bash
set -euo pipefail

PRICES_FILE="${1:?Se requiere archivo de precios}"
MIN_LINES="${2:-10}"

# --- B‑FILEPROC: verificar que el archivo existe y no está vacío ---
if [ ! -s "$PRICES_FILE" ]; then
    echo "[ERROR] Archivo $PRICES_FILE no existe o está vacío" >&2
    exit 1
fi

# --- B‑FILEPROC: contar líneas ---
line_count=$(wc -l < "$PRICES_FILE")
if [ "$line_count" -lt "$MIN_LINES" ]; then
    echo "[ERROR] $PRICES_FILE tiene $line_count líneas (mínimo requerido: $MIN_LINES)" >&2
    exit 1
fi

# --- B‑FILEPROC: validar que cada línea sea un número positivo ---
invalid_lines=$(awk '
    NF != 1 || $1 !~ /^[0-9]+(\.[0-9]{1,2})?$/ || $1 <= 0 {
        print NR
    }' "$PRICES_FILE")

if [ -n "$invalid_lines" ]; then
    echo "[ERROR] Líneas inválidas en $PRICES_FILE: $invalid_lines" >&2
    exit 1
fi

echo "[OK] $PRICES_FILE validado: $line_count líneas, formato correcto"
