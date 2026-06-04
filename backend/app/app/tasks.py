import asyncio
from sqlalchemy import select
from app.celery_app import celery_app
from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.models.recipe import Recipe
from app.services.embedding_service import embed_ingredients


@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def generate_recipe_embedding(self, recipe_id: str, ingredients: list[str]) -> str:
    """레시피의 재료 목록으로 임베딩을 생성해 DB에 저장한다."""
    try:
        vector = embed_ingredients(ingredients)
        asyncio.run(_save_embedding(recipe_id, vector))
        return f"ok:{recipe_id}"
    except Exception as exc:
        raise self.retry(exc=exc)


async def _save_embedding(recipe_id: str, vector: list[float]) -> None:
    async with AsyncSessionLocal() as session:
        result = await session.execute(
            select(Recipe).where(Recipe.id == recipe_id)
        )
        recipe = result.scalar_one_or_none()
        if recipe:
            recipe.embedding = vector
            await session.commit()
