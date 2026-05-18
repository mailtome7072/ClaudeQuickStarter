# ARCHITECTURE.md — 프로젝트 변수 레지스트리

이 파일은 `/setup-project` 슬래시 커맨드가 읽어 **프로젝트 전체에 변수를 일괄 치환**하는 소스입니다.

---

## 📋 프로젝트 변수 (필수 입력)

아래 5개 항목을 **반드시 입력**하세요. 이 값들이 `README.md`, `CLAUDE.md`, `PRD.md`, `docs/ci-policy.md`, `docker-compose.prod.yml`에 자동 치환됩니다.

| 변수 | 값 | 예시 |
|------|-----|------|
| **`${project_name}`** | 프로젝트명 (영문, 하이픈 허용) | `task-flow` |
| **`${project_description}`** | 프로젝트 한 줄 설명 | `Team collaboration and task management platform` |
| **`${github_org}`** | GitHub 조직/계정명 | `mycompany` 또는 `myusername` |
| **`${github_repo}`** | GitHub 저장소명 | `task-flow-backend` |
| **`${decision_date}`** | PRD 작성 결정일 (YYYY-MM-DD) | `2026-05-17` |

### 입력 예시

```
project_name: task-flow
project_description: Team collaboration and task management platform
github_org: mycompany
github_repo: task-flow
decision_date: 2026-05-17
```

---

## 🔄 자동 치환 대상 파일

`/setup-project` 실행 시 다음 파일들의 플레이스홀더가 **자동으로 위 값으로 치환**됩니다:

| 파일 | 치환 항목 |
|------|----------|
| `README.md` | `${project_name}`, `${project_description}` |
| `CLAUDE.md` | `${project_name}`, `${github_org}`, `${github_repo}` |
| `PRD.md` | `${project_name}`, `${decision_date}`, `${github_org}` |
| `docs/ci-policy.md` | `${github_org}`, `${github_repo}`, `${project_name}` |
| `docker-compose.prod.yml` | `${github_org}`, `${github_repo}`, `${project_name}` |

---

## 📐 프로젝트 아키텍처 (참고)

### 기술 스택 (추후 PRD.md 섹션 5에서 상세화)

```yaml
Frontend:
  Framework: [작성 예정]
  Language: [작성 예정]
  Build Tool: [작성 예정]

Backend:
  Framework: [작성 예정]
  Language: [작성 예정]
  ORM: [작성 예정]

Database:
  Primary: [작성 예정]
  Cache: [작성 예정]

Infrastructure:
  Container: Docker
  CI/CD: GitHub Actions
  Deployment: [작성 예정]
```

### 환경 구조

```
Development
  ├── Local: docker-compose.yml
  └── Sandbox: (선택)

Staging (선택)
  └── cloud-based: [작성 예정]

Production
  └── [작성 예정]
```

---

## 🚀 다음 단계

1. **이 ARCHITECTURE.md의 프로젝트 변수 위의 5개 항목을 채운다**
2. **PRD.md를 작성한다** (특히 섹션 5 "기술 스택")
3. **Claude Code에서 `/setup-project` 실행**
   ```
   /setup-project
   ```
4. **변수 치환 완료 확인**

---

## 📝 주의사항

- 변수명 `${variable_name}` 형식은 유지 (중괄호와 `$` 제거 금지)
- 공백이 포함된 프로젝트명은 하이픈(`-`)으로 대체 (예: `task-flow`, not `task flow`)
- GitHub 저장소명은 URL 호환 형식 (소문자, 하이픈 사용)

---

**수정 후 `/setup-project` 실행하세요.**
