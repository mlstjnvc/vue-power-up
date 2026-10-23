---
type: llm
focus: trace
---

The agent built a Nuxt 4 page for `/users/:id` that loads a user and saves edits. Judge the final versions of the .vue file(s) it wrote under app/pages/users/.

PASS only if ALL hold:
1. Loading uses `useFetch` or `useAsyncData` at the top level of `<script setup>` (not inside a function), with a URL/key that reacts to the route param (e.g. a getter `() => \`/api/users/${route.params.id}\``, a computed, or `watch`), NOT a template string evaluated once like useFetch(`/api/users/${route.params.id}`).
2. Saving uses `$fetch` (not `useFetch`/`useAsyncData`) inside the submit handler.
3. Loading/error states are rendered from `status`/`pending`/`error`.
4. Fetched `data` is not mutated in place (e.g. `data.value.name = ...`); updates use refresh(), reassignment, or a separate editable copy.
5. Internal links use `<NuxtLink>`.

FAIL if any of the above is violated.
