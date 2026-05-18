#!/bin/bash
# ============================================================================
# generate-dockerfiles.sh
#
# .claude/stack.json 기반으로 docker/{backend,frontend,nginx}/Dockerfile.*를 생성.
# 각 스택별 베이스 이미지/빌드 명령을 선택.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

STACK_JSON=".claude/stack.json"
[ -f "$STACK_JSON" ] || { echo "✗ $STACK_JSON 없음"; exit 1; }
command -v jq >/dev/null || { echo "✗ jq 필요"; exit 1; }

FE=$(jq -r '.stack.frontend.ui_framework // "none"' "$STACK_JSON")
FE_BUILD=$(jq -r '.stack.frontend.build_tool // "none"' "$STACK_JSON")
FE_PM=$(jq -r '.stack.frontend.package_manager // "pnpm"' "$STACK_JSON")
BE=$(jq -r '.stack.backend.framework // "none"' "$STACK_JSON")
BE_LANG=$(jq -r '.stack.backend.language // "none"' "$STACK_JSON")

mkdir -p docker/backend docker/frontend docker/nginx

# --- Backend Dockerfile.prod ---
case "$BE" in
    FastAPI)
        cat > docker/backend/Dockerfile.prod <<'EOF'
FROM python:3.12-slim AS base
WORKDIR /app
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1

COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . .
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8000/health || exit 1
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
EOF
        ;;
    Django)
        cat > docker/backend/Dockerfile.prod <<'EOF'
FROM python:3.12-slim
WORKDIR /app
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1

COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt gunicorn

COPY . .
RUN python manage.py collectstatic --noinput
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8000/health/ || exit 1
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4"]
EOF
        ;;
    Express)
        cat > docker/backend/Dockerfile.prod <<'EOF'
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD wget -qO- http://localhost:3000/healthz || exit 1
CMD ["node", "src/server.js"]
EOF
        ;;
    *)
        echo "⚠ Backend '$BE' 미지원 — 수동으로 docker/backend/Dockerfile.prod 작성 필요"
        cat > docker/backend/Dockerfile.prod <<EOF
# TODO: '$BE' backend Dockerfile 작성 필요
# 베이스 이미지, 빌드 명령, 헬스 체크를 추가하세요.
EOF
        ;;
esac

# --- Frontend Dockerfile.prod ---
case "$FE-$FE_BUILD" in
    *Next.js*)
        cat > docker/frontend/Dockerfile.prod <<'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json pnpm-lock.yaml* ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "node_modules/.bin/next", "start"]
EOF
        ;;
    React-Vite|Vue-Vite|Svelte-Vite|*-Vite)
        cat > docker/frontend/Dockerfile.prod <<EOF
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json pnpm-lock.yaml* yarn.lock* ./
RUN corepack enable && ${FE_PM} install --frozen-lockfile
COPY . .
RUN ${FE_PM} run build

# 정적 자산을 nginx로 서빙
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
EOF
        ;;
    *)
        echo "⚠ Frontend '$FE/$FE_BUILD' 미지원 — 수동 작성 필요"
        cat > docker/frontend/Dockerfile.prod <<EOF
# TODO: '$FE/$FE_BUILD' frontend Dockerfile 작성 필요
EOF
        ;;
esac

# --- Nginx Dockerfile ---
cat > docker/nginx/Dockerfile <<'EOF'
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/
EXPOSE 80 443
EOF

cat > docker/nginx/nginx.conf <<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

events { worker_connections 1024; }

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" "$http_user_agent"';
    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;
    gzip on;
    include /etc/nginx/conf.d/*.conf;
}
EOF

mkdir -p docker/nginx/conf.d
cat > docker/nginx/conf.d/default.conf <<'EOF'
upstream backend { server backend:8000; }
upstream frontend { server frontend:80; }

server {
    listen 80;
    server_name _;

    location /api/ {
        proxy_pass http://backend/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://frontend/;
        proxy_set_header Host $host;
    }
}
EOF

echo "✓ Dockerfile 생성 완료:"
echo "  - docker/backend/Dockerfile.prod ($BE)"
echo "  - docker/frontend/Dockerfile.prod ($FE-$FE_BUILD)"
echo "  - docker/nginx/Dockerfile + nginx.conf + default.conf"
