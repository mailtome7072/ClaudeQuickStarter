#!/bin/bash
# ============================================================================
# setup-backend-django.sh
#
# Django 5 + DRF + drf-spectacular(OpenAPI) 스캐폴드.
# stack.json의 database/cache/authentication 참조하여 의존성 구성.
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

mkdir -p app/backend
cd app/backend

# requirements.txt — 스택 의존
{
    echo "django>=5.1.0,<6.0"
    echo "djangorestframework>=3.15.0"
    echo "django-cors-headers>=4.6.0"
    echo "drf-spectacular>=0.27.0  # OpenAPI/Swagger 자동 생성"
    echo "python-dotenv>=1.0.0"
    echo "gunicorn>=23.0.0  # 프로덕션 WSGI 서버"
    [[ "$DB" == PostgreSQL* ]] && echo "psycopg[binary]>=3.2.0"
    [[ "$DB" == MySQL* ]] && echo "mysqlclient>=2.2.0"
    [[ "$CACHE" == Redis* ]] && echo "django-redis>=5.4.0"
    [[ "$AUTH" == *JWT* ]] && echo "djangorestframework-simplejwt>=5.3.0"
    [[ "$AUTH" == *OAuth* ]] && echo "django-allauth>=65.0.0"
    echo ""
    echo "# Dev"
    echo "pytest>=8.3.0"
    echo "pytest-django>=4.9.0"
    echo "factory-boy>=3.3.0"
    echo "ruff>=0.7.0"
} > requirements.txt

# 가상환경 생성 + 의존성 설치
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
# Windows/Unix 모두 호환
if [ -f ".venv/Scripts/python.exe" ]; then
    PY=".venv/Scripts/python.exe"
elif [ -f ".venv/bin/python" ]; then
    PY=".venv/bin/python"
else
    PY="python3"
fi

"$PY" -m pip install --upgrade pip setuptools wheel >/dev/null
"$PY" -m pip install -r requirements.txt
"$PY" -m pip install django >/dev/null

# Django 프로젝트 스캐폴드 (config 디렉터리에)
if [ ! -f "manage.py" ]; then
    "$PY" -m django startproject config .
    "$PY" manage.py startapp api
fi

# config/settings.py 갱신 — DRF + DB + Cache + Auth 설정
cat > config/settings_app.py <<EOF
"""
ClaudeQuickStarter Django 설정 오버라이드.
config/settings.py에서 마지막에 'from .settings_app import *' 추가하세요.
"""
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()
BASE_DIR = Path(__file__).resolve().parent.parent

# Secret + Debug
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'change-me-in-env')
DEBUG = os.getenv('DJANGO_DEBUG', 'False').lower() == 'true'
ALLOWED_HOSTS = os.getenv('DJANGO_ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

# Apps
INSTALLED_APPS_EXTRA = [
    'rest_framework',
    'corsheaders',
    'drf_spectacular',
    'api',  # 사용자 앱
]
EOF

# DB 설정 추가
case "$DB" in
    PostgreSQL*)
        cat >> config/settings_app.py <<'EOF'

# Database — PostgreSQL
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('POSTGRES_DB', 'project_dev'),
        'USER': os.getenv('POSTGRES_USER', 'postgres'),
        'PASSWORD': os.getenv('POSTGRES_PASSWORD', ''),
        'HOST': os.getenv('POSTGRES_HOST', 'postgres'),
        'PORT': os.getenv('POSTGRES_PORT', '5432'),
    }
}
EOF
        ;;
    MySQL*)
        cat >> config/settings_app.py <<'EOF'

# Database — MySQL
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.getenv('MYSQL_DATABASE', 'project_dev'),
        'USER': os.getenv('MYSQL_USER', 'app'),
        'PASSWORD': os.getenv('MYSQL_PASSWORD', ''),
        'HOST': os.getenv('MYSQL_HOST', 'mysql'),
        'PORT': os.getenv('MYSQL_PORT', '3306'),
    }
}
EOF
        ;;
esac

# Cache 설정
if [[ "$CACHE" == Redis* ]]; then
    cat >> config/settings_app.py <<'EOF'

# Cache — Redis
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': os.getenv('REDIS_URL', 'redis://redis:6379/0'),
        'OPTIONS': { 'CLIENT_CLASS': 'django_redis.client.DefaultClient' },
    }
}
EOF
fi

# DRF + CORS + drf-spectacular
cat >> config/settings_app.py <<'EOF'

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}

# OpenAPI
SPECTACULAR_SETTINGS = {
    'TITLE': 'API',
    'DESCRIPTION': 'Project API',
    'VERSION': '0.1.0',
}

# CORS
CORS_ALLOWED_ORIGINS = os.getenv('CORS_ORIGINS', 'http://localhost:5173,http://localhost:3000').split(',')
CORS_ALLOW_CREDENTIALS = True
EOF

# JWT 설정 (AUTH가 JWT인 경우)
if [[ "$AUTH" == *JWT* ]]; then
    cat >> config/settings_app.py <<'EOF'

# JWT
REST_FRAMEWORK['DEFAULT_AUTHENTICATION_CLASSES'] = (
    'rest_framework_simplejwt.authentication.JWTAuthentication',
)

from datetime import timedelta
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=int(os.getenv('JWT_EXPIRATION_HOURS', '24'))),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=int(os.getenv('JWT_REFRESH_EXPIRATION_DAYS', '7'))),
    'SIGNING_KEY': os.getenv('JWT_SECRET', SECRET_KEY),
}
EOF
fi

# Middleware 갱신
cat >> config/settings_app.py <<'EOF'

# Middleware (CORS는 가능한 한 위에)
MIDDLEWARE_EXTRA = [
    'corsheaders.middleware.CorsMiddleware',
    # 기본 미들웨어는 settings.py의 MIDDLEWARE 리스트 참조
]
EOF

# config/urls.py에 health + schema 라우트 추가
cat > config/urls_app.py <<'EOF'
"""
추가 URL 패턴. config/urls.py의 urlpatterns에 'from .urls_app import urlpatterns as app_urls'로 머지하세요.
"""
from django.urls import path
from django.http import JsonResponse
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView


def health(request):
    return JsonResponse({'status': 'ok'})


def ready(request):
    # TODO: DB/Cache 헬스 체크
    return JsonResponse({'status': 'ready'})


urlpatterns = [
    path('health/', health),
    path('ready/', ready),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
]
EOF

# 첫 테스트
mkdir -p api/tests
cat > api/tests/__init__.py <<'EOF'
EOF
cat > api/tests/test_health.py <<'EOF'
import pytest
from django.test import Client


@pytest.mark.django_db
def test_health():
    client = Client()
    response = client.get('/health/')
    assert response.status_code == 200
    assert response.json() == {'status': 'ok'}
EOF

# pytest 설정
cat > pyproject.toml <<'EOF'
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

[tool.pytest.ini_options]
DJANGO_SETTINGS_MODULE = "config.settings"
python_files = ["tests.py", "test_*.py", "*_tests.py"]
EOF

# 통합 안내
cat > INTEGRATION.md <<'EOF'
# Django 통합 마무리 단계

스캐폴드된 파일을 활성화하려면:

## 1. config/settings.py 마지막에 추가
```python
from .settings_app import *
INSTALLED_APPS += INSTALLED_APPS_EXTRA
MIDDLEWARE = MIDDLEWARE_EXTRA + MIDDLEWARE
```

## 2. config/urls.py 갱신
```python
from .urls_app import urlpatterns as app_urls
urlpatterns += app_urls
```

## 3. 마이그레이션
```bash
.venv/bin/python manage.py migrate
.venv/bin/python manage.py createsuperuser  # 선택
```

## 4. 개발 서버
```bash
.venv/bin/python manage.py runserver 0.0.0.0:8000
```

## 5. 헬스 체크
- http://localhost:8000/health/
- http://localhost:8000/api/docs/ (Swagger UI)
EOF

echo "✓ Django 5 + DRF backend 스캐폴드 완료"
echo "  - DB: $DB, Cache: $CACHE, Auth: $AUTH"
echo "  - 마이그레이션 + 통합: INTEGRATION.md 참조"
echo "  - 개발 서버: .venv/bin/python manage.py runserver"
