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
cat > src/types.ts <<'TS'
export interface User { id: string; name: string; bio: string }
TS
