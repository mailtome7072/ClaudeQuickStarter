# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🧩 이 저장소의 성격

이 저장소는 **ClaudeQuickStarter 템플릿 자체**입니다. 일반적인 애플리케이션 코드베이스가 아니라, 사용자가 클론해서 **자기 프로젝트로 부트스트랩**하기 위한 스캐폴드입니다.

따라서 이 파일을 읽는 Claude 인스턴스는 두 가지 모드 중 어느 쪽에서 호출됐는지를 먼저 판단해야 합니다:

1. **템플릿 유지보수 모드** — 이 저장소(`ClaudeQuickStarter`)의 템플릿 자체를 고치는 경우 (스캐폴드, 에이전트 정의, 문서 개선 등)
2. **부트스트랩 모드** — 사용자가 이 템플릿을 클론한 신규 프로젝트에서 작업하는 경우 (실제 PRD 작성, 스택 확정, 스프린트 진행 등)

대부분의 워크플로우 안내(스프린트, 배포, 핫픽스 등)는 **부트스트랩 모드**를 가정합니다. 템플릿 유지보수 시에는 그 안내를 그대로 따르지 말고 의도를 참고만 하세요.

---

## 📍 현재 템플릿 상태 (v0.2.0-template 기준)

| 항목 | 상태 |
|------|------|
| **프로젝트 변수 치환** | ❌ 미수행 — `ARCHITECTURE.md`의 변수 입력은 사용자 작업 |
| **기술 스택 확정** | ❌ 미수행 — `.claude/stack.json`은 `status: pending` (gitignored) |
| **PRD §5 작성** | ❌ 미수행 — 사용자 작업 |
| **에이전트 정의** | ✅ 8개 (stack-analyzer, prd-to-roadmap, phase-planner, sprint-planner, sprint-close, sprint-review, deploy-prod, hotfix-close) |
| **슬래시 커맨드** | ✅ 4개 (`/analyze-stack`, `/setup-project`, `/sprint-dev`, `/restart`) + 내장 `/init` |
| **부트스트랩 모듈** | ✅ 10개 setup-modules (FastAPI/Django/Express, React-Vite/Vue/Next.js, generate-env/dockerfiles/compose/actions) |
| **하네스 훅** | ✅ 3개 등록 (scope-validator, forbidden-area-guard, loop-detector) + `.claude/settings.json` |
| **정책/가이드** | ✅ harness-engineering, ci-policy, setup-guide, prompt-guide, strategy 4종 |
| **Windows 지원** | ✅ `SETUP.ps1` 네이티브 (bash 모듈 위임) |
| **앱 코드** | ❌ `app/frontend`, `app/backend`는 빈 폴더 (스택 확정 후 `/setup-project`가 채움) |

### 다음 단계 (부트스트랩 모드로 진입)

1. `ARCHITECTURE.md`의 프로젝트 변수 5개 입력
2. `PRD.md` 섹션 5 "기술 스택" 작성
3. `/analyze-stack` 실행 → 6가지 확인 질문 답변 → `.claude/stack.json` 확정
4. `/setup-project` 실행 → 변수 치환 + 모듈 합성 + SETUP.sh 실행
5. "PRD 기반 ROADMAP 생성해줘" → `prd-to-roadmap`
6. "sprint 1 계획 세워줘" → `sprint-planner`
7. `/sprint-dev 1` → 개발 착수

---

## 🛠️ 실제 동작하는 명령어 (현재 시점)

> 일반적인 `pnpm dev` / `pytest` / `uvicorn` 명령어는 **스택이 확정되고 SETUP.sh가 앱 코드를 생성한 이후에만** 의미가 있습니다. 그 전까지 이 저장소에서 실제로 실행 가능한 명령은 아래뿐입니다.

### 환경 부트스트랩

```bash
# 스택 확정 후 (.claude/stack.json이 confirmed 상태)
bash SETUP.sh
```

**의존성**: `jq`, `docker`, `docker-compose`, (스택에 따라) `pnpm` / `npm` / `python3`

### Windows 환경 주의사항

이 호스트는 **Windows (win32)** 입니다. `SETUP.sh`는 bash 스크립트이므로 직접 실행할 수 없습니다. 다음 중 하나를 사용하세요:

- **WSL2** (권장): `wsl bash SETUP.sh`
- **Git Bash**: Git for Windows에 포함된 bash로 실행
- `jq` 설치 필요 (`choco install jq` 또는 WSL에서 `apt install jq`)

PowerShell 직접 실행은 지원되지 않습니다.

### MCP 서버

`.mcp.json`에 Notion MCP 서버가 설정되어 있습니다. 사용하려면 `NOTION_API_KEY` 환경 변수가 필요합니다.

### Docker (스택 확정 후)

```bash
docker-compose up --build   # docker-compose.yml은 SETUP.sh가 생성
docker-compose down
```

> `docker-compose.prod.yml`은 템플릿으로 이미 존재하지만 `${...}` 플레이스홀더가 치환되지 않은 상태입니다.

---

## 🗂️ 코드베이스 길찾기

### 시각적으로 가장 중요한 진입점

| 파일 | 역할 |
|------|------|
| `README.md` | 사용자용 5단계 빠른 시작 (한국어) |
| `PRD.md` | 제품 요구사항 템플릿 — 섹션 5가 스택 분석의 입력 |
| `ARCHITECTURE.md` | 5개 프로젝트 변수 레지스트리 (치환 소스) |
| `SETUP.sh` | 동적 환경 초기화 — `.claude/stack.json`을 jq로 파싱해서 분기 |
| `.claude/stack.json` | 스택 레지스트리 (gitignored, stack-analyzer가 생성) |
| `.claude/agents/stack-analyzer.md` | 현재 정의된 유일한 에이전트 |
| `docs/stack-analysis-guide.md` | 스택 선택 의사결정 가이드 |

### 디렉터리 의도 (실재하는 것만)

- `.claude/agents/` — 에이전트 정의 (현재 1개)
- `.claude/agents/agent-memory/` — 에이전트 간 공유 메모리
- `.claude/logs/` — 훅 이벤트 로그 (런타임)
- `.claude/tmp/` — 일시 파일
- `scripts/setup-modules/templates/` — SETUP.sh가 사용할 모듈 템플릿 (현재 비어 있음)
- `strategy/` — 전략 지침 (현재 `.gitkeep`만)

---

## 🛡️ 하네스 엔지니어링 원칙 (설계 의도)

이 템플릿이 채택하는 AI 협업 가드레일 5가지입니다. **훅 구현이 아직 없으므로 현재 강제되지는 않습니다** — 부트스트랩된 프로젝트에서 점진적으로 도입할 설계 가이드로 보세요.

1. **Planning First** — 코드 수정 전 `scope.md` 작성
2. **Strict Guardrails** — 금지 영역 (`SETUP.sh`, `docker/`, `.github/workflows/`, `docs/harness-engineering/`) 자동 차단
3. **Verification Loops** — 동일 파일 3회 수정 시 자동 분석 트리거
4. **Policy Enforcement** — 배포 전 Policy Gate 통과 필수
5. **Continuous Verification** — 배포 후 자동 헬스 체크 & 롤백

> 위 원칙을 강제하는 훅(`posttooluse-code-validator.sh` 등)과 정책 문서(`.claude/rules/harness-engineering.md`, `docs/harness-engineering/README.md`)는 **현재 저장소에 없습니다**. 도입 시 별도 작업으로 추가하세요.

---

## 🌿 브랜치 & 커밋 규약

### Branch 전략

```
main (프로덕션, 보호됨)
  ↑
  develop (QA/Staging)
    ↑
    sprint{n} (스프린트 작업)
    hotfix/{설명} (긴급 패치)
```

### Commit 메시지

```
sprint-{n}: [feature/fix/refactor] 짧은 설명

(본문은 필요 시)
Closes #issue-number
```

### PR

- **제목**: `Sprint {n}: 기능 설명`
- **설명**: 변경사항, 테스트 방법, 스크린샷

---

## 📚 워크플로우 (정본 부트스트랩 순서)

> 이 순서는 README.md, ARCHITECTURE.md, PRD.md와 동일합니다. **차이가 있다면 README가 정본**입니다.

```
0. git clone
1. ARCHITECTURE.md 변수 5개 입력
2. PRD.md §5 기술 스택 작성
3. /analyze-stack  ← stack-analyzer 에이전트 + 6가지 질문
4. .claude/stack.json 확정
5. /setup-project  ← (a) 변수 치환 (b) setup-modules 합성 (c) SETUP.sh 실행
6. prd-to-roadmap → ROADMAP.md 생성
7. sprint-planner → Sprint 1 계획
8. /sprint-dev 1 → 개발 착수
```

### `/setup-project`의 정확한 의미

세 가지 일을 순서대로 수행합니다:

1. **ARCHITECTURE 변수 치환** — `${project_name}`, `${github_org}` 등 플레이스홀더를 PRD/CLAUDE/docker-compose 등에서 일괄 치환
2. **setup-modules 합성** — `.claude/stack.json`의 frontend/backend/db 선택에 따라 `scripts/setup-modules/`에서 적절한 모듈을 호출하여 `app/`, `docker/`, `.github/workflows/`, `.env`, `docker-compose.yml` 생성
3. **SETUP.sh 실행** — 의존성 설치, Docker 시작 테스트

### 현재 구현 상태 (v0.2.0)

- ✅ 에이전트 8종 (`stack-analyzer`, `prd-to-roadmap`, `phase-planner`, `sprint-planner`, `sprint-close`, `sprint-review`, `deploy-prod`, `hotfix-close`)
- ✅ 슬래시 커맨드 4종 (`/analyze-stack`, `/setup-project`, `/sprint-dev`, `/restart`) + 내장 `/init`
- ✅ 부트스트랩 모듈 10종 (`scripts/setup-modules/`)
- ✅ 하네스 훅 3종 + `.claude/settings.json` 등록
- ✅ Windows: `SETUP.ps1` 네이티브 + bash 모듈 위임

각 에이전트/커맨드 상세는 `.claude/agents/*.md`, `.claude/commands/*.md` 직접 참조.

---

## ✏️ 작업 시 일반 원칙

- **에이전트/커맨드 호출 전 실재 여부 확인**: `.claude/agents/`, `.claude/commands/` 목록을 먼저 봅니다. 정의가 없으면 자연어로 수행하거나 사용자에게 에이전트 생성을 제안하세요.
- **`SETUP.sh`, `docker-compose*.yml`, `.github/workflows/` 수정**: 신중하게. 템플릿의 핵심이므로 변경은 의도된 개선일 때만.
- **`${변수}` 플레이스홀더**: 임의로 치환하지 마세요. `ARCHITECTURE.md` 입력 후 일괄 치환이 원칙입니다.
- **`.claude/stack.json`**: gitignored이며 형식은 `.claude/stack.json` 내부의 `example` 키 참고.

---

**마지막 갱신**: 2026-05-18 (템플릿 현재 상태 반영 / `/init`)
