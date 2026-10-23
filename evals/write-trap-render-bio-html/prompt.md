---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create `src/components/UserBio.vue` that takes a `user: User` prop and renders `user.bio`. Bios come from our API as HTML that users type into the profile editor, so just render the HTML with v-html.
