---
type: regex
pattern: '(dompurify|sanitize-html|xss)'
match: not_contains
target: { source: file, path: package.json }
flags: i
---
