# CLAUDE.md — Claude Code 협업 지침

이 문서는 Claude Code가 이 프로젝트에서 **작업할 때 따를 지침**입니다.
(`/init` 커맨드가 이 파일을 자동으로 갱신합니다.)

> **참고**: 프로젝트의 기술스택이 확정되면, 이 파일의 "빌드 & 테스트 명령어" 섹션이 자동으로 업데이트됩니다.

---

## 🎯 프로젝트 개요

| 항목 | 값 |
|------|-----|
| **프로젝트명** | ${project_name} |
| **설명** | ${project_description} |
| **GitHub Org** | ${github_org} |
| **저장소** | https://github.com/${github_org}/${github_repo} |

---

## ⚙️ 빌드 & 테스트 명령어

> 🔄 **중요**: 이 섹션은 `/setup-project` 또는 `/analyze-stack` 후 **자동으로 업데이트**됩니다.
> 선택된 기술스택에 따라 명령어가 달라집니다.

### Frontend

```bash
# 패키지 설치 (자동으로 결정됨)
pnpm install  # 또는 npm install, yarn install

# 개발 서버 시작
pnpm dev      # Vite, Next.js 등

# 빌드
pnpm build

# 테스트
pnpm test

# 린트
pnpm lint
```

### Backend

```bash
# 가상환경 활성화 (Python 기준)
source .venv/bin/activate

# 의존성 설치
pip install -r requirements.txt

# 서버 시작 (FastAPI 기준)
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 테스트
pytest app/tests/ -v

# 린트
ruff check app/
```

### Docker

```bash
# 로컬 개발 (docker-compose.yml)
docker-compose up --build

# 로컬 종료
docker-compose down

# 서비스 재시작
docker-compose restart
```

---

## 🔄 워크플로우 및 에이전트 가이드

### 1. 프로젝트 시작 (모든 프로젝트가 거치는 단계)

```
STEP 1: /init 실행
  ↓
STEP 2: PRD.md 작성 (섹션 5 기술 스택)
  ↓
STEP 3: /analyze-stack 실행
  → stack-analyzer 에이전트가 기술스택 분석
  → 완결성, 호환성, 최적화 검증
  → 6가지 확인 질문
  ↓
STEP 4: 대화형 스택 확정
  → .claude/stack.json 생성
  ↓
STEP 5: /setup-project 실행
  → SETUP.sh 동적 생성
  → 개발 환경 초기화
  ↓
STEP 6: /analyze-stack 완료, ROADMAP 생성 준비 완료
```

### 2. 스프린트 계획 (매 스프린트마다)

```
"ROADMAP 검토했어. sprint {n} 계획 세워줘."
  ↓
sprint-planner 에이전트 실행
  → docs/sprint/sprint{n}.md 생성
  → 리스크 식별 시 docs/risk-register/ 기록
  ↓
"계획 검토 완료했어."
  ↓
/sprint-dev {n} 실행
  → sprint{n} 브랜치 생성
  → 현황 파악 및 가이드라인 주입
```

### 3. 스프린트 구현 (sprint-dev 진행 중)

```
/sprint-dev {n}
  ↓
구현 작업 (claude 지원)
  ↓
scope.md 작성 → 코드 수정 (harnessing principle)
  ↓
동일 파일 3회 이상 수정 시 loop-detection 경고
  ↓
모든 Task 완료 후 simplify 스킬 자동 실행 (코드 단순화 1회)
```

### 4. 스프린트 마무리

```
"sprint{n} 구현 완료했어. 마무리 해줘."
  ↓
sprint-close 에이전트 실행
  → ROADMAP.md 상태 업데이트 (진행 중 → 완료)
  → develop PR 생성
  → CHANGELOG.md 업데이트
  → DEPLOY.md 업데이트 (⬜ 항목 초기 작성)
  → sprint-planner 메모리 업데이트
```

### 5. 코드 리뷰 & 검증

```
"sprint-review 실행해줘."
  ↓
sprint-review 에이전트 실행
  → 코드 리뷰 (보안/성능/품질)
  → 자동 검증 (pytest, curl, Playwright)
  → 테스트 결과 기록 (docs/test-reports/)
  → 리스크 기록 (docs/risk-register/) [필요 시]
  → Sprint 회고 작성 (docs/sprint-retrospectives/)
```

### 6. 프로덕션 배포

```
"수동 검증 완료했어. 프로덕션 배포 준비해줘."
  ↓
deploy-prod 에이전트 실행
  → develop → main PR 생성
  → Policy Gate 체크 (harness-ci-gate 스킬)
  → GitHub Actions 자동 배포
  → 배포 후 실서버 검증
  → 배포 이력 기록 (docs/deploy-history/)
```

### 7. 긴급 패치 (Hotfix)

```
STEP 1: git checkout -b hotfix/{설명}
STEP 2: 구현 작업
STEP 3: "hotfix 구현 끝났어. 마무리해줘."
  → hotfix-close 에이전트 실행
  → main PR 생성 (ROADMAP 업데이트 안 함)
  → 머지 후 develop 역머지 안내
```

---

## 📋 에이전트 역할 요약

| 에이전트 | 모델 | 역할 | 트리거 |
|---------|------|------|--------|
| **stack-analyzer** | Opus | 기술스택 분석 & 권장 | "기술스택 분석해줘." |
| **prd-to-roadmap** | Opus | PRD → ROADMAP 자동 생성 | "ROADMAP 생성해줘." |
| **phase-planner** | Opus | 대규모 기능 Phase 설계 | "Phase 설계해줘." |
| **sprint-planner** | Opus | Sprint 계획 수립 | "sprint {n} 계획 세워줘." |
| **sprint-close** | Sonnet | Sprint 마무리 & PR 생성 | "마무리 해줘." |
| **sprint-review** | Sonnet | 코드 리뷰 & 회고 | "sprint-review 실행해줘." |
| **deploy-prod** | Sonnet | 프로덕션 배포 | "배포 준비해줘." |
| **hotfix-close** | Sonnet | 긴급 패치 마무리 | "hotfix 마무리해줘." |

---

## 🛡️ 하네스 엔지니어링 원칙

이 프로젝트는 **5가지 하네스(Harness) 원칙**으로 AI 에이전트의 자율성과 안전성을 동시에 확보합니다.

### 1. Planning First
- **의무**: 코드 수정 전 **반드시 `scope.md` 작성**
- **구현**: `posttooluse-code-validator.sh` 훅이 검증
- **효과**: 무분별한 수정 방지, 목표 명확화

### 2. Strict Guardrails
- **금지 영역 (Forbidden Areas)**:
  - `.github/workflows/` (CI/CD)
  - `SETUP.sh` (초기화 스크립트)
  - `docker/`, `docker-compose*.yml` (인프라)
  - `docs/harness-engineering/` (정책 문서)
- **구현**: `posttooluse-code-validator.sh` 자동 차단
- **예외**: 명시적 사용자 허가 필수

### 3. Verification Loops
- **규칙**: 3회 수정 반복 시 자동 분석 트리거
- **구현**: `posttooluse-scope-tracker.sh` 및 `loop-detection` 스킬
- **효과**: 무한 루프 방지, 다른 접근 강제

### 4. Policy Enforcement
- **배포 전 필수**: Policy Gate 통과 (`harness-ci-gate` 스킬)
- **검사 항목**: 테스트 커버리지, 보안, 성능, 문서화
- **구현**: `deploy-prod` 에이전트가 자동 실행

### 5. Continuous Verification
- **배포 후**: 자동 헬스 체크 & 롤백 트리거
- **모니터링**: 에러율, 응답시간, DB 상태
- **구현**: `deploy-prod` 에이전트 및 CloudWatch

상세: `.claude/rules/harness-engineering.md`

---

## 📝 작업 시 참고 규칙

### Branch 전략

```
main (프로덕션, 보호됨)
  ↑
  develop (QA/Staging)
    ↑
    sprint{n} (스프린트 작업 브랜치)
    hotfix/{설명} (긴급 패치)
```

### Commit 메시지 규약

```
sprint-{n}: [feature/fix/refactor] 짧은 설명

긴 설명이 필요하면 본문에 작성.
Closes #issue-number (해당 시)
```

### PR 규약

- **제목**: `Sprint {n}: 기능 설명`
- **설명**: 변경사항, 테스트 방법, 스크린샷
- **체크리스트**: Code review template 참고

---

## 🎯 주요 슬래시 커맨드

| 커맨드 | 역할 | 언제 사용 |
|--------|------|---------|
| `/init` | 코드베이스 분석 → CLAUDE.md 갱신 | 첫 실행 & 구조 변경 후 |
| `/analyze-stack` | 기술스택 분석 | PRD 작성 후 (처음 1회) |
| `/setup-project` | 환경 변수 치환 & SETUP.sh 생성 | ARCHITECTURE.md 입력 후 |
| `/sprint-dev [n]` | Sprint 구현 진입 | Sprint 계획 후 |
| `/restart` | Docker 서비스 재시작 | 필요 시 |

---

## 📚 추가 문서

- **PRD.md** — 제품 요구사항 (섹션 5 기술 스택)
- **ARCHITECTURE.md** — 프로젝트 변수 레지스트리
- **.claude/agents/stack-analyzer.md** — 스택 분석 에이전트 상세
- **.claude/rules/harness-engineering.md** — 하네스 원칙 상세
- **docs/ci-policy.md** — CI/CD 정책 (자동 생성)
- **docs/stack-analysis-guide.md** — 스택 선택 가이드
- **strategy/*.md** — 전략 지침 (계획, 브랜치, 테스트, 배포 등)

---

## ✨ 팁

1. **막힐 때**: `docs/prompt-guide.md` 참고 (상황별 프롬프트 예시)
2. **에러 추적**: `.claude/logs/` 확인 (훅 이벤트 로그)
3. **메모리 활용**: `.claude/agents/agent-memory/` (팀 전체 지식)
4. **회고**: `docs/sprint-retrospectives/` (다음 스프린트 개선점)

---

**마지막 갱신**: 자동 갱신 (`/init` 커맨드)  
**프로젝트**: ${project_name}  
**기술스택**: 미결정 (stack-analyzer 실행 필요)
