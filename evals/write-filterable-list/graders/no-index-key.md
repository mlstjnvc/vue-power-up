---
type: regex
pattern: ':key="\s*(i|idx|index|n)\s*"'
match: not_contains
target: { source: file, path: src/components/TaskList.vue }
---
