---
description: Docker 서비스를 재시작합니다. 환경 변수 변경 후 또는 캐시 정리 시 사용.
argument-hint: [service] (생략 시 전체)
---

# /restart [service]

## 동작

### 인자 없음 (전체 재시작)
```bash
docker-compose down
docker-compose up -d
```

### 특정 서비스
```bash
docker-compose restart {service}
```

서비스명 예시: `backend`, `frontend`, `postgres`, `redis`, `nginx`

### 캐시 클리어 (`/restart --clean`)
```bash
docker-compose down -v   # 볼륨까지 제거 (DB 데이터 삭제!)
docker-compose up -d --build
```

> ⚠ `--clean`은 DB 볼륨을 삭제합니다. 개발 환경에서만 사용.

## 사용 예

```
/restart
/restart backend
/restart --clean
```

## 출력
재시작 후 다음을 자동 확인:
- `docker-compose ps` (서비스 상태)
- 백엔드 헬스 체크: `curl http://localhost:${BACKEND_PORT}${HEALTH_PATH}`
- 5초 후에도 unhealthy면 로그 출력: `docker-compose logs --tail=50 backend`
