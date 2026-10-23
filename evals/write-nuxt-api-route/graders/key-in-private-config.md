---
type: regex
pattern: '(mailApiKey|mailKey|apiKey)'
target: { source: file, path: nuxt.config.ts }
flags: i
---
