#!/bin/bash
# ============================================================================
# pretooluse-scope-validator.sh
#
# Edit/Write/NotebookEdit 도구 사용 전 scope.md 존재 확인.
# 미존재 시 경고만 출력하고 허용 (block_on_missing=false 기본).
# 엄격 모드는 .claude/hooks-config.json의 scope_validator.strict=true로 활성화.
#
# 입력: stdin JSON (Claude Code 훅 표준)
# 출력: exit 0 = 허용 / exit 2 + stderr = 차단
# ============================================================================
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCOPE_FILE="$PROJECT_ROOT/.claude/tmp/scope.md"
CONFIG_FILE="$PROJECT_ROOT/.claude/hooks-config.json"

# 입력 파싱 (선택적)
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null)

# 메타 커맨드는 면제
case "$TOOL_NAME" in
    "") exit 0 ;;
esac

# 엄격 모드 확인
STRICT="false"
if [ -f "$CONFIG_FILE" ] && command -v jq >/dev/null; then
    STRICT=$(jq -r '.scope_validator.strict // false' "$CONFIG_FILE" 2>/dev/null)
fi

# scope.md 존재 확인
if [ -f "$SCOPE_FILE" ]; then
    exit 0  # 정상
fi

# 없음 — 안내 메시지
MSG="ℹ scope.md가 없습니다 ($SCOPE_FILE). 작업 시작 전 다음을 정리하세요:
  - 목표:
  - 영향 받는 파일:
  - 검증 방법:
  - 롤백 조건:

(엄격 모드: .claude/hooks-config.json의 scope_validator.strict=true)"

if [ "$STRICT" = "true" ]; then
    echo "$MSG" >&2
    exit 2  # 차단
else
    echo "$MSG" >&2
    exit 0  # 경고만, 허용
fi
