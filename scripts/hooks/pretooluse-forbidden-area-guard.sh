#!/bin/bash
# ============================================================================
# pretooluse-forbidden-area-guard.sh
#
# Edit/Write 대상 경로가 Forbidden Area에 속하면 차단.
# 우회 방법: 환경변수 CLAUDE_ALLOW_FORBIDDEN=1 또는
#           .claude/tmp/forbidden-override 파일 생성 (단일 작업 후 자동 삭제됨)
#
# 입력: stdin JSON ({tool_name, tool_input: {file_path}})
# 출력: exit 0 = 허용 / exit 2 + stderr = 차단
# ============================================================================
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OVERRIDE_FILE="$PROJECT_ROOT/.claude/tmp/forbidden-override"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

# 절대경로를 프로젝트 상대경로로 정규화
REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"
REL_PATH="${REL_PATH#./}"

# Forbidden 패턴
FORBIDDEN_PATTERNS=(
    "^\.github/workflows/"
    "^SETUP\.sh$"
    "^SETUP\.ps1$"
    "^scripts/setup-modules/"
    "^scripts/hooks/"
    "^docker-compose\.prod\.yml$"
    "^docker/[^/]+/Dockerfile\.prod$"
    "^docs/harness-engineering/"
    "^\.claude/rules/"
    "^\.claude/settings\.json$"
)

IS_FORBIDDEN=0
MATCHED=""
for pat in "${FORBIDDEN_PATTERNS[@]}"; do
    if [[ "$REL_PATH" =~ $pat ]]; then
        IS_FORBIDDEN=1
        MATCHED="$pat"
        break
    fi
done

[ "$IS_FORBIDDEN" -eq 0 ] && exit 0

# 우회 확인
if [ "${CLAUDE_ALLOW_FORBIDDEN:-0}" = "1" ]; then
    echo "⚠ Forbidden area 수정 허가됨 (env CLAUDE_ALLOW_FORBIDDEN=1): $REL_PATH" >&2
    exit 0
fi

if [ -f "$OVERRIDE_FILE" ]; then
    echo "⚠ Forbidden area 일회성 허가 사용: $REL_PATH" >&2
    rm -f "$OVERRIDE_FILE"
    exit 0
fi

# 차단
cat >&2 <<EOF
✗ Forbidden area 수정 시도 차단됨

파일: $REL_PATH
매칭 패턴: $MATCHED

이 영역은 사용자 명시적 허가 없이 수정할 수 없습니다.
(정책: docs/harness-engineering/README.md 원칙 2)

수정이 필요한 경우 사용자가 다음 중 하나를 실행해야 합니다:
  1. 환경변수: CLAUDE_ALLOW_FORBIDDEN=1 (세션 전체 허용)
  2. 일회성: touch .claude/tmp/forbidden-override (다음 1회만 허용)
EOF
exit 2
