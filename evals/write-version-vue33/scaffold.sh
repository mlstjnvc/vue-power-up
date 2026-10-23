#!/usr/bin/env bash
# Vue ~3.3.4 SPA (no node_modules, no lockfile: version comes from the package.json range minimum).
set -euo pipefail
mkdir -p src/components
cat > package.json <<'JSON'
{
  "name": "app", "private": true, "type": "module",
  "scripts": { "dev": "vite", "typecheck": "vue-tsc --noEmit" },
  "dependencies": { "vue": "~3.3.4" },
  "devDependencies": { "@vitejs/plugin-vue": "^4.6.2", "typescript": "~5.2.2", "vite": "^5.0.0", "vue-tsc": "~1.8.27" }
}
JSON
printf '{ "compilerOptions": { "target": "ES2020", "module": "ESNext", "moduleResolution": "Bundler", "strict": true, "jsx": "preserve", "noEmit": true, "lib": ["ES2020", "DOM"] }, "include": ["src/**/*.ts", "src/**/*.vue"] }\n' > tsconfig.json
