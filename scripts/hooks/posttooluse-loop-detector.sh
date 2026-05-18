#!/bin/bash
# ============================================================================
# posttooluse-loop-detector.sh
#
# Edit/Write 후 호출. 같은 파일을 N(=3)회 수정 시 경고.
# 카운터는 .claude/tmp/edit-counts.json에 누적.
# 세션 시작 시 카운터 리셋: rm .claude/tmp/edit-counts.json
# ============================================================================
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COUNTS_FILE="$PROJECT_ROOT/.claude/tmp/edit-counts.json"
THRESHOLD=3

mkdir -p "$(dirname "$COUNTS_FILE")"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"
REL_PATH="${REL_PATH#./}"

# 카운터 로드/초기화
if [ ! -f "$COUNTS_FILE" ]; then
    echo '{}' > "$COUNTS_FILE"
fi

# 증가
NEW_COUNT=$(jq --arg p "$REL_PATH" '
    .[$p] = (.[$p] // 0) + 1 | .[$p]
' "$COUNTS_FILE")

jq --arg p "$REL_PATH" --argjson n "$NEW_COUNT" '.[$p] = $n' "$COUNTS_FILE" > "${COUNTS_FILE}.tmp"
mv "${COUNTS_FILE}.tmp" "$COUNTS_FILE"

# 임계치 도달 시 경고
if [ "$NEW_COUNT" -ge "$THRESHOLD" ]; then
    cat >&2 <<EOF

⚠ Loop Detection: $REL_PATH 이 세션에서 ${NEW_COUNT}회 수정됨 (임계치 $THRESHOLD)

다음을 자체 점검하세요 (docs/harness-engineering/README.md 원칙 3):
  1. 내 접근 방식이 잘못된 것은 아닌가?
  2. 근본 원인이 다른 곳에 있는 것은 아닌가?
  3. 테스트가 내 의도를 실제로 검증하는가?

계속 진행이 필요하다면 사용자에게 이유를 명시하고 동의를 받으세요.
카운터 리셋: rm $COUNTS_FILE
EOF
fi

exit 0
