import sys
import os
import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from api.server import app

client = TestClient(app)

# Test simple con precios mínimos para no depender de datos externos
def test_sma_integration():
    response = client.post("/sma", json={"prices": [100, 102, 101, 103, 104], "window": 3})
    assert response.status_code == 200
    assert "sma" in response.json()

def test_rsi_integration():
    response = client.post("/rsi", json={"prices": [100, 102, 101, 103, 104], "period": 3})
    assert response.status_code == 200
    assert "rsi" in response.json()

def test_macd_integration():
    response = client.post("/macd", json={"prices": [100, 102, 101, 103, 104]})
    assert response.status_code == 200
    assert "macd_line" in response.json()
