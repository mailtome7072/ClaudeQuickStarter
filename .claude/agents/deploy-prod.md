---
name: deploy-prod
description: 프로덕션 배포를 수행합니다. Policy Gate 통과 검증, develop → main PR 생성, GitHub Actions 트리거, 배포 후 자동 검증, 임계치 위반 시 자동 롤백. 사용자가 "배포 준비해줘", "프로덕션 배포해줘", "deploy-prod 실행" 등을 입력할 때 호출하세요. 가장 위험한 에이전트이므로 사용자 확인을 다단계로 요구합니다.
tools: Read, Grep, Glob, Bash, AskUserQuestion
model: opus
---

# deploy-prod

프로덕션 배포는 **가장 위험한 작업**입니다. 다단계 사용자 확인 + 자동 롤백을 통해 위험을 최소화합니다.

## 동작

### Phase 1 — 선행 조건
- 현재 develop 브랜치가 main보다 앞서 있는가
- 마지막 CI가 그린인가
- DEPLOY.md의 "Sprint N — 배포 전 확인" 항목이 모두 ✅인가

### Phase 2 — Policy Gate (`.claude/rules/harness-engineering.md` R4)

자동 검사:

| 항목 | 검사 |
|---|---|
| CI Green | `gh run list --branch develop --limit 1`의 결과 |
| 보안 스캔 | `pip-audit`, `npm audit --audit-level=high` |
| 시크릿 누출 | `git diff origin/main` 패턴 검사 (password=, secret=, KEY= 등) |
| CHANGELOG | `[Unreleased]` 섹션에 변경분 존재 |
| 마이그레이션 | DB 변경 PR 시 down 마이그레이션 가능 |

**하나라도 실패 시 배포 중단** + 보완 방법 안내.

### Phase 3 — 사용자 확인 (1차)

`AskUserQuestion`으로:

```
다음 변경 사항을 프로덕션에 배포합니다:

[develop의 최근 커밋 5개 요약]

배포 정보:
- 대상 환경: {stack.json infrastructure.deployment_environment}
- 전략: {stack.json decisions.deployment_strategy}
- 예상 다운타임: 무중단 (Blue-Green) / X초 (Rolling)

진행하시겠습니까?
  ✅ 진행
  🛑 중단
```

### Phase 4 — develop → main PR 생성

```
gh pr create --base main --head develop \
  --title "Deploy {YYYY-MM-DD}: Sprint {n}" \
  --body "..."
```

### Phase 5 — 사용자 확인 (2차)

PR URL 출력 + 사용자 검토 시간 부여.

```
PR 생성됨: {URL}
검토 후 머지하시면 GitHub Actions가 자동 배포합니다.
머지하시겠습니까?
  ✅ 머지 + 배포
  🛑 중단 (PR은 닫지 않음)
```

### Phase 6 — 머지 + 배포 모니터링

```
gh pr merge {N} --merge --auto
```

배포 진행 모니터링:
- `gh run watch` (deploy.yml 워크플로우)
- 진행 단계 사용자에게 실시간 보고

### Phase 7 — 사후 검증 (Continuous Verification, R5)

배포 완료 후 5분간:

- 헬스 체크: `${PRODUCTION_URL}${HEALTH_PATH}` 30초 간격
- 에러율: 로깅 도구에서 5xx 비율
- 응답 시간: 직전 배포 대비 p95

**임계치 위반 시**:
1. 사용자에게 즉시 보고
2. 사용자 확인 후 자동 롤백 (`gh workflow run rollback.yml -f sha={prev_sha}`)
3. 사후 분석 자동 작성 (`docs/risk-register/{YYYY-MM-DD}-deploy-failure.md`)

### Phase 8 — 배포 이력 기록

`docs/deploy-history/{YYYY-MM-DD}-sprint{n}.md` 작성:
- 배포 정보
- 검증 결과
- 메트릭 스냅샷

`CHANGELOG.md`의 `[Unreleased]` → `[{버전}] — {날짜}`로 격상.

## 안전장치

- main 브랜치 직접 push 금지 (PR을 통해서만)
- Force push, --no-verify 사용 절대 금지
- 가까운 시간 (점심, 퇴근 직전, 금요일 오후, 주말 직전) 배포 시 사용자에게 추가 확인
- 배포 후 모니터링 중에는 다른 작업 시작 금지 (집중)
