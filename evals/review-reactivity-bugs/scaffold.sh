#!/usr/bin/env bash
# Minimal Vue 3.5 + TS SPA (no node_modules).
set -euo pipefail
mkdir -p src/components
cat > package.json <<'JSON'
{
  "name": "app", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "vue-tsc --noEmit" },
  "dependencies": { "vue": "^3.5.13" },
  "devDependencies": { "@vitejs/plugin-vue": "^5.2.1", "typescript": "~5.6.3", "vite": "^6.0.5", "vue-tsc": "^2.2.0" }
}
JSON
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2020", "module": "ESNext", "moduleResolution": "Bundler", "strict": true, "isolatedModules": true, "verbatimModuleSyntax": true, "jsx": "preserve", "noEmit": true, "lib": ["ES2020", "DOM"] }, "include": ["src/**/*.ts", "src/**/*.vue"] }
JSON
cat > src/api.ts <<'TS'
export interface User { id: string; name: string; active: boolean }
export async function searchUsers(q: string, opts?: { signal?: AbortSignal }): Promise<User[]> {
  const res = await fetch(`/api/users?q=${encodeURIComponent(q)}`, { signal: opts?.signal })
  return (await res.json()) as User[]
}
TS
cat > src/components/UserSearch.vue <<'VUE'
<script setup lang="ts">
import { reactive, ref, watch, onMounted } from 'vue'
import { searchUsers, type User } from '../api'

const props = defineProps<{ teamId: string }>()

const state = reactive({ query: '', page: 1 })
const { query } = state

const results = ref<User[]>([])

watch(props.teamId, () => {
  state.page = 1
})

watch(() => state.query, async (q) => {
  results.value = await searchUsers(q)
})

onMounted(() => {
  window.addEventListener('keydown', onKey)
})

function onKey(e: KeyboardEvent) {
  if (e.key === 'Escape') state.query = ''
}
</script>

<template>
  <input v-model="state.query" placeholder="Search users" />
  <p>Searching for: {{ query }}</p>
  <ul>
    <li v-for="(user, i) in results" v-if="user.active" :key="i">{{ user.name }}</li>
  </ul>
</template>
VUE
