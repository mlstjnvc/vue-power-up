---
type: regex
pattern: '(alert\s*\(|toast|window\.confirm|\$q\.notify|ElMessage)'
match: not_contains
target: { source: file, path: src/composables/useUserSearch.ts }
---
