# Setup Guide — 부트스트랩 가이드 & 트러블슈팅

## 정본 부트스트랩 순서

```
0. git clone
1. ARCHITECTURE.md 변수 5개 입력
2. PRD.md §5 기술 스택 작성
3. /analyze-stack
4. .claude/stack.json 확정
5. /setup-project
6. prd-to-roadmap → ROADMAP.md
7. sprint-planner → Sprint 1 계획
8. /sprint-dev 1
```

상세는 `README.md` 빠른 시작 참조.

---

## 환경 요구사항

### 공통
- Git 2.30+
- Claude Code (CLI)

### Linux/macOS
- bash 4+
- jq 1.6+
- openssl
- docker, docker-compose

### Windows
- PowerShell 7+ (`pwsh`) — 권장
- 또는 WSL2 + Ubuntu 22.04+
- 또는 Git Bash (Git for Windows에 포함)
- Docker Desktop

설치:
```powershell
# Chocolatey 사용 시
choco install git docker-desktop powershell-core jq
```

---

## 자주 발생하는 문제

### Q1. `/analyze-stack` 실행 후에도 `.claude/stack.json`이 `pending`

**원인**: stack-analyzer가 사용자 답변을 받지 못했거나 작성 실패.

**해결**:
1. 6가지 확인 질문에 모두 답변했는지 확인
2. 권한 문제 — `.claude/` 디렉터리 쓰기 권한 확인
3. 다시 `/analyze-stack` 실행

### Q2. `SETUP.sh: jq: command not found`

**원인**: `jq` 미설치.

**해결**:
- Ubuntu: `sudo apt install jq`
- macOS: `brew install jq`
- Windows: `choco install jq` 또는 WSL 사용

### Q3. `SETUP.sh: line N: $'\r': command not found`

**원인**: Windows 줄바꿈(CRLF)으로 저장됨.

**해결**:
```bash
sed -i 's/\r$//' SETUP.sh scripts/setup-modules/*.sh
```

또는 `.gitattributes`에 추가:
```
*.sh text eol=lf
```

### Q4. PowerShell `pwsh ./SETUP.ps1`에서 bash 모듈 호출 실패

**원인**: Git Bash 또는 WSL bash 경로 미발견.

**해결**:
- Git for Windows 설치 (`C:\Program Files\Git\bin\bash.exe`)
- 또는 `wsl --install` 후 재시도

### Q5. `docker-compose up` 실패: `port already in use`

**원인**: 5432 (PostgreSQL), 6379 (Redis), 8000 등 포트 충돌.

**해결**:
1. 기존 컨테이너 정지: `docker ps`로 확인 후 `docker stop <id>`
2. 또는 `docker-compose.yml`의 포트 매핑 변경

### Q6. ARCHITECTURE.md 변수 치환이 안 됨

**원인**: `/setup-project` Phase A가 실행되지 않았거나 변수명 형식 오류.

**해결**:
1. `${변수명}` 형식 유지 확인 (중괄호, $ 제거 금지)
2. `/setup-project` 재실행

### Q7. `.env`의 시크릿이 평문으로 보임

**정상 동작**. `.env`는 `.gitignored`이며 로컬 디스크에만 존재.
프로덕션 시크릿은 GitHub Secrets / AWS Secrets Manager 등에서 주입.

### Q8. 부트스트랩 후 `app/frontend`가 비어 있음

**원인**: 선택한 프론트엔드 스택의 자동 스캐폴드 모듈이 아직 스텁(stub) 상태.

**해결**: 모듈 출력의 임시 방안 명령을 직접 실행.
예: Vue 선택 시 → `cd app/frontend && pnpm create vite . --template vue-ts`

---

## 검증 체크리스트

부트스트랩 완료 후:

- [ ] `.claude/stack.json`이 `status: "confirmed"`
- [ ] `.env`가 존재하고 `__GENERATED_BY_SETUP__` 잔존 없음
- [ ] `docker-compose.yml`, `docker-compose.prod.yml` 생성됨
- [ ] `docker/backend/Dockerfile.prod`, `docker/frontend/Dockerfile.prod` 생성됨
- [ ] `app/frontend/`에 코드 또는 명확한 스캐폴드 안내
- [ ] `app/backend/`에 코드 또는 명확한 스캐폴드 안내
- [ ] `.github/workflows/ci.yml`, `deploy.yml` 생성됨
- [ ] `docker-compose up`이 동작
- [ ] 헬스 체크 응답 (스택별 경로)

---

## 다음 단계

부트스트랩 검증 완료 후:

1. `git add . && git commit -m "Bootstrap: stack confirmed and scaffolded"`
2. `git push -u origin main`
3. Claude Code: `"PRD 기반 ROADMAP 생성해줘."` → `prd-to-roadmap`
4. Claude Code: `"sprint 1 계획 세워줘."` → `sprint-planner` (Phase 7)
5. Claude Code: `/sprint-dev 1`
