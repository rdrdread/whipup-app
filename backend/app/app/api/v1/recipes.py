from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.models.recipe import Recipe
from app.schemas.recipe import (
    RecipeCacheRequest,
    RecipeCacheResponse,
    SimilarRecipeRequest,
)

router = APIRouter()


@router.get("/by-name")
async def get_recipe_by_name(
    q: str = Query(..., description="요리 이름 (예: 된장찌개)"),
    db: AsyncSession = Depends(get_db),
):
    """요리 이름으로 캐시된 레시피를 조회한다.

    Flutter 캐싱 레이어: Local → Server(이 엔드포인트) → AI
    404 응답 시 Flutter 앱이 Gemini AI 생성으로 폴백한다.
    """
    title_search = q.lower().strip()
    result = await db.execute(
        select(Recipe).where(Recipe.title_search == title_search)
    )
    recipe = result.scalar_one_or_none()
    if not recipe:
        raise HTTPException(status_code=404, detail=f"Recipe not found: {q}")
    return recipe.recipe_data


@router.post("/similar")
async def find_similar_recipes(
    body: SimilarRecipeRequest,
    db: AsyncSession = Depends(get_db),
):
    """재료 조합의 임베딩 유사도로 기존 캐시 레시피를 검색한다.

    Flutter 캐싱 레이어: Local → Server(이 엔드포인트) → AI
    임베딩이 없는 레시피는 제외되며, 결과가 없으면 빈 배열을 반환한다.
    """
    from app.services.embedding_service import embed_ingredients
    from pgvector.sqlalchemy import Vector

    query_vector = embed_ingredients(body.ingredients)

    # pgvector cosine distance (1 - cosine_similarity)
    distance_col = Recipe.embedding.cosine_distance(query_vector)
    rows = await db.execute(
        select(Recipe, distance_col.label("distance"))
        .where(Recipe.embedding.is_not(None))
        .order_by(distance_col)
        .limit(body.limit)
    )
    results = []
    for recipe, distance in rows:
        similarity = 1.0 - distance
        if similarity >= body.threshold:
            results.append(recipe.recipe_data)

    return results


@router.post("", response_model=RecipeCacheResponse, status_code=201)
async def cache_recipe(
    body: RecipeCacheRequest,
    db: AsyncSession = Depends(get_db),
):
    """AI 생성 레시피를 서버에 캐시한다.

    Flutter 앱이 Gemini 로 레시피를 생성한 뒤 호출한다.
    이미 같은 제목의 레시피가 있으면 데이터를 업데이트한다.
    ingredients 를 전달하면 Celery 워커가 비동기로 임베딩을 생성한다.
    """
    data = body.recipe_data
    title = data.get("title", "").strip()
    if not title:
        raise HTTPException(status_code=422, detail="title field is required in recipe_data")

    title_search = title.lower()
    result = await db.execute(
        select(Recipe).where(Recipe.title_search == title_search)
    )
    existing = result.scalar_one_or_none()

    if existing:
        existing.recipe_data = data
        existing.title = title
        await db.commit()
        recipe_id = existing.id
        message = "updated"
    else:
        recipe = Recipe(title=title, title_search=title_search, recipe_data=data)
        db.add(recipe)
        await db.commit()
        recipe_id = recipe.id
        message = "cached"

    # 재료 목록이 있으면 비동기 임베딩 생성 트리거
    if body.ingredients:
        from app.tasks import generate_recipe_embedding
        generate_recipe_embedding.delay(recipe_id, body.ingredients)

    return RecipeCacheResponse(id=recipe_id, message=message)


@router.get("/{recipe_id}")
async def get_recipe_by_id(
    recipe_id: str,
    db: AsyncSession = Depends(get_db),
):
    """ID로 레시피를 조회한다."""
    result = await db.execute(select(Recipe).where(Recipe.id == recipe_id))
    recipe = result.scalar_one_or_none()
    if not recipe:
        raise HTTPException(status_code=404, detail="Recipe not found")
    return recipe.recipe_data
