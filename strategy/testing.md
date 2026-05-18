# 테스트 전략

## 커버리지 목표

`.claude/stack.json` `decisions.test_coverage_goal`을 따름. 기본 권장:

| 레이어 | 목표 |
|---|---|
| Backend Unit | ≥ 80% |
| Backend Integration | 핵심 엔드포인트 (인증, 트랜잭션, 외부 통합) |
| Frontend Unit | ≥ 60% (UI 변화 빈도 고려) |
| Frontend Integration | 주요 라우트 |
| E2E | 핵심 사용자 흐름 5~10개 |

## 피라미드

```
   E2E (5-10개) — Playwright, 핵심 흐름
        ▲
  Integration — API ↔ DB, 외부 통합
        ▲
   Unit (다수) — 비즈니스 로직, 유틸
```

비율: Unit 70% / Integration 20% / E2E 10% (실행 횟수 기준)

## 테스트 도구

스택별 (`stack.json` 참조):

| 스택 | Unit | E2E |
|---|---|---|
| FastAPI / Django | pytest | Playwright |
| Express | Jest / Vitest | Playwright |
| React / Vue / Svelte | Vitest | Playwright |
| Next.js | Vitest | Playwright |

## 작성 원칙

1. **Given-When-Then 구조**: 가독성
2. **하나의 assertion 당 하나의 의도**: 실패 시 원인 명확
3. **외부 의존성 격리**: HTTP/DB는 fixture 또는 testcontainers
4. **데이터베이스 통합 테스트는 실제 DB**: SQLite mock 금지 (프로덕션과 동작 차이)

## CI에서

- PR마다 전체 테스트 + 커버리지 리포트
- 커버리지 하락 시 경고 (목표 미달 시 머지 차단 옵션)
- 느린 테스트(>10초)는 별도 잡으로 분리

## 회귀 방지

- 버그 수정 시 **재현 테스트 먼저 작성** → 실패 확인 → 수정 → 통과 확인
- 외부 API 통합 테스트는 contract test로 관리 (Pact 등 선택)
