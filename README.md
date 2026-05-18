# ClaudeQuickStarter

**Claude Code 기반 엔터프라이즈급 프로젝트 템플릿 (feat. 동적 기술스택 선택)**

> 🚀 `git clone` → PRD 작성 → `/analyze-stack` → 스택 확정 → `/setup-project` → 개발 착수
> 기술스택에 따른 반복 설정 제거. 자동화된 온보딩으로 **30분 안에 프로젝트 준비 완료**.

---

## 📋 핵심 개선사항

| 항목 | 기존 (ClaudeStarter) | **ClaudeQuickStarter** |
|------|---------------------|----------------------|
| **기술스택 선택** | 수동 마이그레이션 필요 | ✅ PRD 기반 자동 분석 |
| **SETUP.sh** | React + FastAPI만 가정 | ✅ 모든 스택 지원 (동적) |
| **스택 검증** | 없음 | ✅ 완결성/호환성/최적화 |
| **온보딩** | 2~3시간 | ✅ **30분 이내** |
| **스택 변경 추적** | 없음 | ✅ `.claude/stack.json` |

---

## 🚀 빠른 시작 (5단계)

### **0. 저장소 연결**

```bash
mkdir my-project && cd my-project
git clone https://github.com/[your-org]/ClaudeQuickStarter .
rm -rf .git && git init
git remote add origin https://github.com/[your-org]/[your-repo].git
git add . && git commit -m "Initial commit"
git push -u origin main
```

### **1. PRD.md 작성** (기술 스택 섹션 포함)

```bash
# PRD.md 열어서 섹션 5 "기술 스택" 작성
# 예: Frontend (React), Backend (FastAPI), DB (PostgreSQL) 등
```

### **2. Claude Code 실행**

```
/init
```

그 다음:

```
PRD 작성 완료했어. 기술스택 분석해줘.
```

**→ stack-analyzer 에이전트가 다음을 수행:**
- ✅ 완결성 검증 (필수 항목 확인)
- 📊 호환성 검사 (기술 간 버전 호환)
- 🎯 최적화 권장 (성능/보안)
- ❓ 6가지 확인 질문 (로깅, 모니터링, MFA, 저장소, 배포, 테스트)

### **3. 스택 확정** (대화형)

Claude와 함께:
```
Q1: 로깅 도구? (CloudWatch / ELK / Loki)
Q2: 모니터링? (CloudWatch Metrics / Prometheus)
Q3: MFA 필요? (Yes/No)
Q4: 파일 저장소? (S3 / GCP / Local)
Q5: 배포 전략? (CD / Continuous Delivery)
Q6: 테스트 커버리지? (Backend XX%, Frontend XX%)
```

**→ `.claude/stack.json` 자동 생성**

### **4. 환경 초기화**

```
/setup-project
```

**→ 자동 실행:**
- SETUP.sh 동적 생성 (기술스택 맞춤형)
- Frontend 초기화 (React/Vue/Next.js 등)
- Backend 초기화 (FastAPI/Django/Express 등)
- Docker Compose 자동 생성
- GitHub Actions 활성화
- `.env` 생성

### **5. 개발 착수**

```
ROADMAP 검토했어. sprint 1 계획 세워줘.
```

→ Sprint 1 자동 계획 수립 후:

```
/sprint-dev 1
```

→ 개발 시작 ✨

---

## ✨ 주요 특징

### 1. **PRD 기반 자동 스택 분석**
- PRD에 기술 작성 → Claude 분석 → 권장
- 단순 체크박스 아님. **전문가 수준의 검증**
- 완결성, 호환성, 성능, 보안 관점에서 종합 평가

### 2. **동적 SETUP.sh**
- 선택 스택에 따라 **자동으로 적절한 초기화 스크립트 생성**
- React? FastAPI? Django? Next.js? 모두 지원
- Docker Compose 자동 생성 (스택 맞춤)

### 3. **강력한 하네스 엔지니어링**
- AI 에이전트 자율성 + 안전성
- Planning First, Strict Guardrails, Verification Loops 등 5대 원칙

### 4. **7개 특화 에이전트**
- **`stack-analyzer`** ← 신규: PRD 분석 & 스택 최적화
- `prd-to-roadmap`: PRD → ROADMAP
- `sprint-planner`: Sprint 계획
- `sprint-close`: Sprint 마무리
- `sprint-review`: 코드 리뷰 & 회고
- `deploy-prod`: 배포
- `hotfix-close`: 긴급 패치

### 5. **자동 훅 & 로깅**
- Pre/Post 훅으로 자동 가드레일
- 모든 에이전트 활동 로그 기록
- 세션 summary 자동 생성

---

## 📚 사용 흐름도

```
PRD 작성 (기술 스택 섹션)
    ↓
/analyze-stack
    ↓
Claude: 분석 결과 제시
    ↓
사용자: 대화형 스택 확정 (6가지 질문)
    ↓
.claude/stack.json 생성
    ↓
/setup-project
    ↓
SETUP.sh 동적 생성 & 실행
    ↓
개발 환경 100% 준비
    ↓
/sprint-planner
    ↓
Sprint 1 계획 수립
    ↓
/sprint-dev 1
    ↓
개발 시작 🚀
```

---

## 📂 템플릿 구조 (주요 파일)

```
ClaudeQuickStarter/
├── README.md ..................... 이 파일
├── PRD.md ........................ 제품 요구사항 (기술 스택 표준화)
├── ARCHITECTURE.md ............... 프로젝트 변수 레지스트리
├── CLAUDE.md ..................... AI 협업 지침
├── SETUP.sh ...................... 모듈화 초기화 스크립트
│
├── .claude/
│   ├── agents/
│   │   ├── stack-analyzer.md .... ⭐ NEW: 기술스택 분석 에이전트
│   │   ├── prd-to-roadmap.md
│   │   ├── sprint-planner.md
│   │   └── agent-memory/
│   │       └── stack-analyzer/
│   │           └── MEMORY.md .... ⭐ NEW: 스택 분석 이력
│   ├── hooks/ .................... 자동 훅 (Pre/Post/Stop)
│   ├── rules/ .................... 조건부 규칙
│   ├── skills/ ................... Claude 스킬
│   └── stack.json ................ ⭐ NEW: 기술스택 레지스트리
│
├── docs/
│   ├── stack-analysis-guide.md ... ⭐ NEW: stack-analyzer 상세
│   ├── ci-policy.md .............. CI/CD 정책
│   ├── setup-guide.md ............ 환경 설정 가이드
│   ├── sprint/ ................... Sprint 계획 기록
│   └── ...
│
├── scripts/
│   └── setup-modules/ ............ ⭐ NEW: 모듈화 SETUP 스크립트
│       ├── setup-frontend-react.sh
│       ├── setup-backend-fastapi.sh
│       ├── generate-docker-compose.sh
│       └── templates/
│
├── app/
│   ├── frontend/ ................. (프로젝트 시작 시 생성)
│   └── backend/ .................. (프로젝트 시작 시 생성)
│
├── docker/
│   ├── backend/Dockerfile.prod
│   ├── frontend/Dockerfile.prod
│   └── nginx/Dockerfile
│
└── .github/
    └── workflows/
        ├── ci.yml ............... (스택 기반 자동 활성화)
        └── deploy.yml
```

---

## 🔑 새로운 커맨드

| 커맨드 | 설명 |
|--------|------|
| `/analyze-stack` | PRD 분석 → 기술스택 권장 & 대화형 확정 |
| `/setup-project` | 스택 기반 SETUP.sh 생성 & 실행 |
| `/sprint-dev [n]` | Sprint n 구현 시작 |
| `/init` | CLAUDE.md 갱신 |

---

## 💡 기술스택 선택 예시

### 예시 1: React + FastAPI (가장 인기)

```yaml
Frontend: React 18 + TypeScript + Vite + pnpm
Backend: FastAPI + Python 3.11 + SQLAlchemy
Database: PostgreSQL 16 + Redis 7
Infra: Docker + AWS Lightsail + GitHub Actions
Logging: CloudWatch + JSON
Monitoring: CloudWatch Metrics
```

### 예시 2: Next.js + Django

```yaml
Frontend: Next.js 14 + TypeScript
Backend: Django + Python 3.12
Database: PostgreSQL 16
Infra: Docker + Vercel (Frontend) + Heroku (Backend)
```

### 예시 3: Vue + Express

```yaml
Frontend: Vue 3 + TypeScript + Vite
Backend: Express + Node.js 20
Database: MongoDB 6.0 + Redis 7
Infra: Docker + Docker Compose + AWS ECR
```

---

## 🛡️ 하네스 엔지니어링 (Harness Engineering)

5가지 원칙으로 AI 에이전트 자율성 + 안전성 확보:

| 원칙 | 구현 |
|------|------|
| **1. Planning First** | 코드 수정 전 `scope.md` 작성 의무 |
| **2. Strict Guardrails** | Forbidden Areas 자동 차단 |
| **3. Verification Loops** | 3-retry 후 자동 분석 |
| **4. Policy Enforcement** | 배포 전 Policy Gate 통과 필수 |
| **5. Continuous Verification** | 배포 후 자동 검증 & 롤백 |

상세: `docs/harness-engineering/README.md`

---

## 📖 문서 참고 순서

1. **README.md** (이 파일)
2. **PRD.md** 작성 (섹션 5 기술 스택)
3. **docs/stack-analysis-guide.md** (stack-analyzer 상세)
4. **.claude/agents/stack-analyzer.md** (에이전트 구현)
5. **CLAUDE.md** (AI 협업 지침)
6. **strategy/*.md** (전략 지침)

---

## 🚀 첫 프로젝트 체크리스트

- [ ] 저장소 클론 & 연결
- [ ] PRD.md 작성 (섹션 5 기술 스택 포함)
- [ ] Claude Code: `/init` 실행
- [ ] Claude Code: "기술스택 분석해줘." 입력
- [ ] 6가지 확인 질문 답변
- [ ] Claude Code: `/setup-project` 실행
- [ ] Docker 실행 확인
- [ ] Claude Code: "sprint 1 계획 세워줘." 입력
- [ ] Claude Code: `/sprint-dev 1` 실행
- [ ] 개발 착수 🎉

---

## 📞 FAQ

**Q: 기술스택을 중간에 바꿀 수 있나요?**  
A: Sprint 1 종료 전까지는 가능합니다. 이후로는 비용(마이그레이션)이 크므로 권장하지 않습니다.

**Q: 스택-analyzer가 권장하는 것과 다르게 선택하고 싶어요.**  
A: 충분히 가능합니다. 대화 중 이유를 설명하면 Claude가 함께 검토하고 최종 선택을 존중합니다.

**Q: 로컬에서 Docker 없이 개발할 수 있나요?**  
A: SETUP.sh를 수정하면 가능하지만, 일관성 및 프로덕션 배포 시 복잡해집니다. Docker 권장.

**Q: 여러 사람이 사용할 수 있나요?**  
A: 네. 에이전트 메모리(`.claude/agents/agent-memory/`)가 팀 전체에 공유되므로 학습 효과가 있습니다.

---

## 🎯 다음 단계

👉 **지금 바로 시작하세요!**

```bash
git clone https://github.com/[your-org]/ClaudeQuickStarter my-project
cd my-project
rm -rf .git && git init && git remote add origin [your-repo]
# PRD.md 작성 후
# Claude Code: /init
# Claude Code: "기술스택 분석해줘."
```

Happy Coding! 🚀

---

**버전**: 1.0-ClaudeQuickStarter  
**최종 업데이트**: 2026-05-17  
**기반**: ClaudeStarter (skyang)
