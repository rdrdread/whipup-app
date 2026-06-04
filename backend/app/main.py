from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.database import create_tables
from app.api.v1 import recipes


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_tables()
    yield


app = FastAPI(title="whipup API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(recipes.router, prefix="/v1/recipes", tags=["recipes"])


@app.get("/health")
async def health():
    return {"status": "ok", "service": "whipup-api"}
