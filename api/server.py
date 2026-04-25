from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List, Optional
import subprocess, tempfile, os, json
from pathlib import Path
from api.database import init_db, save_signal, get_signals, get_connection

app = FastAPI(title="Trading Simulator API")
COBOL_DIR = Path(os.environ.get("COBOL_DIR", "/app/cobol"))

class IndicatorRequest(BaseModel):
    prices: List[float]
    period: Optional[int] = None
    window: Optional[int] = None
    k_period: Optional[int] = None
    d_period: Optional[int] = None
    symbol: str = "TEST"

@app.on_event("startup")
def startup():
    init_db()

def run_cobol(program, input_data):
    with tempfile.NamedTemporaryFile(mode='w', suffix='.dat', delete=False) as f:
        f.write(input_data)
        input_file = f.name
    try:
        binary = str(COBOL_DIR / program)
        result = subprocess.run([binary, input_file], capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            raise RuntimeError(result.stderr)
        return result.stdout.strip()
    finally:
        os.unlink(input_file)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/sma")
def sma(req: IndicatorRequest):
    # B-VALID: validar entrada
    if not req.prices or len(req.prices) == 0:
        raise HTTPException(status_code=400, detail="El campo prices esta vacio")
    if not all(isinstance(p, (int, float)) and p > 0 for p in req.prices):
        raise HTTPException(status_code=400, detail="Todos los precios deben ser numericos y positivos")
    
    data = run_cobol("sma", "\n".join(f"{p:.2f}" for p in req.prices))
    val = float(data)
    save_signal("SMA", req.symbol, val, req.window or 5, json.dumps(req.prices))
    return {"sma": val, "window": req.window, "symbol": req.symbol}

@app.post("/rsi")
def rsi(req: IndicatorRequest):
    data = run_cobol("rsi", "\n".join(f"{p:.2f}" for p in req.prices))
    val = float(data)
    save_signal("RSI", req.symbol, val, req.period or 14, json.dumps(req.prices))
    return {"rsi": val, "period": req.period, "symbol": req.symbol}

@app.post("/macd")
def macd(req: IndicatorRequest):
    data = run_cobol("macd", "\n".join(f"{p:.2f}" for p in req.prices))
    parts = data.split()
    macd_line = float(parts[0]) if len(parts) > 0 else 0.0
    signal_line = float(parts[1]) if len(parts) > 1 else 0.0
    histogram = float(parts[2]) if len(parts) > 2 else 0.0
    save_signal("MACD", req.symbol, macd_line, None, json.dumps(req.prices))
    return {"macd_line": macd_line, "signal_line": signal_line, "histogram": histogram}

@app.post("/bollinger")
def bollinger(req: IndicatorRequest):
    input_data = "\n".join(f"{p:.2f}" for p in req.prices)
    data = run_cobol("bollinger", input_data)
    lines = data.strip().split('\n')
    output = []
    for line in lines:
        parts = line.split()
        if len(parts) == 3:
            output.append({"price": float(parts[0]), "upper": float(parts[1]), "lower": float(parts[2])})
    save_signal("BOLLINGER", req.symbol, output[-1]["upper"] if output else 0, req.period or 20, json.dumps(req.prices))
    return {"bollinger": output, "period": req.period, "symbol": req.symbol}

@app.post("/atr")
def atr(req: IndicatorRequest):
    data = run_cobol("atr", "\n".join(f"{p:.2f}" for p in req.prices))
    values = [float(x) for x in data.strip().split('\n') if x]
    save_signal("ATR", req.symbol, values[-1] if values else 0, req.period or 14, json.dumps(req.prices))
    return {"atr": values, "period": req.period, "symbol": req.symbol}

@app.post("/stochastic")
def stochastic(req: IndicatorRequest):
    data = run_cobol("stochastic", "\n".join(f"{p:.2f}" for p in req.prices))
    lines = data.strip().split('\n')
    output = []
    for line in lines:
        parts = line.split()
        if len(parts) == 2:
            output.append({"pct_k": float(parts[0]), "pct_d": float(parts[1])})
    save_signal("STOCHASTIC", req.symbol, output[-1]["pct_k"] if output else 0, req.k_period or 14, json.dumps(req.prices))
    return {"stochastic": output, "k_period": req.k_period, "d_period": req.d_period, "symbol": req.symbol}

@app.post("/decision")
def decision(symbol: str = "MSFT", period: str = "6mo"):
    try:
        import yfinance as yf
        ticker = yf.Ticker(symbol)
        df = ticker.history(period=period)
        if df.empty:
            raise HTTPException(status_code=404, detail="No data")
        closes = df['Close'].tolist()
        macd_val = run_cobol("macd", "\n".join(f"{p:.2f}" for p in closes[-26:]))
        parts = macd_val.split()
        macd_line = float(parts[0]) if parts else 0.0
        if macd_line > 0.01:
            signal = "BUY"
        elif macd_line < -0.01:
            signal = "SELL"
        else:
            signal = "HOLD"
        return {"symbol": symbol, "signal": signal, "macd": macd_line}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/signals")
def list_signals(indicator: Optional[str] = None, limit: int = 50):
    return get_signals(indicator, limit)
