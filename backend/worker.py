"""AI processing worker."""

from __future__ import annotations

import asyncio
from datetime import datetime

import structlog
from sqlalchemy import select

from app.database import SessionLocal
from app.models import AIQueue, Email
from app.services.ai_service import AIService

logger = structlog.get_logger()


class AIWorker:
    """Simple polling worker for AI categorization."""

    def __init__(self) -> None:
        self.ai_service = AIService()
        self.running = True

    async def process_loop(self) -> None:
        """Main loop."""
        while self.running:
            async with SessionLocal() as session:
                stmt = (
                    select(AIQueue, Email)
                    .join(Email, AIQueue.email_id == Email.id)
                    .where(AIQueue.status == "pending")
                    .order_by(AIQueue.created_at)
                    .limit(10)
                )
                result = await session.execute(stmt)
                rows = result.all()

                if not rows:
                    await asyncio.sleep(5)
                    continue

                for queue_item, email in rows:
                    await self._process_one(session, queue_item, email)

            await asyncio.sleep(1)

    async def _process_one(self, session, queue_item: AIQueue, email: Email) -> None:
        """Process a single email."""
        try:
            queue_item.status = "processing"
            queue_item.attempts += 1
            await session.commit()

            result = await self.ai_service.categorize_email(email.subject, email.sender, email.snippet)
            email.category = result.get("category")
            queue_item.status = "complete"
            await session.commit()

            logger.info("ai_processed", email_id=str(email.id), category=email.category)
        except Exception as exc:
            queue_item.status = "failed"
            queue_item.error = str(exc)
            await session.commit()
            logger.error("ai_failed", error=str(exc), email_id=str(email.id))


async def main() -> None:
    """Run the worker."""
    worker = AIWorker()
    await worker.process_loop()


if __name__ == "__main__":
    asyncio.run(main())
