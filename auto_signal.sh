#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_URL="${API_URL:?Se requiere definir API_URL}"
SYMBOL="${1:-AAPL}"
PERIOD="${2:-6mo}"
TEMP_PRICES="/tmp/prices_$$.dat"
TEMP_SIGNALS="/tmp/signals_$$.txt"
COBOL_DIR="${COBOL_DIR:?Se requiere definir COBOL_DIR}"
CHECKPOINT_FILE="$SCRIPT_DIR/.checkpoint_${SYMBOL}"
CORRELATION_ID="$(date +%s)-$$"

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$level] [CID=$CORRELATION_ID] $message" >&2
}

cleanup() {
    rm -f "$TEMP_PRICES" "$TEMP_SIGNALS"
    log "INFO" "Limpiando archivos temporales…"
}
trap cleanup INT TERM EXIT

log "INFO" "Iniciando auto_signal.sh para $SYMBOL ($PERIOD)"

# --- B-CHECKPOINT: Leer estado anterior ---
START_DATE=""
if [ -f "$CHECKPOINT_FILE" ]; then
    log "INFO" "Encontrado checkpoint en $CHECKPOINT_FILE"
    read -r cnt date_start date_end < "$CHECKPOINT_FILE"
    if [ -n "$date_end" ] && [ "$date_end" != "None" ]; then
        log "INFO" "Última fecha procesada: $date_end. Retomando desde allí."
        START_DATE="$date_end"
    else
        log "WARN" "Checkpoint corrupto o incompleto. Iniciando desde cero."
        rm -f "$CHECKPOINT_FILE"
        START_DATE=""
    fi
else
    log "INFO" "Sin checkpoint previo. Iniciando desde cero."
fi

log "INFO" "Descargando datos de $SYMBOL desde $START_DATE…"
python3 "$SCRIPT_DIR/fetch_data.py" "$SYMBOL" "$PERIOD" "$START_DATE"

# --- B-CHECKPOINT: Guardar progreso ---
# --- B-STRMANIP: extraer último registro sin cut ---
prices_file="$SCRIPT_DIR/prices.dat"
last_line=$(tail -1 "$prices_file" 2>/dev/null || true)
if [ -n "$last_line" ]; then
    # El archivo prices.dat tiene formato YYYY-MM-DD,OPEN,HIGH,LOW,CLOSE,VOLUME
    # Extraemos la fecha (primer campo antes de la primera coma)
    last_date="${last_line%%,*}"
    # Si no hay coma, asumimos que es solo un número (precio simple)
    if [ "$last_date" = "$last_line" ]; then
        last_date=$(date +%Y-%m-%d)
    fi
else
    last_date="None"
fi
echo "$(date +%s) $(date +%Y-%m-%d) $last_date" > "$CHECKPOINT_FILE"
log "INFO" "Checkpoint guardado: último registro procesado $last_date"

# --- B-FILEPROC: validar archivo de precios antes de COBOL ---

# --- B-BACKUP: backup de archivos de datos antes de procesar ---
log "INFO" "Haciendo backup de archivos de datos..."
cp "$prices_file" "$prices_file.$(date +%Y%m%d_%H%M%S).bak"
cp "$SCRIPT_DIR/data/trading.db" "$SCRIPT_DIR/data/trading.db.$(date +%Y%m%d_%H%M%S).bak" 2>/dev/null || true
log "INFO" "Validando archivo de precios..."
"$SCRIPT_DIR/validate_prices.sh" "$prices_file" 10

log "INFO" "Generando señales de cruce SMA…"
"$COBOL_DIR/sma_cross" "$prices_file" > "$TEMP_SIGNALS"

log "INFO" "Ejecutando motor de backtesting…"
metrics=$("$COBOL_DIR/trader" "$TEMP_SIGNALS")
log "INFO" "Métricas: $metrics"

log "INFO" "Solicitando señal al API…"
curl -s -X POST "${API_URL}/decision?symbol=${SYMBOL}&period=${PERIOD}" \
  -H "Content-Type: application/json" | python3 -m json.tool

log "INFO" "Script finalizado correctamente."
rm -f "$CHECKPOINT_FILE"
