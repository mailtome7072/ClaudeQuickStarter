#!/bin/bash
# ============================================================================
# generate-github-actions.sh
#
# stack.json 기반으로 .github/workflows/ci.yml과 deploy.yml 생성.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

STACK_JSON=".claude/stack.json"
[ -f "$STACK_JSON" ] || { echo "✗ $STACK_JSON 없음"; exit 1; }
command -v jq >/dev/null || { echo "✗ jq 필요"; exit 1; }

FE_PM=$(jq -r '.stack.frontend.package_manager // "pnpm"' "$STACK_JSON")
BE=$(jq -r '.stack.backend.framework // "none"' "$STACK_JSON")
BE_LANG=$(jq -r '.stack.backend.language // "none"' "$STACK_JSON")
CI=$(jq -r '.stack.infrastructure.ci_cd_platform // "GitHub Actions"' "$STACK_JSON")

if [[ "$CI" != *GitHub* ]]; then
    echo "ℹ CI/CD 플랫폼이 GitHub Actions가 아님 ($CI) — 건너뜀"
    echo "  수동으로 해당 플랫폼용 워크플로우를 작성하세요."
    exit 0
fi

mkdir -p .github/workflows

# Backend 테스트 명령 결정
case "$BE" in
    FastAPI|Django) BE_TEST="pytest"; BE_INSTALL="pip install -r requirements.txt" ;;
    Express)        BE_TEST="npm test"; BE_INSTALL="npm ci" ;;
    *)              BE_TEST="echo 'no backend tests'"; BE_INSTALL="" ;;
esac

# Python 버전
PY_VER="3.12"
[[ "$BE_LANG" == *3.11* ]] && PY_VER="3.11"

# --- ci.yml ---
cat > .github/workflows/ci.yml <<EOF
name: CI

on:
  push:
    branches: [main, develop, 'sprint*']
  pull_request:
    branches: [main, develop]

jobs:
  frontend:
    runs-on: ubuntu-latest
    if: \${{ hashFiles('app/frontend/package.json') != '' }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install $FE_PM
        run: |
          if [ "$FE_PM" = "pnpm" ]; then npm install -g pnpm; fi
      - name: Install dependencies
        working-directory: app/frontend
        run: $FE_PM install --frozen-lockfile
      - name: Lint
        working-directory: app/frontend
        run: $FE_PM run lint || true
      - name: Test
        working-directory: app/frontend
        run: $FE_PM test || true
      - name: Build
        working-directory: app/frontend
        run: $FE_PM run build

  backend:
    runs-on: ubuntu-latest
    if: \${{ hashFiles('app/backend/requirements.txt') != '' || hashFiles('app/backend/package.json') != '' }}
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        if: \${{ hashFiles('app/backend/requirements.txt') != '' }}
        uses: actions/setup-python@v5
        with:
          python-version: '$PY_VER'
      - name: Setup Node
        if: \${{ hashFiles('app/backend/package.json') != '' }}
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install dependencies
        working-directory: app/backend
        run: $BE_INSTALL
      - name: Test
        working-directory: app/backend
        run: $BE_TEST
EOF

# --- deploy.yml ---
DEPLOY_ENV=$(jq -r '.stack.infrastructure.deployment_environment // "AWS Lightsail"' "$STACK_JSON")
STRATEGY=$(jq -r '.decisions.deployment_strategy // "Continuous Delivery (CDelivery)"' "$STACK_JSON")

cat > .github/workflows/deploy.yml <<EOF
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: \${{ github.actor }}
          password: \${{ secrets.GITHUB_TOKEN }}

      - name: Build & push backend
        if: \${{ hashFiles('docker/backend/Dockerfile.prod') != '' }}
        uses: docker/build-push-action@v6
        with:
          context: ./app/backend
          file: ./docker/backend/Dockerfile.prod
          push: true
          tags: ghcr.io/\${{ github.repository_owner }}/\${{ github.event.repository.name }}-backend:latest

      - name: Build & push frontend
        if: \${{ hashFiles('docker/frontend/Dockerfile.prod') != '' }}
        uses: docker/build-push-action@v6
        with:
          context: ./app/frontend
          file: ./docker/frontend/Dockerfile.prod
          push: true
          tags: ghcr.io/\${{ github.repository_owner }}/\${{ github.event.repository.name }}-frontend:latest

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    # 배포 전략: $STRATEGY
    # 대상 환경: $DEPLOY_ENV
    environment: production
    steps:
      - name: Deploy notice
        run: |
          echo "TODO: $DEPLOY_ENV 배포 단계 구현 필요"
          echo "예: AWS Lightsail SSH로 docker pull & restart"
          echo "    또는 ECS/Kubernetes/Cloud Run 등 대상별 액션"
EOF

echo "✓ GitHub Actions 워크플로우 생성:"
echo "  - .github/workflows/ci.yml (Frontend $FE_PM + Backend $BE)"
echo "  - .github/workflows/deploy.yml (대상: $DEPLOY_ENV, 전략: $STRATEGY)"
echo ""
echo "⚠ deploy.yml의 실제 배포 단계는 환경별로 다름 — 수동 보완 필요"
