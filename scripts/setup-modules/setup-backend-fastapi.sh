#!/bin/bash
# ============================================================================
# setup-backend-fastapi.sh
#
# FastAPI + SQLAlchemy + Alembic 기본 구조를 app/backend/에 스캐폴드.
# stack.json의 database.primary_database / cache / authentication 참조.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

STACK_JSON=".claude/stack.json"
[ -f "$STACK_JSON" ] || { echo "✗ $STACK_JSON 없음"; exit 1; }
command -v jq >/dev/null || { echo "✗ jq 필요"; exit 1; }
command -v python3 >/dev/null || { echo "✗ python3 필요"; exit 1; }

DB=$(jq -r '.stack.database.primary_database // "none"' "$STACK_JSON")
CACHE=$(jq -r '.stack.database.cache // "none"' "$STACK_JSON")
AUTH=$(jq -r '.stack.backend.authentication // "none"' "$STACK_JSON")
ORM=$(jq -r '.stack.backend.orm // "SQLAlchemy"' "$STACK_JSON")

mkdir -p app/backend/{app,app/api,app/api/routes,app/core,app/models,app/schemas,app/services,app/tests,alembic}
cd app/backend

# requirements.txt — 스택 의존
{
    echo "fastapi>=0.115.0"
    echo "uvicorn[standard]>=0.32.0"
    echo "pydantic>=2.9.0"
    echo "pydantic-settings>=2.6.0"
    echo "python-dotenv>=1.0.0"
    [ "$ORM" = "SQLAlchemy" ] && echo "sqlalchemy>=2.0.0" && echo "alembic>=1.13.0"
    [[ "$DB" == PostgreSQL* ]] && echo "psycopg2-binary>=2.9.10"
    [[ "$DB" == MySQL* ]] && echo "pymysql>=1.1.1" && echo "cryptography"
    [[ "$DB" == MongoDB* ]] && echo "motor>=3.6.0"
    [[ "$CACHE" == Redis* ]] && echo "redis>=5.2.0"
    [[ "$AUTH" == *JWT* ]] && echo "python-jose[cryptography]>=3.3.0" && echo "passlib[bcrypt]>=1.7.4"
    echo "httpx>=0.27.0  # 테스트용"
    echo ""
    echo "# Dev"
    echo "pytest>=8.3.0"
    echo "pytest-asyncio>=0.24.0"
    echo "ruff>=0.7.0"
} > requirements.txt

# app/main.py — 최소 엔트리포인트
cat > app/main.py <<'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings

app = FastAPI(title=settings.PROJECT_NAME, version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/ready")
def ready():
    # TODO: DB/Redis 연결 확인
    return {"status": "ready"}
EOF

# app/core/config.py
cat > app/core/config.py <<'EOF'
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "my-project"
    DATABASE_URL: str = "sqlite:///./dev.db"
    JWT_SECRET: str = "change_me"
    JWT_ALGORITHM: str = "HS256"
    CORS_ORIGINS: list[str] = ["http://localhost:5173"]

    class Config:
        env_file = ".env"

settings = Settings()
EOF

# pyproject.toml — 린트/포맷 설정
cat > pyproject.toml <<'EOF'
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["app/tests"]
EOF

# 첫 테스트
cat > app/tests/test_health.py <<'EOF'
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}
EOF

# Alembic 초기화 (조건부)
if [ "$ORM" = "SQLAlchemy" ] && [[ "$DB" == PostgreSQL* || "$DB" == MySQL* ]]; then
    cat > alembic.ini <<'EOF'
[alembic]
script_location = alembic
sqlalchemy.url = driver://user:pass@host/dbname
EOF
    echo "ℹ alembic init은 가상환경 생성 후 실행: alembic init alembic"
fi

echo "✓ FastAPI backend 스캐폴드 완료"
echo "  - DB: $DB, Cache: $CACHE, Auth: $AUTH, ORM: $ORM"
echo "  - 가상환경 + 의존성 설치: SETUP.sh가 수행"
