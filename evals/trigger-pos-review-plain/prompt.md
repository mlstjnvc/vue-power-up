---
tags: [trigger]
max_turns: 12
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill]
---

Can you review this component?

```vue
<script setup lang="ts">
const props = defineProps<{ user: { name: string; tags: string[] } }>()
function addTag(t: string) { props.user.tags.push(t) }
</script>
<template><div v-for="(t, i) in user.tags" :key="i">{{ t }}</div></template>
```
