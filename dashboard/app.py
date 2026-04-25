import streamlit as st
import sqlite3
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import requests
import os
import json

DB_PATH = os.environ.get("DB_PATH", os.path.expanduser("~/trading-sim/data/trading.db"))
API_URL = os.environ.get("API_URL", "http://localhost:8000")

st.set_page_config(page_title="Trading Simulator", layout="wide")
st.title("📊 Simulador de Trading Algorítmico COBOL + Python")

tab1, tab2, tab3 = st.tabs(["📊 Rendimiento", "📈 Señales", "🕯️ Velas"])

with tab1:
    st.subheader("Resultados del Backtesting")
    try:
        conn = sqlite3.connect(DB_PATH)
        df = pd.read_sql("SELECT * FROM backtests ORDER BY created_at DESC LIMIT 1", conn)
        conn.close()
        if not df.empty:
            last = df.iloc[0]
            col1, col2, col3 = st.columns(3)
            col1.metric("Capital Final", f"${last['final_equity']:,.2f}")
            col2.metric("P&L", f"${last['pnl']:,.2f}", delta=f"{last['pnl']/10000*100:.1f}%")
            col3.metric("Win Rate", f"{last['win_rate']:.1f}%")
            equity_data = json.loads(last['equity_curve'])
            if equity_data:
                df_eq = pd.DataFrame(equity_data)
                df_eq['date'] = pd.to_datetime(df_eq['date'], utc=True)
                fig = go.Figure()
                fig.add_trace(go.Scatter(x=df_eq['date'], y=df_eq['equity'], mode='lines', name='Estrategia', line=dict(color='cyan')))
                fig.add_hline(y=10000, line_dash="dash", line_color="gray", annotation_text="Capital Inicial")
                fig.update_layout(template="plotly_dark", title="Curva de Equity", xaxis_title="Fecha", yaxis_title="Capital ($)")
                st.plotly_chart(fig, use_container_width=True)
            trades_data = json.loads(last['trades'])
            if trades_data:
                st.subheader("Últimas Operaciones")
                st.dataframe(pd.DataFrame(trades_data), use_container_width=True)
        else:
            st.info("No hay backtests todavía. Ejecutá: python3 backtest_strategy.py MSFT 2y")
    except Exception as e:
        st.error(f"No se pudieron cargar los datos: {e}")

with tab2:
    with st.sidebar:
        st.header("Generar Señal Manual")
        symbol = st.text_input("Símbolo", value="TEST")
        indicator = st.selectbox("Indicador", ["SMA", "RSI", "MACD", "BOLLINGER", "ATR"])
        period = st.slider("Período", 2, 26, 14)
        prices_input = st.text_area("Precios (uno por línea)", value="100\n102.5\n101.75\n103\n104.2\n105")
        if st.button("Calcular y guardar"):
            prices = [float(p.strip()) for p in prices_input.strip().split('\n') if p.strip()]
            payload = {"prices": prices, "symbol": symbol, "period": period}
            try:
                response = requests.post(f"{API_URL}/{indicator.lower()}", json=payload)
                if response.status_code == 200:
                    st.success(f"{indicator} calculada: {response.json()}")
                    st.rerun()
                else:
                    st.error(f"Error: {response.json()['detail']}")
            except Exception as e:
                st.error(f"No se pudo conectar a la API: {e}")
    st.subheader("Curva de Equity Simulada")
    conn = sqlite3.connect(DB_PATH)
    df_signals = pd.read_sql("SELECT * FROM signals ORDER BY created_at", conn)
    conn.close()
    if not df_signals.empty:
        df_signals['equity'] = 10000.0
        for i in range(1, len(df_signals)):
            prev_val = df_signals.iloc[i]['value']
            curr_val = df_signals.iloc[i-1]['value']
            df_signals.loc[i, 'equity'] = df_signals.loc[i-1, 'equity'] * (1.005 if curr_val > prev_val else 0.998)
        st.line_chart(df_signals.set_index('created_at')['equity'])
    else:
        st.info("Sin señales. Generá una desde la barra lateral.")

with tab3:
    st.subheader("🕯️ Velas de ejemplo")
    dates = pd.date_range(start="2025-01-01", periods=30, freq="D")
    close = 100 + np.cumsum(np.random.randn(30) * 2)
    df_candles = pd.DataFrame({
        "Date": dates,
        "Open": close - np.random.rand(30),
        "High": close + np.random.rand(30),
        "Low": close - np.random.rand(30)*2,
        "Close": close
    })
    fig = go.Figure(data=[go.Candlestick(
        x=df_candles["Date"],
        open=df_candles["Open"],
        high=df_candles["High"],
        low=df_candles["Low"],
        close=df_candles["Close"]
    )])
    fig.update_layout(template="plotly_dark", xaxis_rangeslider_visible=False)
    st.plotly_chart(fig, use_container_width=True)
