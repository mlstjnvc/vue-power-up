---
type: regex
pattern: 'setTimeout|new Promise\(\s*\(?r(esolve)?\)?\s*=>\s*setTimeout'
match: not_contains
target: { source: file, path: src/__tests__/NewsletterSignup.test.ts }
---
