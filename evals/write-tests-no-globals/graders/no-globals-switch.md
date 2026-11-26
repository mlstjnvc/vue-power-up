---
type: regex
pattern: 'globals\s*:\s*true'
match: not_contains
target: { source: file, path: vitest.config.ts }
---
VUE-TEST-007: fix cleanup in the setup file; don't change the project's test config by switching on `globals`.
