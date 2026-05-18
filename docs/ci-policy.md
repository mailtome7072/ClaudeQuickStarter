# CI/CD 정책

이 문서는 모든 PR이 거쳐야 하는 CI 게이트와 배포 정책을 정의합니다.

> 워크플로우 파일은 `/setup-project` 실행 시 `.github/workflows/`에 생성됩니다.
> 이 문서는 그 정책의 의도와 운영 원칙입니다.

---

## CI 파이프라인 (`.github/workflows/ci.yml`)

### 트리거
- `push`: `main`, `develop`, `sprint*`
- `pull_request`: `main`, `develop`

### 단계

1. **Frontend Job** (조건: `app/frontend/package.json` 존재)
   - 의존성 설치 (frozen-lockfile)
   - Lint (`pnpm run lint` 또는 동등)
   - Unit test (`pnpm test`)
   - Build (`pnpm run build`)

2. **Backend Job** (조건: `app/backend/requirements.txt` 또는 `package.json` 존재)
   - 의존성 설치
   - Lint (ruff/eslint)
   - Unit + Integration test (pytest/jest)

### 실패 시
- PR 머지 차단 (GitHub Branch Protection)
- 작성자에게 알림

---

## 배포 파이프라인 (`.github/workflows/deploy.yml`)

### 트리거
- `push`: `main`
- `workflow_dispatch` (수동 배포 — CDelivery 선택 시)

### 단계

1. **Build & Push**
   - Frontend/Backend Docker 이미지 빌드
   - GitHub Container Registry (`ghcr.io`)에 push
   - 태그: `latest` + git SHA

2. **Deploy** (대상 환경별)
   - Lightsail: SSH로 docker pull & restart
   - Cloud Run: `gcloud run deploy`
   - ECS: task definition 업데이트
   - 기타: stack.json `infrastructure.deployment_environment` 참조

3. **Post-Deploy Verification** (deploy-prod 에이전트가 수행)
   - 헬스 체크 (스택별 경로)
   - 5분간 모니터링
   - 실패 시 자동 롤백

---

## Branch Protection 권장 설정

### main
- ✅ Require pull request before merging
- ✅ Require approvals: 1+
- ✅ Require status checks to pass before merging
  - CI Frontend
  - CI Backend
- ✅ Require branches to be up to date before merging
- ✅ Include administrators
- ❌ Allow force pushes
- ❌ Allow deletions

### develop
- ✅ Require pull request before merging
- ✅ Require status checks to pass before merging
- ❌ Allow force pushes
- ❌ Allow deletions

---

## Secrets 관리

### GitHub Repository Secrets

- `DEPLOY_SSH_KEY` (Lightsail SSH 키)
- `DEPLOY_HOST` (배포 대상 호스트)
- `GHCR_TOKEN` (자동 — `${{ secrets.GITHUB_TOKEN }}`)
- `CODECOV_TOKEN` (선택)
- 외부 통합 시크릿 (`STRIPE_SECRET_KEY`, `SENDGRID_API_KEY` 등)

### 절대 커밋하지 말 것

- `.env`
- `*.pem`, `*.key`
- `credentials.json`

`.gitignore`가 이를 보호하지만 PR 검토 시 항상 확인.

---

## Policy Gate (deploy-prod가 자동 검사)

배포 전 다음을 모두 통과해야 함:

| 검사 | 통과 기준 |
|---|---|
| CI Green | 마지막 commit의 모든 job 성공 |
| 테스트 커버리지 | `stack.json` `decisions.test_coverage_goal` 이상 |
| 보안 스캔 | `pip-audit` 또는 `npm audit --audit-level=high` 통과 |
| 시크릿 누출 | `git diff origin/main`에서 시크릿 패턴 검출 안 됨 |
| CHANGELOG | 마지막 release 이후 변경분 기록 있음 |
| 마이그레이션 | DB 변경 시 down 마이그레이션 가능 |

실패 항목은 PR 코멘트로 명시.

---

## 메트릭 & 알람 (운영)

### 수집 메트릭
- API 응답 시간 (p50, p95, p99)
- 에러율 (5xx 비율)
- DB 연결 풀 사용률
- CPU / Memory

### 알람 임계치 (기본 — 프로젝트별 조정)
- 에러율 > 1%: Slack 경고
- 에러율 > 5%: 자동 롤백 + 페이지 호출
- 응답 시간 p95 > 2× 기준선: Slack 경고
- Health endpoint 실패 3회 연속: 자동 롤백

도구: `stack.json` `infrastructure.monitoring` 참조 (CloudWatch / Prometheus / Datadog 등)
