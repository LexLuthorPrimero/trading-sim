"""SQLite database for trading simulator."""
import sqlite3
import os
from datetime import datetime

DB_PATH = os.environ.get("DB_PATH", "trading.db")

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_connection()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS signals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            indicator TEXT NOT NULL,
            symbol TEXT NOT NULL,
            value REAL NOT NULL,
            window INTEGER,
            prices TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS equity (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            balance REAL NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS trades (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            symbol TEXT NOT NULL,
            entry_price REAL NOT NULL,
            exit_price REAL,
            quantity INTEGER DEFAULT 1,
            entry_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            exit_time TIMESTAMP,
            profit REAL
        );
    """)
    conn.commit()
    conn.close()

def save_signal(indicator, symbol, value, window=None, prices=None):
    conn = get_connection()
    conn.execute(
        "INSERT INTO signals (indicator, symbol, value, window, prices) VALUES (?, ?, ?, ?, ?)",
        (indicator, symbol, value, window, prices)
    )
    conn.commit()
    conn.close()

def get_signals(indicator=None, limit=50):
    conn = get_connection()
    if indicator:
        rows = conn.execute(
            "SELECT * FROM signals WHERE indicator = ? ORDER BY created_at DESC LIMIT ?",
            (indicator, limit)
        ).fetchall()
    else:
        rows = conn.execute(
            "SELECT * FROM signals ORDER BY created_at DESC LIMIT ?",
            (limit,)
        ).fetchall()
    conn.close()
    return [dict(r) for r in rows]
