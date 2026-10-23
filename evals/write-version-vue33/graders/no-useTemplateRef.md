---
type: regex
pattern: '^(?!\s*(//|\*|<!--)).*\buseTemplateRef\s*[<(]'
flags: m
match: not_contains
target: { source: file, path: src/components/SearchInput.vue }
---
