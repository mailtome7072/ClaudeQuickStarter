# DEPLOY.md — 배포 후 수동 작업 체크리스트

> 이 파일은 `sprint-close` 에이전트가 자동으로 업데이트합니다.
> 각 Sprint 후 배포 시 완료할 수동 작업을 기록합니다.

## Sprint N — 배포 후 수동 작업

> 날짜: YYYY-MM-DD

### 🔄 배포 전 확인

- ⬜ 모든 테스트 통과 (pytest >= 80%, Playwright >=5개 시나리오)
- ⬜ 코드 리뷰 승인 (>=2명)
- ⬜ CHANGELOG.md 업데이트
- ⬜ 마이그레이션 스크립트 준비 (DB 변경 시)

### 🚀 배포

- ⬜ develop → main PR 생성 (GitHub)
- ⬜ GitHub Actions 자동 배포 시작
- ⬜ 배포 로그 확인 (성공/실패)

### ✅ 배포 후 검증 (실서버)

#### 헬스 체크
- ⬜ 프론트엔드 로드: https://[production-url]/
- ⬜ 백엔드 헬스: https://[production-url]/api/health
- ⬜ API 문서: https://[production-url]/api/docs

#### 기본 기능 테스트
- ⬜ 사용자 인증 (로그인/로그아웃)
- ⬜ 핵심 비즈니스 로직 (이번 Sprint의 기능)
- ⬜ 데이터 저장/로드 (DB 동작)
- ⬜ 에러 핸들링 (오류 로그 정상)

#### 성능 & 모니터링
- ⬜ API 응답 시간 확인 (< 200ms 목표)
- ⬜ 에러율 확인 (< 1%)
- ⬜ CloudWatch Logs 정상 기록
- ⬜ CPU/Memory 사용률 정상

#### 보안
- ⬜ HTTPS 동작 (https:// 필수)
- ⬜ CORS 정책 확인 (프론트엔드만 허용)
- ⬜ 환경변수 노출 여부 확인 (시크릿 안전)

### 📝 배포 이력 기록

배포 완료 후 `docs/deploy-history/` 폴더에 기록:

```markdown
# Sprint N 배포 (YYYY-MM-DD)

## 배포 정보
- **Sprint**: N
- **배포 시간**: HH:MM UTC
- **배포자**: [사용자명]
- **변경 사항**: [주요 기능 요약]

## 검증 결과
- ✅ 헬스 체크 통과
- ✅ 기본 기능 테스트 통과
- ✅ 성능 정상 (응답시간 X ms, 에러율 X%)

## 롤백 계획 (필요 시)
롤백 필요 조건: 에러율 > 5% 또는 주요 기능 장애
롤백 방법: git revert 후 재배포
```

### 🚨 장애 대응

배포 후 문제 발생 시:

1. **즉시 대응** (< 5분)
   - ⬜ 상황 파악 (에러율, 응답시간, 에러 로그)
   - ⬜ 긴급 회의 (Slack #incidents 채널)

2. **롤백 여부 판단** (< 10분)
   - ✅ 롤백: 이전 버전으로 복구
   - 🔧 Hotfix: 문제 고쳐서 재배포

3. **사후 분석**
   - ⬜ 근본 원인 분석 (RCA) 문서 작성
   - ⬜ `docs/risk-register/` 기록
   - ⬜ 팀 회고에서 개선 방안 논의

---

## 공통 문제 해결

### API 호출 실패
- 백엔드 서버 실행 확인: `docker-compose ps`
- 데이터베이스 연결 확인: `POSTGRES_PASSWORD` 정확성
- 방화벽/CORS 설정 확인

### 데이터베이스 오류
- 마이그레이션 완료 확인: `alembic current`
- 롤백 필요 시: `alembic downgrade -1`
- 백업 확인: `docs/deploy-history/` 참고

### 성능 저하
- 캐시 확인: Redis 연결 상태
- 쿼리 성능: CloudWatch Logs에서 느린 쿼리 검색
- 동시 사용자 확인: 예상 트래픽 초과 여부

---

**마지막 배포**: [날짜]  
**현재 버전**: [버전번호]  
**다음 배포 일정**: [예정일]
