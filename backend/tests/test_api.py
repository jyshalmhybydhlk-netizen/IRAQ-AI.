import os

os.environ['AI_PROVIDER'] = 'ollama'
os.environ['DATABASE_URL'] = 'sqlite:///./test_iraq_ai.db'

from fastapi.testclient import TestClient
from app.main import app


def test_health():
    with TestClient(app) as client:
        response = client.get('/health')
        assert response.status_code == 200
        assert response.json()['status'] == 'ok'


def test_ready():
    with TestClient(app) as client:
        assert client.get('/ready').status_code == 200


def test_empty_message_rejected():
    with TestClient(app) as client:
        response = client.post('/api/v1/chat', json={'message': ''})
        assert response.status_code == 422
