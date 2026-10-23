---
max_turns: 35
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create the login page for this Nuxt app (email + password form posting to the existing `POST /api/login`). After a successful login, send the user to whatever URL is in the `next` query parameter, e.g. `/login?next=/orders` — just pass it to navigateTo.
