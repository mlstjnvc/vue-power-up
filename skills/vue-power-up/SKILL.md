---
name: vue-power-up
description: Use when writing, changing or reviewing Vue 3 code with TypeScript — .vue single-file components, <script setup>, composables, Pinia stores, Nuxt pages, layouts, server/api routes, middleware or plugins. Applies version-aware Vue/Nuxt/Pinia best practices, anti-pattern guardrails and security checks. Not for React, Svelte, Angular or Vue 2 Options-API-only maintenance.
---

# vue-power-up

The user describes what they need. You deliver production-quality Vue + TypeScript code that:
- fits their project and installed versions
- avoids known anti-patterns
- is secure by default.

The rules live in `references/`. Load only the files the task needs.

## Workflow

Follow these steps in order for every write task. Steps 1–3 can be brief for small changes, but they can't be skipped.

### 1. Understand the request
- Restate the deliverable in one line.
- Ask **only** if the ambiguity changes the architecture, for example:
  - SSR-rendered or client-only?
  - new store or local state?
  - new API route or existing endpoint?
- Otherwise pick the sensible default and name it in your report.

### 2. Detect the project context
- **Versions:** see [Version detection](#version-detection). Do this before writing any code.
- **Project type:**
  - **Nuxt:** a `nuxt` dependency or a `nuxt.config.*` file.
  - **Vite SPA:** `vite` + `vue` and no `nuxt`.
  - **Nuxt layout:** the source dir is `app/` on Nuxt ≥ 4, or on Nuxt 3 with `future.compatibilityVersion: 4`. Otherwise it's the project root.
- **TypeScript:** whether `strict` is on. Nuxt generates its own tsconfig with `strict: true` unless `typescript.strict: false` is set in `nuxt.config`. If strict is off, still write strict-clean code.
- **Conventions:** open 1–2 existing files of the same kind (component, store, route) and match their folder layout, naming and style. Exception: if a convention is an anti-pattern in the catalog, follow the rule and say so.
- **Existing libraries:** validation (zod, valibot, yup), UI kit, test runner and libraries, ESLint config. Use what's there. **Never add a dependency without asking.**

### 3. Plan the files
List the components, composables, stores, routes and tests you'll create or change, with one line each on why it lives there. Keep components single-purpose. Logic used in more than one place goes in a composable or store.

### 4. Implement with the guardrails
- New code uses `<script setup lang="ts">` and the Composition API. Leave existing Options API code alone unless the task changes it.
- Apply the rules from `references/`, **version-gated**: never use an API above the detected version. If a newer API would be better, mention the upgrade path in one line.
- No `any`, no unchecked `as` casts, and no `!` used just to silence the compiler.

### 5. Security pass
Trace every new data flow from its source (user input, URL, route params, API response, cookies, storage) to its sink. When a flow reaches one of these sinks, load [`references/security.md`](references/security.md):
- **Template HTML:** untrusted data never goes into `v-html`. Render it as text instead, and only sanitize after the user approves a sanitizer dependency (VUE-SEC-001).
- **URL attributes:** untrusted values in `href`, `src` or `action` need scheme validation (VUE-SEC-002).
- **Templates, components, styles:** never compile or render untrusted content as a template, dynamic component or style object (VUE-SEC-003).
- **Redirects:** user-controlled targets must be same-origin relative paths (VUE-SEC-004).
- **Server handlers:**
  - validate body, query and params (VUE-NUXT-011)
  - check auth and ownership (VUE-NUXT-013)
  - never fetch a user-supplied URL (VUE-SEC-006)
  - return only the fields the client needs (VUE-SEC-005).
- **Client-visible data:** keep secrets out of client code, `VITE_*` vars, `runtimeConfig.public`, the SSR payload and stores (VUE-SEC-005, VUE-NUXT-015).
- **Cookies:**
  - sessions use server-set `httpOnly`/`secure`/`sameSite` cookies (VUE-SEC-007)
  - state changes don't happen on GET (VUE-SEC-008).

### 6. Tests
- **If the project has a test setup,** add or update tests for the behaviour you built, following [`references/testing.md`](references/testing.md):
  - use the project's libraries: Testing Library for user flows, Vue Test Utils for the emitted-event or props contract, `@nuxt/test-utils` for Nuxt-dependent code
  - test what the user sees and does, not internal state
  - await async work properly, never `setTimeout`
  - use a fresh Pinia per test
  - mock the network.
- **If there's no test setup,** say so and offer to add one. Don't install anything without consent.

### 7. Self-check
Check the code you produced against every red flag below and against the rules of the reference files you loaded. Then run the project's **existing** checks, if they're installed:
- type check: a `typecheck` script, or `npx vue-tsc --noEmit` / `npx nuxi typecheck`
- lint
- the tests covering the changed files.

Fix failures your change caused. Report pre-existing failures, but don't fix them unless asked.

### 8. Report
Summarize:
- what you built (files and their purpose)
- defaults you chose in step 1
- version-related choices
- checks run and their results
- **every guardrail deviation:** each place where you didn't follow the request literally, and why.

## When a request conflicts with a guardrail

Build the safe or idiomatic version, and explain the deviation in your report: what was asked, what you did instead, and the risk you avoided. Don't comply silently and don't refuse silently.

If the user insists after the explanation, do what they asked. Add a code comment at that spot naming the risk and the rule id, for example `// VUE-SEC-001 accepted by user: renders unsanitized HTML`.

## Reviewing code

When the user asks to review Vue code in plain language ("review this component"), follow [`references/review.md`](references/review.md), with the named files as the scope. To review uncommitted changes or a commit, the user can run `/vue-power-up:review [commit]`. A review never edits files. Apply proposed changes only when the user asks for them afterwards.

## Version detection

1. **Find the right `package.json`.** In a monorepo, use the package that owns the files you're changing.
2. **Resolve installed versions in this order:**
   - `node_modules/<pkg>/package.json` → `version`
   - otherwise, the lockfile entry (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock`)
   - otherwise, the minimum of the `package.json` range (`^3.4.21` → 3.4.21).
3. **Packages to resolve:**
   - `vue`, `nuxt`, `pinia`, `@pinia/nuxt`, `typescript`, `vue-tsc`
   - test packages: `vitest`, `@vue/test-utils`, `@testing-library/vue`, `@nuxt/test-utils`.
   - Nuxt ships its own `vue`, so resolve `vue` from `node_modules` there too.
4. **If you can't determine a version,** assume the latest stable release and say so in the report.

APIs that need a minimum version (rules carry their own **Applies** range):

| Need | Minimum |
|---|---|
| `defineSlots`, `defineOptions`, `<script setup generic="T">`, imported types in `defineProps`, `toValue` / `MaybeRefOrGetter` | Vue 3.3 |
| `defineModel`, `watch(..., { once: true })` | Vue 3.4 |
| Reactive props destructure (with defaults), `useTemplateRef`, `useId`, `onWatcherCleanup`, numeric `deep` in `watch` | Vue 3.5 |
| `app/` source dir by default | Nuxt 4 (Nuxt 3 needs `future.compatibilityVersion: 4`) |

## Red flags

If you're about to do any of these, stop and fix the approach:

- Writing code before resolving versions, or using an API above the detected version
- Adding a dependency, or changing `tsconfig` or lint config, without asking
- Writing new code with the Options API, or `<script>` without `lang="ts"`
- Following a request literally when it hits a guardrail, without explaining the deviation
- Leaving a new data flow unchecked by the security pass
- `v-html` with data you didn't produce, or `:href`/`navigateTo` with an unvalidated user value (VUE-SEC-001, VUE-SEC-002, VUE-SEC-004)
- Claiming checks passed without running them
- `any`, an unchecked `as`, or `!` to make an error go away (VUE-TS-010)
- `defineEmits([...])` array syntax, or a runtime-object `defineProps` in a TS component (VUE-TS-004, VUE-TS-002)
- A hand-written `modelValue` prop + `update:modelValue` emit on Vue ≥ 3.4 (VUE-COMP-001)
- Assigning to a prop, or mutating an object/array prop (VUE-COMP-002)
- Destructuring a `reactive()` object, or `watch(props.x, …)` instead of a getter (VUE-REACT-001, VUE-REACT-007)
- Nuxt: `useFetch`/`useAsyncData` inside a handler, or a fetch URL built once from route params (VUE-NUXT-002, VUE-NUXT-003)
- A server handler that uses body, query or params without validation, or without an auth check where data is private (VUE-NUXT-011, VUE-NUXT-013)
- A secret under `runtimeConfig.public`, or `process.env` in app or server code (VUE-NUXT-015, VUE-NUXT-014)
- Destructuring store state without `storeToRefs`, or calling `useXStore()` at module top level (VUE-PINIA-001, VUE-PINIA-003)
- Calling a composable inside an event handler, a timer or a nested async function (VUE-CMPS-004)
- In SSR apps: `window`/`document`/`localStorage` during setup, or per-user state at module scope (VUE-CMPS-008, VUE-CMPS-009)
- `v-if` and `v-for` on the same element, or an index/missing `:key` on a changing list (VUE-TPL-001, VUE-TPL-002)

## References

Load a file when the task touches its domain:

| File | Load when |
|---|---|
| [`references/typescript-sfc.md`](references/typescript-sfc.md) | Any `.vue` file or TS code using Vue APIs: props, emits, refs, template refs, provide/inject, slots, generics |
| [`references/components.md`](references/components.md) | Creating or changing components: v-model, prop flow, exposed methods, splitting, naming, styles |
| [`references/reactivity.md`](references/reactivity.md) | Any state: `ref`/`reactive`, `computed`, `watch`, side-effect cleanup |
| [`references/templates.md`](references/templates.md) | Writing templates: lists, conditionals, template logic, interactive elements, form labels |
| [`references/composables.md`](references/composables.md) | Writing or calling a composable (`use*`), or any SSR-sensitive shared state |
| [`references/pinia.md`](references/pinia.md) | Defining or using Pinia stores, including in router guards, plugins and Nuxt pages |
| [`references/nuxt.md`](references/nuxt.md) | Any Nuxt project: data fetching, SSR state, hydration, links, file locations, server routes, runtime config, middleware, plugins |
| [`references/security.md`](references/security.md) | A data flow reaches HTML, URLs, redirects, dynamic components or styles, server requests, cookies, or client-visible state |
| [`references/performance.md`](references/performance.md) | Large data, long lists, heavy components, bundle size, SSR hydration cost |
| [`references/testing.md`](references/testing.md) | Writing or changing tests (Vitest, Testing Library, Vue Test Utils, Pinia, Nuxt) |
| [`references/review.md`](references/review.md) | The user asks for a review: procedure, verdict rules, output format |
| [`references/rule-catalog.md`](references/rule-catalog.md) | You need the rule format, severities, or the index of every rule id |
