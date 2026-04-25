# Deuda Técnica – Trading Simulator

## Criterios de registro

Cada item incluye:
- **Descripción:** qué atajo se tomó.
- **Impacto:** qué pasaría si no se resuelve.
- **Plan de resolución:** cuándo y cómo abordarlo.
- **Fecha de revisión sugerida:** próxima ventana de mantenimiento.

---

## Items pendientes

| ID | Descripción | Impacto | Plan de resolución | Fecha de revisión |
| :--- | :--- | :--- | :--- | :--- |
| D‑001 | El filtro de debug en `run_cobol()` asume que las líneas de log empiezan con `[DEBUG]`. Si se cambia el formato de los logs en COBOL, la API podría romperse. | La API devolvería valores incorrectos o fallaría al parsear stdout. | Definir un contrato formal de salida: COBOL debe imprimir primero las líneas de debug y en la última línea el valor calculado. Documentar en README. | 2026‑05‑15 |
| D‑002 | Los programas COBOL usan `OCCURS 1000 TIMES` para las tablas de precios. Si se reciben más de 1000 registros, el programa falla. | Desbordamiento de tabla y pérdida de datos. | Migrar a archivos INDEXED con acceso dinámico, o usar `OCCURS DEPENDING ON` con límite configurable. | 2026‑06‑01 |
| D‑003 | La estrategia de trading combinada (`strategy.cob`) usa umbrales fijos (RSI 45/55, MACD > 0). No se realizó optimización con backtesting histórico. | Las señales pueden no ser óptimas para los activos actuales. | Ejecutar backtest con diferentes umbrales y seleccionar los mejores según Sharpe ratio o profit factor. | 2026‑05‑30 |
| D‑004 | La API de Alpaca no está probada con credenciales reales. El código fue escrito pero no validado contra el endpoint real. | El módulo de trading no funcionará en producción. | Obtener credenciales de Alpaca y probar `/account` y `/trade-signal` con órdenes paper. | 2026‑05‑20 |
| D‑005 | El dashboard muestra velas con datos aleatorios de ejemplo, no conectados a la API real de Yahoo Finance. | La sección de "Velas" no refleja datos reales. | Conectar el endpoint `/bollinger` o `/macd` al gráfico de velas con datos descargados de Yahoo Finance. | 2026‑06‑10 |
| D‑006 | Los tests de integración requieren que la variable `COBOL_DIR` esté definida manualmente. Si no se configura, los tests fallan. | Falsos negativos en CI/CD. | Agregar un fixture de pytest que detecte automáticamente la ruta de los binarios COBOL, o definir un valor por defecto robusto en `conftest.py`. | 2026‑05‑25 |

---

## Revisión periódica

- **Frecuencia:** cada 2 semanas durante el desarrollo activo.
- **Responsable:** Lucas Cañete.
- **Estado al 2026‑04‑25:** 6 items pendientes, 0 resueltos.

> Este archivo sigue el bloque **B‑DEBT** del prompt **MODO ADAPTATIVO CONTEXTUAL v17**.
