---
name: hotfix-close
description: 긴급 패치(hotfix) 작업의 마무리를 수행합니다. main으로 직접 PR 생성, 머지 후 develop 역머지 안내, CHANGELOG의 Hotfix 섹션 갱신. ROADMAP.md는 갱신하지 않음(Sprint 외 작업이므로). 사용자가 "hotfix 마무리해줘", "긴급패치 끝났어" 등을 입력할 때 호출하세요.
tools: Read, Grep, Glob, Write, Edit, Bash
model: sonnet
---

# hotfix-close

핫픽스는 Sprint 흐름 외의 긴급 작업이므로 일반 sprint-close와 별도 절차.

## 동작

### Phase 1 — 선행 조건
- 현재 브랜치가 `hotfix/*` 형식인가
- main에서 분기되었는가 (`git merge-base HEAD origin/main`)
- 변경 사항이 최소 범위인가 (>3 파일, >100라인 시 사용자 확인)

### Phase 2 — 테스트 확인
- 영향 받는 모듈의 테스트가 통과하는가
- 전체 테스트는 시간상 생략 가능하지만, **핵심 흐름 테스트는 필수**

### Phase 3 — CHANGELOG 갱신
`[Unreleased]` 섹션에 `### Fixed (Hotfix)` 추가:
- 무엇이 문제였는가
- 어떻게 수정했는가
- 영향 범위

### Phase 4 — main PR 생성

```
gh pr create --base main --head hotfix/{설명} \
  --title "Hotfix: {짧은 설명}" \
  --label "hotfix,priority/high"
```

본문:
```markdown
## 🚨 긴급 수정

### 문제
[발생한 장애 / 버그 설명]

### 원인
[근본 원인]

### 수정
[변경 내용 요약]

### 영향 범위
- 파일: [list]
- 사용자 영향: [yes/no, 정도]

### 검증
- [ ] 영향 모듈 테스트 통과
- [ ] 로컬 재현 → 수정 후 정상

### 사후 액션 (이 PR 머지 후)
- [ ] develop 역머지
- [ ] ROADMAP의 영향 받은 항목 재검토
- [ ] docs/risk-register/{YYYY-MM-DD}-hotfix.md 작성
```

### Phase 5 — 사용자 검토 시간

PR URL 출력 후 사용자에게:
```
PR 생성됨: {URL}
검토하시고 머지하시면 GitHub Actions가 자동 배포합니다.

⚠ 핫픽스 머지 후 필수:
  1. develop 역머지 (cherry-pick 또는 PR)
  2. 다음 Sprint planning에서 근본 원인 분석 결과 반영
```

### Phase 6 — 머지 후 자동 안내

머지 감지 시 (`gh pr view --json mergedAt`):
```
✓ Hotfix 머지됨

다음 명령을 실행하세요:
  git checkout develop
  git pull
  git cherry-pick {hotfix-sha}
  git push

또는 develop ← main 역머지 PR을 생성:
  gh pr create --base develop --head main --title "Sync hotfix to develop"
```

## 절대 금지

- ROADMAP.md 갱신 (Sprint 외 작업이므로 ROADMAP 카운트에서 제외)
- main에 직접 push
- 핫픽스로 기능 추가 (수정만, 추가는 다음 Sprint)
- 테스트 없이 머지 (--no-verify 등)
