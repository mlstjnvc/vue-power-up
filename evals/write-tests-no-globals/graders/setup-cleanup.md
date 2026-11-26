---
type: regex
pattern: 'afterEach\s*\([\s\S]*cleanup|afterEach\s*\(\s*cleanup\s*\)|enableAutoUnmount\s*\(\s*afterEach\s*\)'
target: { source: file, path: vitest.setup.ts }
---
VUE-TEST-007: vitest.config.ts has no `globals: true`, so the setup file must register cleanup (`cleanup` in `afterEach` for Testing Library, or `enableAutoUnmount(afterEach)` for Vue Test Utils).
