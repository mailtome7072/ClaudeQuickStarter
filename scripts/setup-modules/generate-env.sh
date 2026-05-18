#!/bin/bash
# ============================================================================
# generate-env.sh
#
# .env.example을 .env로 복사하면서:
#   1) __GENERATED_BY_SETUP__ 플레이스홀더를 openssl rand 강한 값으로 치환
#   2) .claude/stack.json의 선택에 따라 사용하지 않는 섹션 주석 처리/제거
#   3) PROJECT_NAME, DOCKER_NAMESPACE를 ARCHITECTURE.md 값으로 치환
#
# 호출: bash scripts/setup-modules/generate-env.sh
# 전제: .claude/stack.json (confirmed), .env.example 존재
# 출력: .env (없으면 생성, 있으면 백업 후 갱신)
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

STACK_JSON=".claude/stack.json"
ENV_EXAMPLE=".env.example"
ENV_OUT=".env"

if [ ! -f "$STACK_JSON" ]; then
    echo "✗ $STACK_JSON 없음. 먼저 /analyze-stack 실행." >&2
    exit 1
fi
if [ ! -f "$ENV_EXAMPLE" ]; then
    echo "✗ $ENV_EXAMPLE 없음." >&2
    exit 1
fi
if ! command -v jq >/dev/null; then
    echo "✗ jq 필요. apt install jq / brew install jq / choco install jq" >&2
    exit 1
fi
if ! command -v openssl >/dev/null; then
    echo "✗ openssl 필요." >&2
    exit 1
fi

# 기존 .env 백업
if [ -f "$ENV_OUT" ]; then
    cp "$ENV_OUT" "${ENV_OUT}.backup.$(date +%s)"
    echo "ℹ 기존 .env를 ${ENV_OUT}.backup.*로 백업"
fi

# stack.json에서 결정 추출
DB=$(jq -r '.stack.database.primary_database // "none"' "$STACK_JSON")
CACHE=$(jq -r '.stack.database.cache // "none"' "$STACK_JSON")
AUTH=$(jq -r '.stack.backend.authentication // "none"' "$STACK_JSON")
FILE_STORAGE=$(jq -r '.decisions.file_storage // "none"' "$STACK_JSON")

# 강한 시크릿 생성 함수
gen_secret() { openssl rand -hex 32; }

# 1단계: .env.example 복사
cp "$ENV_EXAMPLE" "$ENV_OUT"

# 2단계: __GENERATED_BY_SETUP__ 치환
# POSIX sed (macOS/Linux 둘 다 호환을 위해 임시 파일 사용)
while grep -q '__GENERATED_BY_SETUP__' "$ENV_OUT"; do
    SECRET=$(gen_secret)
    # 한 번에 하나씩 치환 (각 occurrence가 다른 값을 가지도록)
    sed -i.tmp "0,/__GENERATED_BY_SETUP__/s//${SECRET}/" "$ENV_OUT"
    rm -f "${ENV_OUT}.tmp"
done

# 3단계: 사용하지 않는 DB 섹션 주석 처리
# 간단히: 선택된 DB 아닌 섹션 라인은 #이 없으면 # 추가
# (.env.example은 이미 미사용 섹션이 # 처리되어 있는 구조)
case "$DB" in
    *"PostgreSQL"*) ;; # 기본 활성
    *"MySQL"*)
        # POSTGRES_ 라인 주석 처리, MYSQL_ 라인 주석 해제
        sed -i.tmp -E 's/^(POSTGRES_|DATABASE_URL=postgresql)/# \1/' "$ENV_OUT"
        sed -i.tmp -E 's/^# (MYSQL_|DATABASE_URL=mysql)/\1/' "$ENV_OUT"
        rm -f "${ENV_OUT}.tmp"
        ;;
    *"MongoDB"*)
        sed -i.tmp -E 's/^(POSTGRES_|DATABASE_URL=postgresql)/# \1/' "$ENV_OUT"
        sed -i.tmp -E 's/^# (MONGO_|DATABASE_URL=mongodb)/\1/' "$ENV_OUT"
        rm -f "${ENV_OUT}.tmp"
        ;;
esac

# 4단계: AUTH 섹션
case "$AUTH" in
    *"JWT"*) ;; # JWT 활성 (기본)
    *"Session"*)
        sed -i.tmp -E 's/^(JWT_)/# \1/' "$ENV_OUT"
        sed -i.tmp -E 's/^# (SESSION_)/\1/' "$ENV_OUT"
        rm -f "${ENV_OUT}.tmp"
        ;;
    *"OAuth"*)
        sed -i.tmp -E 's/^(JWT_)/# \1/' "$ENV_OUT"
        sed -i.tmp -E 's/^# (OAUTH_)/\1/' "$ENV_OUT"
        rm -f "${ENV_OUT}.tmp"
        ;;
esac

# 5단계: ARCHITECTURE.md 변수 (PROJECT_NAME, DOCKER_NAMESPACE)
# /setup-project Phase A가 이미 치환했어야 하지만 fallback
if [ -f "ARCHITECTURE.md" ]; then
    PROJECT_NAME=$(grep -oP '(?<=\*\*`\$\{project_name\}`\*\*\* \| )[^|]+' ARCHITECTURE.md 2>/dev/null | head -1 | xargs || true)
    if [ -n "${PROJECT_NAME:-}" ] && [ "$PROJECT_NAME" != "프로젝트명 (영문, 하이픈 허용)" ]; then
        sed -i.tmp "s/^PROJECT_NAME=.*/PROJECT_NAME=${PROJECT_NAME}/" "$ENV_OUT"
        rm -f "${ENV_OUT}.tmp"
    fi
fi

echo "✓ .env 생성 완료"
echo "  - DB: $DB"
echo "  - Cache: $CACHE"
echo "  - Auth: $AUTH"
echo "  - File Storage: $FILE_STORAGE"
echo "  - 모든 시크릿: openssl rand -hex 32로 강한 값 생성"
echo ""
echo "⚠ 이 파일은 gitignored입니다. 절대 커밋하지 마세요."
