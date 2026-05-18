---
description: Sprint N 구현 단계로 진입합니다. sprint{N} 브랜치 생성/체크아웃, 현황 파악, 가이드라인 주입.
argument-hint: <sprint-number> (예: /sprint-dev 1)
---

# /sprint-dev {N}

Sprint 구현 작업의 진입점.

## 동작

### 1. 선행 조건
- `docs/sprint/sprint{N}.md`가 존재 (없으면 "sprint {N} 계획 세워줘"부터)
- 이전 Sprint가 완료(또는 명시적 병행 진행)

### 2. 브랜치
- 현재 브랜치가 `sprint{N}`이면 그대로 진행
- 아니면 `develop`에서 분기:
  ```bash
  git checkout develop && git pull
  git checkout -b sprint{N}
  ```

### 3. 현황 파악
다음을 출력:
- `docs/sprint/sprint{N}.md`의 작업 목록 + 완료 상태
- 미완 작업 중 다음 우선순위 작업
- 선행 조건 만족된 작업만 표시

### 4. 가이드라인 주입
이 Sprint 동안 다음 정책이 활성화됨을 안내:
- `.claude/rules/harness-engineering.md` 적용
- Forbidden Area 자동 차단 (Phase 8 훅이 있을 시)
- scope.md 작성 의무

### 5. 다음 작업 제안
가장 우선순위 높은 미완 작업에 대해:
- 작업 명세 출력 (`docs/sprint/sprint{N}.md`의 해당 섹션)
- 예상 영향 파일
- 작업 시작 시 scope.md 자동 생성 제안

## 사용 예

```
/sprint-dev 1
```

```
Sprint 1 진입
브랜치: sprint1 (develop에서 새로 분기)

작업 현황:
  ✅ T1: 부트스트랩 검증
  🔄 T2: 사용자 모델 정의 (진행 중)
  ⬜ T3: 인증 엔드포인트 (T2 완료 후)
  ⬜ T4: 인증 UI

다음 우선순위: T2
영향 파일: app/backend/app/models/user.py, app/backend/alembic/versions/

scope.md를 작성하시겠습니까? (Y/n)
```
