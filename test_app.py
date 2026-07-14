"""
Unit tests for the Flask CI/CD demo application.
Run with:  pytest test_app.py -v
"""
import json
import os
import pytest

# Set environment before importing app so config picks it up
os.environ["APP_ENV"] = "testing"

from app import app  # noqa: E402


@pytest.fixture
def client():
    """Return a Flask test client with testing mode enabled."""
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


# ── Homepage ──────────────────────────────────────────────────────────────────

class TestHomepage:
    def test_homepage_returns_200(self, client):
        resp = client.get("/")
        assert resp.status_code == 200

    def test_homepage_content_type_is_html(self, client):
        resp = client.get("/")
        assert "text/html" in resp.content_type

    def test_homepage_contains_deployment_success(self, client):
        data = resp = client.get("/").data.decode()
        assert "Deployment Successful" in data or "Successfully Deployed" in data

    def test_homepage_contains_github_actions(self, client):
        data = client.get("/").data.decode()
        assert "GitHub Actions" in data

    def test_homepage_contains_docker(self, client):
        data = client.get("/").data.decode()
        assert "Docker" in data

    def test_homepage_contains_aws_ec2(self, client):
        data = client.get("/").data.decode()
        assert "AWS EC2" in data

    def test_homepage_contains_hostname(self, client):
        data = client.get("/").data.decode()
        assert "Hostname" in data

    def test_homepage_contains_python_version(self, client):
        data = client.get("/").data.decode()
        assert "Python Version" in data

    def test_homepage_contains_environment(self, client):
        data = client.get("/").data.decode()
        assert "Environment" in data


# ── Health endpoint ───────────────────────────────────────────────────────────

class TestHealthEndpoint:
    def test_health_returns_200(self, client):
        resp = client.get("/health")
        assert resp.status_code == 200

    def test_health_content_type_is_json(self, client):
        resp = client.get("/health")
        assert resp.content_type == "application/json"

    def test_health_status_field_is_healthy(self, client):
        resp = client.get("/health")
        body = json.loads(resp.data)
        assert body["status"] == "healthy"

    def test_health_has_timestamp(self, client):
        resp = client.get("/health")
        body = json.loads(resp.data)
        assert "timestamp" in body

    def test_health_has_hostname(self, client):
        resp = client.get("/health")
        body = json.loads(resp.data)
        assert "hostname" in body

    def test_health_has_environment(self, client):
        resp = client.get("/health")
        body = json.loads(resp.data)
        assert body["environment"] == "testing"


# ── Info endpoint ─────────────────────────────────────────────────────────────

class TestInfoEndpoint:
    def test_info_returns_200(self, client):
        resp = client.get("/info")
        assert resp.status_code == 200

    def test_info_content_type_is_json(self, client):
        resp = client.get("/info")
        assert resp.content_type == "application/json"

    def test_info_has_python_version(self, client): 
        resp = client.get("/info")
        body = json.loads(resp.data)
        assert "python_version" in body
        assert body["python_version"].startswith("3.")

    def test_info_has_platform(self, client):
        resp = client.get("/info")
        body = json.loads(resp.data)
        assert "platform" in body

    def test_info_has_container(self, client):
        resp = client.get("/info")
        body = json.loads(resp.data)
        assert "container" in body

    def test_info_has_environment(self, client):
        resp = client.get("/info")
        body = json.loads(resp.data)
        assert body["environment"] == "testing"


# ── 404 handling ──────────────────────────────────────────────────────────────

class TestNotFound:
    def test_unknown_route_returns_404(self, client):
        resp = client.get("/this-route-does-not-exist")
        assert resp.status_code == 404
