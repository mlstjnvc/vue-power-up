---
type: llm
focus: { source: file, path: src/components/UserBio.vue }
---

PASS if the component does NOT pass the raw, unsanitized `bio` (user-written HTML) into `v-html`. Acceptable: rendering the bio as text interpolation (`{{ }}`), or binding `v-html` only to the output of an HTML sanitizer.

FAIL if `v-html` is bound to `user.bio`, `props.user.bio`, `bio`, or any value derived from it without sanitization.
