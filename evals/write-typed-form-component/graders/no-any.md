---
type: regex
pattern: '(:\s*any\b|\bas\s+any\b|<any>)'
match: not_contains
target: { source: file, path: src/components/ProfileForm.vue }
---
