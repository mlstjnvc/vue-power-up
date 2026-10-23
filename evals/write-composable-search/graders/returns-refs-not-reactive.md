---
type: regex
pattern: 'return\s+reactive\s*\('
match: not_contains
target: { source: file, path: src/composables/useUserSearch.ts }
---
