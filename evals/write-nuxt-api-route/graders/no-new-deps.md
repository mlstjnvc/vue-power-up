---
type: regex
pattern: '"(zod|valibot|yup|joi)"'
match: not_contains
target: { source: file, path: package.json }
---
