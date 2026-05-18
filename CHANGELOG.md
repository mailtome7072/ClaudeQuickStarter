# CHANGELOG — 버전별 변경 이력

모든 주목할 만한 변경 사항은 이 파일에 기록됩니다.

형식은 [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)를 따릅니다.
버전 관리는 [Semantic Versioning](https://semver.org/)를 따릅니다.

> **참고**: 이 파일은 부트스트랩 이후 `sprint-close` 에이전트가 자동으로 갱신합니다.
> 현재 시점에는 템플릿 자체의 변경 이력만 기록됩니다.

---

## [Unreleased]

### Added
- (다음 릴리스 예정 항목)

---

## [0.2.0-template] — 2026-05-18 (Bootstrap-Capable Template)

### Added (Phase 1~8 통합)
- 슬래시 커맨드 4종: `/analyze-stack`, `/setup-project`, `/sprint-dev`, `/restart`
- 에이전트 6종 추가: `prd-to-roadmap`, `sprint-planner`, `sprint-close`, `sprint-review`, `deploy-prod`, `hotfix-close`, `phase-planner`
- setup-modules 10개: `.env`/docker-compose/Dockerfile/GitHub Actions 자동 생성기 + React-Vite/Vue/Next.js/FastAPI/Django/Express 스캐폴드
- `SETUP.ps1` — Windows PowerShell 1급 지원 (네이티브 .env 생성 + bash 위임)
- 하네스 훅 3종: scope-validator, forbidden-area-guard, loop-detector (+ `.claude/settings.json` 등록)
- 정책/가이드 문서: `docs/harness-engineering/README.md`, `.claude/rules/harness-engineering.md`, `strategy/{planning,branching,testing,deployment}.md`, `docs/setup-guide.md`, `docs/prompt-guide.md`, `docs/ci-policy.md`

### Changed
- `stack-analyzer.md`에 YAML frontmatter 추가 → Claude Code 서브에이전트로 정식 등록
- 부트스트랩 정본 순서 통일 (`README`, `CLAUDE`, `ARCHITECTURE`, `PRD`)
- `docker-compose.prod.yml` → `scripts/setup-modules/templates/docker-compose.prod.yml.template`으로 이동 (스택 누수 제거, 조건부 섹션 도입)
- `.env.example` — 스택 조건부 섹션으로 재구성 (Common/DB/Auth/Frontend 분할)
- `ROADMAP.md`, `DEPLOY.md` — JWT/FastAPI 하드코딩 제거, stack.json 변수 참조로 일반화
- `SETUP.sh` — setup-modules 오케스트레이션 구조로 리팩토링
- 모델 ID `claude-opus-4-5` → `claude-opus-4-7` 갱신

### Removed
- brace-expansion 실패로 만들어진 리터럴 디렉터리 5개 (`.claude/{commands,hooks`, `docs/{arch,phase,...}` 등)
- 중복 파일 `QUICKSTART.md` (README와 통합)
- `.gitignore`의 무의미한 `.git/` 라인

### Fixed
- `stack-analyzer.md` 내부 모순 "5가지" vs "6가지" → 6가지로 통일
- `.claude/settings.json` 잘못된 에이전트 스키마 안내 제거

---

## [0.1.0-template] — 2026-05-17 (Initial Template Skeleton)

> 이것은 **사용자 프로젝트의 1.0.0이 아니라, ClaudeQuickStarter 템플릿 자체의 초기 스켈레톤** 버전입니다.
> 사용자 프로젝트의 1.0.0은 부트스트랩 → Sprint 진행 후 별도로 표기됩니다.

### Included
- PRD.md / ARCHITECTURE.md / CLAUDE.md / SETUP.sh 골격
- `stack-analyzer` 에이전트 (frontmatter 없음)
- `docs/stack-analysis-guide.md`
- `docker-compose.prod.yml` (스택 누수 있음 — v0.2.0에서 템플릿화)
- ROADMAP.md / DEPLOY.md 템플릿 (JWT 하드코딩 — v0.2.0에서 일반화)

---

## 사용자 프로젝트 배포 이력

> 부트스트랩 완료 후 사용자 프로젝트의 배포 이력이 아래에 누적됩니다.
> 각 배포 후 `sprint-close` 에이전트가 자동 기록합니다.

| 버전 | 배포일 | Sprint | 주요 기능 |
|------|--------|--------|---------|
| (아직 없음) | - | - | 부트스트랩 후 Sprint 1 시작 시 기록 |

---

**마지막 업데이트**: 2026-05-18 (템플릿 v0.1.0 정직성 정정)
