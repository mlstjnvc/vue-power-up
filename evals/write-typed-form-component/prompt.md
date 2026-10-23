---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create `src/components/ProfileForm.vue`. It should be a form for editing the `Profile` from `src/types.ts` (name, email, newsletter opt-in). The parent should be able to use it as `<ProfileForm v-model="profile" @submit="save" />`, and submitting the form should emit `submit` with the profile. Then use it in `src/App.vue`.
