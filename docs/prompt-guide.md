# Prompt Guide — 상황별 Claude Code 프롬프트 예시

## 부트스트랩 단계

### 스택 분석 요청
```
/analyze-stack
```
또는:
```
PRD 작성 완료했어. 기술스택 분석해줘.
```

### 부트스트랩 실행
```
/setup-project
```

### ROADMAP 생성
```
PRD 기반으로 ROADMAP 생성해줘.
```

---

## Sprint 진행

### Sprint 계획 수립
```
Sprint 1 계획 세워줘.
ROADMAP의 Sprint 2를 더 자세히 계획해줘.
Sprint 3에 [기능명]을 추가하고 일정 재조정해줘.
```

### Sprint 구현 진입
```
/sprint-dev 1
```

### 작업 단위 진행
```
사용자 인증 API 구현해줘. JWT + RefreshToken 방식. 테스트 포함.
```

(scope.md가 자동 생성됨)

### 막혔을 때
```
[기능명] 구현하면서 [에러 메시지/현상] 발생. 원인 분석하고 해결책 제안해줘.
```

```
이 PR의 변경 사항을 리뷰해줘. 보안/성능 관점 중심.
```

### 리팩토링
```
app/backend/services/ 의 코드를 리뷰하고 단순화해줘. 동작 변경 없이.
```
또는 `/simplify` 스킬.

---

## 검증 & 리뷰

### 변경 사항 리뷰
```
/review
```

### 보안 리뷰
```
/security-review
```

### 테스트 추가
```
app/backend/api/routes/auth.py 의 모든 엔드포인트에 대해 pytest 작성해줘.
정상 흐름 + 에러 케이스 포함.
```

---

## Sprint 마무리

### Sprint 종료
```
sprint 1 구현 완료했어. 마무리해줘.
```

(sprint-close 에이전트가 PR 생성, CHANGELOG/ROADMAP/DEPLOY 갱신)

### Sprint 회고
```
sprint 1 회고 작성해줘. 잘된 것, 개선할 것, 멈출 것.
```

---

## 배포

### 프로덕션 배포 준비
```
수동 검증 완료했어. 프로덕션 배포 준비해줘.
```

(deploy-prod 에이전트가 Policy Gate 검사 → develop → main PR)

### 핫픽스
```
git checkout -b hotfix/payment-timeout
# 구현 후
hotfix 구현 끝났어. 마무리해줘.
```

---

## 진단 & 디버깅

### 환경 확인
```
현재 부트스트랩 상태가 어떻게 되어 있는지 점검해줘.
```

### 의존성 갱신 확인
```
package.json / requirements.txt의 모든 의존성을 검토하고
보안 취약점 있는 것 알려줘.
```

### 로그 분석
```
docker-compose logs backend의 최근 100줄을 보고 에러 패턴 분석해줘.
```

---

## 메타 작업

### CLAUDE.md 갱신
```
/init
```

### 설정 변경
```
/update-config
허용 명령어에 'docker compose ps' 추가해줘.
```

### 권한 프롬프트 줄이기
```
/fewer-permission-prompts
```

---

## 안 좋은 프롬프트 패턴 (피하기)

| ❌ 안 좋음 | ✅ 좋음 |
|---|---|
| "버그 고쳐줘" | "auth.py:42의 NameError 'token' 발생. 원인 분석하고 수정해줘." |
| "테스트 추가해줘" | "services/user_service.py 의 create_user() 함수에 unit test 추가. 정상 + 중복 이메일 케이스." |
| "이거 더 좋게 만들어줘" | "이 함수의 시간복잡도가 O(n²)인데, O(n log n)으로 줄일 수 있는 방법 검토해줘." |
| "전부 다 리뷰해줘" | "이번 PR의 diff에서 보안 관련 변경 사항만 검토해줘." |

---

## 팁

1. **scope를 명시**: 작업 전 "이 작업의 영향 범위는 X와 Y뿐이야"라고 알려주면 에이전트가 그 범위를 지킴.
2. **검증 방법을 명시**: "구현 후 pytest -k test_auth 통과를 확인해줘"
3. **롤백 조건을 명시**: "마이그레이션이 실패하면 alembic downgrade로 되돌리고 보고해줘"
4. **단계적 진행**: 큰 작업은 "먼저 계획만 보여줘 → 동의하면 진행"으로 분리
