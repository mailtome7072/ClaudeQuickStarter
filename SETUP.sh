#!/bin/bash
set -euo pipefail

# ============================================================================
# ClaudeQuickStarter — Modular SETUP Script
# 기술스택에 따라 동적으로 초기화 모듈을 로드합니다.
# 
# 사용법: bash SETUP.sh
# 전제조건: .claude/stack.json이 존재해야 함 (stack-analyzer가 생성)
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# 1. 전제조건 확인
# ============================================================================

echo -e "${BLUE}=== ClaudeQuickStarter Setup ===${NC}"
echo ""

if [ ! -f ".claude/stack.json" ]; then
    echo -e "${RED}✗ 에러: .claude/stack.json을 찾을 수 없습니다.${NC}"
    echo "  먼저 'stack-analyzer' 에이전트를 실행하여 기술스택을 확정하세요."
    echo "  Claude Code에서: \"기술스택 분석해줘.\""
    exit 1
fi

echo -e "${GREEN}✓ .claude/stack.json 발견${NC}"

# ============================================================================
# 2. 기술스택 파싱
# ============================================================================

echo -e "${YELLOW}기술스택 파싱 중...${NC}"

if ! command -v jq &> /dev/null; then
    echo -e "${RED}✗ jq가 설치되지 않았습니다. apt install jq 또는 brew install jq를 실행하세요.${NC}"
    exit 1
fi

FRONTEND=$(jq -r '.stack.frontend.ui_framework // "none"' .claude/stack.json)
FRONTEND_PM=$(jq -r '.stack.frontend.package_manager // "pnpm"' .claude/stack.json)
BACKEND=$(jq -r '.stack.backend.framework // "none"' .claude/stack.json)
BACKEND_LANG=$(jq -r '.stack.backend.language // "none"' .claude/stack.json)
DATABASE=$(jq -r '.stack.database.primary_database // "none"' .claude/stack.json)
CACHE=$(jq -r '.stack.database.cache // "none"' .claude/stack.json)

echo -e "${GREEN}✓ 기술스택 파싱 완료${NC}"
echo ""
echo "🔧 감지된 스택:"
echo "  Frontend: $FRONTEND"
echo "  Frontend PM: $FRONTEND_PM"
echo "  Backend: $BACKEND"
echo "  Database: $DATABASE"
echo "  Cache: $CACHE"
echo ""

# ============================================================================
# 3. 필수 도구 확인
# ============================================================================

echo -e "${YELLOW}필수 도구 확인 중...${NC}"

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}✗ $1이(가) 설치되지 않았습니다.${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ $1 $(${1} --version 2>&1 | head -1)${NC}"
    return 0
}

check_command git
check_command docker
check_command docker-compose

echo ""

# ============================================================================
# 4. Frontend 초기화 (조건부)
# ============================================================================

if [[ "$FRONTEND" != "none" && -d "app/frontend" ]]; then
    echo -e "${YELLOW}Frontend 초기화 중: $FRONTEND...${NC}"
    
    case "$FRONTEND" in
        *"React"*)
            echo "  → React 프로젝트 감지"
            cd "$PROJECT_ROOT/app/frontend"
            if [ -f "package.json" ]; then
                echo "  → package.json 발견, 의존성 설치 중..."
                if [ "$FRONTEND_PM" = "pnpm" ]; then
                    check_command pnpm
                    pnpm install
                elif [ "$FRONTEND_PM" = "npm" ]; then
                    npm install
                else
                    yarn install
                fi
                echo -e "${GREEN}✓ Frontend 설치 완료${NC}"
            fi
            cd "$PROJECT_ROOT"
            ;;
        *"Next.js"*)
            echo "  → Next.js 프로젝트 감지"
            cd "$PROJECT_ROOT/app/frontend"
            if [ -f "package.json" ]; then
                if [ "$FRONTEND_PM" = "pnpm" ]; then
                    pnpm install
                else
                    npm install
                fi
                echo -e "${GREEN}✓ Next.js 설치 완료${NC}"
            fi
            cd "$PROJECT_ROOT"
            ;;
        *"Vue"*)
            echo "  → Vue 프로젝트 감지"
            cd "$PROJECT_ROOT/app/frontend"
            if [ -f "package.json" ]; then
                if [ "$FRONTEND_PM" = "pnpm" ]; then
                    pnpm install
                else
                    npm install
                fi
                echo -e "${GREEN}✓ Vue 설치 완료${NC}"
            fi
            cd "$PROJECT_ROOT"
            ;;
        *)
            echo -e "${YELLOW}⚠ 미지원 Frontend: $FRONTEND${NC}"
            ;;
    esac
    echo ""
fi

# ============================================================================
# 5. Backend 초기화 (조건부)
# ============================================================================

if [[ "$BACKEND" != "none" && -d "app/backend" ]]; then
    echo -e "${YELLOW}Backend 초기화 중: $BACKEND...${NC}"
    
    case "$BACKEND" in
        "FastAPI")
            echo "  → FastAPI 프로젝트 감지"
            if [ "$BACKEND_LANG" = "Python 3.11+" ] || [ "$BACKEND_LANG" = "Python 3.12+" ]; then
                cd "$PROJECT_ROOT/app/backend"
                if [ ! -d ".venv" ]; then
                    echo "  → Python 가상환경 생성 중..."
                    python3 -m venv .venv
                fi
                source .venv/bin/activate
                if [ -f "requirements.txt" ]; then
                    echo "  → 의존성 설치 중..."
                    pip install --upgrade pip setuptools wheel
                    pip install -r requirements.txt
                    echo -e "${GREEN}✓ FastAPI 설치 완료${NC}"
                fi
                cd "$PROJECT_ROOT"
            fi
            ;;
        "Django")
            echo "  → Django 프로젝트 감지"
            cd "$PROJECT_ROOT/app/backend"
            if [ ! -d ".venv" ]; then
                python3 -m venv .venv
            fi
            source .venv/bin/activate
            if [ -f "requirements.txt" ]; then
                pip install --upgrade pip
                pip install -r requirements.txt
                echo -e "${GREEN}✓ Django 설치 완료${NC}"
            fi
            cd "$PROJECT_ROOT"
            ;;
        "Express")
            echo "  → Express 프로젝트 감지"
            cd "$PROJECT_ROOT/app/backend"
            if [ -f "package.json" ]; then
                npm install
                echo -e "${GREEN}✓ Express 설치 완료${NC}"
            fi
            cd "$PROJECT_ROOT"
            ;;
        *)
            echo -e "${YELLOW}⚠ 미지원 Backend: $BACKEND${NC}"
            ;;
    esac
    echo ""
fi

# ============================================================================
# 6. .env 생성 (미존재 시)
# ============================================================================

if [ ! -f ".env" ]; then
    echo -e "${YELLOW}.env 파일 생성 중...${NC}"
    
    cat > .env << 'EOF'
# Database
POSTGRES_DB=project_dev
POSTGRES_USER=postgres
POSTGRES_PASSWORD=dev_password_change_me
DATABASE_URL=postgresql://postgres:dev_password_change_me@postgres:5432/project_dev

# Redis
REDIS_URL=redis://redis:6379/0

# API
API_HOST=http://backend:8000
API_PORT=8000
FRONTEND_URL=http://localhost:5173

# JWT (FastAPI 기준)
JWT_SECRET=your_secret_key_change_me
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# 배포
DOCKER_REGISTRY=ghcr.io
DOCKER_NAMESPACE=your_github_org
EOF
    
    echo -e "${GREEN}✓ .env 생성 완료 (보안을 위해 시크릿값을 변경하세요)${NC}"
    echo ""
fi

# ============================================================================
# 7. Docker 시작 테스트
# ============================================================================

echo -e "${YELLOW}Docker 서비스 시작 테스트 중...${NC}"

if [ -f "docker-compose.yml" ]; then
    echo "  → docker-compose.yml 발견"
    docker-compose up -d 2>/dev/null || true
    sleep 5
    
    if docker-compose ps | grep -q "running"; then
        echo -e "${GREEN}✓ Docker 서비스 실행 중${NC}"
        docker-compose down
    else
        echo -e "${YELLOW}⚠ Docker 서비스 시작 실패 (나중에 재시도)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ docker-compose.yml을 찾을 수 없습니다.${NC}"
    echo "  Sprint 1에서 생성될 예정입니다."
fi

echo ""

# ============================================================================
# 8. 완료 메시지
# ============================================================================

echo -e "${GREEN}=== SETUP 완료! ===${NC}"
echo ""
echo "✅ 다음 단계:"
echo "  1. .env 파일의 시크릿값을 변경하세요 (POSTGRES_PASSWORD, JWT_SECRET 등)"
echo "  2. GitHub에 푸시하세요 (git add . && git commit -m 'Setup complete')"
echo "  3. Claude Code에서 /sprint-planner를 실행하세요"
echo ""
echo "🚀 개발 시작:"
echo "  docker-compose up    # 로컬 서버 시작"
echo "  pnpm dev            # (Frontend) 개발 서버"
echo "  python -m uvicorn app.main:app --reload  # (Backend) 개발 서버"
echo ""
