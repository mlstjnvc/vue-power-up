#!/usr/bin/env bash
# Nuxt 4 project (app/ srcDir), no node_modules.
set -euo pipefail
mkdir -p app/pages app/components app/composables server/api/users shared/types
cat > package.json <<'JSON'
{
  "name": "nuxt-app", "private": true, "type": "module",
  "scripts": { "dev": "nuxt dev", "build": "nuxt build", "typecheck": "nuxi typecheck" },
  "dependencies": { "nuxt": "^4.1.2", "vue": "^3.5.21", "vue-router": "^4.5.1" },
  "devDependencies": { "typescript": "~5.9.2", "vue-tsc": "^3.0.6" }
}
JSON
cat > nuxt.config.ts <<'TS'
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
})
TS
printf '{\n  "files": [],\n  "references": [{ "path": "./.nuxt/tsconfig.app.json" }, { "path": "./.nuxt/tsconfig.server.json" }, { "path": "./.nuxt/tsconfig.shared.json" }, { "path": "./.nuxt/tsconfig.node.json" }]\n}\n' > tsconfig.json
cat > app/app.vue <<'VUE'
<template>
  <NuxtLayout><NuxtPage /></NuxtLayout>
</template>
VUE
cat > shared/types/user.ts <<'TS'
export interface User { id: string; name: string; email: string; bio: string }
TS
cat > server/api/users/[id].get.ts <<'TS'
import type { User } from '~~/shared/types/user'
const users: Record<string, User> = {
  '1': { id: '1', name: 'Ada', email: 'ada@example.com', bio: 'Engineer' },
  '2': { id: '2', name: 'Linus', email: 'linus@example.com', bio: 'Kernel' },
}
export default defineEventHandler((event) => {
  const id = getRouterParam(event, 'id')
  const user = id ? users[id] : undefined
  if (!user) throw createError({ statusCode: 404, statusMessage: 'User not found' })
  return user
})
TS
cat > server/api/users/[id].put.ts <<'TS'
export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  return { ok: true, ...body }
})
TS
