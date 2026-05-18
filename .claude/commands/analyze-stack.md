---
description: PRD.md §5 기술스택을 분석하고 사용자와의 대화로 .claude/stack.json을 확정합니다.
argument-hint: (인자 없음)
---

# /analyze-stack

`stack-analyzer` 서브에이전트를 호출하여 다음을 수행합니다:

1. **선행 조건 검증**
   - `ARCHITECTURE.md`의 변수 5개가 모두 입력되었는지 (`${project_name}` 등 잔존 여부)
   - `PRD.md` §5 "기술 스택" 섹션이 작성되었는지
   - `.claude/stack.json`이 이미 `status: "confirmed"`라면 사용자에게 재실행 의도 확인

2. **PRD §5 파싱** — frontend/backend/database/infrastructure/other 항목 추출

3. **3단계 검증**
   - 완결성 (Completeness): 필수 6항목 + 권장 3항목
   - 호환성 (Compatibility): Frontend-Backend / DB-ORM / 런타임 / Cache-Backend
   - 최적화 (Optimization): 성능 / 보안 / 운영

4. **6가지 의사결정 질문** (`AskUserQuestion` 도구 사용)
   - Q1: 프로덕션 로깅 도구 (CloudWatch / ELK / Loki)
   - Q2: 모니터링 (CloudWatch Metrics / Prometheus / Datadog / 없음)
   - Q3: MFA 필요 여부 (없음 / TOTP / WebAuthn)
   - Q4: 파일 저장소 (S3 / GCS / 로컬 / 없음)
   - Q5: 배포 전략 (CD / CDelivery)
   - Q6: 테스트 커버리지 목표 (Backend %, Frontend %)

5. **`.claude/stack.json` 작성** — `status: "confirmed"`, `confirmed_at`, `confirmed_by` (git user.email), `stack`, `decisions`, `compatibility_check`, `recommendations`, `change_log`

6. **`docs/arch/stack-decision.md` 생성** — 팀이 공유할 사람-가독성 결정 기록 (stack.json은 gitignored이므로)

7. **메모리 갱신** — `.claude/agents/agent-memory/stack-analyzer/MEMORY.md`에 분석 이력 추가

8. **다음 단계 안내**: `/setup-project` 실행

---

## 상세 명세

전체 동작은 `.claude/agents/stack-analyzer.md`와 `docs/stack-analysis-guide.md`를 참조하세요.

## 사용 예

```
/analyze-stack
```

또는 자연어:

```
PRD 작성 완료했어. 기술스택 분석해줘.
```
