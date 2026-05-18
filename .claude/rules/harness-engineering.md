# 하네스 엔지니어링 규칙 (에이전트 동작 규칙)

> 이 문서는 모든 Claude Code 에이전트가 따라야 하는 정책입니다.
> 정책 배경은 `docs/harness-engineering/README.md` 참고.

---

## R1. Planning First

### 의무
**Edit, Write, NotebookEdit 도구 사용 전**에 다음을 확인:

- 현재 작업의 `scope.md`가 있는가? (`.claude/tmp/scope.md` 또는 PR 디렉터리)
- scope.md에 명시된 파일만 수정하는가?
- 변경의 목표/검증 방법이 명시되어 있는가?

scope.md 없이 작업 시작 시:
```markdown
ℹ scope.md가 없습니다. 다음 정보를 정리해 주세요:
- 목표:
- 영향 받는 파일:
- 검증 방법:
- 롤백 조건:
```

### 예외
- 단일 파일 한 줄 수정 (오타, 변수명 등): 생략 가능
- `/init`, `/setup-project` 등 메타 커맨드 자체 실행: 생략 가능

---

## R2. Forbidden Areas

### 명시적 허가 없이 수정 금지

```
.github/workflows/**
SETUP.sh
SETUP.ps1
scripts/setup-modules/**
scripts/hooks/**
docker-compose.prod.yml
docker/*/Dockerfile.prod
docs/harness-engineering/**
.claude/rules/**
.claude/settings.json
```

### 사용자 허가 절차

사용자가 명시적으로 다음 중 하나를 입력해야 함:
- "Forbidden area 수정 허가: <경로>"
- "이 파일 수정해도 됨" (구체적 파일 언급)
- 슬래시 커맨드 사용 (예: `/update-config`)

허가 후에도 변경 사항은 명확히 출력하여 사용자가 검토 가능하게.

---

## R3. Loop Detection

### 동일 파일 3회 수정 감지

`posttooluse-loop-detector.sh` 훅이 자동으로 감지하지만, 에이전트도 자체 점검:

- 한 세션에서 같은 파일을 3번째 수정 시도 시 일시정지
- 다음 질문을 자체적으로 답변:
  1. "내 접근 방식이 잘못된 것은 아닌가?"
  2. "근본 원인이 다른 곳에 있는 것은 아닌가?"
  3. "테스트가 내 의도를 실제로 검증하는가?"
- 답변 후에도 동일 파일 수정이 필요하다고 판단되면 진행, **이유를 명시**

---

## R4. Policy Gate (배포 전)

### `deploy-prod` 또는 main 브랜치 PR 생성 직전 검사

| 항목 | 검사 방법 |
|---|---|
| 테스트 통과 | CI 그린 확인 (last commit) |
| 린트 통과 | ruff/eslint 종료 코드 0 |
| 보안 스캔 | `pip-audit`, `npm audit --audit-level=high` |
| 시크릿 누출 | `git diff origin/main`에서 `password=`, `secret=`, `KEY=` 등 검사 |
| CHANGELOG | 마지막 release 이후 변경분 기록 여부 |
| 마이그레이션 | DB 변경 PR이면 마이그레이션 파일 존재 + 다운그레이드 가능 |

### 실패 시
- 자동 차단 (PR 생성 또는 머지 거부)
- 누락 항목 명시 + 보완 방법 안내

---

## R5. Continuous Verification (배포 후)

### `deploy-prod` 에이전트가 N분간 모니터링

- 헬스 체크: `${PRODUCTION_URL}${HEALTH_PATH}` 30초 간격
- 에러율: 로깅 도구(`stack.json` `infrastructure.logging`)에서 5xx 비율
- 응답 시간: 직전 배포 대비 p95 비교

### 임계치 위반 시
1. 즉시 사용자에게 보고
2. 사용자 확인 후 자동 롤백 (이전 Docker 이미지 태그로)
3. 사후 분석 보고서를 `docs/risk-register/`에 작성

---

## 일반 원칙

### 의도 보존
- 사용자가 명시한 의도를 임의로 확장하지 말 것
- "그 김에 ~도 해줄게" 금지 (별도 작업으로 제안)

### 정직한 보고
- 시도했으나 실패한 부분은 명확히 보고
- "완료"라고 말하기 전에 실제 검증 (테스트 실행, 파일 확인 등)

### 비용 의식
- 토큰/시간 비용이 큰 작업(전체 코드베이스 재작성 등) 전 사용자 확인
- 반복 작업은 스크립트화 검토
