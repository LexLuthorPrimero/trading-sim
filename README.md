# Trading Simulator – COBOL + Python  

Sistema de trading algorítmico que utiliza **COBOL** para calcular 6 indicadores técnicos con datos reales de Yahoo Finance, orquestado por una **API FastAPI** y visualizado en un **dashboard Streamlit**.  

## Indicadores  

| Indicador | Descripción |  
| :--- | :--- |  
| SMA | Media Móvil Simple |  
| RSI | Fuerza Relativa (sobrecompra/sobreventa) |  
| MACD | Convergencia/Divergencia de Medias Móviles |  
| Bollinger | Bandas de Bollinger (volatilidad) |  
| ATR | Rango Verdadero Promedio (volatilidad) |  
| Stochastic | Oscilador Estocástico (momentum) |  

## Calidad COBOL aplicada  

- Tipos financieros `COMP-3` y `COMP` (B‑NUM)  
- `FILE STATUS` verificado en cada operación (B‑ARCH / B‑FSTATUS)  
- Párrafos numerados (`1000-INICIO` … `9999-ERROR`) (B‑NAMING)  
- Rutina de lectura extraída a COPY books (B‑COPY)  
- Logs de depuración en cada párrafo (B‑DEBUG)  
- Validación de entradas numéricas (B‑VALID)  

## Arquitectura  

```text
Yahoo Finance → fetch_data.py → archivos .dat  
                         ↓  
                COBOL (6 indicadores + 2 COPY books)  
                         ↓  
                FastAPI (endpoints REST en :8000)  
                         ↓  
                SQLite (persistencia de señales y backtests)  
                         ↓  
                Streamlit (dashboard en :8500)  

Ejecución
bash

docker compose up --build -d  
# API → http://localhost:8000/docs  
# Dashboard → http://localhost:8501  

Endpoints
Método	Ruta	Descripción
POST	/sma	Media Móvil Simple
POST	/rsi	Fuerza Relativa
POST	/macd	MACD
POST	/bollinger	Bandas de Bollinger
POST	/atr	Rango Verdadero Promedio
POST	/stochastic	Oscilador Estocástico
GET	/signals	Señales guardadas
GET	/health	Estado de la API
Tecnologías

COBOL Python FastAPI Streamlit Docker Compose SQLite GitHub Actions Yahoo Finance
Autor

Lucas Cañete – Estudiante de Ingeniería Informática (UBA)
GitHub | LinkedIn
