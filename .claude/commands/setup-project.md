---
description: ARCHITECTURE 변수 치환 + stack.json 기반 setup-modules 합성 + SETUP.sh 실행. 부트스트랩의 두 번째 단계.
argument-hint: (인자 없음)
---

# /setup-project

`/analyze-stack`이 완료된 후 실행합니다. 세 단계로 동작합니다.

## 선행 조건 검증

다음을 먼저 확인하고, 실패 시 명확한 메시지로 중단합니다:

1. `.claude/stack.json`이 존재하고 `status: "confirmed"`인가? → 아니면 `/analyze-stack` 먼저 실행하라고 안내
2. `ARCHITECTURE.md`에 `${...}` 잔존 변수가 없는가? → 있으면 어떤 변수가 비었는지 안내
3. `jq` (또는 PowerShell 환경에서는 `ConvertFrom-Json` 사용 가능)
4. `docker`, `docker-compose` 설치 여부

## Phase A — ARCHITECTURE 변수 일괄 치환

`ARCHITECTURE.md`에서 5개 변수(`project_name`, `project_description`, `github_org`, `github_repo`, `decision_date`)를 읽어 다음 파일들에서 `${변수명}` → 실제 값으로 일괄 치환:

- `README.md`
- `CLAUDE.md`
- `PRD.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `DEPLOY.md`
- (생성될) `docs/ci-policy.md`
- (생성될) `docker-compose.prod.yml`

치환 도구: `sed -i` (Unix) 또는 PowerShell `(Get-Content ... ) -replace ... | Set-Content`

## Phase B — stack.json 기반 setup-modules 합성

`.claude/stack.json`을 읽어 다음 결정에 따라 `scripts/setup-modules/`의 적절한 모듈 호출:

| stack.json 키 | 호출할 모듈 |
|---|---|
| `frontend.ui_framework` "React" + `frontend.build_tool` "Vite" | `setup-modules/setup-frontend-react-vite.sh` |
| `frontend.ui_framework` "Vue" | `setup-modules/setup-frontend-vue.sh` |
| `frontend.ui_framework` "Next.js" | `setup-modules/setup-frontend-nextjs.sh` |
| `backend.framework` "FastAPI" | `setup-modules/setup-backend-fastapi.sh` |
| `backend.framework` "Django" | `setup-modules/setup-backend-django.sh` |
| `backend.framework` "Express" | `setup-modules/setup-backend-express.sh` |
| (항상) | `setup-modules/generate-docker-compose.sh` (템플릿 기반 조건부 합성) |
| (항상) | `setup-modules/generate-dockerfiles.sh` |
| (항상) | `setup-modules/generate-env.sh` (강한 시크릿 자동 생성) |
| (항상) | `setup-modules/generate-github-actions.sh` |

각 모듈은:
- 입력: `.claude/stack.json` (jq로 파싱) + `scripts/setup-modules/templates/`
- 출력: `app/frontend/`, `app/backend/`, `docker/*/Dockerfile.*`, `docker-compose.yml`, `docker-compose.prod.yml`, `.env`, `.github/workflows/*.yml`

미지원 스택일 경우 명확한 에러 + 다음 행동(수동 모듈 작성 또는 사용자 지원) 안내.

## Phase C — SETUP 스크립트 실행

OS 감지하여 적절한 변형 호출:

| OS | 실행 |
|---|---|
| Linux/macOS | `bash SETUP.sh` |
| Windows (PowerShell 7+ 권장) | `pwsh ./SETUP.ps1` |
| Windows + WSL2 | WSL 내에서 `bash SETUP.sh` |
| Windows + Git Bash | Git Bash에서 `bash SETUP.sh` |

PowerShell 변형(`SETUP.ps1`)은 .env 생성/변수 치환을 네이티브로 처리하고, 복잡한 스택 합성은 Git Bash 또는 WSL의 bash로 위임합니다.

SETUP.sh는:
1. 생성된 `app/frontend/`, `app/backend/`에서 의존성 설치 (pnpm/pip 등)
2. `docker-compose up -d`로 서비스 시작 테스트
3. 결과 요약 출력

## Phase D — 완료 보고 & 다음 단계 안내

```
✓ 변수 치환 완료
✓ setup-modules 합성 완료 (app/, docker/, .env, .github/)
✓ SETUP.sh 실행 완료

다음 단계:
  1. .env의 시크릿 값 확인 (자동 생성됨)
  2. git add . && git commit -m "Bootstrap: stack confirmed and setup complete"
  3. Claude Code: "PRD 기반 ROADMAP 생성해줘." → prd-to-roadmap
  4. Claude Code: "sprint 1 계획 세워줘." → sprint-planner
  5. Claude Code: /sprint-dev 1
```

---

## 사용 예

```
/setup-project
```

선행 단계가 안 되어 있으면:

```
✗ .claude/stack.json이 status: "pending" 상태입니다.
  먼저 /analyze-stack을 실행하세요.
```
