#!/usr/bin/env bash
# Vue 3.5 + Pinia 3 SPA (no node_modules).
set -euo pipefail
mkdir -p src/components src/stores
cat > package.json <<'JSON'
{
  "name": "shop", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "vue-tsc --noEmit" },
  "dependencies": { "vue": "^3.5.13", "pinia": "^3.0.1", "vue-router": "^4.5.0" },
  "devDependencies": { "@vitejs/plugin-vue": "^5.2.1", "typescript": "~5.6.3", "vite": "^6.0.5", "vue-tsc": "^2.2.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2020", "module": "ESNext", "moduleResolution": "Bundler", "strict": true, "isolatedModules": true, "verbatimModuleSyntax": true, "jsx": "preserve", "noEmit": true, "lib": ["ES2020", "DOM"] }, "include": ["src/**/*.ts", "src/**/*.vue"] }
JSON
cat > src/main.ts <<'TS'
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import { router } from './router'
createApp(App).use(createPinia()).use(router).mount('#app')
TS
printf 'export interface Product { id: string; name: string; price: number }\n' > src/types.ts
cat > src/stores/auth.ts <<'TS'
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<{ id: string; name: string } | null>(null)
  const lastLogin = ref<number | null>(null)
  const isLoggedIn = computed(() => user.value !== null)

  async function login(name: string) {
    user.value = { id: crypto.randomUUID(), name }
    lastLogin.value = Date.now()
  }

  return { user, isLoggedIn, login }
})
TS
cat > src/router.ts <<'TS'
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from './stores/auth'

const auth = useAuthStore()

export const router = createRouter({ history: createWebHistory(), routes: [] })

router.beforeEach((to) => {
  if (to.meta.requiresAuth && !auth.isLoggedIn) return '/login'
})
TS
cat > src/components/UserBadge.vue <<'VUE'
<script setup lang="ts">
import { useAuthStore } from '../stores/auth'
const { user, isLoggedIn, login } = useAuthStore()
</script>

<template>
  <span v-if="isLoggedIn">{{ user?.name }}</span>
  <button v-else type="button" @click="login('guest')">Log in</button>
</template>
VUE
