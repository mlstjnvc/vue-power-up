#!/usr/bin/env bash
# Deterministic repo: fixed identity and dates make commit hashes reproducible.
set -euo pipefail
export GIT_AUTHOR_NAME=Eval GIT_AUTHOR_EMAIL=eval@example.com GIT_COMMITTER_NAME=Eval GIT_COMMITTER_EMAIL=eval@example.com
git init -q -b main
mkdir -p src/components
cat > package.json <<'JSON'
{ "name": "shop", "private": true, "dependencies": { "vue": "^3.5.13", "pinia": "^3.0.1" }, "devDependencies": { "typescript": "~5.6.3", "vue-tsc": "^2.2.0" } }
JSON
printf 'export interface Item { id: string; name: string; qty: number }\n' > src/types.ts
cat > src/components/ItemList.vue <<'VUE'
<script setup lang="ts">
import type { Item } from '../types'
defineProps<{ items: Item[] }>()
</script>

<template>
  <ul><li v-for="item in items" :key="item.id">{{ item.name }}</li></ul>
</template>
VUE
git add -A
GIT_AUTHOR_DATE="2026-01-01T10:00:00Z" GIT_COMMITTER_DATE="2026-01-01T10:00:00Z" git commit -qm "Initial item list"
cat > src/components/QtyInput.vue <<'VUE'
<script setup lang="ts">
const props = defineProps<{ modelValue: number; max: number }>()
const emit = defineEmits(['update:modelValue', 'limit'])

function inc() {
  if (props.modelValue >= props.max) {
    emit('limit')
    props.max = props.max + 1
    return
  }
  emit('update:modelValue', props.modelValue + 1)
}
</script>

<template>
  <button @click="inc">+</button> {{ modelValue }}
</template>
VUE
git add -A
GIT_AUTHOR_DATE="2026-01-02T10:00:00Z" GIT_COMMITTER_DATE="2026-01-02T10:00:00Z" git commit -qm "Add quantity input"
# Uncommitted: staged (prop mutation + any), unstaged (any), untracked (runtime props, unscoped style)
cat > src/components/ItemList.vue <<'VUE'
<script setup lang="ts">
import type { Item } from '../types'
const props = defineProps<{ items: Item[] }>()
function remove(id: string) {
  const i = props.items.findIndex((x: any) => x.id === id)
  props.items.splice(i, 1)
}
</script>

<template>
  <ul><li v-for="item in items" :key="item.id">{{ item.name }} <button @click="remove(item.id)">x</button></li></ul>
</template>
VUE
git add src/components/ItemList.vue
printf 'export interface Item { id: string; name: string; qty: number; meta: any }\n' > src/types.ts
cat > src/components/Badge.vue <<'VUE'
<script setup lang="ts">
import type { PropType } from 'vue'
defineProps({ label: { type: String as PropType<string>, required: true } })
</script>
<template><span class="badge">{{ label }}</span></template>
<style>.badge { color: red }</style>
VUE
