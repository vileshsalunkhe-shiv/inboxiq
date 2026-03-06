"""Unit tests for security helpers."""

from app.utils.security import hash_token


def test_hash_token_deterministic() -> None:
    token = "abc123"
    assert hash_token(token) == hash_token(token)
