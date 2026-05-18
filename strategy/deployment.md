# 배포 전략

## 환경

```
개발 (로컬)              스테이징                  프로덕션
docker-compose.yml   →   Lightsail/Cloud Run  →   Lightsail/Cloud Run
                         (auto on develop)        (manual on main)
```

세부 환경(`stack.json` `infrastructure.deployment_environment`)에 따라 변경.

## 자동화 수준

`stack.json` `decisions.deployment_strategy` 참조:

### Continuous Deployment (CD)
- main 머지 → 즉시 프로덕션 배포
- 전제: 테스트 커버리지 ≥ 80%, 모니터링 + 자동 롤백 준비

### Continuous Delivery (CDelivery, 기본 권장)
- main 머지 → 스테이징 자동 배포
- 프로덕션은 수동 승인 (`workflow_dispatch` 또는 PR approval)
- 안정성 우선

## 배포 단계 (deploy-prod 에이전트)

### 사전 검증 (Policy Gate)
- ✅ CI 그린
- ✅ 보안 스캔 (`pip-audit`, `npm audit`)
- ✅ 시크릿 누출 검사 (`git diff`)
- ✅ CHANGELOG 갱신
- ✅ 마이그레이션 파일 존재 (DB 변경 시) + 다운그레이드 가능

### 배포
1. Docker 이미지 빌드 + push (`ghcr.io/${org}/${name}-{frontend|backend}:${git_sha}`)
2. 대상 환경에 배포 (Lightsail SSH / Cloud Run gcloud / ECS task definition)
3. 헬스 체크 대기 (최대 5분)

### 사후 검증 (Continuous Verification)
- 5분간 모니터링 (에러율, 응답시간, DB 상태)
- 임계치 초과 시 자동 롤백 (이전 SHA 태그 사용)
- 정상 완료 시 `docs/deploy-history/` 기록

## 롤백

### 트리거
- 자동: 에러율 > 5%, 헬스 체크 실패
- 수동: 사용자 명령 또는 deploy-prod 에이전트의 검증 실패 보고

### 절차
1. 이전 안정 Docker 이미지 SHA 확인 (`docs/deploy-history/`)
2. 대상 환경에 이전 SHA 이미지로 재배포
3. 헬스 체크 통과 확인
4. 사후 분석 (`docs/risk-register/`)

### 데이터베이스 마이그레이션 롤백
- Alembic: `alembic downgrade -1`
- Django: `python manage.py migrate <app> <prev_version>`
- Prisma: 새 다운 마이그레이션 작성

> ⚠ **마이그레이션 롤백은 데이터 손실 가능**. 사전에 백업 확인 필수.

## 핫픽스 흐름 (hotfix-close 에이전트)

```
1. git checkout -b hotfix/<설명> origin/main
2. 구현 (최소 변경)
3. 테스트 (핵심 흐름만)
4. PR → main (긴급 라벨)
5. 머지 + 즉시 배포
6. develop 역머지
7. CHANGELOG 갱신 (Hotfix 섹션)
```
