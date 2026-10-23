---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a reusable composable in `src/composables/useUserSearch.ts` that searches users with `searchUsers` from `src/api.ts` whenever the search text changes. Components should be able to pass the search text as a ref or straight from a prop. Old requests that are still running when the text changes must not overwrite newer results, and if the search fails, the user should see an error message.
