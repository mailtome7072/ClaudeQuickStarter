# 하네스 엔지니어링 (Harness Engineering)

이 프로젝트는 AI 코딩 에이전트의 **자율성**과 **안전성**을 동시에 확보하기 위해
5가지 하네스 원칙을 채택합니다. 각 원칙은 정책(이 문서)과 강제력(훅 + 에이전트)으로 구성됩니다.

> **상태**: 강제력(훅)은 Phase 8에서 구현됩니다. 현재는 정책 가이드로서 기능합니다.

---

## 원칙 1 — Planning First

### 정책
**코드를 수정하기 전에 반드시 `scope.md`를 작성**합니다.

`scope.md`는 다음을 명시:
- **목표**: 무엇을 변경하는가
- **범위**: 어떤 파일/모듈에 영향을 미치는가
- **검증 방법**: 변경이 의도대로 작동했는지 어떻게 확인하는가
- **롤백 조건**: 어떤 신호가 보이면 되돌릴 것인가

### 왜 필요한가
- 무분별한 "이거도 고치고 저거도 고치자" 식의 작업 방지
- 작업 종료 시 객관적 평가 기준 제공
- 변경의 의도가 commit 메시지/PR 설명에 자동 반영

### 강제력 (Phase 8 예정)
`pretooluse-scope-validator.sh` 훅이 Edit/Write 직전에 scope.md 존재 확인.
미존재 시 작업 차단 + 작성 가이드 출력.

---

## 원칙 2 — Strict Guardrails

### 정책
다음 영역은 **명시적 사용자 허가 없이 수정 금지**:

| 영역 | 이유 |
|---|---|
| `.github/workflows/` | CI/CD 정책 변경은 보안/배포에 광범위한 영향 |
| `SETUP.sh`, `SETUP.ps1` | 부트스트랩 로직 변경은 모든 신규 프로젝트에 영향 |
| `scripts/setup-modules/` | 동일 |
| `docker-compose.prod.yml`, `docker/*/Dockerfile.*` | 프로덕션 배포 환경 |
| `docs/harness-engineering/` | 정책 문서 자체 |
| `.claude/rules/` | 에이전트 정책 |
| `.claude/settings.json` | 훅 등록 |

### 왜 필요한가
- AI 에이전트가 "에러를 빠르게 우회"하기 위해 CI/배포 설정을 무력화하는 패턴 방지
- 정책 문서를 에이전트가 임의로 약화하는 위험 차단

### 강제력 (Phase 8 예정)
`pretooluse-forbidden-area-guard.sh` 훅이 위 경로 수정을 자동 차단.
우회하려면 사용자가 명시적으로 "Forbidden Area 수정 허가"를 줘야 함.

---

## 원칙 3 — Verification Loops

### 정책
**동일 파일을 3회 연속 수정**하면 강제 일시정지하고 다음을 검토:

1. 접근 방식이 잘못된 것은 아닌가? (다른 방향 시도)
2. 근본 원인이 다른 곳에 있는 것은 아닌가?
3. 테스트가 실제 의도를 검증하는가?

### 왜 필요한가
- "에러 → 임시 패치 → 새 에러 → 또 패치" 무한 루프 방지
- 빠른 실패(fail-fast)로 잘못된 가정 노출

### 강제력 (Phase 8 예정)
`posttooluse-loop-detector.sh` 훅이 파일별 수정 횟수 추적.
3회 도달 시 "다른 접근 검토" 메시지 + 의도적 일시정지.

---

## 원칙 4 — Policy Enforcement

### 정책
**프로덕션 배포 전 Policy Gate 통과 필수**:

- ✅ 모든 테스트 통과 (커버리지 목표 — `.claude/stack.json` `decisions.test_coverage_goal`)
- ✅ 린트 통과 (스택별 — ruff/eslint 등)
- ✅ 보안 스캔 (기본: `npm audit` / `pip-audit`)
- ✅ 환경 변수 비밀번호/토큰 미노출 (커밋 diff 검사)
- ✅ CHANGELOG.md 업데이트
- ✅ 마이그레이션 스크립트 검토 (DB 스키마 변경 시)

### 왜 필요한가
- 배포 직전의 마지막 안전망
- 개별 PR이 모두 통과했어도 통합 시점 검증 필요

### 강제력
`deploy-prod` 에이전트(Phase 7)와 `harness-ci-gate` 스킬이 실행 시점에 자동 검사.

---

## 원칙 5 — Continuous Verification

### 정책
**배포 후 자동 헬스 체크 + 임계치 위반 시 롤백 트리거**:

| 메트릭 | 임계치 (기본) | 조치 |
|---|---|---|
| 에러율 | > 5% | 자동 롤백 |
| API 응답 시간 (p95) | > 2× 기준선 | 경보 + 수동 검토 |
| DB 연결 풀 사용률 | > 90% | 경보 |
| Health endpoint 응답 | 비정상 | 자동 롤백 |

### 왜 필요한가
- 배포 직후 5~30분이 가장 위험한 시간대
- 사람의 모니터링은 야간/주말에 약함 → 자동화 필수

### 강제력
`deploy-prod` 에이전트가 배포 후 N분간 모니터링 후 결과 보고.
실패 시 이전 Docker 이미지 태그로 자동 롤백.

---

## 원칙 간 관계

```
Planning First (의도 명확화)
    ↓
Strict Guardrails (실수 차단)
    ↓
Verification Loops (잘못된 가정 조기 노출)
    ↓
Policy Enforcement (배포 직전 최종 검증)
    ↓
Continuous Verification (배포 후 안전망)
```

각 원칙은 다른 원칙이 실패할 때를 대비한 **보조 안전망** 역할을 합니다.
하나라도 빠지면 사각지대가 생깁니다.

---

## 적용 우선순위

새 프로젝트에 도입할 때:

1. **Planning First** (가장 큰 효과, 가장 낮은 비용)
2. **Strict Guardrails** (자주 발생하는 실수 차단)
3. **Policy Enforcement** (배포 안정성)
4. **Continuous Verification** (운영 안정성)
5. **Verification Loops** (디버깅 패턴 개선 — 후순위 가능)

---

## 참고

- 정책 규칙 상세: `.claude/rules/harness-engineering.md` (Phase 6에서 작성)
- 훅 구현: `scripts/hooks/` (Phase 8)
- 배포 게이트: `harness-ci-gate` 스킬
