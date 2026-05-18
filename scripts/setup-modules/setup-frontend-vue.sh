#!/bin/bash
# ============================================================================
# setup-frontend-vue.sh (스텁)
#
# Vue 3 + Vite + TypeScript 스캐폴드. 현재 구현 미완료 — 향후 추가.
# 임시: Vite 공식 템플릿 직접 사용 안내.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "⚠ Vue 프론트엔드 자동 스캐폴드는 아직 구현되지 않았습니다."
echo ""
echo "임시 방안:"
echo "  cd app/frontend"
echo "  pnpm create vite . --template vue-ts"
echo ""
echo "또는 Nuxt 사용 시:"
echo "  npx nuxi@latest init ."
echo ""
echo "스캐폴드 후 SETUP.sh를 다시 실행하면 의존성 설치까지 자동 진행됩니다."
exit 0
