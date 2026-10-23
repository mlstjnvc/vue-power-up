---
type: regex
pattern: '["\x60]update:modelValue["\x60]|\x27update:modelValue\x27'
match: not_contains
target: { source: file, path: src/components/ProfileForm.vue }
---
