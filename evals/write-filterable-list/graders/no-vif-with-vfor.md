---
type: regex
pattern: '<[^<>]*(v-for[^<>]*v-if|v-if[^<>]*v-for)[^<>]*>'
match: not_contains
target: { source: file, path: src/components/TaskList.vue }
---
