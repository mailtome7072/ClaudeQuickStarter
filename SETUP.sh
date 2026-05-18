#!/bin/bash
# ============================================================================
# SETUP.sh — ClaudeQuickStarter 부트스트랩 오케스트레이터
#
# /setup-project Phase C에서 호출됨. 다음 순서로 setup-modules를 합성:
#   1. 선행 조건 (stack.json confirmed, jq, docker 등)
#   2. .env 생성 (강한 시크릿 자동)
#   3. docker-compose 생성
#   4. Dockerfile 생성
#   5. GitHub Actions 생성
#   6. Frontend 스캐폴드 (스택 기반)
#   7. Backend 스캐폴드 (스택 기반)
#   8. 의존성 설치
#   9. Docker 시작 테스트
#
# 사용법: bash SETUP.sh
# Windows: WSL2, Git Bash 또는 (향후) SETUP.ps1
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# ============================================================================
# 1. 선행 조건
# ============================================================================
echo -e "${BLUE}=== ClaudeQuickStarter Setup ===${NC}\n"

if [ ! -f ".claude/stack.json" ]; then
    echo -e "${RED}✗ .claude/stack.json 없음${NC}"
    echo "  먼저 /analyze-stack을 실행하여 기술스택을 확정하세요."
    exit 1
fi

STACK_STATUS=$(jq -r '.status // "pending"' .claude/stack.json 2>/dev/null || echo "invalid")
if [ "$STACK_STATUS" != "confirmed" ]; then
    echo -e "${RED}✗ .claude/stack.json status가 '$STACK_STATUS' (confirmed 아님)${NC}"
    echo "  /analyze-stack을 다시 실행하여 스택을 확정하세요."
    exit 1
fi

check_cmd() {
    if ! command -v "$1" >/dev/null; then
        echo -e "${RED}✗ $1 필요${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ $1${NC}"
}

echo -e "${YELLOW}[1/9] 필수 도구 확인${NC}"
check_cmd jq || exit 1
check_cmd openssl || exit 1
check_cmd git || exit 1
check_cmd docker || echo "  (docker 없음 — Docker 단계는 건너뜀)"
check_cmd docker-compose || echo "  (docker-compose 없음 — Docker 단계는 건너뜀)"
echo ""

# ============================================================================
# 2. 스택 출력
# ============================================================================
FE=$(jq -r '.stack.frontend.ui_framework // "none"' .claude/stack.json)
BE=$(jq -r '.stack.backend.framework // "none"' .claude/stack.json)
DB=$(jq -r '.stack.database.primary_database // "none"' .claude/stack.json)
CACHE=$(jq -r '.stack.database.cache // "none"' .claude/stack.json)

echo -e "${YELLOW}[2/9] 확정 스택${NC}"
echo "  Frontend: $FE"
echo "  Backend: $BE"
echo "  DB: $DB"
echo "  Cache: $CACHE"
echo ""

# ============================================================================
# 3. .env 생성
# ============================================================================
echo -e "${YELLOW}[3/9] .env 생성 (강한 시크릿 자동)${NC}"
bash scripts/setup-modules/generate-env.sh
echo ""

# ============================================================================
# 4. docker-compose 생성
# ============================================================================
echo -e "${YELLOW}[4/9] docker-compose 생성${NC}"
bash scripts/setup-modules/generate-docker-compose.sh
echo ""

# ============================================================================
# 5. Dockerfile 생성
# ============================================================================
echo -e "${YELLOW}[5/9] Dockerfile 생성${NC}"
bash scripts/setup-modules/generate-dockerfiles.sh
echo ""

# ============================================================================
# 6. GitHub Actions 생성
# ============================================================================
echo -e "${YELLOW}[6/9] GitHub Actions 생성${NC}"
bash scripts/setup-modules/generate-github-actions.sh
echo ""

# ============================================================================
# 7. Frontend 스캐폴드
# ============================================================================
echo -e "${YELLOW}[7/9] Frontend 스캐폴드: $FE${NC}"
case "$FE" in
    React*) bash scripts/setup-modules/setup-frontend-react-vite.sh ;;
    Vue*)   bash scripts/setup-modules/setup-frontend-vue.sh ;;
    Next.js*) bash scripts/setup-modules/setup-frontend-nextjs.sh ;;
    none)   echo "  (Frontend 없음)" ;;
    *)      echo -e "${YELLOW}  ⚠ '$FE' 모듈 없음 — 수동 스캐폴드 필요${NC}" ;;
esac
echo ""

# ============================================================================
# 8. Backend 스캐폴드
# ============================================================================
echo -e "${YELLOW}[8/9] Backend 스캐폴드: $BE${NC}"
case "$BE" in
    FastAPI) bash scripts/setup-modules/setup-backend-fastapi.sh ;;
    Django)  bash scripts/setup-modules/setup-backend-django.sh ;;
    Express) bash scripts/setup-modules/setup-backend-express.sh ;;
    none)    echo "  (Backend 없음)" ;;
    *)       echo -e "${YELLOW}  ⚠ '$BE' 모듈 없음 — 수동 스캐폴드 필요${NC}" ;;
esac
echo ""

# Backend 의존성 설치 (FastAPI/Django의 경우)
if [[ "$BE" == FastAPI || "$BE" == Django ]] && [ -f "app/backend/requirements.txt" ]; then
    echo -e "${YELLOW}  → Python 가상환경 + 의존성 설치${NC}"
    cd app/backend
    if [ ! -d ".venv" ]; then python3 -m venv .venv; fi
    # Windows/Unix 모두 호환
    if [ -f ".venv/Scripts/activate" ]; then
        source .venv/Scripts/activate
    else
        source .venv/bin/activate
    fi
    pip install --upgrade pip setuptools wheel >/dev/null
    pip install -r requirements.txt
    deactivate
    cd "$PROJECT_ROOT"
    echo -e "${GREEN}  ✓ Python 의존성 설치 완료${NC}"
fi

# Frontend 의존성 설치
if [ -f "app/frontend/package.json" ]; then
    FE_PM=$(jq -r '.stack.frontend.package_manager // "pnpm"' .claude/stack.json)
    echo -e "${YELLOW}  → Frontend 의존성 설치 ($FE_PM)${NC}"
    cd app/frontend
    case "$FE_PM" in
        pnpm) command -v pnpm >/dev/null && pnpm install || npm install ;;
        yarn) command -v yarn >/dev/null && yarn install || npm install ;;
        npm|*) npm install ;;
    esac
    cd "$PROJECT_ROOT"
    echo -e "${GREEN}  ✓ Frontend 의존성 설치 완료${NC}"
fi
echo ""

# ============================================================================
# 9. Docker 시작 테스트
# ============================================================================
echo -e "${YELLOW}[9/9] Docker 시작 테스트${NC}"
if command -v docker-compose >/dev/null && [ -f "docker-compose.yml" ]; then
    docker-compose up -d 2>/dev/null || echo "  ⚠ 시작 실패 (수동 확인 필요)"
    sleep 3
    docker-compose ps
    echo ""
    echo "  로컬 종료: docker-compose down"
else
    echo "  (docker-compose 또는 docker-compose.yml 없음 — 건너뜀)"
fi
echo ""

# ============================================================================
# 완료
# ============================================================================
echo -e "${GREEN}=== SETUP 완료 ===${NC}\n"
echo "다음 단계:"
echo "  1. git status로 생성된 파일 확인"
echo "  2. .env 검토 (시크릿 자동 생성됨, .gitignored)"
echo "  3. git add . && git commit -m 'Bootstrap: stack confirmed and scaffolded'"
echo "  4. Claude Code: \"PRD 기반 ROADMAP 생성해줘.\""
echo "  5. Claude Code: \"sprint 1 계획 세워줘.\""
echo "  6. Claude Code: /sprint-dev 1"
