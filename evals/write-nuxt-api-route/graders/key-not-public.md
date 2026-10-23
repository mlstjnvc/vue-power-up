---
type: regex
pattern: 'public\s*:\s*\{[^}]*(key|secret|token)'
match: not_contains
target: { source: file, path: nuxt.config.ts }
flags: i
---
