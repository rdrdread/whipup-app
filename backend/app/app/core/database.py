from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.core.config import settings

DATABASE_URL = settings.database_url.replace(
    "postgresql://", "postgresql+asyncpg://"
)

engine = create_async_engine(DATABASE_URL, echo=False, pool_pre_ping=True)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def create_tables() -> None:
    async with engine.begin() as conn:
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        from app.models import recipe  # noqa: F401
        await conn.run_sync(Base.metadata.create_all)
        # 기존 테이블에 embedding 컬럼이 없으면 추가 (idempotent)
        await conn.execute(text(
            "ALTER TABLE recipes ADD COLUMN IF NOT EXISTS embedding vector(768)"
        ))


async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
