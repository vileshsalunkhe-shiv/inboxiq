"""Unit tests for auth service."""

from app.services.auth_service import AuthService


class DummyDB:
    """Minimal stub for DB."""


def test_build_google_auth_url_contains_client_id(monkeypatch) -> None:
    from app import config

    monkeypatch.setattr(config.settings, "google_client_id", "client")
    monkeypatch.setattr(config.settings, "google_redirect_uri", "http://localhost/callback")

    service = AuthService(DummyDB())
    url = service.build_google_auth_url(None)
    assert "client" in url
    assert "redirect_uri" in url
