from pydantic import BaseModel


class RecipeCacheRequest(BaseModel):
    """Flutter 앱이 AI 생성 레시피를 서버에 캐시할 때 사용하는 요청 스키마.

    recipe_data 는 Flutter Recipe.toJson() 의 camelCase JSON 을 그대로 수신한다.
    ingredients 를 함께 전달하면 비동기 임베딩 생성이 트리거된다.
    """

    recipe_data: dict
    ingredients: list[str] = []


class RecipeCacheResponse(BaseModel):
    id: str
    message: str = "cached"


class SimilarRecipeRequest(BaseModel):
    """재료 조합으로 유사 레시피를 검색할 때 사용하는 요청 스키마."""

    ingredients: list[str]
    limit: int = 3
    threshold: float = 0.85
