#!/bin/bash
# ============================================================================
# setup-backend-django.sh (스텁)
#
# Django 5 + DRF 스캐폴드. 향후 자동화 예정.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "⚠ Django 백엔드 자동 스캐폴드는 아직 구현되지 않았습니다."
echo ""
echo "임시 방안:"
echo "  cd app/backend"
echo "  python3 -m venv .venv"
echo "  source .venv/bin/activate  # Windows: .venv\\Scripts\\activate"
echo "  pip install django djangorestframework"
echo "  django-admin startproject config ."
echo "  python manage.py startapp api"
echo ""
echo "스캐폴드 후 SETUP.sh를 다시 실행하세요."
exit 0
