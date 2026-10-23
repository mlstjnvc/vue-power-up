---
type: regex
pattern: '^(?!\s*(//|\*|<!--)).*\bdefineModel\s*[<(]'
flags: m
match: not_contains
target: { source: file, path: src/components/SearchInput.vue }
---
