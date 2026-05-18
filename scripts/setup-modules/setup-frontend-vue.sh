#!/bin/bash
# ============================================================================
# setup-frontend-vue.sh
#
# Vue 3 + Vite + TypeScript 프로젝트를 app/frontend/에 스캐폴드.
# stack.json의 package_manager (pnpm/npm/yarn)를 따름.
# Pinia (상태관리), Vue Router, @tanstack/vue-query 포함.
# ============================================================================
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

STACK_JSON=".claude/stack.json"
[ -f "$STACK_JSON" ] || { echo "✗ $STACK_JSON 없음"; exit 1; }
command -v jq >/dev/null || { echo "✗ jq 필요"; exit 1; }

PM=$(jq -r '.stack.frontend.package_manager // "pnpm"' "$STACK_JSON")
LANG=$(jq -r '.stack.frontend.language // "TypeScript"' "$STACK_JSON")

mkdir -p app/frontend
cd app/frontend

if [ -f "package.json" ]; then
    echo "ℹ app/frontend에 package.json 존재 — 스캐폴드 건너뜀, 의존성만 설치"
else
    TEMPLATE="vue"
    [ "$LANG" = "TypeScript" ] && TEMPLATE="vue-ts"

    echo "→ Vite ($TEMPLATE) 스캐폴드 중 ($PM)..."
    case "$PM" in
        pnpm) pnpm create vite . --template "$TEMPLATE" ;;
        yarn) yarn create vite . --template "$TEMPLATE" ;;
        npm|*) npm create vite@latest . -- --template "$TEMPLATE" ;;
    esac
fi

# 권장 추가 의존성
echo "→ 권장 의존성 설치 (vue-router, pinia, @tanstack/vue-query)..."
EXTRA_DEPS="vue-router@4 pinia @tanstack/vue-query axios"
case "$PM" in
    pnpm) pnpm add $EXTRA_DEPS ;;
    yarn) yarn add $EXTRA_DEPS ;;
    npm|*) npm install $EXTRA_DEPS ;;
esac

# Pinia + Router 기본 구조 (TypeScript 기준)
if [ "$LANG" = "TypeScript" ] && [ ! -d "src/stores" ]; then
    mkdir -p src/stores src/router src/views

    cat > src/stores/counter.ts <<'EOF'
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useCounterStore = defineStore('counter', () => {
    const count = ref(0)
    const doubleCount = computed(() => count.value * 2)
    function increment() { count.value++ }
    return { count, doubleCount, increment }
})
EOF

    cat > src/router/index.ts <<'EOF'
import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes: [
        { path: '/', name: 'home', component: () => import('../views/HomeView.vue') },
    ],
})

export default router
EOF

    cat > src/views/HomeView.vue <<'EOF'
<script setup lang="ts">
import { useCounterStore } from '../stores/counter'
const counter = useCounterStore()
</script>

<template>
    <main>
        <h1>Home</h1>
        <button @click="counter.increment">Count: {{ counter.count }}</button>
    </main>
</template>
EOF

    # main.ts 갱신 안내
    if [ -f "src/main.ts" ]; then
        cp src/main.ts src/main.ts.original
        cat > src/main.ts <<'EOF'
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { VueQueryPlugin } from '@tanstack/vue-query'
import router from './router'
import App from './App.vue'
import './style.css'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.use(VueQueryPlugin)
app.mount('#app')
EOF
    fi
fi

# Vite 환경변수
if [ ! -f ".env.example" ]; then
    cat > .env.example <<'EOF'
# Vite는 VITE_* 접두사만 클라이언트에 노출
VITE_API_URL=http://localhost:8000
EOF
fi

# 린트 설정 (eslint-plugin-vue)
echo "→ ESLint + Vue 플러그인 설치..."
LINT_DEPS="eslint eslint-plugin-vue"
[ "$LANG" = "TypeScript" ] && LINT_DEPS="$LINT_DEPS @typescript-eslint/parser @typescript-eslint/eslint-plugin"

case "$PM" in
    pnpm) pnpm add -D $LINT_DEPS ;;
    yarn) yarn add -D $LINT_DEPS ;;
    npm|*) npm install --save-dev $LINT_DEPS ;;
esac

echo "✓ Vue 3 + Vite frontend 스캐폴드 완료 ($PM, $LANG)"
echo "  - 개발 서버: cd app/frontend && $PM run dev"
echo "  - 추가됨: vue-router, pinia, @tanstack/vue-query, axios"
echo "  - 구조: src/{stores,router,views}"
