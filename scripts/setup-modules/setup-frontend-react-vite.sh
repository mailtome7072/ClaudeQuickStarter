#!/bin/bash
# ============================================================================
# setup-frontend-react-vite.sh
#
# React + Vite + TypeScript 프로젝트를 app/frontend/에 스캐폴드.
# stack.json의 package_manager (pnpm/npm/yarn)를 따름.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

STACK_JSON=".claude/stack.json"
[ -f "$STACK_JSON" ] || { echo "✗ $STACK_JSON 없음"; exit 1; }
command -v jq >/dev/null || { echo "✗ jq 필요"; exit 1; }

PM=$(jq -r '.stack.frontend.package_manager // "pnpm"' "$STACK_JSON")
LANG=$(jq -r '.stack.frontend.language // "TypeScript"' "$STACK_JSON")

mkdir -p app/frontend
cd app/frontend

if [ -f "package.json" ]; then
    echo "ℹ app/frontend에 package.json 이미 존재 — 스캐폴드 건너뜀, 의존성 설치만 수행"
else
    # Vite 템플릿 결정
    if [ "$LANG" = "TypeScript" ]; then
        TEMPLATE="react-ts"
    else
        TEMPLATE="react"
    fi

    echo "→ Vite ($TEMPLATE) 스캐폴드 중 ($PM)..."
    case "$PM" in
        pnpm) pnpm create vite . --template "$TEMPLATE" ;;
        yarn) yarn create vite . --template "$TEMPLATE" ;;
        npm|*) npm create vite@latest . -- --template "$TEMPLATE" ;;
    esac
fi

# 권장 추가 의존성
echo "→ 권장 의존성 설치 (router, query, zustand)..."
EXTRA_DEPS="react-router-dom @tanstack/react-query zustand"
case "$PM" in
    pnpm) pnpm add $EXTRA_DEPS ;;
    yarn) yarn add $EXTRA_DEPS ;;
    npm|*) npm install $EXTRA_DEPS ;;
esac

# Vite 환경변수 예시
if [ ! -f ".env.example" ]; then
    cat > .env.example <<'EOF'
# Vite는 VITE_* 접두사만 클라이언트에 노출
VITE_API_URL=http://localhost:8000
EOF
fi

echo "✓ React + Vite frontend 스캐폴드 완료 ($PM, $LANG)"
echo "  - 개발 서버: cd app/frontend && $PM run dev"
