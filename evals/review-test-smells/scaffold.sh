#!/usr/bin/env bash
# Vue 3.5 SPA with Vitest + Testing Library + VTU configured (no node_modules).
set -euo pipefail
mkdir -p src/components src/__tests__
cat > package.json <<'JSON'
{
  "name": "app", "private": true, "type": "module",
  "scripts": { "dev": "vite", "test": "vitest run", "typecheck": "vue-tsc --noEmit" },
  "dependencies": { "vue": "^3.5.13" },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.2.1", "typescript": "~5.6.3", "vite": "^6.0.5", "vue-tsc": "^2.2.0",
    "vitest": "^3.0.5", "jsdom": "^26.0.0", "@vue/test-utils": "^2.4.6",
    "@testing-library/vue": "^8.1.0", "@testing-library/user-event": "^14.6.1", "@testing-library/jest-dom": "^6.6.3"
  }
}
JSON
cat > vitest.config.ts <<'TS'
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
export default defineConfig({ plugins: [vue()], test: { environment: 'jsdom', globals: true, setupFiles: ['./vitest.setup.ts'] } })
TS
printf "import '@testing-library/jest-dom/vitest'\n" > vitest.setup.ts
cat > tsconfig.json <<'JSON'
{ "compilerOptions": { "target": "ES2020", "module": "ESNext", "moduleResolution": "Bundler", "strict": true, "isolatedModules": true, "verbatimModuleSyntax": true, "jsx": "preserve", "noEmit": true, "lib": ["ES2020", "DOM"], "types": ["vitest/globals"] }, "include": ["src/**/*.ts", "src/**/*.vue", "*.ts"] }
JSON
cat > src/components/ExistingButton.vue <<'VUE'
<script setup lang="ts">
defineEmits<{ press: [] }>()
</script>
<template><button type="button" @click="$emit('press')"><slot /></button></template>
VUE
cat > src/__tests__/ExistingButton.test.ts <<'TS'
import { render, screen } from '@testing-library/vue'
import userEvent from '@testing-library/user-event'
import ExistingButton from '../components/ExistingButton.vue'

test('emits press when clicked', async () => {
  const { emitted } = render(ExistingButton, { slots: { default: 'Go' } })
  await userEvent.setup().click(screen.getByRole('button', { name: 'Go' }))
  expect(emitted().press).toHaveLength(1)
})
TS
cat > src/components/LoginForm.vue <<'VUE'
<script setup lang="ts">
import { ref } from 'vue'
const email = ref('')
const error = ref('')
const loading = ref(false)
async function submit() {
  loading.value = true
  const res = await fetch('/api/login', { method: 'POST', body: JSON.stringify({ email: email.value }) })
  if (!res.ok) error.value = 'Login failed'
  loading.value = false
}
</script>
<template>
  <form @submit.prevent="submit">
    <label for="email">Email</label><input id="email" v-model="email" />
    <button type="submit" :disabled="loading">Log in</button>
    <p v-if="error" role="alert">{{ error }}</p>
  </form>
</template>
VUE
cat > src/__tests__/LoginForm.test.ts <<'TS'
import { mount } from '@vue/test-utils'
import LoginForm from '../components/LoginForm.vue'

test('shows error', async () => {
  const wrapper = mount(LoginForm)
  wrapper.vm.email = 'x@example.com'
  await wrapper.find('form').trigger('submit')
  await new Promise((r) => setTimeout(r, 1000))
  expect(wrapper.vm.error).toBe('Login failed')
})
TS
