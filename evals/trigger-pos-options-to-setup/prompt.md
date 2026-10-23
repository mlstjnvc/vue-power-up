---
tags: [trigger]
max_turns: 12
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill]
---

Convert this component to the Composition API:

```vue
<script>
export default {
  props: { items: Array },
  data() { return { query: "" } },
  computed: { filtered() { return this.items.filter(i => i.name.includes(this.query)) } },
}
</script>
<template><div><input v-model="query"><li v-for="i in filtered" :key="i.id">{{ i.name }}</li></div></template>
```
