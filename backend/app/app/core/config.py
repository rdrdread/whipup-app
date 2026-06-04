from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://whipup:password@db:5432/whipup"
    redis_url: str = "redis://redis:6379/0"
    gemini_api_key: str = ""
    secret_key: str = "dev-secret-key"

    model_config = {"env_file": ".env"}


settings = Settings()
