# ClaudeQuickStarter

PRD를 작성하면 Claude Code가 함께 기술 스택을 정하고, 그 결정에 맞춰 앱 구조 / Docker / CI/CD를 자동으로 합성해주는 **프로젝트 부트스트랩 템플릿**.

```
PRD 작성  →  스택 확정 (6가지 질문)  →  자동 부트스트랩  →  첫 Sprint 시작
```

- **프론트엔드**: React / Vue / Next.js (Vite 또는 Turbopack)
- **백엔드**: FastAPI / Django / Express (Python / Node.js)
- **데이터베이스**: PostgreSQL / MySQL / MongoDB + Redis(선택)
- **배포**: AWS Lightsail · ECS · App Runner · GCP Cloud Run · Azure · Vercel · Heroku · Kubernetes

---

## 시작하기 전에

| 항목 | 필요 | 설치 |
|---|---|---|
| Claude Code | 최신 | [claude.com/claude-code](https://claude.com/claude-code) |
| Git | 2.30+ | OS 패키지 매니저 |
| Docker + Docker Compose | Docker Desktop 또는 동등 | [docker.com](https://www.docker.com/) |
| **Linux/macOS**: `jq`, `openssl`, `bash` | — | `apt install jq` / `brew install jq` |
| **Windows**: PowerShell 7+ <br>또는 WSL2 / Git Bash | — | `choco install pwsh git jq` |

확인:

```bash
claude --version && git --version && docker --version && jq --version
```

---

## 5분 부트스트랩

> 각 단계는 앞 단계의 결과 위에서만 의미가 있습니다. **순서대로** 진행하세요.

### Step 0 — 저장소 생성

#### 방법 A: "Use this template" 버튼 (권장)

1. https://github.com/mailtome7072/ClaudeQuickStarter 페이지에서 우측 상단 **"Use this template" → "Create a new repository"**
2. 새 저장소 이름/오너 입력 → **Create repository**
3. 로컬로 클론:
   ```bash
   git clone https://github.com/[your-org]/[your-repo].git
   cd [your-repo]
   ```

이 방법은 깨끗한 단일 초기 커밋으로 시작하며 템플릿과 fork 관계가 없습니다.

#### 방법 B: 수동 클론 (CLI 선호 또는 권한 제약 시)

```bash
mkdir my-project && cd my-project
git clone https://github.com/mailtome7072/ClaudeQuickStarter .
rm -rf .git && git init
git remote add origin https://github.com/[your-org]/[your-repo].git
git add . && git commit -m "Initial commit"
git push -u origin main
```

> Windows PowerShell에서는 `rm -rf .git` 대신 `Remove-Item -Recurse -Force .git`

### Step 1 — `ARCHITECTURE.md` 변수 5개 입력

파일 상단 표의 5개 항목을 채웁니다:

| 변수 | 예시 |
|---|---|
| `project_name` | `task-flow` |
| `project_description` | `Team collaboration platform` |
| `github_org` | `mycompany` |
| `github_repo` | `task-flow` |
| `decision_date` | `2026-05-18` |

이 값들은 다음 단계(`/setup-project`)에서 README / PRD / CLAUDE / docker-compose의 `${...}` 플레이스홀더에 자동 치환됩니다.

### Step 2 — `PRD.md` 작성

특히 **§5 "기술 스택"**을 채웁니다. 각 항목의 "선택" 컬럼은 변경 가능한 기본값이며, 불확실한 항목은 `TBD`로 두면 다음 단계의 대화에서 함께 결정합니다.

### Step 3 — 스택 분석 (Claude Code에서)

```
/analyze-stack
```

`stack-analyzer` 에이전트가 다음을 수행:

- ✅ **완결성** — 필수 6항목 입력 확인
- 📊 **호환성** — Frontend↔Backend, DB↔ORM, 런타임 버전
- 🎯 **최적화** — 성능 / 보안 / 운영 권장
- ❓ **6가지 대화형 질문** — 로깅 / 모니터링 / MFA / 파일 저장소 / 배포 전략 / 테스트 커버리지

답변 완료 시 `.claude/stack.json`이 `status: "confirmed"`로 저장됩니다.

### Step 4 — 부트스트랩 실행

```
/setup-project
```

세 단계가 순차로 자동 수행:

1. **변수 치환** — ARCHITECTURE.md의 값을 모든 `${...}` 플레이스홀더에 적용
2. **모듈 합성** — `.claude/stack.json` 기반으로 `app/`, `docker/`, `docker-compose*.yml`, `.env`(강한 시크릿 자동), `.github/workflows/` 생성
3. **SETUP 실행** — 의존성 설치 + Docker 시작 테스트
   - Linux/macOS: `bash SETUP.sh`
   - Windows: `pwsh ./SETUP.ps1` (네이티브) 또는 WSL/Git Bash에서 `bash SETUP.sh`

### Step 5 — 동작 확인

```bash
docker-compose ps                              # 모든 서비스 healthy
curl http://localhost:8000/health              # FastAPI/Django (Express는 /healthz)
```

브라우저에서:
- http://localhost (Nginx 통합 진입점)
- http://localhost:5173 (Vite 개발 서버) 또는 http://localhost:3000 (Next.js)

### Step 6 — ROADMAP & 첫 Sprint

```
PRD 기반으로 ROADMAP 생성해줘.
```
→ `prd-to-roadmap`이 PRD §3을 분석해 `ROADMAP.md`를 채움.

```
Sprint 1 계획 세워줘.
```
→ `sprint-planner`가 작업 단위로 분해해 `docs/sprint/sprint1.md` 작성.

```
/sprint-dev 1
```
→ `sprint1` 브랜치 생성 + 개발 진입.

---

## 부트스트랩 후 생성되는 것

`/setup-project` 완료 시 다음이 자동 생성됩니다 (스택 선택에 따라 내용이 달라짐):

```
app/
├── frontend/                      # React / Vue / Next.js
└── backend/                       # FastAPI / Django / Express

docker/
├── backend/Dockerfile.prod
├── frontend/Dockerfile.prod
└── nginx/{Dockerfile, nginx.conf, conf.d/default.conf}

docker-compose.yml                 # 로컬 개발 (DB/캐시 포함)
docker-compose.prod.yml            # 프로덕션 (Nginx 포함)
.env                               # 강한 시크릿 자동 생성 (gitignored)

.github/workflows/
├── ci.yml                         # 테스트 + 린트
├── deploy.yml                     # 환경별 배포 (Lightsail/ECS/Cloud Run/...)
└── rollback.yml                   # 이전 안정 SHA로 재배포
```

---

## 일상 작업 (부트스트랩 이후)

| 상황 | 명령 |
|---|---|
| Sprint 계획 | `"Sprint N 계획 세워줘"` → `sprint-planner` |
| Sprint 구현 진입 | `/sprint-dev N` |
| 코드 리뷰 + 회고 | `"sprint-review 실행해줘"` |
| Sprint 마무리 (PR 생성) | `"Sprint 마무리해줘"` → `sprint-close` |
| 프로덕션 배포 | `"배포 준비해줘"` → `deploy-prod` (Policy Gate + 모니터링 + 자동 롤백) |
| 긴급 패치 | `"hotfix 마무리해줘"` → `hotfix-close` |
| Docker 재시작 | `/restart` |
| CLAUDE.md 갱신 | `/init` |

전체 프롬프트 예시: [`docs/prompt-guide.md`](docs/prompt-guide.md)

---

## 스택 선택 예시

| 조합 | 적합한 경우 |
|---|---|
| React 18 + FastAPI + PostgreSQL + Redis | 가장 빠른 시작, 풍부한 생태계 |
| Next.js 14 + Express + MongoDB | JS/TS 풀스택, Vercel 배포 친화 |
| Vue 3 + Django + PostgreSQL | 안정성 우선, 관리자 UI 자동 |
| Svelte + Spring Boot + MySQL | 엔터프라이즈 자바 스택 |

`stack-analyzer`가 선택 조합의 호환성을 검증하고, `/setup-project`가 선택에 맞춰 합성합니다.

선택 가이드 (의사결정 매트릭스): [`docs/stack-analysis-guide.md`](docs/stack-analysis-guide.md)

---

## 템플릿이 제공하는 것

| 카테고리 | 내용 |
|---|---|
| **에이전트 8** | `stack-analyzer`, `prd-to-roadmap`, `phase-planner`, `sprint-planner`, `sprint-close`, `sprint-review`, `deploy-prod`, `hotfix-close` |
| **슬래시 커맨드 4** | `/analyze-stack`, `/setup-project`, `/sprint-dev`, `/restart` (+ Claude Code 내장 `/init`) |
| **부트스트랩 모듈 10** | `.env` / `docker-compose` / `Dockerfile` / GitHub Actions 생성기 + 프론트엔드/백엔드 스캐폴드 6종 |
| **안전 훅 3** | scope 검증 / 금지 영역 차단 / 무한 루프 감지 (bash + PowerShell 양쪽) |
| **운영 가이드** | `strategy/`(계획·브랜치·테스트·배포) + `docs/`(harness-engineering·ci-policy·setup-guide·prompt-guide) |

---

## 설계 원리

### 1. PRD가 진실의 원천

모든 부트스트랩 결정은 `PRD.md`와 `.claude/stack.json`에서만 도출됩니다. 임의의 가정 없음 — 사용자가 입력하지 않은 기능은 ROADMAP에도 들어가지 않습니다.

### 2. 정적 / 생성 자산 분리

- **정적 (템플릿에 포함)**: 에이전트 정의, 슬래시 커맨드, 부트스트랩 모듈, 정책 문서, `*.template`
- **생성 (스택 확정 후)**: `app/`, `docker/`, `docker-compose*.yml`, `.env`, `.github/workflows/`

→ React/FastAPI 외 어떤 조합도 동일한 흐름으로 지원.

### 3. 하네스 5원칙 (AI 안전성)

| 원칙 | 강제 도구 |
|---|---|
| Planning First | `scope-validator` 훅 (scope.md 작성 의무) |
| Strict Guardrails | `forbidden-area-guard` 훅 (`.github/workflows/`, `SETUP.sh` 등 차단) |
| Verification Loops | `loop-detector` 훅 (동일 파일 3회 수정 시 경고) |
| Policy Enforcement | `deploy-prod` 에이전트 (배포 전 Policy Gate) |
| Continuous Verification | `deploy-prod` 에이전트 (배포 후 모니터링 + 자동 롤백) |

상세: [`docs/harness-engineering/README.md`](docs/harness-engineering/README.md)

### 4. Cross-platform

| 환경 | 진입점 |
|---|---|
| Linux/macOS | `bash SETUP.sh` |
| Windows 네이티브 | `pwsh ./SETUP.ps1` (`.env` 생성은 PowerShell 네이티브, 복잡한 스택 합성은 bash 모듈 위임) |
| Windows + WSL2 / Git Bash | `bash SETUP.sh` |

---

## 문제가 생기면

| 증상 | 해결 |
|---|---|
| `jq: command not found` | `apt install jq` / `brew install jq` / `choco install jq` |
| `.claude/stack.json` status가 `pending` | `/analyze-stack` 먼저 실행 |
| `SETUP.sh: $'\r': command not found` | CRLF 줄바꿈 — `sed -i 's/\r$//' SETUP.sh` (또는 `.gitattributes` 적용 확인) |
| Windows에서 PS1이 bash 모듈 호출 실패 | Git for Windows 또는 WSL2 설치 |
| Forbidden area 차단 메시지 | 의도된 동작. 우회는 `CLAUDE_ALLOW_FORBIDDEN=1` 환경변수 또는 `touch .claude/tmp/forbidden-override` (다음 1회만) |
| 부트스트랩 후 `app/frontend`가 비어 있음 | 선택한 스택의 스캐폴드가 스텁(예: Vue/Next.js 일부) — 출력의 임시 안내 실행 |

상세: [`docs/setup-guide.md`](docs/setup-guide.md)

---

## 더 알아보기

| 문서 | 내용 |
|---|---|
| [`PRD.md`](PRD.md) | 제품 요구사항 템플릿 (§5에서 스택 작성) |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | 프로젝트 변수 레지스트리 |
| [`CLAUDE.md`](CLAUDE.md) | Claude Code 협업 지침 (이 저장소 내 작업 시 참조) |
| [`docs/stack-analysis-guide.md`](docs/stack-analysis-guide.md) | 스택 선택 의사결정 매트릭스 |
| [`docs/prompt-guide.md`](docs/prompt-guide.md) | 상황별 프롬프트 예시 |
| [`docs/setup-guide.md`](docs/setup-guide.md) | 부트스트랩 트러블슈팅 |
| [`docs/ci-policy.md`](docs/ci-policy.md) | CI/CD 정책, Secrets, Branch Protection |
| [`docs/harness-engineering/README.md`](docs/harness-engineering/README.md) | AI 안전 5원칙 상세 |
| [`strategy/`](strategy/) | 계획 / 브랜치 / 테스트 / 배포 전략 |
| [`CHANGELOG.md`](CHANGELOG.md) | 템플릿 버전 이력 |

---

**버전**: v0.2.0-template
**마지막 업데이트**: 2026-05-18
**기반**: ClaudeStarter (skyang)
