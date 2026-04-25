FROM debian:stable-slim AS builder
RUN apt-get update && apt-get install -y gnucobol && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY cobol/ ./cobol/
RUN cd cobol && \
    cobc -x -o sma sma.cob && \
    cobc -x -o rsi rsi.cob && \
    cobc -x -o macd macd.cob && \
    cobc -x -o bollinger bollinger.cob && \
    cobc -x -o atr atr.cob && \
    cobc -x -o stochastic stochastic.cob && \
    cobc -x -o sma_cross sma_cross.cob && \
    cobc -x -o trader trader.cob

FROM python:3.12-slim
RUN apt-get update && apt-get install -y gnucobol curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/cobol/ /app/cobol/
COPY api/requirements.txt /app/api/requirements.txt
RUN pip install --no-cache-dir -r /app/api/requirements.txt
COPY api/ /app/api/
ENV COBOL_DIR=/app/cobol
ENV DB_PATH=/app/data/trading.db
RUN mkdir -p /app/data
CMD ["python", "-m", "uvicorn", "api.server:app", "--host", "0.0.0.0", "--port", "8000"]
