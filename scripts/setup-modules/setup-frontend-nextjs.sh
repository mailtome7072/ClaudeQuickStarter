#!/bin/bash
# ============================================================================
# setup-frontend-nextjs.sh
#
# Next.js 14+ App Router + TypeScript + Tailwind 스캐폴드.
# stack.json의 package_manager (pnpm/npm/yarn)를 따름.
# Zustand (상태관리), @tanstack/react-query 포함.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

STACK_JSON=".claude/stack.json"
[ -f "$STACK_JSON" ] || { echo "✗ $STACK_JSON 없음"; exit 1; }
command -v jq >/dev/null || { echo "✗ jq 필요"; exit 1; }

PM=$(jq -r '.stack.frontend.package_manager // "pnpm"' "$STACK_JSON")
LANG=$(jq -r '.stack.frontend.language // "TypeScript"' "$STACK_JSON")
USE_TS="--typescript"
[ "$LANG" = "JavaScript" ] && USE_TS="--javascript"

mkdir -p app/frontend
cd app/frontend

if [ -f "package.json" ]; then
    echo "ℹ app/frontend에 package.json 존재 — 스캐폴드 건너뜀, 의존성만 설치"
else
    echo "→ create-next-app 실행 중 ($PM, $LANG)..."
    # create-next-app은 빈 디렉터리에서도 동작; --yes 사용 X (대신 명시 옵션)
    case "$PM" in
        pnpm)
            pnpm create next-app@latest . \
                $USE_TS --app --tailwind --eslint \
                --src-dir --import-alias '@/*' --use-pnpm --no-turbopack
            ;;
        yarn)
            yarn create next-app . \
                $USE_TS --app --tailwind --eslint \
                --src-dir --import-alias '@/*' --use-yarn --no-turbopack
            ;;
        npm|*)
            npx create-next-app@latest . \
                $USE_TS --app --tailwind --eslint \
                --src-dir --import-alias '@/*' --use-npm --no-turbopack
            ;;
    esac
fi

# 권장 추가 의존성
echo "→ 권장 의존성 설치 (zustand, react-query)..."
EXTRA_DEPS="zustand @tanstack/react-query @tanstack/react-query-devtools"
case "$PM" in
    pnpm) pnpm add $EXTRA_DEPS ;;
    yarn) yarn add $EXTRA_DEPS ;;
    npm|*) npm install $EXTRA_DEPS ;;
esac

# Query Provider 기본 구조
if [ "$LANG" = "TypeScript" ]; then
    mkdir -p src/lib src/stores

    cat > src/lib/query-provider.tsx <<'EOF'
'use client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export default function QueryProvider({ children }: { children: React.ReactNode }) {
    const [client] = useState(() => new QueryClient({
        defaultOptions: { queries: { staleTime: 60_000 } },
    }))
    return (
        <QueryClientProvider client={client}>
            {children}
            <ReactQueryDevtools initialIsOpen={false} />
        </QueryClientProvider>
    )
}
EOF

    cat > src/stores/counter.ts <<'EOF'
import { create } from 'zustand'

interface CounterState {
    count: number
    increment: () => void
    reset: () => void
}

export const useCounter = create<CounterState>((set) => ({
    count: 0,
    increment: () => set((s) => ({ count: s.count + 1 })),
    reset: () => set({ count: 0 }),
}))
EOF

    # layout.tsx 갱신 안내 (사용자 직접 수정 권장)
    cat > src/lib/INTEGRATION.md <<'EOF'
# Next.js 통합 가이드

## QueryProvider를 app/layout.tsx에 추가

```tsx
// src/app/layout.tsx
import QueryProvider from '@/lib/query-provider'

export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="ko">
            <body>
                <QueryProvider>{children}</QueryProvider>
            </body>
        </html>
    )
}
```

## API 통신 예시

```tsx
'use client'
import { useQuery } from '@tanstack/react-query'

export function UserList() {
    const { data, isLoading } = useQuery({
        queryKey: ['users'],
        queryFn: () => fetch(`${process.env.NEXT_PUBLIC_API_URL}/users`).then(r => r.json()),
    })
    if (isLoading) return <p>Loading...</p>
    return <ul>{data?.map((u: any) => <li key={u.id}>{u.name}</li>)}</ul>
}
```
EOF
fi

# Next.js 환경변수 (NEXT_PUBLIC_ 접두사만 클라이언트 노출)
if [ ! -f ".env.example" ]; then
    cat > .env.example <<'EOF'
# Next.js는 NEXT_PUBLIC_* 접두사만 클라이언트에 노출
NEXT_PUBLIC_API_URL=http://localhost:8000

# 서버 사이드 전용 (NEXT_PUBLIC_ 없음)
INTERNAL_API_KEY=
EOF
fi

# next.config.js에 standalone 빌드 (Docker 최적화) 안내
if [ -f "next.config.mjs" ]; then
    if ! grep -q "output:" next.config.mjs; then
        cat >> next.config.mjs <<'EOF'

// Docker 빌드 최적화 — standalone 모드
// 활성화하려면 위 nextConfig 객체에 다음을 추가:
//   output: 'standalone'
EOF
    fi
fi

echo "✓ Next.js 14 + App Router frontend 스캐폴드 완료 ($PM, $LANG)"
echo "  - 개발 서버: cd app/frontend && $PM run dev (포트 3000)"
echo "  - 추가됨: zustand, @tanstack/react-query + devtools"
echo "  - 구조: src/{app,lib,stores}"
echo "  - 통합 안내: src/lib/INTEGRATION.md"
