from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List, Optional, Callable, Dict, Any
import functools, subprocess, tempfile, os, json
from pathlib import Path
from api.database import init_db, save_signal, get_signals

app = FastAPI(title="Trading Simulator API")
COBOL_DIR = Path(os.environ.get("COBOL_DIR", "/app/cobol"))

class IndicatorRequest(BaseModel):
    prices: List[float]
    period: Optional[int] = None
    window: Optional[int] = None
    k_period: Optional[int] = None
    d_period: Optional[int] = None
    symbol: str = "TEST"

def require_valid_prices(func: Callable):
    @functools.wraps(func)
    def wrapper(req: IndicatorRequest):
        if not req.prices or len(req.prices) == 0:
            raise HTTPException(status_code=400, detail="El campo 'prices' está vacío")
        if not all(isinstance(p, (int, float)) and p > 0 for p in req.prices):
            raise HTTPException(status_code=400, detail="Todos los precios deben ser numéricos y positivos")
        return func(req)
    return wrapper

def run_cobol(program: str, input_data: str) -> str:
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

IndicatorProcessor = Callable[[str], Dict[str, Any]]

def make_indicator_endpoint(
    indicator: str,
    processor: IndicatorProcessor,
    period_key: str = "period",
    period_default: int = 14,
    value_key: str = "value"
) -> Callable:
    """Factory de endpoints DRY: valida, ejecuta COBOL, procesa y persiste."""
    @app.post(f"/{indicator}")
    @require_valid_prices
    @functools.wraps(processor)
    def endpoint(req: IndicatorRequest):
        data = run_cobol(indicator, "\n".join(f"{p:.2f}" for p in req.prices))
        result = processor(data)
        period = getattr(req, period_key, None) or period_default
        save_signal(indicator.upper(), req.symbol, result.get(value_key, 0), period, json.dumps(req.prices))
        return {**result, "symbol": req.symbol, period_key: period}
    return endpoint

def sma_processor(data: str) -> Dict[str, Any]:
    return {"sma": float(data.strip())}

def rsi_processor(data: str) -> Dict[str, Any]:
    return {"rsi": float(data.strip())}

def macd_processor(data: str) -> Dict[str, Any]:
    parts = data.strip().split()
    return {
        "macd_line": float(parts[0]) if len(parts) > 0 else 0.0,
        "signal_line": float(parts[1]) if len(parts) > 1 else 0.0,
        "histogram": float(parts[2]) if len(parts) > 2 else 0.0
    }

def bollinger_processor(data: str) -> Dict[str, Any]:
    lines = data.strip().split('\n')
    output = []
    for line in lines:
        parts = line.split()
        if len(parts) == 3:
            output.append({"price": float(parts[0]), "upper": float(parts[1]), "lower": float(parts[2])})
    return {"bollinger": output, "value": output[-1]["upper"] if output else 0}

def atr_processor(data: str) -> Dict[str, Any]:
    values = [float(x) for x in data.strip().split('\n') if x]
    return {"atr": values, "value": values[-1] if values else 0}

def stochastic_processor(data: str) -> Dict[str, Any]:
    lines = data.strip().split('\n')
    output = []
    for line in lines:
        parts = line.split()
        if len(parts) == 2:
            output.append({"pct_k": float(parts[0]), "pct_d": float(parts[1])})
    return {"stochastic": output, "value": output[-1]["pct_k"] if output else 0}

make_indicator_endpoint("sma", sma_processor, period_key="window", period_default=5)
make_indicator_endpoint("rsi", rsi_processor, period_key="period", period_default=14)
make_indicator_endpoint("macd", macd_processor, period_key="period", period_default=12, value_key="macd_line")
make_indicator_endpoint("bollinger", bollinger_processor, period_key="period", period_default=20, value_key="value")
make_indicator_endpoint("atr", atr_processor, period_key="period", period_default=14, value_key="value")
make_indicator_endpoint("stochastic", stochastic_processor, period_key="k_period", period_default=14, value_key="value")

@app.on_event("startup")
def startup():
    init_db()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/signals")
def list_signals(indicator: Optional[str] = None, limit: int = 50):
    return get_signals(indicator, limit)
