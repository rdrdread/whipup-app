from pydantic_settings import BaseSettings
from pydantic import computed_field


class Settings(BaseSettings):
    db_password: str = "password"
    postgres_host: str = "db"
    postgres_port: int = 5432
    postgres_user: str = "whipup"
    postgres_db: str = "whipup"

    redis_url: str = "redis://redis:6379/0"
    gemini_api_key: str = ""
    secret_key: str = "dev-secret-key"

    model_config = {"env_file": ".env"}

    @computed_field
    @property
    def database_url(self) -> str:
        return (
            f"postgresql://{self.postgres_user}:{self.db_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )


settings = Settings()
