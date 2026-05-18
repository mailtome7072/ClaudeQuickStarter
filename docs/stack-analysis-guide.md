# 기술스택 선택 가이드 (stack-analyzer)

**이 문서는 `stack-analyzer` 에이전트의 동작 방식과, 사용자가 기술스택을 선택할 때 고려할 사항을 설명합니다.**

---

## 📌 빠른 참조

### 프로세스

```
1. PRD.md 섹션 5 "기술 스택" 작성
   ↓
2. Claude Code: "기술스택 분석해줘."
   ↓
3. stack-analyzer 에이전트 실행
   ├─ 완결성 검증 (필수 항목 확인)
   ├─ 호환성 검사 (버전 호환)
   ├─ 최적화 권장 (성능/보안)
   └─ 6가지 확인 질문
   ↓
4. 사용자 응답 → 대화형 확정
   ↓
5. .claude/stack.json 생성
```

---

## ✅ 완결성 검증 (Completeness Check)

stack-analyzer는 **필수 요소**를 확인합니다:

### 필수 (반드시 기재)

- [ ] 프론트엔드 (또는 "없음")
- [ ] 백엔드 (또는 "없음")
- [ ] 데이터베이스 (또는 "없음")
- [ ] 배포 환경
- [ ] CI/CD 도구
- [ ] 인증 방식

### 권장 (프로덕션 필수)

- [ ] 로깅 전략
- [ ] 모니터링 도구
- [ ] 시크릿 관리

**결과 예시:**

```
✅ 필수 항목: 6/6 완성
⚠️ 권장 항목: 1/3 완성 (로깅, 모니터링 미명시)
→ 보완 필요
```

---

## 📊 호환성 검사 (Compatibility Check)

### 검사 항목

#### 1. Frontend-Backend 호환성

| Frontend | Backend | 호환성 | 비고 |
|----------|---------|--------|------|
| React | FastAPI | ✅ REST API | 표준 조합 |
| React | Django | ✅ REST API | 대안 |
| React | Express | ✅ REST API | Node 선호 시 |
| Next.js | Django | ✅ SSR 가능 | API 분리 권장 |
| Vue | FastAPI | ✅ REST API | 경량 조합 |
| Vue | Spring | ✅ REST API | 엔터프라이즈 |

**경고 조건:**
- GraphQL Frontend + REST Backend: 호환성은 있지만 추가 작업 필요
- WebSocket 필요: Express ✅, FastAPI ✅, Django ⚠️

#### 2. Database-ORM 호환성

| Database | ORM | 호환성 |
|----------|-----|--------|
| PostgreSQL | SQLAlchemy | ✅ |
| PostgreSQL | Django ORM | ✅ |
| PostgreSQL | Prisma | ✅ |
| MySQL 8.0+ | SQLAlchemy | ✅ |
| MongoDB | SQLAlchemy | ❌ SQL 기반 ORM 불가 |
| MongoDB | Mongoose | ✅ (Node) |

#### 3. 런타임 호환성

| 조합 | 호환성 | 비고 |
|------|--------|------|
| Node.js 20 + React 18 + Vite | ✅ | 권장 |
| Node.js 18 + React 18 + Vite | ⚠️ 호환 | 가능하지만 구식 |
| Node.js 14 + React 18 | ❌ | 미지원 |
| Python 3.11 + FastAPI 0.104+ | ✅ | 권장 |
| Python 3.8 + FastAPI 0.104+ | ❌ | Python 3.8 EOL |

---

## 🎯 최적화 권장 (Optimization Recommendations)

### 성능 (Performance)

**Frontend 최적화:**
```markdown
Vite 번들 크기 < 200KB (gzip)
  ├─ Code-splitting (React.lazy + Suspense)
  ├─ Tree-shaking (미사용 코드 제거)
  └─ 이미지 최적화 (next/image 또는 vite-plugin-imagemin)

API 호출 최적화
  ├─ React Query (데이터 페칭 + 캐싱)
  ├─ 페이지네이션 (limit/offset)
  └─ GraphQL (필요 필드만 요청)
```

**Backend 최적화:**
```markdown
FastAPI async 라우터
  ├─ CPU 작업: ThreadPoolExecutor
  ├─ I/O 작업: async/await
  └─ 동시성 튜닝: uvicorn workers

Database 성능
  ├─ N+1 쿼리 방지 (eager loading)
  ├─ 인덱스 설정
  └─ 연결 풀 튜닝 (pool_size, max_overflow)

캐싱 활용
  ├─ Redis: 세션, 임시 데이터, 결과 캐시
  ├─ CDN: 정적 자산
  └─ HTTP 캐싱: ETag, Last-Modified
```

### 보안 (Security)

**필수 (반드시 구현):**
- ✅ HTTPS/TLS 1.3
- ✅ CORS 정책 (도메인 화이트리스트)
- ✅ JWT 서명 + Refresh Token
- ✅ SQL Injection 방지 (ORM 사용)

**권장 (프로덕션 필수):**
- 🟡 Content Security Policy (CSP) 헤더
- 🟡 Rate Limiting (슬로우다운 공격 방지)
- 🟡 API 버전 관리 (v1, v2)
- 🟡 Secrets 관리 (AWS Secrets Manager, Vault)

**선택 (특정 요구사항):**
- 🟢 MFA (금융, 의료, B2B)
- 🟢 WebAuthn (생체 인증)
- 🟢 OAuth 2.0 (소셜 로그인)

### 운영 (Operations)

**필수 (프로덕션):**
- 📝 **로깅**: JSON 구조화 로그
  - CloudWatch (AWS)
  - ELK Stack (자체 호스팅)
  - Loki + Grafana (경량)

- 📊 **모니터링**: 핵심 메트릭
  - API 응답 시간 (latency)
  - 에러율 (5xx)
  - DB 커넥션 풀
  - 서버 리소스 (CPU, Memory)

- 🚨 **에러 추적**:
  - Sentry (권장)
  - CloudWatch Logs Insights
  - Custom 대시보드

- 🏥 **헬스 체크**:
  - `/health` (준비 상태)
  - `/ready` (의존성 확인)
  - Liveness probe (K8s)

---

## ❓ 6가지 사용자 확인 질문 (Decision Points)

### Q1: 프로덕션 로깅 도구

**현황**: PRD에 "로깅" 기재됨

**선택지:**

```yaml
A) CloudWatch (AWS 기본):
   비용: ~$50/월 (로그 저장량에 따라)
   장점: AWS 연동, 관리형, 자동 보관
   단점: AWS 종속

B) ELK Stack (Elasticsearch + Logstash + Kibana):
   비용: 자체 호스팅 (EC2 비용)
   장점: 강력한 검색, 완전 제어
   단점: 운영 복잡도 높음, 유지보수 필요

C) Loki + Grafana (경량):
   비용: 낮음 (자체 호스팅 또는 Grafana Cloud)
   장점: 가볍고, 시계열 최적화
   단점: 기능 제한 (전문검색 약함)

D) 구조화된 로그만 (개발 단계):
   비용: 0
   장점: 빠른 시작
   단점: 프로덕션 가시성 낮음 (권장 안 함)
```

**결정 방법:**
- 💰 비용 우선: C (Loki)
- 🔍 기능 우선: B (ELK)
- 🚀 빠른 시작: A (CloudWatch)

---

### Q2: 프로덕션 모니터링

**현황**: PRD에 미명시

**선택지:**

```yaml
필수 메트릭:
  - API 응답 시간 (latency, ms)
  - 에러율 (%, 5xx 비중)
  - DB 커넥션 풀 (사용 중 / 전체)
  - 서버 리소스 (CPU %, Memory %)

도구 선택:
A) CloudWatch Metrics (AWS):
   비용: AWS 기본 포함 또는 최소 비용
   장점: AWS 통합, 자동 수집
   
B) Prometheus + Grafana (자체 호스팅):
   비용: 서버 비용만
   장점: 강력한 쿼리, 커스터마이징
   
C) Datadog / New Relic (SaaS):
   비용: $200+/월
   장점: 엔터프라이즈급, 강력한 분석
   
D) 없음 (로깅만 수행):
   비용: 0
   단점: 실시간 가시성 없음 (권장 안 함)
```

**결정 방법:**
- 🚀 빠른 시작 & AWS: A (CloudWatch)
- 💰 낮은 비용: B (Prometheus)
- 👔 엔터프라이즈: C (Datadog)

---

### Q3: 다중 인증 (MFA)

**질문**: MFA가 필수인가?

**기준:**

```
필수 (100% 권장):
  ✅ 금융 서비스 (뱅킹, 결제)
  ✅ 의료 정보 (PHI, HIPAA)
  ✅ 기업용 (B2B, 직원 시스템)
  ✅ 정부 관련

선택 (요구사항 검토):
  🟡 SaaS 협업 도구
  🟡 사용자 데이터 민감
  🟡 규제 산업 (금융, 의료 이외)

불필요:
  🟢 공개 콘텐츠 플랫폼
  🟢 커뮤니티 포럼
```

**MFA 방식:**

```yaml
TOTP (Time-based One-Time Password):
  예: Google Authenticator, Authy
  장점: 표준, 사용자 선택 가능
  단점: QR코드 스캔 필요 (초기 설정)

SMS:
  장점: 간단한 UX
  단점: SMS 비용, 보안 취약 (SIM 탈취)

WebAuthn (생체 인증):
  예: Face ID, Touch ID, Security Key
  장점: 가장 안전함
  단점: 브라우저/디바이스 지원 필요
```

---

### Q4: 파일/이미지 저장소

**질문**: 사용자가 업로드한 파일/이미지를 어디에 저장할 것인가?

**선택지:**

```yaml
A) AWS S3 (권장, 프로덕션 표준):
   비용: $0.023/GB/월 + 전송료
   장점: 확장성, 보안, CDN 연동
   개발: LocalStack 사용 (docker-compose)
   
B) GCP Cloud Storage:
   비용: $0.020/GB/월
   장점: S3와 유사, GCP 생태계
   
C) Azure Blob Storage:
   비용: $0.0184/GB/월
   장점: Azure 통합
   
D) 로컬 파일시스템:
   비용: 0 (호스팅 비용만)
   장점: 개발 빠름
   단점: 프로덕션 불가, 확장 어려움
   
E) 없음 (파일 업로드 없음):
   비용: 0
```

**결정 방법:**
- 🚀 표준 & 확장성: A (S3)
- 💰 낮은 비용: C (Azure) 또는 B (GCP)
- 🔬 개발만: D (로컬)

---

### Q5: 배포 자동화 전략

**질문**: 배포는 어떤 수준으로 자동화할 것인가?

**선택지:**

```yaml
A) Continuous Deployment (CD):
   정의: PR merge → 즉시 프로덕션 배포
   장점: 빠른 피드백, 배포 자동화
   단점: 장애 위험 높음, 롤백 기술 필수
   추천: 팀이 경험 있고, 자동 테스트 충실할 때

B) Continuous Delivery (CDelivery):
   정의: PR merge → 스테이징 배포, 프로덕션은 수동 승인
   장점: 안정성 우선, 통제 가능
   단점: 배포 주기가 2-3일 (빠른 피드백 어려움)
   추천: 일반적인 팀의 표준 선택

C) Manual Deployment:
   정의: 모든 배포를 수동으로
   단점: 오류 가능성, 배포 시간 낭비
   추천: 비추천 (CI/CD 최소한 활용)
```

**결정 기준:**

```
CD 추천:
  ✅ 팀의 CI/CD 경험 있음
  ✅ 자동 테스트 커버리지 >= 80%
  ✅ 모니터링/로깅 세팅 완료
  ✅ 롤백 전략 준비됨
  ✅ 장애 대응 프로세스 있음

CDelivery 추천:
  ✅ 팀이 CI/CD 배우는 중
  ✅ 사용자가 중요한 데이터 다룸
  ✅ 배포 주기 2-3일 허용
  ✅ 안정성 우선
```

---

### Q6: 테스트 커버리지 목표

**질문**: 테스트 커버리지 목표는?

**표준:**

```yaml
Backend (Python/FastAPI):
  권장: >= 80% (중요한 로직)
  기준:
    - 90%: 높음 (금융, 의료)
    - 80%: 표준 (일반 SaaS)
    - 60%: 낮음 (스타트업)

Frontend (React):
  권장: >= 60% (UI 변화 잦음)
  기준:
    - Unit: >= 80% (로직)
    - Integration: >= 60%
    - E2E: 핵심 사용자 흐름
      (Playwright로 5-10개 시나리오)
```

**테스트 전략:**

```yaml
Backend:
  Unit: pytest로 비즈니스 로직
    → 목표: 80% 커버리지
  Integration: API ↔ DB 통합
    → 목표: 핵심 엔드포인트
  E2E: API curl 또는 Playwright (선택)

Frontend:
  Unit: Vitest로 유틸리티, 훅
    → 목표: 70%
  E2E: Playwright로 사용자 흐름
    → 목표: 핵심 5-10개 시나리오
```

---

## 📝 PRD 섹션 5 작성 체크리스트

```markdown
## 5. 기술 스택

### 5.1 프론트엔드
- [ ] UI 프레임워크 (React/Vue/Next.js 등)
- [ ] 언어 (TypeScript/JavaScript)
- [ ] 빌드 도구 (Vite/Webpack 등)
- [ ] 패키지 매니저 (pnpm/npm/yarn)
- [ ] 상태관리 (Zustand/Redux 등)
- [ ] 테스트 (Vitest/Jest 등)
- [ ] E2E 테스트 (Playwright/Cypress 등)

### 5.2 백엔드
- [ ] 프레임워크 (FastAPI/Django/Express 등)
- [ ] 언어 (Python/Node.js/Java 등)
- [ ] ORM (SQLAlchemy/Django ORM 등)
- [ ] 테스트 (pytest/Jest 등)
- [ ] 인증 (JWT/Session/OAuth 등)

### 5.3 데이터베이스 & 캐싱
- [ ] 주 DB (PostgreSQL/MySQL/MongoDB 등)
- [ ] 마이그레이션 (Alembic/Flyway 등)
- [ ] 캐싱 (Redis/Memcached 등)

### 5.4 인프라 & 배포
- [ ] 컨테이너 (Docker/Podman)
- [ ] 배포 환경 (AWS Lightsail/GCP/Vercel 등)
- [ ] CI/CD (GitHub Actions/GitLab CI 등)
- [ ] 모니터링 (CloudWatch/Prometheus 등)
- [ ] 로깅 (CloudWatch/ELK 등)

### 5.5 기타
- [ ] 파일 저장소 (S3/GCS 등)
- [ ] 메일 서비스 (SendGrid/SES 등)
```

---

## 🎯 다음 단계

1. **PRD.md 섹션 5 작성** (위 체크리스트 참고)
2. **Claude Code: `/init` 실행**
3. **Claude Code: "기술스택 분석해줘." 입력**
4. **stack-analyzer 결과 검토**
5. **6가지 질문 답변**
6. **스택 확정 → `.claude/stack.json` 생성**
7. **`/setup-project` 실행**

---

**작성**: stack-analyzer 에이전트  
**참고**: `.claude/agents/stack-analyzer.md` (에이전트 상세)
