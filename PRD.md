# PRD — ${project_name}

| 항목 | 값 |
|------|-----|
| **프로젝트명** | ${project_name} |
| **작성일** | ${decision_date} |
| **버전** | 1.0 |
| **담당자** | [이름] |
| **승인자** | [이름] |

---

## 1. 문제 정의 & 목표

### 1.1 현황 분석
- 해결할 문제 또는 기회 포착
- 현재 시장/사용자 상황

### 1.2 목표
- 구체적이고 측정 가능한 목표
- 비즈니스 임팩트

### 1.3 성공 지표 (KPI)
- 정량적 지표 (예: 사용자 수, 성능)
- 정성적 지표 (예: NPS, 만족도)

---

## 2. 타겟 사용자 & 사용자 스토리

### 2.1 타겟 사용자 Persona
- 역할, 나이, 기술 수준
- Pain Point, Motivation

### 2.2 사용자 스토리
```
As a [사용자], I want to [기능], so that [이유]
```

예시:
```
As a project manager, I want to track team progress in real-time, 
so that I can identify bottlenecks early.
```

---

## 3. 기능 요구사항

### 3.1 핵심 기능 (MVP)
- [ ] 기능 1: 설명
- [ ] 기능 2: 설명

### 3.2 보조 기능 (Phase 2+)
- [ ] 기능 3: 설명

### 3.3 Out of Scope
- 프로젝트 범위 밖의 것들

---

## 4. 비기능 요구사항 (NFR)

### 4.1 성능
- 응답 시간: X ms 이하
- 동시 사용자: X명 이상 지원
- 처리량: X req/sec

### 4.2 확장성
- 사용자 증가 시 확장 전략
- 데이터 증가 관리 방안

### 4.3 신뢰성 & 가용성
- Uptime 목표: 99.9%
- RTO (Recovery Time Objective): X시간
- RPO (Recovery Point Objective): X시간

### 4.4 보안
- 데이터 암호화: At-rest, In-transit
- 인증/인가 방식
- 감사 로그 요구사항
- GDPR/개인정보보호법 준수

### 4.5 사용성
- 접근성 (WCAG 레벨)
- 모바일 지원 여부
- UI/UX 가이드라인

---

## 5. 기술 스택

> **중요**: 이 섹션은 `/analyze-stack` 커맨드 실행 시 **stack-analyzer 에이전트가 검증**합니다.
> 불확실한 부분은 "TBD" 또는 "권장받음"으로 표기해도 무방합니다.
>
> 아래 표의 **"선택" 컬럼은 가장 자주 사용되는 기본값**일 뿐이며,
> 프로젝트 요구에 맞춰 **언제든 다른 옵션으로 교체 가능**합니다.
> "대안" 컬럼 외의 다른 기술도 자유롭게 입력하세요 (예: Svelte, Go, MongoDB, Spring Boot 등).
> `stack-analyzer`가 입력된 조합의 호환성을 검증합니다.

### 5.1 프론트엔드

| 항목 | 선택 | 대안 | 비고 |
|------|------|------|------|
| **UI 프레임워크** | React 18+ | Vue 3, Next.js 14+, Svelte | 상호작용성 중심 |
| **언어** | TypeScript | JavaScript | 타입 안정성 필요 시 TS 권장 |
| **빌드 도구** | Vite | Webpack, Create React App | Vite = 개발 DX 최적 |
| **패키지 매니저** | pnpm | npm, yarn | pnpm = 디스크 효율성 ↑ |
| **상태 관리** | Zustand | Redux, Recoil, Jotai | 복잡도에 따라 선택 |
| **API 통신** | React Query / TanStack Query | axios + custom hooks | 데이터 페칭 최적화 |
| **UI 컴포넌트 라이브러리** | shadcn/ui (또는 Ant Design) | Material-UI, Bootstrap | 디자인 일관성 |
| **테스트 프레임워크** | Vitest | Jest | 속도 vs 생태계 |
| **E2E 테스트** | Playwright | Cypress, WebdriverIO | 크로스 브라우저 지원 |
| **배포 대상** | Self-hosted (Docker) | Vercel, Netlify | 기업 요구사항 고려 |

**프론트엔드 선택 이유:**
```
[프로젝트 특성에 맞게 작성]
예: "높은 상호작용성 필요 → React 선택"
    "빠른 개발 속도 필요 → Vite 선택"
```

---

### 5.2 백엔드

| 항목 | 선택 | 대안 | 비고 |
|------|------|------|------|
| **프레임워크** | FastAPI | Django, Express, Spring | 성능 vs 개발 속도 |
| **언어** | Python 3.11+ | Node.js 20+, Java, Go | 팀 역량 고려 |
| **ORM/쿼리** | SQLAlchemy | Django ORM, TypeORM, Prisma | DB 추상화 수준 |
| **테스트 프레임워크** | pytest | Django TestCase, Jest | 테스트 커버리지 목표 |
| **인증 방식** | JWT + RefreshToken | Session-based, OAuth 2.0 | 토큰 갱신 필요 시 |
| **API 문서** | OpenAPI (자동) | GraphQL (별도) | REST vs GraphQL |
| **배경 작업** | Celery (또는 RQ) | Bull, APScheduler | 비동기 작업 필요 시 |
| **환경 변수** | python-dotenv | 환경 설정 서비스 | 로컬 vs 프로덕션 |

**백엔드 선택 이유:**
```
[프로젝트 특성에 맞게 작성]
예: "고성능 API 필요 → FastAPI 선택"
    "Django 생태계 활용 → Django 선택"
```

---

### 5.3 데이터베이스 & 캐싱

| 항목 | 선택 | 대안 | 비고 |
|------|------|------|------|
| **주 데이터베이스** | PostgreSQL 16 | MySQL 8.0+, MongoDB 6.0+ | 관계형 vs 비관계형 |
| **스키마 마이그레이션** | Alembic | Flyway, Liquibase | Python/FastAPI 권장 |
| **캐싱 레이어** | Redis 7 | Memcached, Valkey | 세션/임시 데이터 |
| **검색 엔진** | Elasticsearch (선택) | Meilisearch, Typesense | 전문검색 필요 시 |
| **메시지 큐** | RabbitMQ (선택) | Kafka, AWS SQS | 비동기 처리 필요 시 |

**DB 선택 이유:**
```
[프로젝트 특성에 맞게 작성]
예: "ACID 트랜잭션 필요 → PostgreSQL 선택"
    "Document 구조 → MongoDB 고려"
```

---

### 5.4 인프라 & 배포

| 항목 | 선택 | 대안 | 비고 |
|------|------|------|------|
| **컨테이너화** | Docker + Docker Compose | 없음 (VM 배포) | 개발-운영 일관성 |
| **오케스트레이션** | Docker Compose (개발) / Kubernetes (선택) | ECS, Nomad | 팀 역량 고려 |
| **배포 환경** | AWS Lightsail | GCP Cloud Run, Azure ACI, Vercel, Heroku | 비용/기능/팀 선호 |
| **CI/CD 도구** | GitHub Actions | GitLab CI, CircleCI, Jenkins | Git 서비스와 연계 |
| **모니터링** | CloudWatch (AWS) | Prometheus + Grafana, Datadog, New Relic | 선택 사항 |
| **로깅** | CloudWatch Logs + JSON 구조화 | ELK Stack, Loki, Datadog | 운영 복잡도 고려 |
| **환경 분리** | 개발 (로컬 Docker), 스테이징 (Lightsail), 프로덕션 (Lightsail) | - | 배포 안정성 필수 |

**인프라 선택 이유:**
```
[프로젝트 특성에 맞게 작성]
예: "빠른 배포 필요 → GitHub Actions + Docker 선택"
    "낮은 운영 복잡도 → Lightsail 선택"
```

---

### 5.5 기타 (선택 사항)

| 항목 | 선택 | 설명 |
|------|------|------|
| **API 문서** | OpenAPI/Swagger (자동) | FastAPI 기본 제공 |
| **로깅 포맷** | JSON 구조화 로그 | 프로덕션 배포 후 분석 용이 |
| **시크릿 관리** | GitHub Secrets + .env | CI/CD에서 환경변수 주입 |
| **CDN** | CloudFront (AWS) | 정적 자산 배포 (선택) |
| **메일 서비스** | SendGrid (또는 AWS SES) | 이메일 발송 필요 시 |
| **결제** | Stripe (또는 다른 결제사) | 유료 기능 필요 시 |

---

## 6. 인수 조건 (Acceptance Criteria)

### 6.1 기능별 AC
```
Given [상황]
When [사용자 행동]
Then [기대 결과]
```

예시:
```
Feature: 사용자 로그인
Scenario: 정상 로그인
  Given 사용자가 로그인 페이지에 있음
  When 유효한 이메일과 비밀번호를 입력하고 로그인 버튼을 클릭
  Then 대시보드 페이지로 리다이렉트되어야 함
```

### 6.2 성능 AC
- 페이지 로딩 시간: 3초 이내
- API 응답 시간: 200ms 이내
- 번들 크기: JavaScript < 200KB (gzip)

### 6.3 보안 AC
- HTTPS 적용
- CORS 정책 명시
- SQL Injection 방지 (ORM 사용)
- XSS 방지 (Content Security Policy)

---

## 7. 도메인 용어 사전

| 용어 | 정의 | 예시/비고 |
|------|------|----------|
| [용어1] | [정의] | [예시] |
| [용어2] | [정의] | [예시] |

예시:
```
| Sprint | 1-2주 단위의 반복 개발 사이클 | Sprint 1 = 2026-05-16 ~ 2026-05-30 |
| Epic | 여러 Sprint에 걸친 큰 기능 | "결제 시스템" = Sprint 1~3 |
| User Story | 개별 기능 단위 | "사용자 로그인" |
```

---

## 8. 제약사항 & 리스크

### 8.1 제약사항
- 예산 제한
- 일정 제한
- 인력 제한
- 외부 의존성 (API, 서비스)

### 8.2 주요 리스크
- 기술 리스크 (선택 스택 학습곡선 높음)
- 일정 리스크 (예: 외부 API 통합 지연)
- 리소스 리스크 (팀원 부재)

### 8.3 완화 전략
- 위험별 대응 계획

---

## 9. 로드맵 (개요)

| Phase | 기간 | 목표 | 우선순위 |
|-------|------|------|---------|
| Phase 1 (MVP) | 2026-05-16 ~ 2026-06-27 (6주 = 3 Sprint) | 핵심 기능 1, 2 출시 | 🔴 필수 |
| Phase 2 | 2026-06-28 ~ 2026-08-08 (6주 = 3 Sprint) | 보조 기능 3, 4 추가 | 🟡 중요 |
| Phase 3 | 2026-08-09 ~ | 성능 최적화, 모니터링 | 🟢 선택 |

> 상세 로드맵은 `/analyze-stack` 후 `prd-to-roadmap` 에이전트가 자동 생성합니다.

---

## 10. 참고자료

- [외부 문서 링크]
- [스크린샷, 와이어프레임]
- [경쟁사 분석]

---

## 📋 **다음 단계 (정본 부트스트랩 순서)**

> 이 순서는 README.md, CLAUDE.md, ARCHITECTURE.md와 동일합니다.

| # | 단계 | 도구 / 명령 |
|---|---|---|
| 1 | ✅ ARCHITECTURE.md 변수 5개 입력 (선행) | 수동 |
| 2 | ✅ **현재 단계**: PRD.md §5 작성 | 수동 |
| 3 | `/analyze-stack` — 스택 분석 & 6가지 질문 | `stack-analyzer` 에이전트 |
| 4 | `.claude/stack.json` 확정 (대화형) | 사용자 답변 |
| 5 | `/setup-project` — 변수 치환 + 부트스트랩 | `setup-modules` |
| 6 | ROADMAP 생성 ("PRD 기반 ROADMAP 생성해줘") | `prd-to-roadmap` 에이전트 |
| 7 | Sprint 1 계획 ("sprint 1 계획 세워줘") | `sprint-planner` 에이전트 |
| 8 | `/sprint-dev 1` → 개발 착수 | 사용자 |

**다음 액션**: Claude Code에서 `/analyze-stack` 또는 "PRD 작성 완료했어. 기술스택 분석해줘."

