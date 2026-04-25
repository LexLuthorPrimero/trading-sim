#!/usr/bin/env python3
"""Descarga datos de Yahoo Finance y genera precios.dat para COBOL."""
import yfinance as yf
import sys
import os

SYMBOL = sys.argv[1] if len(sys.argv) > 1 else "AAPL"
PERIOD = sys.argv[2] if len(sys.argv) > 2 else "6mo"

def main():
    ticker = yf.Ticker(SYMBOL)
    df = ticker.history(period=PERIOD)
    
    # Para ATR/Stochastic (requieren HIGH, LOW, CLOSE)
    atr_file = os.path.join(os.path.dirname(__file__), "prices_atr.dat")
    with open(atr_file, "w") as f:
        for _, row in df.iterrows():
            f.write(f"{row['High']:.2f},{row['Low']:.2f},{row['Close']:.2f}\n")
    
    # Para SMA/RSI/MACD/Bollinger (solo CLOSE)
    prices_file = os.path.join(os.path.dirname(__file__), "prices.dat")
    with open(prices_file, "w") as f:
        for _, row in df.iterrows():
            f.write(f"{row['Close']:.2f}\n")
    
    print(f"Datos de {SYMBOL} descargados: {len(df)} velas en {atr_file} y {prices_file}")

if __name__ == "__main__":
    main()
