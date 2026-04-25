import pytest
from fastapi.testclient import TestClient
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from api.server import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_sma_valid():
    response = client.post("/sma", json={
        "prices": [100, 102.5, 101.75, 103, 104.2, 105],
        "window": 5
    })
    assert response.status_code == 200
    data = response.json()
    assert "sma" in data
    assert 103 < data["sma"] < 104
