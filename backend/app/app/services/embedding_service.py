import google.generativeai as genai
from app.core.config import settings

_MODEL = "models/text-embedding-004"

genai.configure(api_key=settings.gemini_api_key)


def embed_ingredients(ingredients: list[str]) -> list[float]:
    """재료 목록을 768차원 벡터로 변환한다.

    재료명을 쉼표로 이어 한 문장으로 만든 뒤 Gemini embedding API에 전달한다.
    """
    text = ", ".join(ingredients)
    result = genai.embed_content(model=_MODEL, content=text)
    return result["embedding"]
