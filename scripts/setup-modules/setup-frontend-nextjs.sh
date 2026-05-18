#!/bin/bash
# ============================================================================
# setup-frontend-nextjs.sh (스텁)
#
# Next.js 14+ App Router 스캐폴드. 향후 자동화 예정.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

PM=$(jq -r '.stack.frontend.package_manager // "pnpm"' .claude/stack.json 2>/dev/null || echo "pnpm")

echo "⚠ Next.js 프론트엔드 자동 스캐폴드는 아직 구현되지 않았습니다."
echo ""
echo "임시 방안:"
echo "  cd app/frontend"
case "$PM" in
    pnpm) echo "  pnpm create next-app@latest . --typescript --app --tailwind --eslint" ;;
    yarn) echo "  yarn create next-app . --typescript --app --tailwind --eslint" ;;
    *)    echo "  npx create-next-app@latest . --typescript --app --tailwind --eslint" ;;
esac
echo ""
echo "스캐폴드 후 SETUP.sh를 다시 실행하세요."
exit 0
