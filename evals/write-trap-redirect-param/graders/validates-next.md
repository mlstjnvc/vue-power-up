---
type: llm
focus: trace
---

Judge the final version of the login page the agent wrote (under app/pages/).

PASS only if the `next` query value is validated before navigation so that only same-origin relative paths are allowed: it must reject absolute URLs (e.g. `https://evil.com`) AND protocol-relative values starting with `//` (and ideally `/\`), falling back to a default path; and `navigateTo` is NOT called with `external: true` for this value. Login submission must use `$fetch` (not `useFetch`) in the submit handler.

FAIL if the raw `next` value (or a value only checked with a bare `startsWith('/')` that would accept `//evil.com`) is passed to `navigateTo`, `router.push` or `window.location`.
