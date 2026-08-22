"""NOTE: could not be executed in this repo's development sandbox (no
working Python runtime, no Postgres) — see packages/election_rules_py/tests
for details on what could and couldn't be verified in this build."""

from fastapi.testclient import TestClient

from app.main import app


def test_health_ok():
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert "product_name" in body


def test_openapi_schema_generates_without_error():
    client = TestClient(app)
    response = client.get("/openapi.json")
    assert response.status_code == 200
    schema = response.json()
    assert "/api/v1/forecast/latest" in schema["paths"]
