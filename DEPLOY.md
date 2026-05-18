# DEPLOY.md — 배포 후 수동 작업 체크리스트

> ⚠️ **이 파일은 템플릿 골격입니다.**
> 부트스트랩 후 `/setup-project`가 `.claude/stack.json`을 기반으로 스택별 경로/도구를
> 치환합니다(예: 헬스 체크 경로, 마이그레이션 명령). 각 Sprint 후 `sprint-close` 에이전트가
> 신규 항목을 추가합니다.

---

## Sprint N — 배포 후 수동 작업

> 날짜: YYYY-MM-DD

### 🔄 배포 전 확인

- ⬜ 모든 테스트 통과 (목표 커버리지는 `.claude/stack.json` `decisions.test_coverage_goal` 참조)
- ⬜ 코드 리뷰 승인 (>=2명)
- ⬜ CHANGELOG.md 업데이트
- ⬜ 마이그레이션 스크립트 준비 (DB 스키마 변경 시 — `stack.json` `database.migration_tool` 참조)

### 🚀 배포

- ⬜ develop → main PR 생성 (GitHub)
- ⬜ GitHub Actions 자동 배포 시작 (`.github/workflows/deploy.yml`)
- ⬜ 배포 로그 확인 (성공/실패)

### ✅ 배포 후 검증 (실서버)

#### 헬스 체크

> 경로는 스택별로 다름. `/setup-project`가 `.env`의 `HEALTH_PATH`를 설정합니다.
> 예: FastAPI/Django=`/health`, Express=`/healthz`, Spring=`/actuator/health`, Next.js=`/api/health`

- ⬜ 프론트엔드 로드: `https://${PRODUCTION_URL}/`
- ⬜ 백엔드 헬스: `https://${PRODUCTION_URL}${API_PREFIX}${HEALTH_PATH}`
- ⬜ API 문서: `https://${PRODUCTION_URL}${API_PREFIX}/docs` (스택 기본값 — `stack.json` `backend.api_documentation`)

#### 기본 기능 테스트

- ⬜ 인증 (로그인/로그아웃) — `stack.json` `backend.authentication` 방식 기준
- ⬜ 이번 Sprint의 핵심 비즈니스 로직
- ⬜ 데이터 저장/로드 (DB 동작) — `stack.json` `database.primary_database` 기준
- ⬜ 에러 핸들링 (오류 로그 정상 기록)

#### 성능 & 모니터링

- ⬜ API 응답 시간 (목표: PRD §4.1 또는 200ms 이내)
- ⬜ 에러율 (목표: < 1%)
- ⬜ 로깅 정상 기록 — `stack.json` `infrastructure.logging` (CloudWatch/ELK/Loki 등)
- ⬜ CPU/Memory 사용률 정상

#### 보안

- ⬜ HTTPS 동작 (https:// 강제)
- ⬜ CORS 정책 (프론트엔드 도메인만 허용)
- ⬜ 환경변수 노출 여부 (시크릿 안전, 응답에 포함 안 됨)

### 📝 배포 이력 기록

배포 완료 후 `docs/deploy-history/` 폴더에 기록:

```markdown
# Sprint N 배포 (YYYY-MM-DD)

## 배포 정보
- **Sprint**: N
- **배포 시간**: HH:MM UTC
- **배포자**: [사용자명]
- **변경 사항**: [주요 기능 요약]
- **스택 변경**: [있으면 stack.json 변경 이력 인용]

## 검증 결과
- ✅ 헬스 체크 통과
- ✅ 기본 기능 테스트 통과
- ✅ 성능 정상 (응답시간 X ms, 에러율 X%)

## 롤백 계획 (필요 시)
롤백 필요 조건: 에러율 > 5% 또는 주요 기능 장애
롤백 방법: git revert 후 재배포 (또는 이전 Docker 이미지 태그로 되돌림)
```

### 🚨 장애 대응

배포 후 문제 발생 시:

1. **즉시 대응** (< 5분)
   - ⬜ 상황 파악 (에러율, 응답시간, 에러 로그)
   - ⬜ 긴급 알림 (팀 채널)

2. **롤백 여부 판단** (< 10분)
   - ✅ 롤백: 이전 버전으로 복구
   - 🔧 Hotfix: 문제 고쳐서 재배포 (`hotfix-close` 에이전트)

3. **사후 분석**
   - ⬜ 근본 원인 분석 (RCA) 문서 작성
   - ⬜ `docs/risk-register/` 기록
   - ⬜ 팀 회고 (`docs/sprint-retrospectives/`)에서 개선 방안 논의

---

## 공통 문제 해결 (스택 무관 가이드라인)

### API 호출 실패

1. 백엔드 서버 실행 확인: `docker-compose ps`
2. 데이터베이스 연결 확인: `.env`의 DB 인증 정보 정확성
3. 방화벽/CORS 설정 확인

### 데이터베이스 오류

> 마이그레이션 도구는 스택별로 다름 — `stack.json` `database.migration_tool` 참조

- **Alembic** (Python/SQLAlchemy): `alembic current`, 롤백 `alembic downgrade -1`
- **Django ORM**: `python manage.py showmigrations`, 롤백 `python manage.py migrate app_name <prev>`
- **Prisma** (Node): `npx prisma migrate status`, 롤백은 새 마이그레이션 작성
- **Flyway**: `flyway info`, 롤백은 down 스크립트 또는 새 마이그레이션

백업 확인: `docs/deploy-history/` 참고

### 성능 저하

- 캐시 상태 확인 (Redis 사용 시): `redis-cli ping`, 메모리 사용량
- 쿼리 성능: 로깅 도구에서 슬로우 쿼리 검색 (`stack.json` `infrastructure.logging` 기준)
- 동시 사용자 확인: 예상 트래픽 초과 여부

---

**마지막 배포**: [날짜]
**현재 버전**: [버전번호]
**다음 배포 일정**: [예정일]
**상태**: 템플릿 골격 (`/setup-project` 실행 후 스택별 값으로 치환됨)
