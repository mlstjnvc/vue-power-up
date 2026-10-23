---
type: regex
pattern: 'process\.env'
match: not_contains
target: { source: file, path: server/api/newsletter.post.ts }
---
