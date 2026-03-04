"""Claude AI email categorization service."""

from __future__ import annotations

import asyncio
import json
from dataclasses import dataclass
from typing import Any

import anthropic
import structlog

from app.config import settings

logger = structlog.get_logger()


CATEGORIES = [
    "Urgent",
    "Action Required",
    "Finance",
    "FYI",
    "Newsletter",
    "Receipt",
    "Spam",
]


@dataclass
class CategorizationResult:
    """AI categorization output."""

    category: str
    summary: str
    confidence: float


class AICategorizationService:
    """Wrapper around Claude API for email categorization."""

    def __init__(self) -> None:
        self.client = anthropic.AsyncAnthropic(api_key=settings.claude_api_key)

    @staticmethod
    def _safe_json(text: str) -> dict[str, Any] | None:
        """Parse JSON from model output, tolerating extra text."""
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            pass

        start = text.find("{")
        end = text.rfind("}")
        if start == -1 or end == -1 or end <= start:
            return None
        try:
            return json.loads(text[start : end + 1])
        except json.JSONDecodeError:
            return None

    @staticmethod
    def _normalize_category(value: str | None) -> str:
        if not value:
            return "FYI"
        value = value.strip()
        for category in CATEGORIES:
            if value.lower() == category.lower():
                return category
        return "FYI"

    @staticmethod
    def _normalize_confidence(value: Any) -> float:
        try:
            confidence = float(value)
        except (TypeError, ValueError):
            return 0.0
        return max(0.0, min(1.0, confidence))

    async def categorize_email(
        self,
        subject: str | None,
        sender: str | None,
        snippet: str | None,
        body: str | None = None,
    ) -> CategorizationResult:
        """Return category + summary + confidence for an email."""
        if not settings.claude_api_key:
            logger.warning("claude_api_key_missing")
            return CategorizationResult(category="FYI", summary="", confidence=0.0)

        prompt = (
            "You are an email triage assistant. "
            "Classify the email into exactly one of these categories: "
            f"{', '.join(CATEGORIES)}. "
            "Then provide a 1-2 sentence neutral summary and a confidence score between 0 and 1. "
            "Return strict JSON with keys: category, summary, confidence.\n\n"
            f"Sender: {sender}\n"
            f"Subject: {subject}\n"
            f"Snippet: {snippet}\n"
            f"Body: {body}\n"
        )

        retries = 3
        delay = 0.6
        for attempt in range(1, retries + 1):
            try:
                response = await self.client.messages.create(
                    model="claude-sonnet-4-20250514",
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=200,
                    temperature=0.2,
                )
                content = response.content[0].text
                parsed = self._safe_json(content)
                if not parsed:
                    raise ValueError("Claude returned non-JSON response")

                category = self._normalize_category(parsed.get("category"))
                summary = (parsed.get("summary") or "").strip()
                confidence = self._normalize_confidence(parsed.get("confidence"))

                return CategorizationResult(category=category, summary=summary, confidence=confidence)
            except anthropic.RateLimitError as exc:
                logger.warning("claude_rate_limited", attempt=attempt, error=str(exc))
            except anthropic.APIStatusError as exc:
                logger.warning("claude_api_error", attempt=attempt, status_code=exc.status_code)
            except Exception as exc:
                logger.error("ai_categorization_failed", attempt=attempt, error=str(exc))

            if attempt < retries:
                await asyncio.sleep(delay)
                delay *= 2

        return CategorizationResult(category="FYI", summary="", confidence=0.0)
