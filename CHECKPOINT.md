# Checkpoint / Restart en Batch COBOL

Este documento sigue el bloque **B‑CHECKPOINT** de la especificación v19.

## Patrón canónico

1. **Al iniciar:** abrir archivo de checkpoint.
   - Si existe y está íntegro → leer último registro procesado.
   - Si no existe → ejecución inicial.
   - Si existe pero está corrupto → loguear, alertar, ejecutar desde cero.

2. **Durante el procesamiento:** cada N registros (1000‑5000 según criticidad):
   - Guardar en el archivo de checkpoint:
     - Identificador del job
     - Número de checkpoint (secuencial)
     - Último registro procesado exitosamente
     - Acumuladores y totales parciales
     - Timestamp

3. **Al finalizar exitosamente:** borrar el archivo de checkpoint.

4. **Ante falla:** el archivo de checkpoint persiste.
   La próxima ejecución retoma desde el último checkpoint.

## Aplicación en el proyecto

El script `auto_signal.sh` implementa checkpoint a nivel de archivo de datos:
- Guarda la última fecha procesada en `.checkpoint_<SYMBOL>`.
- Si el script falla, la próxima ejecución retoma desde esa fecha.

Para un batch COBOL puro (sin Python), el patrón completo está descrito
en el bloque B‑CHECKPOINT del prompt.
