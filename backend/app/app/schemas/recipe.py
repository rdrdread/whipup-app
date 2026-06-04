from pydantic import BaseModel


class RecipeCacheRequest(BaseModel):
    """Flutter 앱이 AI 생성 레시피를 서버에 캐시할 때 사용하는 요청 스키마.

    recipe_data 는 Flutter Recipe.toJson() 의 camelCase JSON 을 그대로 수신한다.
    """

    recipe_data: dict


class RecipeCacheResponse(BaseModel):
    id: str
    message: str = "cached"
