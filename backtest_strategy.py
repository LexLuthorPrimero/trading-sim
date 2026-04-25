#!/usr/bin/env python3
"""Backtest con cruce de SMA usando COBOL (sma_cross + trader)."""
import yfinance as yf
import subprocess
import os
import sys
import json
import sqlite3

COBOL_DIR = os.path.join(os.path.dirname(__file__), "cobol")
DB_PATH = os.path.expanduser("~/trading-sim/data/trading.db")

def run_cobol(program, input_file=None):
    cmd = [os.path.join(COBOL_DIR, program)]
    if input_file:
        cmd.append(input_file)
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        raise RuntimeError(f"COBOL error: {result.stderr}")
    return result.stdout.strip()

def main():
    symbol = sys.argv[1] if len(sys.argv) > 1 else "MSFT"
    period = sys.argv[2] if len(sys.argv) > 2 else "6mo"
    
    print(f"Descargando {symbol} ({period})...")
    ticker = yf.Ticker(symbol)
    df = ticker.history(period=period)
    if df.empty:
        print("Sin datos"); return
    
    closes = df['Close'].tolist()
    prices_file = "/tmp/backtest_prices.dat"
    with open(prices_file, "w") as f:
        for p in closes:
            f.write(f"{p:.2f}\n")
    
    print("Generando señales de cruce SMA...")
    signals = run_cobol("sma_cross", prices_file)
    
    signals_file = "/tmp/backtest_signals.txt"
    with open(signals_file, "w") as f:
        f.write(signals)
    
    print("Ejecutando motor de backtesting...")
    metrics = run_cobol("trader", signals_file)
    parts = metrics.split()
    if len(parts) != 3:
        print(f"Error: formato inesperado de métricas: {metrics}")
        return
    
    capital, trades, wins = float(parts[0]), int(parts[1]), int(parts[2])
    win_rate = (wins / trades * 100) if trades > 0 else 0
    pnl = capital - 10000
    
    print(f"\n===== RESULTADOS =====")
    print(f"Capital final: ${capital:,.2f} | P&L: ${pnl:,.2f}")
    print(f"Trades: {trades} | Win rate: {win_rate:.1f}%")
    
    conn = sqlite3.connect(DB_PATH)
    conn.execute('''CREATE TABLE IF NOT EXISTS backtests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol TEXT, period TEXT, initial_capital REAL, final_equity REAL,
        pnl REAL, total_trades INTEGER, win_rate REAL,
        trades TEXT, equity_curve TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)''')
    
    equity_curve = [{"date": str(df.index[i]), "equity": 10000 + (closes[i] - closes[0]) * trades} for i in range(len(closes))]
    
    conn.execute(
        "INSERT INTO backtests (symbol,period,initial_capital,final_equity,pnl,total_trades,win_rate,trades,equity_curve) VALUES (?,?,?,?,?,?,?,?,?)",
        (symbol, period, 10000, round(capital,2), round(pnl,2), trades, round(win_rate,1),
         json.dumps([]), json.dumps(equity_curve))
    )
    conn.commit()
    conn.close()
    print("Guardado en DB.")

if __name__ == "__main__":
    main()
