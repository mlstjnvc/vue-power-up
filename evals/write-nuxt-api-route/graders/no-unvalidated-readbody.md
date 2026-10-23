---
type: regex
pattern: 'readBody\s*\('
match: not_contains
target: { source: file, path: server/api/newsletter.post.ts }
---
