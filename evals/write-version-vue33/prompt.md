---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create `src/components/SearchInput.vue`: a text input that works with `v-model` on the parent, has a clear (×) button, has an accessible label, and exposes a `focus()` method the parent can call through a template ref.
