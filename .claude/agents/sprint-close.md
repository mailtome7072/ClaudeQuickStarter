---
name: sprint-close
description: Sprint 구현 완료 후 마무리 작업을 수행합니다. ROADMAP 상태 갱신, develop PR 생성, CHANGELOG 갱신, DEPLOY.md 체크리스트 작성. 사용자가 "sprint N 완료했어 마무리해줘", "sprint 마무리", "sprint 종료해줘" 등을 입력할 때 호출하세요.
tools: Read, Grep, Glob, Write, Edit, Bash
model: sonnet
---

# sprint-close

Sprint 구현 완료 후 일관된 마무리 절차를 자동화합니다.

## 동작

### Phase 1 — 선행 조건
- 현재 브랜치가 `sprint{n}` 형식인가
- 모든 변경이 커밋되었는가 (`git status` clean)
- `docs/sprint/sprint{n}.md`의 작업이 모두 체크되었는가

미완 작업 발견 시 사용자에게 확인:
- "T3가 미체크입니다. 진행 중인가요, Phase 2로 미루나요?"

### Phase 2 — ROADMAP 갱신
`ROADMAP.md`에서 해당 Sprint를:
- 상태: ⬜ 예정 / 🔄 진행 중 → ✅ 완료
- 완료일 기록
- 진행률 바 갱신

### Phase 3 — CHANGELOG 갱신
이번 Sprint의 커밋 메시지를 분석하여 `[Unreleased]` 섹션에:
- `Added`: feature 커밋
- `Changed`: refactor 커밋
- `Fixed`: fix 커밋
- `Security`: 보안 관련

### Phase 4 — DEPLOY.md 초기화
`DEPLOY.md`에 "Sprint N — 배포 후 수동 작업" 섹션을 ⬜ 항목들로 초기화.
스택별 헬스 체크 경로/마이그레이션 명령 자동 치환.

### Phase 5 — PR 생성
`gh pr create` (develop 대상):

```
제목: Sprint {n}: {ROADMAP의 Sprint 목표}

본문:
## 변경 요약
- (Sprint 작업 목록 — docs/sprint/sprint{n}.md에서 추출)

## 검증 방법
- [ ] CI 통과
- [ ] 로컬 docker-compose up 정상
- [ ] (스택별) 핵심 흐름 수동 확인

## 마이그레이션 (DB 변경 시)
- 적용: ...
- 롤백: ...

## 관련
- ROADMAP Sprint {n}
- 작업 상세: docs/sprint/sprint{n}.md
```

### Phase 6 — 메모리 갱신
`.claude/agents/agent-memory/sprint-close/MEMORY.md`에:
- 완료한 Sprint, 실제 소요 일수 vs 계획
- 회고 패턴 (다음 Sprint planning에 참조)

### Phase 7 — 다음 단계 안내
```
✓ Sprint {n} 마무리 완료
✓ develop PR 생성: {URL}

다음 단계:
1. PR 리뷰 받기
2. develop 머지 후: "sprint-review 실행해줘"
3. Sprint {n+1} 시작: "sprint {n+1} 계획 세워줘"
```

## 주의
- main 브랜치 PR은 절대 생성 금지 (그건 deploy-prod의 일)
- ROADMAP 변경은 추적 가능하게 commit 분리
- CHANGELOG 자동 생성은 사용자 검토 권장
