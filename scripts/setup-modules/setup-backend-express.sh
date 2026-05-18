#!/bin/bash
# ============================================================================
# setup-backend-express.sh (스텁)
#
# Express + TypeScript 스캐폴드. 향후 자동화 예정.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "⚠ Express 백엔드 자동 스캐폴드는 아직 구현되지 않았습니다."
echo ""
echo "임시 방안:"
echo "  cd app/backend"
echo "  npm init -y"
echo "  npm install express dotenv cors"
echo "  npm install -D typescript @types/express @types/node ts-node nodemon"
echo "  npx tsc --init"
echo ""
echo "스캐폴드 후 SETUP.sh를 다시 실행하세요."
exit 0
