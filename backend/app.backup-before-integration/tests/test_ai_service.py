"""Unit tests for AI service JSON parsing."""

from app.services.ai_service import AIService


def test_safe_json_parses_plain_json() -> None:
    payload = '{"category": "Work", "confidence": 0.9}'
    assert AIService._safe_json(payload) == {"category": "Work", "confidence": 0.9}


def test_safe_json_parses_json_with_wrapping_text() -> None:
    payload = "Here is the result: {\"category\": \"Other\", \"confidence\": 0.2} Thanks!"
    assert AIService._safe_json(payload) == {"category": "Other", "confidence": 0.2}


def test_safe_json_returns_none_on_invalid() -> None:
    payload = "no json here"
    assert AIService._safe_json(payload) is None
