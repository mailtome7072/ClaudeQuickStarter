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

## 🚀 빠른 시작 (정본 부트스트랩 순서)

> 아래 순서는 모든 문서(`README.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `PRD.md`)에서 동일합니다.

### **0. 저장소 연결**

```bash
mkdir my-project && cd my-project
git clone https://github.com/[your-org]/ClaudeQuickStarter .
rm -rf .git && git init
git remote add origin https://github.com/[your-org]/[your-repo].git
git add . && git commit -m "Initial commit"
git push -u origin main
```

> **Windows 사용자**: PowerShell에서는 `rm -rf` 대신 `Remove-Item -Recurse -Force .git` 사용. SETUP 단계는 WSL2 또는 Git Bash 필요 (현재 `SETUP.ps1` 미제공 — Phase 5에서 추가 예정).

### **1. `ARCHITECTURE.md` 변수 5개 입력**

`ARCHITECTURE.md` 상단의 표에 `project_name`, `project_description`, `github_org`, `github_repo`, `decision_date`를 채웁니다. 이 값들은 `/setup-project` 단계에서 PRD/CLAUDE/docker-compose 등의 `${...}` 플레이스홀더에 일괄 치환됩니다.

### **2. `PRD.md` §5 "기술 스택" 작성**

각 항목의 "선택" 컬럼을 프로젝트 요구에 맞게 채웁니다. 불확실한 항목은 "TBD"로 두면 `stack-analyzer`가 대화로 확정합니다.

### **3. `/analyze-stack` — 스택 분석 & 대화형 확정**

Claude Code에서:

```
/analyze-stack
```

> 현재 슬래시 커맨드는 Phase 1에서 구현 예정. 그 전까지는 자연어로 "PRD 작성 완료했어. 기술스택 분석해줘."라고 입력하세요.

**`stack-analyzer` 에이전트가 수행**:
- 완결성 검증 (필수 항목 확인)
- 호환성 검사 (기술 간 버전 호환)
- 최적화 권장 (성능/보안)
- **6가지 확인 질문** (로깅, 모니터링, MFA, 파일 저장소, 배포 전략, 테스트 커버리지)

→ 사용자 답변 후 `.claude/stack.json`이 `status: "confirmed"`로 생성됨

### **4. `/setup-project` — 변수 치환 + 스택 기반 부트스트랩**

```
/setup-project
```

**세 단계로 동작**:
1. `ARCHITECTURE.md`의 변수를 `${project_name}` 등 플레이스홀더에 일괄 치환
2. `.claude/stack.json`을 읽어 `scripts/setup-modules/`의 적절한 모듈로 `app/`, `docker/`, `.github/workflows/`, `docker-compose.yml`, `.env` 합성
3. `SETUP.sh`(또는 WSL/Git Bash 환경) 실행 — Frontend/Backend 의존성 설치, Docker 시작 테스트

### **5. ROADMAP 생성**

```
PRD 기반으로 ROADMAP 생성해줘.
```

→ `prd-to-roadmap` 에이전트가 `ROADMAP.md`를 PRD §3 (기능 요구사항) 기반으로 갱신.

### **6. 개발 착수**

```
sprint 1 계획 세워줘.
```

→ `sprint-planner` 에이전트 (Phase 7 구현 예정)

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

## 📚 사용 흐름도 (정본)

```
0. git clone
   ↓
1. ARCHITECTURE.md 변수 5개 입력
   ↓
2. PRD.md §5 기술 스택 작성
   ↓
3. /analyze-stack
   ├─ stack-analyzer: 완결성/호환성/최적화 분석
   └─ 사용자: 대화형 6가지 질문 답변
   ↓
4. .claude/stack.json 확정 (status: confirmed)
   ↓
5. /setup-project
   ├─ ARCHITECTURE 변수 치환
   ├─ stack.json 기반 setup-modules 합성
   └─ SETUP.sh 실행
   ↓
6. prd-to-roadmap → ROADMAP.md 생성
   ↓
7. sprint-planner → Sprint 1 계획
   ↓
8. /sprint-dev 1 → 개발 착수 🚀
```

---

## 📂 템플릿 구조

### 정적 자산 (템플릿에 포함됨)

```
ClaudeQuickStarter/
├── README.md ..................... 이 파일
├── PRD.md ........................ 제품 요구사항 템플릿 (§5 기술 스택)
├── ARCHITECTURE.md ............... 프로젝트 변수 레지스트리
├── CLAUDE.md ..................... AI 협업 지침
├── CHANGELOG.md .................. 템플릿/사용자 프로젝트 변경 이력
├── ROADMAP.md .................... 로드맵 템플릿 (prd-to-roadmap이 채움)
├── DEPLOY.md ..................... 배포 체크리스트 템플릿
├── SETUP.sh ...................... 동적 부트스트랩 스크립트
│
├── .claude/
│   ├── agents/
│   │   ├── stack-analyzer.md .... 기술스택 분석 (현재 유일)
│   │   └── agent-memory/
│   │       └── stack-analyzer/MEMORY.md
│   ├── stack.json ............... 스택 레지스트리 (gitignored)
│   ├── commands/ ................ 슬래시 커맨드 (Phase 1에서 채움)
│   ├── rules/ ................... 정책 규칙 (Phase 6에서 채움)
│   ├── skills/ .................. 스킬 (선택)
│   └── tmp/
│
├── docs/
│   └── stack-analysis-guide.md .. 스택 선택 의사결정 가이드
│
├── scripts/
│   ├── setup-modules/ ........... 부트스트랩 모듈 (Phase 1에서 채움)
│   └── hooks/ ................... 자동 훅 (Phase 8에서 채움)
│
└── .mcp.json ..................... MCP 서버 설정 (Notion)
```

### 부트스트랩 후 생성되는 것

`/setup-project` 실행 후 `.claude/stack.json`의 선택에 따라 다음이 생성됩니다:

```
├── app/
│   ├── frontend/  (선택한 UI 프레임워크 코드)
│   └── backend/   (선택한 백엔드 프레임워크 코드)
├── docker/
│   ├── backend/Dockerfile.prod   (스택 기반)
│   ├── frontend/Dockerfile.prod  (스택 기반)
│   └── nginx/Dockerfile
├── docker-compose.yml            (로컬 개발)
├── docker-compose.prod.yml       (프로덕션 — 스택 기반 변수 치환)
├── .env                          (강한 시크릿 자동 생성)
└── .github/workflows/
    ├── ci.yml
    └── deploy.yml
```

### 운영 중 누적되는 것

```
├── docs/
│   ├── sprint/             (sprint-planner가 누적)
│   ├── sprint-retrospectives/
│   ├── test-reports/       (sprint-review가 누적)
│   ├── deploy-history/     (deploy-prod가 누적)
│   ├── risk-register/      (필요 시)
│   └── arch/               (아키텍처 결정 기록)
└── strategy/               (계획/브랜치/테스트/배포 전략)
```

---

## 🔑 슬래시 커맨드

| 커맨드 | 설명 | 상태 |
|--------|------|------|
| `/init` | CLAUDE.md 갱신 | ✅ Claude Code 내장 |
| `/analyze-stack` | PRD 분석 → 기술스택 권장 & 대화형 확정 | 🚧 Phase 1 |
| `/setup-project` | 변수 치환 + 스택 기반 부트스트랩 + SETUP.sh 실행 | 🚧 Phase 1 |
| `/sprint-dev [n]` | Sprint n 구현 시작 | 🚧 Phase 7 |
| `/restart` | Docker 서비스 재시작 | 🚧 Phase 7 |

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

- [ ] 저장소 클론 & 연결 (`git clone`, 원격 변경)
- [ ] **ARCHITECTURE.md 변수 5개 입력** (`project_name`, `github_org` 등)
- [ ] **PRD.md 작성** (특히 §5 기술 스택)
- [ ] Claude Code: `/init` 실행 (CLAUDE.md 갱신)
- [ ] Claude Code: `/analyze-stack` 실행 (또는 "기술스택 분석해줘.")
- [ ] 6가지 확인 질문 답변 → `.claude/stack.json` 확정
- [ ] Claude Code: `/setup-project` 실행 (변수 치환 + 부트스트랩)
- [ ] Docker 실행 확인 (`docker-compose up`)
- [ ] Claude Code: "PRD 기반 ROADMAP 생성해줘."
- [ ] Claude Code: "sprint 1 계획 세워줘."
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
