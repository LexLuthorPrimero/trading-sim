#!/usr/bin/env python3
"""Backtest con cruce de MACD usando COBOL."""
import yfinance as yf, subprocess, os, sys, json, sqlite3

COBOL_DIR = os.path.join(os.path.dirname(__file__), "cobol")
DB_PATH = os.path.expanduser("~/trading-sim/trading.db")

def run_cobol(program, input_data):
    with open("/tmp/cobol_input.dat", "w") as f:
        f.write(input_data)
    result = subprocess.run([os.path.join(COBOL_DIR, program), "/tmp/cobol_input.dat"],
                            capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        raise RuntimeError(f"COBOL error: {result.stderr}")
    return result.stdout.strip()

def calculate_macd(prices):
    data = "\n".join(f"{p:.2f}" for p in prices[-26:])
    parts = run_cobol("macd", data).split()
    return float(parts[0]) if parts else 0.0

def evaluate_strategy(macd_curr, macd_prev):
    data = f"{macd_curr:.2f},{macd_prev:.2f}\n"
    return run_cobol("strategy", data).strip()

def main():
    symbol = sys.argv[1] if len(sys.argv) > 1 else "MSFT"
    period = sys.argv[2] if len(sys.argv) > 2 else "6mo"
    capital, position = 10000.0, 0
    trades, equity_curve = [], []
    prev_macd = 0.0

    print(f"Descargando {symbol} ({period})...")
    ticker = yf.Ticker(symbol)
    df = ticker.history(period=period)
    if df.empty:
        print("Sin datos"); return
    closes = df['Close'].tolist()

    for i in range(60, len(closes)):
        try:
            macd_curr = calculate_macd(closes[:i+1])
            decision = evaluate_strategy(macd_curr, prev_macd)
            price = closes[i]
            date = df.index[i]

            if decision == "BUY " and position == 0:
                position = capital / price
                capital = 0
                trades.append({"date": str(date), "action": "BUY", "price": price, "value": position * price})
            elif decision == "SELL" and position > 0:
                capital = position * price
                position = 0
                trades.append({"date": str(date), "action": "SELL", "price": price, "value": capital})

            equity_curve.append({"date": str(date), "equity": capital + position * price})
            prev_macd = macd_curr
        except Exception as e:
            continue

    final_equity = capital + position * closes[-1]
    pnl = final_equity - 10000
    win_trades = sum(1 for t in trades if t['action'] == 'SELL' and t['value'] > 10000)
    total_trades = len([t for t in trades if t['action'] == 'SELL'])
    win_rate = (win_trades / total_trades * 100) if total_trades > 0 else 0

    print(f"\n===== RESULTADOS =====")
    print(f"Capital final: ${final_equity:,.2f} | P&L: ${pnl:,.2f}")
    print(f"Trades: {total_trades} | Win rate: {win_rate:.1f}%")

    conn = sqlite3.connect(DB_PATH)
    conn.execute('''CREATE TABLE IF NOT EXISTS backtests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        symbol TEXT, period TEXT, initial_capital REAL, final_equity REAL,
        pnl REAL, total_trades INTEGER, win_rate REAL,
        trades TEXT, equity_curve TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)''')
    conn.execute("INSERT INTO backtests (symbol,period,initial_capital,final_equity,pnl,total_trades,win_rate,trades,equity_curve) VALUES (?,?,?,?,?,?,?,?,?)",
                 (symbol, period, 10000, round(final_equity,2), round(pnl,2), total_trades, round(win_rate,1),
                  json.dumps(trades), json.dumps(equity_curve)))
    conn.commit(); conn.close()
    print("Guardado en DB.")

if __name__ == "__main__":
    main()
