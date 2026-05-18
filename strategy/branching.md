# 브랜치 전략

## 기본 구조

```
main (프로덕션 — 보호)
  ↑ PR (deploy-prod 에이전트)
develop (QA / Staging)
  ↑ PR (sprint-close 에이전트)
sprint{n} (Sprint 작업 브랜치 — 단일 또는 여러 사람)
  ↑ 직접 commit 또는 feature 브랜치
hotfix/{설명} (긴급 패치 — main에서 직접 분기)
  ↑ PR → main (hotfix-close 에이전트), 머지 후 develop 역머지
```

## 브랜치 명명

| 종류 | 형식 | 예시 |
|---|---|---|
| Sprint | `sprint{n}` | `sprint1` |
| Feature (Sprint 내부) | `sprint{n}/{slug}` | `sprint1/auth-login` |
| Hotfix | `hotfix/{slug}` | `hotfix/payment-timeout` |
| Refactor | `refactor/{slug}` | `refactor/extract-service` |

## 보호 규칙 (main, develop)

- **main**: PR + 1+ 리뷰 + CI 통과 + Policy Gate 통과
- **develop**: PR + CI 통과
- 직접 push 금지 (admin도)
- Force push 금지

## 충돌 해결

- Sprint 브랜치는 정기적으로 develop을 머지/리베이스
- main 브랜치 충돌 시 hotfix와 sprint 머지 순서: hotfix 먼저, sprint는 hotfix 머지된 develop 위에서 리베이스

## 커밋 메시지 규약

```
sprint-{n}: [feature/fix/refactor/test/docs] 짧은 설명

본문 (선택):
- 동기/배경
- 변경의 결과

Closes #issue-number (선택)
Co-Authored-By: ... (페어 작업 시)
```

타입:
- `feature`: 신규 기능
- `fix`: 버그 수정
- `refactor`: 동작 동일, 구조 개선
- `test`: 테스트 추가/수정
- `docs`: 문서
- `chore`: 의존성/도구 변경

## PR 규약

- **제목**: `Sprint {n}: 기능 설명` (예: `Sprint 2: JWT 인증 + Refresh Token`)
- **설명 템플릿**:
  ```
  ## 변경 요약
  - ...

  ## 검증 방법
  - [ ] 단위 테스트
  - [ ] 통합 테스트
  - [ ] 수동 검증 (스크린샷)

  ## 마이그레이션 (DB 변경 시)
  - 적용 명령: ...
  - 롤백 명령: ...

  ## 관련 이슈
  Closes #N
  ```
