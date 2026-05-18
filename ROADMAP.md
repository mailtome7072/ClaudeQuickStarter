# ROADMAP.md — 프로젝트 로드맵

> ⚠️ **이 파일은 템플릿 골격입니다.**
> 부트스트랩 완료 후 `prd-to-roadmap` 에이전트가 `PRD.md §3 (기능 요구사항)`을 읽어
> 사용자 프로젝트의 실제 로드맵으로 **전체 교체**합니다.
> Sprint 명세, 기능, 일정은 모두 PRD에서 도출되므로 아래는 *형식 예시*일 뿐입니다.

---

## 📌 로드맵 개요 (예시 구조)

| Phase | 기간 | 목표 | Sprint |
|-------|------|------|--------|
| **MVP** | YYYY-MM ~ YYYY-MM | PRD §3.1 핵심 기능 출시 | Sprint 1-3 |
| **Phase 2 확장** | YYYY-MM ~ YYYY-MM | PRD §3.2 보조 기능 | Sprint 4-6 |
| **최적화 & 안정화** | YYYY-MM ~ | 성능/보안 강화 | Sprint 7+ |

---

## 🚀 MVP Phase (예시 — prd-to-roadmap이 교체)

### Sprint 1: 부트스트랩 검증 & 첫 도메인 모델

> ⚠️ "프로젝트 초기화", "Docker 환경 설정", "기술스택 확정"은 **부트스트랩 단계에서 이미 완료**되므로 Sprint 1에 넣지 않습니다.

**목표**: 부트스트랩 결과를 검증하고 첫 도메인 엔티티 구현

| 기능 | 상태 | 담당 | 우선순위 |
|------|------|------|---------|
| 부트스트랩 결과 검증 (docker-compose up, /health 응답) | ⬜ | TBD | 🔴 필수 |
| [PRD §3.1 첫 번째 핵심 기능 — prd-to-roadmap이 채움] | ⬜ | TBD | 🔴 필수 |
| [첫 DB 마이그레이션 — 스택 기반 도구 사용] | ⬜ | TBD | 🔴 필수 |
| CI 그린 (테스트, 린트) | ⬜ | TBD | 🟡 권장 |

---

### Sprint 2: 인증 시스템

**목표**: 사용자가 선택한 인증 방식([스택 확정 시 결정] — JWT / Session / OAuth 등) 구현

| 기능 | 상태 | 담당 | 우선순위 |
|------|------|------|---------|
| [인증 시스템 — `.claude/stack.json` `backend.authentication` 참조] | ⬜ | TBD | 🔴 필수 |
| 사용자 프로필 (CRUD) | ⬜ | TBD | 🔴 필수 |
| 인증 UI | ⬜ | TBD | 🔴 필수 |
| API 문서 (스택 기본값: FastAPI=OpenAPI 자동, Express=수동 등) | ⬜ | TBD | 🟡 권장 |

---

### Sprint 3: 비즈니스 로직 & 테스트

**목표**: PRD §3.1 나머지 핵심 기능 + 테스트 커버리지 달성

| 기능 | 상태 | 담당 | 우선순위 |
|------|------|------|---------|
| [PRD §3.1 핵심 기능 #N — prd-to-roadmap이 채움] | ⬜ | TBD | 🔴 필수 |
| 테스트 작성 (목표: stack.json `decisions.test_coverage_goal` 참조) | ⬜ | TBD | 🔴 필수 |
| E2E 테스트 (핵심 사용자 흐름 5-10개) | ⬜ | TBD | 🔴 필수 |

---

## 📊 진행 상황

```
Sprint 1: [░░░░░░░░░░] 0% (예정)
Sprint 2: [░░░░░░░░░░] 0% (예정)
Sprint 3: [░░░░░░░░░░] 0% (예정)

MVP: [░░░░░░░░░░] 0% 전체
```

---

## 🎯 주요 마일스톤 (예시)

| 마일스톤 | 목표일 | 상태 | 참고 |
|---------|--------|------|------|
| 부트스트랩 완료 | YYYY-MM-DD | ⬜ | `/setup-project` 종료 시점 |
| 첫 베타 배포 | YYYY-MM-DD | ⬜ | Sprint 2 종료 후 staging |
| MVP 출시 | YYYY-MM-DD | ⬜ | Sprint 3 종료 후 production |
| Phase 2 시작 | YYYY-MM-DD | ⬜ | (추후 계획) |

---

## 📝 참고

- **자동 갱신**: 부트스트랩 후 `prd-to-roadmap`이 이 파일을 PRD 기반으로 교체. 이후 각 Sprint 완료 시 `sprint-close`가 상태 갱신.
- **상태 기호**:
  - ⬜ 미진행 (Not Started)
  - 🔄 진행 중 (In Progress)
  - ✅ 완료 (Completed)
  - ❌ 차단됨 (Blocked)
- **우선순위**:
  - 🔴 필수 (Must Have, MVP 포함)
  - 🟡 권장 (Should Have, Phase 2로 연기 가능)
  - 🟢 선택 (Nice to Have, 향후 검토)

---

**상태**: 템플릿 골격 (사용자 프로젝트 부트스트랩 후 교체됨)
**다음 갱신**: `prd-to-roadmap` 에이전트가 PRD 파싱 후
