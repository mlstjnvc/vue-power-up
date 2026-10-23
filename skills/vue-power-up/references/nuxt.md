# Nuxt (`VUE-NUXT-*`)

Rules for Nuxt apps: data fetching, SSR-safe state and rendering, navigation, project layout, server routes, runtime config, middleware and plugins. Nuxt 4 is primary. Nuxt 3 differences are noted per rule.

**Before applying:** confirm the project is Nuxt and resolve its version (SKILL.md, step 2). In Nuxt 4 the source dir is `app/` (`app/pages`, `app/components`, `app/composables`, `app/stores`, …), while `server/`, `shared/` and `public/` stay at the root. Nuxt 3 uses the root, unless `future.compatibilityVersion: 4` is set. Also see the SSR rules in `composables.md` (VUE-CMPS-008, VUE-CMPS-009).

## Data fetching and SSR state

### VUE-NUXT-001 · Fetch render data with `useFetch`/`useAsyncData`, not bare `$fetch` in setup  `warn`

**Why:** A bare `await $fetch()` in `<script setup>` runs on the server *and again* on the client during hydration (double fetching), and its result isn't sent to the client in the payload. `useFetch`/`useAsyncData` fetch once on the server, put the result in the payload, and reuse it during hydration.
**Source:** https://nuxt.com/docs/4.x/getting-started/data-fetching

```ts
// ❌ pages/products.vue
const products = await $fetch<Product[]>('/api/products')

// ✅
const { data: products, status, error } = await useFetch<Product[]>('/api/products')
// ✅ custom logic / non-$fetch sources
const { data } = await useAsyncData('product-stats', () => getStats(range.value), { watch: [range] })
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:**
- Client-only components and pages (`ssr: false`, `.client.vue`).
- Data that should deliberately be fetched only on the client (`useFetch(url, { server: false })` is still preferred, for its state handling).

---

### VUE-NUXT-002 · Use `$fetch` (not `useFetch`/`useAsyncData`) for user-triggered requests  `error`

**Why:**
- `useFetch` and `useAsyncData` are composables. They must run during setup (VUE-CMPS-004), and they register cached, keyed state.
- Called inside a click or submit handler, they run outside the component context, can return stale cached data, and leak keyed entries.
- The Nuxt docs recommend `$fetch` for client-side, event-based interactions.

**Source:** https://nuxt.com/docs/4.x/getting-started/data-fetching#fetch

```ts
// ❌
async function save() {
  const { data } = await useFetch('/api/profile', { method: 'PUT', body: form.value })
}

// ✅
async function save() {
  try {
    await $fetch('/api/profile', { method: 'PUT', body: form.value })
    await refreshNuxtData('profile') // or the refresh() returned by useFetch
  } catch (e) {
    saveError.value = e instanceof Error ? e.message : 'Save failed'
  }
}
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** none. To re-run a setup-level `useFetch` from a handler, call its `refresh()`/`execute()`.

---

### VUE-NUXT-003 · Make fetches react to their inputs  `error`

**Why:**
- A URL built with a template string from route params or refs, *at call time*, is evaluated once. When the param changes (client-side navigation between `/users/1` and `/users/2` reuses the page component), the page keeps showing the first user's data.
- Pass a getter or computed URL, or reactive `query` values, or list sources in `watch`.

**Source:** https://nuxt.com/docs/4.x/getting-started/data-fetching#computed-url · https://nuxt.com/docs/4.x/getting-started/data-fetching#watch

```ts
// ❌
const route = useRoute()
const { data: user } = await useFetch(`/api/users/${route.params.id}`)

// ✅ getter URL: refetches when the param changes
const { data: user } = await useFetch(() => `/api/users/${route.params.id}`)
// ✅ reactive query
const { data } = await useFetch('/api/products', { query: { page, q: search } }) // page, search are refs
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** pages where the param can't change without remounting (e.g. a `key` on `<NuxtPage>` forces remount).

---

### VUE-NUXT-004 · Give `useAsyncData` an explicit, unique key per distinct data, and keep options consistent per key  `warn`

**Why:**
- The key caches the result and de-duplicates it between server and client.
- All calls with the same key share the same `data`, `error` and `status` refs (Nuxt 4 "singleton data fetching layer"). So two different queries under one key overwrite each other, and conflicting options (`deep`, `transform`, `pick`, …) under one key warn and misbehave.
- The Nuxt docs recommend always setting your own key.

**Source:** https://nuxt.com/docs/4.x/getting-started/data-fetching#keys · https://nuxt.com/docs/4.x/getting-started/upgrade#singleton-data-fetching-layer

```ts
// ❌ same key for different data
const { data: a } = await useAsyncData('user', () => getUser(idA))
const { data: b } = await useAsyncData('user', () => getUser(idB))

// ✅
const { data: user } = await useAsyncData(() => `user:${id.value}`, () => getUser(id.value))
```

**Applies:** Nuxt ≥ 3.0 (shared refs per key: Nuxt ≥ 4; reactive keys: Nuxt ≥ 3.17) · **Exceptions:** `useFetch` generates a key from the URL and options. An explicit `key` is only needed when sharing or disambiguating.

---

### VUE-NUXT-005 · Handle `status` and `error` from fetch composables  `warn`

**Why:**
- `data` is `undefined` while loading, on error, and when the fetch was skipped on the server (`server: false`, `lazy`). It defaults to `undefined` in Nuxt 4; it was `null` in Nuxt 3.
- Templates that assume data is present crash or show empty UI with no feedback.
- Render the pending and error states from `status` (`idle` | `pending` | `success` | `error`) and `error`.

**Source:** https://nuxt.com/docs/4.x/getting-started/data-fetching#return-values · https://nuxt.com/docs/4.x/getting-started/upgrade#default-data-and-error-values-in-useasyncdata-and-usefetch

```vue
<script setup lang="ts">
const { data: orders, status, error, refresh } = await useFetch<Order[]>('/api/orders', { lazy: true })
</script>

<template>
  <p v-if="status === 'pending'">Loading…</p>
  <ErrorNotice v-else-if="error" :error="error" @retry="refresh()" />
  <OrdersTable v-else-if="orders" :orders="orders" />
</template>
```

**Applies:** Nuxt ≥ 3.0 (Nuxt 4: `undefined` defaults, `pending` only true while `status === 'pending'`) · **Exceptions:** non-lazy fetches with `throw createError()` on failure, where a page-level error boundary handles the error.

---

### VUE-NUXT-006 · Don't mutate nested fetched data in place on Nuxt 4 (it's a `shallowRef`)  `error`

**Why:** In Nuxt 4, `data` from `useFetch`/`useAsyncData` is a `shallowRef`. `data.value.items.push(x)` or `data.value.name = 'x'` doesn't trigger updates, so the UI silently stays stale. Replace the value, refetch, or opt in with `deep: true` when in-place editing is really needed.
**Source:** https://nuxt.com/docs/4.x/getting-started/upgrade#shallow-data-reactivity-in-useasyncdata-and-usefetch

```ts
// ❌ Nuxt 4
const { data: todos } = await useFetch<Todo[]>('/api/todos')
function add(t: Todo) { todos.value?.push(t) }

// ✅
function add(t: Todo) { todos.value = [...(todos.value ?? []), t] }
// ✅ or editable copy / opt-in
const { data: draft } = await useFetch<Settings>('/api/settings', { deep: true })
```

**Applies:** Nuxt ≥ 4 (or Nuxt 3 with `compatibilityVersion: 4`) · **Exceptions:** Nuxt 3 default behaviour (deep `ref`), and calls with `deep: true`.

---

### VUE-NUXT-007 · Share state with `useState` (unique key, serializable value), never module-scope refs  `error`

**Why:**
- Module-scope `ref`s are shared by every request on the server, so they leak state between users (VUE-CMPS-009).
- `useState(key, init)` creates per-request state that's serialized into the payload and hydrated on the client.
- The value must be serializable: no classes, functions or symbols.
- Use Pinia (`VUE-PINIA-*`) when the state comes with actions and derived values.

**Source:** https://nuxt.com/docs/4.x/getting-started/state-management · https://nuxt.com/docs/4.x/api/composables/use-state

```ts
// ❌ app/composables/useCounter.ts
const count = ref(0)
export const useCounter = () => count

// ✅
export const useCounter = () => useState<number>('counter', () => 0)
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:**
- module-scope *constants*
- client-only plugins and components where no server render happens.
- Don't name your own function `useState`: the name is reserved by Nuxt's compiler.

---

### VUE-NUXT-008 · Render the same markup on server and client  `warn`

**Why:**
- Values that differ between server and client cause hydration mismatches: console warnings, flicker, and event handlers attached to the wrong nodes. Examples: `Date.now()`, `Math.random()`, time-of-day greetings, `window.innerWidth`, `localStorage`.
- Fixes:
  - compute client-only values in `onMounted`
  - wrap them in `<ClientOnly>` (with a fallback)
  - share random or initial values with `useState`
  - persist with `useCookie`
  - use CSS media queries for responsive layout.

**Source:** https://nuxt.com/docs/4.x/guide/best-practices/hydration

```vue
<!-- ❌ -->
<p>{{ new Date().getHours() < 12 ? 'Good morning' : 'Hello' }}</p>
<Sidebar v-if="window.innerWidth > 1024" />

<!-- ✅ -->
<ClientOnly fallback="Hello"><Greeting /></ClientOnly>
<Sidebar class="hidden lg:block" />
```

**Applies:** Nuxt ≥ 3.0 (SSR) · **Exceptions:** `ssr: false` apps and routes.

---

### VUE-NUXT-009 · Use `<NuxtLink>` for internal links  `warn`

**Why:** A plain `<a href="/about">` does a full page reload: state is lost, and the app re-downloads and re-hydrates. `<NuxtLink>` navigates client-side and prefetches visible links. Use it for external links too, since it adds `rel="noopener noreferrer"` for `target="_blank"`. For programmatic navigation use `navigateTo()`.
**Source:** https://nuxt.com/docs/4.x/api/components/nuxt-link · https://nuxt.com/docs/4.x/api/utils/navigate-to

```vue
<!-- ❌ -->
<a href="/orders">Orders</a>
<div @click="$router.push('/orders')">Orders</div>

<!-- ✅ -->
<NuxtLink to="/orders">Orders</NuxtLink>
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** links to files or routes outside the Nuxt app (downloads, server-rendered legacy paths). Use `external`, or plain `<a>` with a reason.

---

### VUE-NUXT-010 · Put files where the project's Nuxt version expects them  `warn`

**Why:**
- Auto-imports, routing and server handlers depend on location.
- A page created in `pages/` in a Nuxt 4 project (whose pages live in `app/pages/`) isn't routed. A composable outside `composables/` isn't auto-imported. API code outside `server/` is bundled into the client.
- Check where existing files live before creating new ones.

**Source:** https://nuxt.com/docs/4.x/getting-started/upgrade#new-directory-structure · https://nuxt.com/docs/4.x/directory-structure

```
✅ Nuxt 4                         ✅ Nuxt 3 (default)
app/pages/orders/[id].vue          pages/orders/[id].vue
app/components/OrderCard.vue       components/OrderCard.vue
app/composables/useOrders.ts       composables/useOrders.ts
app/stores/orders.ts (@pinia/nuxt) stores/orders.ts
server/api/orders/[id].get.ts      server/api/orders/[id].get.ts
shared/types/order.ts (Nuxt ≥ 3.14 shared/)
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** projects that set a custom `srcDir` or `dir` options in `nuxt.config`. Follow the config.

## Server routes, config, middleware and plugins

### VUE-NUXT-011 · Validate every server input (body, query, route params)  `error`

**Why:**
- Anything in a request is attacker-controlled.
- `readBody(event)` / `getQuery(event)` return whatever was sent, and a TypeScript annotation or `as` cast doesn't check it.
- Use h3's validated readers with a schema, which reject bad input with a 400 before your logic runs.
- **Validator choice:** use the project's existing validator (zod, valibot, …). If there's none, write a type-guard function rather than adding a dependency unasked.

**Source:** https://nuxt.com/docs/4.x/directory-structure/server · https://v1.h3.dev/examples/validate-data · https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html

```ts
// ❌ server/api/users/[id].put.ts
export default defineEventHandler(async (event) => {
  const body = (await readBody(event)) as { name: string; email: string }
  return updateUser(getRouterParam(event, 'id')!, body)
})

// ✅ with zod (already a project dependency)
import { z } from 'zod'
const Params = z.object({ id: z.string().regex(/^\d+$/) })
const Body = z.object({ name: z.string().trim().min(1).max(100), email: z.string().email() })

export default defineEventHandler(async (event) => {
  const { id } = await getValidatedRouterParams(event, Params.parse)
  const body = await readValidatedBody(event, Body.parse)
  return updateUser(id, body)
})

// ✅ without a schema library
function isProfileUpdate(v: unknown): v is { name: string; email: string } {
  return typeof v === 'object' && v !== null
    && typeof (v as Record<string, unknown>).name === 'string'
    && typeof (v as Record<string, unknown>).email === 'string'
}
const body = await readValidatedBody(event, isProfileUpdate)
```

**Applies:** Nuxt ≥ 3.0 (h3 ≥ 1.8 validated readers) · **Exceptions:** none for data used in logic, queries, file paths, URLs or responses.

---

### VUE-NUXT-012 · Signal failures with `createError` and the right status; don't leak internals  `warn`

**Why:**
- Returning `{ error: '…' }` with status 200 makes failures look like successes to `useFetch` (whose `error` stays empty), to caches and to monitoring.
- Throw `createError({ statusCode, statusMessage })` with the correct 4xx/5xx code.
- Don't put stack traces, SQL or internal messages in client-visible responses (`data` and `message` reach the client).

**Source:** https://nuxt.com/docs/4.x/api/utils/create-error · https://nuxt.com/docs/4.x/getting-started/error-handling

```ts
// ❌
if (!user) return { error: 'not found' }
catch (e) { throw createError({ statusCode: 500, statusMessage: String(e) }) }

// ✅
if (!user) throw createError({ statusCode: 404, statusMessage: 'User not found' })
catch (e) { console.error(e); throw createError({ statusCode: 500, statusMessage: 'Could not update user' }) }
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** endpoints whose documented contract returns domain results (e.g. validation messages for a form) with an appropriate 4xx status.

---

### VUE-NUXT-013 · Enforce authentication and authorization on the server, in every handler that needs it  `error`

**Why:**
- Route middleware, hidden buttons and `v-if="isAdmin"` only shape the UI. Anyone can call `/api/...` directly.
- Each server handler (or a server middleware that sets `event.context.user`, plus a check in the handler) must check *who* is calling **and** whether they may access *this* resource. Checking ownership as well as role prevents IDOR.

**Source:** https://nuxt.com/docs/4.x/directory-structure/server#server-middleware · https://owasp.org/Top10/A01_2021-Broken_Access_Control/

```ts
// ❌ relies on the page's route middleware
export default defineEventHandler(async (event) => {
  return getInvoice(getRouterParam(event, 'id')!)
})

// ✅
export default defineEventHandler(async (event) => {
  const user = event.context.user // set by server/middleware/auth.ts from the session cookie
  if (!user) throw createError({ statusCode: 401, statusMessage: 'Unauthorized' })
  const { id } = await getValidatedRouterParams(event, Params.parse)
  const invoice = await getInvoice(id)
  if (!invoice || invoice.ownerId !== user.id) throw createError({ statusCode: 404, statusMessage: 'Not found' })
  return invoice
})
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** deliberately public endpoints. Make that explicit (e.g. a comment), and still validate input.

---

### VUE-NUXT-014 · Read configuration with `useRuntimeConfig`, not `process.env`  `warn`

**Why:**
- `process.env.X` in app code is replaced or empty after the build. On the client it doesn't exist.
- Runtime config is overridable per deployment with `NUXT_`-prefixed env vars (e.g. `NUXT_API_SECRET` → `runtimeConfig.apiSecret`). Default values that read a *differently named* env var only work at build time.
- On the server, pass `event` (`useRuntimeConfig(event)`) so runtime overrides apply.

**Source:** https://nuxt.com/docs/4.x/guide/going-further/runtime-config

```ts
// ❌ server/api/weather.get.ts
const key = process.env.WEATHER_KEY

// ✅ nuxt.config.ts
export default defineNuxtConfig({ runtimeConfig: { weatherKey: '', public: { apiBase: '/api' } } })
// server handler
const { weatherKey } = useRuntimeConfig(event) // set via NUXT_WEATHER_KEY
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** `nuxt.config.ts` itself (build-time) may read `process.env`, and so may build tooling.

---

### VUE-NUXT-015 · Never put secrets in `runtimeConfig.public` or `app.config`  `error`

**Why:** Everything under `runtimeConfig.public` (and all of `app.config.ts`) is sent to the browser and visible in the page payload. API keys, tokens, DB URLs and signing secrets must stay in private `runtimeConfig` keys and only be read in `server/` code.
**Source:** https://nuxt.com/docs/4.x/guide/going-further/runtime-config#exposing · https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html

```ts
// ❌
runtimeConfig: { public: { stripeSecretKey: '', openaiKey: '' } }

// ✅
runtimeConfig: {
  stripeSecretKey: '', // server only (NUXT_STRIPE_SECRET_KEY)
  public: { stripePublishableKey: '' }, // designed to be public
}
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** values that are public by design (publishable keys, public site URLs, analytics site IDs).

---

### VUE-NUXT-016 · In route middleware, return `navigateTo()`/`abortNavigation()`; treat it as UX, not security  `warn`

**Why:**
- Route middleware decides navigation by its **return value**. Calling `router.push` inside it, or `navigateTo` without returning it, starts a second navigation while the first continues.
- Route middleware runs on the client and can be bypassed, so it's not access control. The server must check too (VUE-NUXT-013).

**Source:** https://nuxt.com/docs/4.x/directory-structure/app/middleware · https://nuxt.com/docs/4.x/api/utils/navigate-to

```ts
// ❌ app/middleware/auth.ts
export default defineNuxtRouteMiddleware((to) => {
  const { loggedIn } = useUserSession()
  if (!loggedIn.value) useRouter().push('/login')
})

// ✅
export default defineNuxtRouteMiddleware((to) => {
  const { loggedIn } = useUserSession()
  if (!loggedIn.value) return navigateTo({ path: '/login', query: { next: to.fullPath } })
})
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** none.

---

### VUE-NUXT-017 · Suffix environment-specific plugins `.client`/`.server`  `warn`

**Why:** Plugins run on both server and client by default. A plugin that touches `window`, analytics SDKs or browser-only libraries crashes the server render, and a server-only plugin leaks into the client bundle. The `.client.ts`/`.server.ts` suffix limits where it runs, and `import.meta.client` handles the occasional branch.
**Source:** https://nuxt.com/docs/4.x/directory-structure/app/plugins

```
❌ app/plugins/analytics.ts         (uses window.dataLayer)
✅ app/plugins/analytics.client.ts
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** universal plugins that are SSR-safe.
