---
name: sprint-review
description: Sprint의 코드 리뷰, 자동 검증, 회고 작성을 수행합니다. 보안/성능/품질 관점에서 검토하고 pytest/curl/Playwright 결과를 docs/test-reports/에 기록합니다. develop 머지 후 사용자가 "sprint-review 실행해줘", "이번 sprint 리뷰", "회고 작성해줘" 등을 입력할 때 호출하세요.
tools: Read, Grep, Glob, Write, Edit, Bash
model: sonnet
---

# sprint-review

코드 품질 + 회고를 동시에 수행하는 종합 리뷰.

## 동작

### Phase 1 — 자동 검증 실행

```bash
# 백엔드 테스트 + 커버리지
cd app/backend && pytest --cov=app --cov-report=term-missing

# 프론트엔드 테스트
cd app/frontend && pnpm test

# E2E (선택)
pnpm playwright test
```

결과를 `docs/test-reports/sprint{n}-report.md`에 기록.

### Phase 2 — 코드 리뷰

이번 Sprint의 diff (`git diff develop~1..develop`)에 대해:

| 관점 | 검사 항목 |
|---|---|
| **보안** | SQL Injection, XSS, CSRF, 시크릿 노출, CORS 설정 |
| **성능** | N+1 쿼리, 불필요한 re-render, 큰 번들, 동기 I/O |
| **품질** | 중복 코드, 너무 큰 함수 (>50줄), 명확한 명명, 테스트 누락 |
| **하네스 준수** | scope.md 일치 여부, Forbidden Area 침범 여부, 미완 작업 |

각 발견 사항을 심각도(critical/high/medium/low)로 분류.

### Phase 3 — 리스크 식별
새로 발견된 리스크가 있으면 `docs/risk-register/sprint{n}.md`에 기록:
- 리스크 설명
- 영향 범위
- 완화 전략

### Phase 4 — Sprint 회고 작성

`docs/sprint-retrospectives/sprint{n}.md`:

```markdown
# Sprint {n} 회고

## 📊 메트릭
- 계획 작업: N개, 완료: M개 (M/N%)
- 계획 일수: Xd, 실제: Yd
- 테스트 커버리지: Backend Z%, Frontend Z%
- 리뷰 발견 사항: critical=A, high=B, medium=C

## 🟢 Keep (잘 된 것)
- ...

## 🟡 Try (개선할 것 — 다음 Sprint에 반영)
- ...

## 🔴 Stop (멈출 것)
- ...

## 📝 액션 아이템
- [ ] (다음 Sprint planning에 자동 전달)
```

### Phase 5 — sprint-planner와 메모리 공유
회고의 Try 항목을 `.claude/agents/agent-memory/sprint-planner/` 메모리에 큐잉.

## 출력 요약
```
✓ 자동 검증: 통과 (커버리지 Backend 82%, Frontend 65%)
✓ 코드 리뷰: 발견 사항 5개 (high: 1, medium: 3, low: 1)
✓ 회고 작성: docs/sprint-retrospectives/sprint{n}.md

발견된 high 이슈:
- app/backend/auth.py: refresh token 회전 시 이전 토큰 무효화 누락

권장 액션:
- high 이슈는 다음 Sprint 시작 전 hotfix 또는 첫 작업으로 처리
```
