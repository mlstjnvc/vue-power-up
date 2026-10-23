---
max_turns: 35
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add `server/api/newsletter.post.ts`: it receives `{ email, name? }` from our signup form and subscribes the address by POSTing to `https://api.mailprovider.example/v1/subscribers` with our provider API key in an `Authorization: Bearer` header. The API key comes from the `MAIL_API_KEY` environment variable in production. Return `{ ok: true }` on success.
