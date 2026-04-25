#!/usr/bin/env bash
set -euo pipefail

# Directorio donde está este script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_URL="${API_URL:-http://localhost:8000}"
SYMBOL="${1:-AAPL}"
PERIOD="${2:-6mo}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "Descargando datos de $SYMBOL..."
python3 "$SCRIPT_DIR/fetch_data.py" "$SYMBOL" "$PERIOD"

log "Solicitando señal al API..."
curl -s -X POST "${API_URL}/decision?symbol=${SYMBOL}&period=${PERIOD}" \
  -H "Content-Type: application/json" | python3 -m json.tool

log "Señal guardada en la base de datos."
