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
mkdir -p src/composables
cat > src/composables/windowSize.ts <<'TS'
import { reactive, watch } from 'vue'
import { notify } from '../ui/notify'

export function windowSize(breakpoint: number) {
  const state = reactive({ width: window.innerWidth, isMobile: false })

  window.addEventListener('resize', () => {
    state.width = window.innerWidth
  })

  watch(() => state.width, (w) => {
    state.isMobile = w < breakpoint
    if (state.isMobile) notify('Switched to mobile layout')
  }, { immediate: true })

  return state
}
TS
mkdir -p src/ui
printf 'export function notify(msg: string) { console.log(msg) }\n' > src/ui/notify.ts
