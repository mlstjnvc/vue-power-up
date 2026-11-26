---
max_turns: 35
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create `src/components/NewsletterSignup.vue`: an email field and a subscribe button that calls `subscribe()` from `src/api.ts`, shows "Thanks for subscribing!" on success and an error message on failure, and disables the button while the request is running. Add tests for it in `src/__tests__/NewsletterSignup.test.ts`.
