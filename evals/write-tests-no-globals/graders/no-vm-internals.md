---
type: regex
pattern: 'wrapper\.vm\.|\.vm\.'
match: not_contains
target: { source: file, path: src/__tests__/NewsletterSignup.test.ts }
---
