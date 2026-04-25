import sys
import os
import pytest
from unittest.mock import patch, MagicMock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from api.server import app
from fastapi.testclient import TestClient

client = TestClient(app)

@patch("api.server.run_cobol")
def test_sma_mocked(mock_run):
    mock_run.return_value = "102.50"
    response = client.post("/sma", json={"prices": [100, 102, 101, 103, 104], "window": 3})
    assert response.status_code == 200
    assert response.json()["sma"] == 102.50

@patch("api.server.run_cobol")
def test_rsi_mocked(mock_run):
    mock_run.return_value = "55"
    response = client.post("/rsi", json={"prices": [100, 102, 101, 103, 104], "period": 3})
    assert response.status_code == 200
    assert response.json()["rsi"] == 55

@patch("api.server.run_cobol")
def test_macd_mocked(mock_run):
    mock_run.return_value = "0.50 0.40 0.10"
    response = client.post("/macd", json={"prices": [100, 102, 101, 103, 104]})
    assert response.status_code == 200
    assert response.json()["macd_line"] == 0.50
    assert response.json()["histogram"] == 0.10

@patch("api.server.run_cobol")
def test_bollinger_mocked(mock_run):
    mock_run.return_value = "102.00 105.00 99.00"
    response = client.post("/bollinger", json={"prices": [100, 102, 101, 103, 104]})
    assert response.status_code == 200
    data = response.json()["bollinger"]
    assert len(data) == 1
    assert data[0]["upper"] == 105.00

@patch("api.server.run_cobol")
def test_atr_mocked(mock_run):
    mock_run.return_value = "2.50\n3.10\n1.80"
    response = client.post("/atr", json={"prices": [100, 102, 101, 103, 104]})
    assert response.status_code == 200
    assert response.json()["atr"] == [2.50, 3.10, 1.80]

@patch("api.server.run_cobol")
def test_stochastic_mocked(mock_run):
    mock_run.return_value = "45.00 50.00"
    response = client.post("/stochastic", json={"prices": [100, 102, 101, 103, 104], "k_period": 3, "d_period": 2})
    assert response.status_code == 200
    assert response.json()["stochastic"][0]["pct_k"] == 45.00

@patch("api.server.run_cobol")
def test_validation_empty_prices(mock_run):
    mock_run.return_value = "0"
    response = client.post("/sma", json={"prices": [], "window": 3})
    assert response.status_code == 400
    assert "vacío" in response.json()["detail"]
