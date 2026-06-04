#!/bin/bash
# whipup 백엔드 배포 스크립트
# 사용법: bash /volume1/docker/whipup/deploy.sh

set -e

REPO_DIR="/volume1/docker/whipup-repo"
APP_DIR="/volume1/docker/whipup/app"
COMPOSE_DIR="/volume1/docker/whipup"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# root이면 sudo 불필요, 일반 유저면 NOPASSWD sudo 사용
if [ "$(id -u)" = "0" ]; then
    DC="docker-compose"
else
    DC="sudo docker-compose"
fi

# ── 저장소 클론 또는 최신화 ──────────────────────────────────────────────────────
if [ -d "$REPO_DIR/.git" ]; then
    log "저장소 업데이트 중..."
    cd "$REPO_DIR" && git pull origin main
else
    log "저장소 최초 클론 중..."
    git clone https://github.com/rdrdread/whipup-app.git "$REPO_DIR"
fi

# ── 자기 자신도 최신 버전으로 교체 ──────────────────────────────────────────────
cp "$REPO_DIR/backend/scripts/deploy.sh" "$COMPOSE_DIR/deploy.sh"

# ── 백엔드 소스 복사 ────────────────────────────────────────────────────────────
log "백엔드 소스 복사 중..."
rsync -av --no-perms --no-owner --no-group \
    --exclude='__pycache__' --exclude='*.pyc' \
    "$REPO_DIR/backend/app/" "$APP_DIR/"

# ── 컨테이너 재빌드 및 재시작 (DB·Redis 유지) ──────────────────────────────────
log "API 컨테이너 재빌드 중..."
cd "$COMPOSE_DIR"
$DC build api celery_worker
$DC up -d --no-deps api celery_worker

log "======================================"
log " 배포 완료!"
log "======================================"
echo ""
echo "  API:  https://whipup.synology.me/health"
echo "  문서: https://whipup.synology.me/docs"
echo ""
$DC logs --tail=10 api
