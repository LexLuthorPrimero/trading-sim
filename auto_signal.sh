#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_URL="${API_URL:-http://localhost:8000}"
SYMBOL="${1:-AAPL}"
PERIOD="${2:-6mo}"
TEMP_PRICES="/tmp/prices_$$.dat"
TEMP_SIGNALS="/tmp/signals_$$.txt"
COBOL_DIR="${COBOL_DIR:-$SCRIPT_DIR/cobol}"
CORRELATION_ID="$(date +%s)-$$"

# --- B‑LOG: función de logging estructurado ---
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$level] [CID=$CORRELATION_ID] $message" >&2
}

# --- B‑SIGNALS: función de limpieza ---
cleanup() {
    rm -f "$TEMP_PRICES" "$TEMP_SIGNALS"
    log "INFO" "Limpiando archivos temporales…"
}
trap cleanup INT TERM EXIT

log "INFO" "Iniciando auto_signal.sh para $SYMBOL ($PERIOD)"

if ! command -v python3 &> /dev/null; then
    log "ERROR" "python3 no está instalado"
    exit 1
fi

log "INFO" "Descargando datos de $SYMBOL…"
python3 "$SCRIPT_DIR/fetch_data.py" "$SYMBOL" "$PERIOD"

log "INFO" "Generando señales de cruce SMA…"
"$COBOL_DIR/sma_cross" "$SCRIPT_DIR/prices.dat" > "$TEMP_SIGNALS"

log "INFO" "Ejecutando motor de backtesting…"
metrics=$("$COBOL_DIR/trader" "$TEMP_SIGNALS")
log "INFO" "Métricas: $metrics"

log "INFO" "Solicitando señal al API…"
curl -s -X POST "${API_URL}/decision?symbol=${SYMBOL}&period=${PERIOD}" \
  -H "Content-Type: application/json" | python3 -m json.tool

log "INFO" "Script finalizado correctamente."
