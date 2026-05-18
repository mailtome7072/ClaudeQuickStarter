#!/bin/bash
# ============================================================================
# setup-backend-express.sh
#
# Express + TypeScript 스캐폴드.
# stack.json의 database/cache/authentication 참조하여 의존성/구조 구성.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

STACK_JSON=".claude/stack.json"
[ -f "$STACK_JSON" ] || { echo "✗ $STACK_JSON 없음"; exit 1; }
command -v jq >/dev/null || { echo "✗ jq 필요"; exit 1; }
command -v node >/dev/null || { echo "✗ Node.js 필요"; exit 1; }

DB=$(jq -r '.stack.database.primary_database // "none"' "$STACK_JSON")
CACHE=$(jq -r '.stack.database.cache // "none"' "$STACK_JSON")
AUTH=$(jq -r '.stack.backend.authentication // "none"' "$STACK_JSON")
ORM=$(jq -r '.stack.backend.orm // "Prisma"' "$STACK_JSON")
LANG=$(jq -r '.stack.backend.language // "TypeScript"' "$STACK_JSON")
PM_BE=$(jq -r '.stack.backend.package_manager // "npm"' "$STACK_JSON")

mkdir -p app/backend
cd app/backend

if [ ! -f "package.json" ]; then
    echo "→ npm init 중..."
    case "$PM_BE" in
        pnpm) pnpm init ;;
        yarn) yarn init -y ;;
        npm|*) npm init -y ;;
    esac
fi

# package.json scripts 설정
node <<'EOF'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.type = 'module';
pkg.scripts = {
    ...pkg.scripts,
    "dev": "tsx watch src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "test": "vitest",
    "lint": "eslint src --ext .ts",
};
pkg.main = 'dist/server.js';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
EOF

# 런타임 의존성
RUNTIME_DEPS="express cors helmet dotenv pino pino-http"
[[ "$DB" == PostgreSQL* ]] && RUNTIME_DEPS="$RUNTIME_DEPS pg"
[[ "$DB" == MySQL* ]] && RUNTIME_DEPS="$RUNTIME_DEPS mysql2"
[[ "$DB" == MongoDB* ]] && RUNTIME_DEPS="$RUNTIME_DEPS mongodb"
[[ "$CACHE" == Redis* ]] && RUNTIME_DEPS="$RUNTIME_DEPS ioredis"
[[ "$AUTH" == *JWT* ]] && RUNTIME_DEPS="$RUNTIME_DEPS jsonwebtoken bcrypt"
[[ "$AUTH" == *Session* ]] && RUNTIME_DEPS="$RUNTIME_DEPS express-session connect-redis"
[[ "$AUTH" == *OAuth* ]] && RUNTIME_DEPS="$RUNTIME_DEPS passport passport-google-oauth20"

# ORM
case "$ORM" in
    Prisma) RUNTIME_DEPS="$RUNTIME_DEPS @prisma/client" ;;
    TypeORM) RUNTIME_DEPS="$RUNTIME_DEPS typeorm reflect-metadata" ;;
    Drizzle) RUNTIME_DEPS="$RUNTIME_DEPS drizzle-orm" ;;
esac

# 개발 의존성
DEV_DEPS="typescript tsx @types/node @types/express @types/cors vitest supertest @types/supertest eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin"
[[ "$AUTH" == *JWT* ]] && DEV_DEPS="$DEV_DEPS @types/jsonwebtoken @types/bcrypt"
[[ "$AUTH" == *Session* ]] && DEV_DEPS="$DEV_DEPS @types/express-session"
[ "$ORM" = "Prisma" ] && DEV_DEPS="$DEV_DEPS prisma"

echo "→ 런타임 의존성 설치..."
case "$PM_BE" in
    pnpm) pnpm add $RUNTIME_DEPS ;;
    yarn) yarn add $RUNTIME_DEPS ;;
    npm|*) npm install $RUNTIME_DEPS ;;
esac

echo "→ 개발 의존성 설치..."
case "$PM_BE" in
    pnpm) pnpm add -D $DEV_DEPS ;;
    yarn) yarn add -D $DEV_DEPS ;;
    npm|*) npm install --save-dev $DEV_DEPS ;;
esac

# tsconfig.json
if [ ! -f "tsconfig.json" ]; then
    cat > tsconfig.json <<'EOF'
{
    "compilerOptions": {
        "target": "ES2022",
        "module": "ESNext",
        "moduleResolution": "Bundler",
        "outDir": "dist",
        "rootDir": "src",
        "strict": true,
        "esModuleInterop": true,
        "skipLibCheck": true,
        "forceConsistentCasingInFileNames": true,
        "resolveJsonModule": true,
        "experimentalDecorators": true,
        "emitDecoratorMetadata": true
    },
    "include": ["src/**/*"],
    "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF
fi

# 디렉터리 구조
mkdir -p src/routes src/middleware src/services src/config src/__tests__

# src/server.ts — 엔트리포인트
cat > src/server.ts <<'EOF'
import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import pinoHttp from 'pino-http'
import { logger } from './config/logger.js'
import { healthRouter } from './routes/health.js'

const app = express()
const PORT = parseInt(process.env.PORT || '3000', 10)

app.use(helmet())
app.use(cors({
    origin: (process.env.CORS_ORIGINS || 'http://localhost:5173').split(','),
    credentials: true,
}))
app.use(express.json({ limit: '1mb' }))
app.use(pinoHttp({ logger }))

// 라우트
app.use('/', healthRouter)
// TODO: app.use('/api/v1/users', usersRouter)

// 에러 핸들러 (마지막)
app.use((err: Error, req: express.Request, res: express.Response, _next: express.NextFunction) => {
    logger.error({ err, path: req.path }, 'unhandled error')
    res.status(500).json({ error: 'Internal Server Error' })
})

app.listen(PORT, () => {
    logger.info(`Server listening on http://localhost:${PORT}`)
})

export default app
EOF

# src/config/logger.ts
cat > src/config/logger.ts <<'EOF'
import pino from 'pino'

export const logger = pino({
    level: process.env.LOG_LEVEL || 'info',
    formatters: {
        level: (label) => ({ level: label }),
    },
    timestamp: () => `,"time":"${new Date().toISOString()}"`,
})
EOF

# src/routes/health.ts
cat > src/routes/health.ts <<'EOF'
import { Router } from 'express'

export const healthRouter = Router()

healthRouter.get('/healthz', (req, res) => {
    res.json({ status: 'ok' })
})

healthRouter.get('/readyz', async (req, res) => {
    // TODO: DB/Cache 헬스 체크
    res.json({ status: 'ready' })
})
EOF

# 첫 테스트
cat > src/__tests__/health.test.ts <<'EOF'
import { describe, it, expect } from 'vitest'
import request from 'supertest'
import app from '../server.js'

describe('Health', () => {
    it('GET /healthz returns 200 ok', async () => {
        const res = await request(app).get('/healthz')
        expect(res.status).toBe(200)
        expect(res.body).toEqual({ status: 'ok' })
    })
})
EOF

# vitest 설정
cat > vitest.config.ts <<'EOF'
import { defineConfig } from 'vitest/config'

export default defineConfig({
    test: {
        environment: 'node',
        globals: true,
        coverage: {
            reporter: ['text', 'html'],
            exclude: ['dist', 'src/__tests__'],
        },
    },
})
EOF

# ESLint 설정
cat > .eslintrc.json <<'EOF'
{
    "parser": "@typescript-eslint/parser",
    "plugins": ["@typescript-eslint"],
    "extends": [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended"
    ],
    "parserOptions": {
        "ecmaVersion": 2022,
        "sourceType": "module"
    },
    "env": { "node": true, "es2022": true }
}
EOF

# Prisma 스키마 (선택)
if [ "$ORM" = "Prisma" ]; then
    mkdir -p prisma
    DB_PROVIDER="postgresql"
    [[ "$DB" == MySQL* ]] && DB_PROVIDER="mysql"
    [[ "$DB" == MongoDB* ]] && DB_PROVIDER="mongodb"
    cat > prisma/schema.prisma <<EOF
generator client {
    provider = "prisma-client-js"
}

datasource db {
    provider = "${DB_PROVIDER}"
    url      = env("DATABASE_URL")
}

// TODO: 모델 정의
// model User {
//   id        String   @id @default(uuid())
//   email     String   @unique
//   createdAt DateTime @default(now())
// }
EOF
    cat > prisma/README.md <<'EOF'
# Prisma 사용법

```bash
# 마이그레이션 생성
npx prisma migrate dev --name init

# Prisma 클라이언트 생성
npx prisma generate

# DB 시각화
npx prisma studio
```
EOF
fi

echo "✓ Express + TypeScript backend 스캐폴드 완료 ($PM_BE)"
echo "  - DB: $DB, Cache: $CACHE, Auth: $AUTH, ORM: $ORM"
echo "  - 개발 서버: cd app/backend && $PM_BE run dev (포트 3000)"
echo "  - 헬스 체크: http://localhost:3000/healthz"
echo "  - 테스트: $PM_BE test"
[ "$ORM" = "Prisma" ] && echo "  - Prisma: prisma/README.md 참조"
