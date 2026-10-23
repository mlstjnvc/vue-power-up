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
cat > src/router.ts <<'TS'
import { createRouter, createWebHistory } from 'vue-router'
export const router = createRouter({ history: createWebHistory(), routes: [] })
TS
