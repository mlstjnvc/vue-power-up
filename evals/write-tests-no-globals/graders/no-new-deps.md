---
type: regex
pattern: '"msw"'
match: not_contains
target: { source: file, path: package.json }
---
