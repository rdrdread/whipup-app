from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.models.recipe import Recipe
from app.schemas.recipe import RecipeCacheRequest, RecipeCacheResponse

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


@router.post("", response_model=RecipeCacheResponse, status_code=201)
async def cache_recipe(
    body: RecipeCacheRequest,
    db: AsyncSession = Depends(get_db),
):
    """AI 생성 레시피를 서버에 캐시한다.

    Flutter 앱이 Gemini 로 레시피를 생성한 뒤 호출한다.
    이미 같은 제목의 레시피가 있으면 데이터를 업데이트한다.
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
        return RecipeCacheResponse(id=existing.id, message="updated")

    recipe = Recipe(title=title, title_search=title_search, recipe_data=data)
    db.add(recipe)
    await db.commit()
    return RecipeCacheResponse(id=recipe.id, message="cached")


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
