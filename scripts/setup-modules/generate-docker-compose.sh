#!/bin/bash
# ============================================================================
# generate-docker-compose.sh
#
# scripts/setup-modules/templates/docker-compose.prod.yml.template을 기반으로
# .claude/stack.json의 선택에 따라 조건부 섹션을 활성화/제거하여
# docker-compose.prod.yml과 docker-compose.yml(로컬)을 생성합니다.
#
# 조건부 마커 형식 (템플릿 내):
#   # @if database.primary_database startswith "PostgreSQL"
#   ...
#   # @endif
#
# 호출: bash scripts/setup-modules/generate-docker-compose.sh
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

STACK_JSON=".claude/stack.json"
TEMPLATE="scripts/setup-modules/templates/docker-compose.prod.yml.template"
OUT_PROD="docker-compose.prod.yml"
OUT_DEV="docker-compose.yml"

[ -f "$STACK_JSON" ] || { echo "✗ $STACK_JSON 없음"; exit 1; }
[ -f "$TEMPLATE" ] || { echo "✗ $TEMPLATE 없음"; exit 1; }
command -v jq >/dev/null || { echo "✗ jq 필요"; exit 1; }

# 결정값 추출
DB=$(jq -r '.stack.database.primary_database // "none"' "$STACK_JSON")
CACHE=$(jq -r '.stack.database.cache // "none"' "$STACK_JSON")
AUTH=$(jq -r '.stack.backend.authentication // "none"' "$STACK_JSON")
FE=$(jq -r '.stack.frontend.ui_framework // "none"' "$STACK_JSON")
FE_BUILD=$(jq -r '.stack.frontend.build_tool // "none"' "$STACK_JSON")
BE=$(jq -r '.stack.backend.framework // "none"' "$STACK_JSON")

# Frontend env var 결정
case "$FE-$FE_BUILD" in
    *Next.js*) FE_API_ENV="NEXT_PUBLIC_API_URL"; FE_PORT=3000 ;;
    *Nuxt*)    FE_API_ENV="NUXT_PUBLIC_API_URL"; FE_PORT=3000 ;;
    *-Vite|React-Vite|Vue-Vite|Svelte-Vite) FE_API_ENV="VITE_API_URL"; FE_PORT=5173 ;;
    *) FE_API_ENV="REACT_APP_API_URL"; FE_PORT=3000 ;;  # CRA fallback
esac

# Backend port/health 결정
case "$BE" in
    FastAPI)   BE_PORT=8000; HEALTH=/health ;;
    Django)    BE_PORT=8000; HEALTH=/health/ ;;
    Express)   BE_PORT=3000; HEALTH=/healthz ;;
    "Spring Boot") BE_PORT=8080; HEALTH=/actuator/health ;;
    *)         BE_PORT=8000; HEALTH=/health ;;
esac

# 조건부 매처
should_include() {
    local cond="$1"
    case "$cond" in
        'database.primary_database startswith "PostgreSQL"')
            [[ "$DB" == PostgreSQL* ]] ;;
        'database.primary_database startswith "MySQL"')
            [[ "$DB" == MySQL* ]] ;;
        'database.primary_database startswith "MongoDB"')
            [[ "$DB" == MongoDB* ]] ;;
        'database.cache startswith "Redis"')
            [[ "$CACHE" == Redis* ]] ;;
        'backend.authentication contains "JWT"')
            [[ "$AUTH" == *JWT* ]] ;;
        *)
            echo "⚠ 알 수 없는 조건: $cond" >&2
            return 0 ;;
    esac
}

# 템플릿 처리: @if/@endif 블록 필터링
process_template() {
    local include=1
    local stack_includes=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*@if[[:space:]]+(.+)$ ]]; then
            local cond="${BASH_REMATCH[1]}"
            if should_include "$cond"; then
                stack_includes+=(1)
            else
                stack_includes+=(0)
            fi
            include=$(IFS=*; echo "$((${stack_includes[*]}))")
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*@endif ]]; then
            unset 'stack_includes[-1]'
            if [ ${#stack_includes[@]} -eq 0 ]; then
                include=1
            else
                include=$(IFS=*; echo "$((${stack_includes[*]}))")
            fi
            continue
        fi
        [ "$include" = "1" ] && echo "$line"
    done
}

# 변수 치환
PROJECT_NAME=$(grep -oP '(?<=^PROJECT_NAME=).*' .env 2>/dev/null | head -1 || echo "my-project")
DOCKER_REG=$(grep -oP '(?<=^DOCKER_REGISTRY=).*' .env 2>/dev/null | head -1 || echo "ghcr.io")
DOCKER_NS=$(grep -oP '(?<=^DOCKER_NAMESPACE=).*' .env 2>/dev/null | head -1 || echo "your-org")

# 처리 + 변수 치환
process_template < "$TEMPLATE" \
    | sed -e "s|\${FRONTEND_API_ENV_VAR}|$FE_API_ENV|g" \
          -e "s|\${BACKEND_PORT}|$BE_PORT|g" \
          -e "s|\${HEALTH_PATH}|$HEALTH|g" \
          -e "s|\${FRONTEND_API_URL}|http://backend:$BE_PORT|g" \
    > "$OUT_PROD"

# 개발용 (로컬): nginx 서비스 제외, backend/frontend는 image 대신 build 사용
# awk로 nginx 블록(# === Nginx ===부터 다음 최상위 키워드 직전까지) 제거
awk '
    /^[[:space:]]*# === Nginx/ { skip=1; next }
    /^volumes:/ || /^networks:/ { skip=0 }
    !skip { print }
' "$OUT_PROD" \
    | sed -e "s|^    image: \${DOCKER_REGISTRY}.*-backend:latest|    build:\n      context: ./app/backend\n      dockerfile: ../../docker/backend/Dockerfile.prod|" \
          -e "s|^    image: \${DOCKER_REGISTRY}.*-frontend:latest|    build:\n      context: ./app/frontend\n      dockerfile: ../../docker/frontend/Dockerfile.prod|" \
          -e "s|\${PROJECT_NAME}|$PROJECT_NAME|g" \
    > "$OUT_DEV"

# 개발용 포트 노출 안내 주석
cat >> "$OUT_DEV" << 'EOF'

# (개발용 포트 노출은 각 서비스에 ports: 섹션을 추가해서 사용)
# 예시:
#   backend.ports:  ["8000:8000"]
#   frontend.ports: ["5173:5173"]
EOF

echo "✓ docker-compose.prod.yml 생성: $OUT_PROD"
echo "✓ docker-compose.yml (개발) 생성: $OUT_DEV"
echo "  - Frontend API env: $FE_API_ENV (port $FE_PORT)"
echo "  - Backend: $BE (port $BE_PORT, health $HEALTH)"
echo "  - DB: $DB, Cache: $CACHE, Auth: $AUTH"
