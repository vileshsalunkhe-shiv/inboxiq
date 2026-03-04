"""Claude AI integration for categorization and digest summaries."""

from __future__ import annotations

import json
from typing import Any

import anthropic
import structlog

from app.config import settings

logger = structlog.get_logger()


class AIService:
    """Wrapper around Claude API."""

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

    async def categorize_email(self, subject: str | None, sender: str | None, snippet: str | None) -> dict[str, Any]:
        """Return category + confidence for an email."""
        if not settings.claude_api_key:
            logger.warning("claude_api_key_missing")
            return {"category": "Other", "confidence": 0.0}

        prompt = f"""
        Categorize this email into one of: Work, Personal, Newsletters, Finance, Shopping, Social, Other.
        Return JSON: {{"category": "name", "confidence": 0-1}}

        Sender: {sender}
        Subject: {subject}
        Snippet: {snippet}
        """
        try:
            response = await self.client.messages.create(
                model="claude-3-haiku-20240307",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=100,
            )
            content = response.content[0].text
            parsed = self._safe_json(content)
            if not parsed:
                raise ValueError("Claude returned non-JSON response")
            return parsed
        except Exception as exc:
            logger.error("ai_categorization_failed", error=str(exc))
            return {"category": "Other", "confidence": 0.0}

    async def summarize_digest(self, payload: dict[str, Any]) -> dict[str, Any]:
        """Generate a digest summary using Claude."""
        if not settings.claude_api_key:
            logger.warning("claude_api_key_missing")
            return {"category_summaries": {}, "highlights": [], "insights": ""}

        prompt = f"""
        Summarize these emails by category and extract highlights.
        Data: {json.dumps(payload)[:6000]}
        Return JSON: {{"category_summaries": {{}}, "highlights": [], "insights": ""}}
        """
        try:
            response = await self.client.messages.create(
                model="claude-3-haiku-20240307",
                messages=[{"role": "user", "content": prompt}],
                max_tokens=800,
            )
            parsed = self._safe_json(response.content[0].text)
            if not parsed:
                raise ValueError("Claude returned non-JSON response")
            return parsed
        except Exception as exc:
            logger.error("digest_summary_failed", error=str(exc))
            return {"category_summaries": {}, "highlights": [], "insights": ""}
