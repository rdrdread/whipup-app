#!/bin/bash
# whipup 백엔드 시놀로지 자동 설치 스크립트
# 사용법: curl -fsSL https://raw.githubusercontent.com/rdrdread/whipup-app/main/backend/scripts/setup.sh | sudo bash

set -e

# ── 색상 출력 ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ── 사전 조건 확인 ─────────────────────────────────────────────────────────────
command -v docker >/dev/null 2>&1 || err "Docker가 설치되어 있지 않습니다. DSM 패키지 센터에서 Docker 또는 Container Manager를 설치하세요."
command -v docker-compose >/dev/null 2>&1 || err "docker-compose를 찾을 수 없습니다."
log "Docker 환경 확인 완료"

# ── 환경변수 입력 ──────────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo "   whipup 백엔드 설치 마법사"
echo "============================================"
echo ""

read -p "DB 비밀번호 (영문+숫자 조합 권장): " DB_PASSWORD
[[ -z "$DB_PASSWORD" ]] && err "DB 비밀번호는 필수입니다."

read -p "Gemini API 키: " GEMINI_API_KEY
[[ -z "$GEMINI_API_KEY" ]] && err "Gemini API 키는 필수입니다."

SECRET_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
log "SECRET_KEY 자동 생성 완료"

# ── 디렉토리 생성 ──────────────────────────────────────────────────────────────
BASE_DIR="/volume1/docker/whipup"
mkdir -p "$BASE_DIR"/{app,postgres_data,redis_data}
log "디렉토리 생성: $BASE_DIR"

# ── .env 파일 ──────────────────────────────────────────────────────────────────
cat > "$BASE_DIR/.env" << ENVEOF
DB_PASSWORD=${DB_PASSWORD}
GEMINI_API_KEY=${GEMINI_API_KEY}
SECRET_KEY=${SECRET_KEY}
POSTGRES_HOST=db
POSTGRES_PORT=5432
POSTGRES_USER=whipup
POSTGRES_DB=whipup
REDIS_URL=redis://redis:6379/0
ENVEOF
chmod 600 "$BASE_DIR/.env"
log ".env 파일 생성 완료 (권한 600)"

# ── docker-compose.yml ─────────────────────────────────────────────────────────
cat > "$BASE_DIR/docker-compose.yml" << 'COMPOSEEOF'
version: '3.9'

services:
  api:
    build: ./app
    container_name: whipup_api
    restart: unless-stopped
    ports:
      - "8000:8000"
    env_file: .env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - whipup_net
    deploy:
      resources:
        limits:
          memory: 512M

  db:
    image: pgvector/pgvector:pg16
    container_name: whipup_db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_PASSWORD+whipup}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: whipup
    command: >
      postgres
        -c shared_buffers=256MB
        -c effective_cache_size=1GB
        -c max_connections=50
    volumes:
      - ./postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U whipup"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - whipup_net
    deploy:
      resources:
        limits:
          memory: 1G

  redis:
    image: redis:7-alpine
    container_name: whipup_redis
    restart: unless-stopped
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - ./redis_data:/data
    networks:
      - whipup_net
    deploy:
      resources:
        limits:
          memory: 256M

  celery_worker:
    build: ./app
    container_name: whipup_celery
    restart: unless-stopped
    command: celery -A app.celery_app worker --loglevel=info --concurrency=2
    env_file: .env
    depends_on:
      - api
      - redis
    networks:
      - whipup_net
    deploy:
      resources:
        limits:
          memory: 256M

networks:
  whipup_net:
    driver: bridge
COMPOSEEOF
log "docker-compose.yml 생성 완료"

# ── FastAPI Dockerfile ─────────────────────────────────────────────────────────
cat > "$BASE_DIR/app/Dockerfile" << 'DOCKEREOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
DOCKEREOF

# ── requirements.txt ──────────────────────────────────────────────────────────
cat > "$BASE_DIR/app/requirements.txt" << 'REQEOF'
fastapi==0.115.0
uvicorn[standard]==0.32.0
sqlalchemy==2.0.36
asyncpg==0.30.0
alembic==1.14.0
celery[redis]==5.4.0
redis==5.2.0
pgvector==0.3.5
google-generativeai==0.8.3
python-dotenv==1.0.1
pydantic==2.10.0
pydantic-settings==2.6.1
REQEOF

# ── FastAPI main.py ────────────────────────────────────────────────────────────
cat > "$BASE_DIR/app/main.py" << 'MAINEOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="whipup API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "whipup-api"}

@app.get("/")
async def root():
    return {"message": "whipup API is running"}
MAINEOF
log "FastAPI 기본 앱 생성 완료"

# ── update.sh 생성 ─────────────────────────────────────────────────────────────
cat > "$BASE_DIR/update.sh" << 'UPDATEEOF'
#!/bin/bash
# 백엔드 업데이트 스크립트
# 사용법: sudo bash /volume1/docker/whipup/update.sh

set -e
cd /volume1/docker/whipup

echo "[1/3] 최신 코드 반영..."
# git pull origin main  # git으로 관리 시 주석 해제

echo "[2/3] 이미지 재빌드..."
docker-compose build api celery_worker

echo "[3/3] API/Celery 재시작 (DB·Redis 유지)..."
docker-compose up -d --no-deps api celery_worker

echo ""
echo "업데이트 완료! 최근 로그:"
docker-compose logs --tail=20 api
UPDATEEOF
chmod +x "$BASE_DIR/update.sh"
log "update.sh 생성 완료"

# ── 컨테이너 빌드 및 실행 ──────────────────────────────────────────────────────
cd "$BASE_DIR"
log "컨테이너 빌드 시작 (수 분 소요)..."
docker-compose up -d --build

# ── 헬스체크 ──────────────────────────────────────────────────────────────────
echo ""
log "헬스체크 대기 (30초)..."
sleep 30

LOCAL_IP=$(hostname -I | awk '{print $1}')
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/health" 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    log "API 서버 정상 응답 확인!"
else
    warn "아직 시작 중이거나 응답 없음 (상태: $HTTP_STATUS) — 잠시 후 직접 확인하세요."
fi

# ── 완료 안내 ──────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
log " 설치 완료!"
echo "============================================"
echo ""
echo "  내부 API:  http://${LOCAL_IP}:8000"
echo "  API 문서:  http://${LOCAL_IP}:8000/docs"
echo "  헬스체크:  http://${LOCAL_IP}:8000/health"
echo ""
echo "  [ 다음 단계 ]"
echo "  1) 공유기 포트 포워딩: 외부 8000 → ${LOCAL_IP}:8000"
echo "  2) DSM → 제어판 → 외부 액세스 → DDNS 설정"
echo "  3) DSM → 제어판 → 보안 → 인증서 → Let's Encrypt"
echo "  4) DSM → 제어판 → 로그인 포털 → 역방향 프록시 설정"
echo ""
echo "  [ 부팅 자동 시작 ]"
echo "  DSM → 제어판 → 작업 스케줄러 → 생성 → 트리거된 작업"
echo "  이벤트: 부팅 / 명령: cd /volume1/docker/whipup && docker-compose up -d"
echo ""
echo "  [ 컨테이너 관리 ]"
echo "  상태 확인: docker-compose -f $BASE_DIR/docker-compose.yml ps"
echo "  로그 보기: docker-compose -f $BASE_DIR/docker-compose.yml logs -f api"
echo "  업데이트:  sudo bash $BASE_DIR/update.sh"
echo ""
