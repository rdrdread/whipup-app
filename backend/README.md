# Backend (Phase 2.1)

> **CLAUDE.md §3.5:** Backend 루트는 `backend/` 서브디렉토리. FastAPI 서버는 Phase 2.1 구축 시 이 디렉토리에 생성된다.

---

## 예정 기술 스택

| Component | Role |
|-----------|------|
| **FastAPI** | 비즈니스 로직 & AI 오케스트레이션 |
| **PostgreSQL** | 전체 기록 및 레시피 캐시 (Embedding 포함) |
| **pgvector** | 식재료 조합 유사도 계산 |
| **Celery** | 비동기 분석 및 데이터 정제 |
| **Redis** | 비동기 큐 관리 및 캐싱 |

## Phase 2.1 시작 시 생성 예정 구조

```
backend/
├── app/
│   ├── main.py            # FastAPI entry point
│   ├── api/               # Router endpoints
│   ├── core/              # Config, DB, Security
│   ├── models/            # SQLAlchemy models
│   ├── schemas/           # Pydantic schemas
│   ├── services/          # Business logic
│   └── tasks/             # Celery tasks
├── alembic/               # DB migrations
├── tests/
├── Dockerfile
├── docker-compose.yml
└── requirements.txt
```
