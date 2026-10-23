# Pinia (`VUE-PINIA-*`)

Rules for defining and using Pinia stores in Vue and Nuxt.

**Choosing a syntax:** option stores and setup stores are both official. Pinia's docs say to pick whichever feels more comfortable: option stores are simpler, setup stores more flexible.
- **Existing project:** match its stores.
- **New project:** setup stores mirror `<script setup>` and work naturally with composables. Use them unless the project says otherwise.

**When a store is the right tool:** use a store for state shared across distant components or pages, or state that must survive navigation. State used by one component (or one parent and its children) belongs in local `ref`s, props or provide/inject. That's a judgement call, not a rule.

---

### VUE-PINIA-001 · Destructure store state and getters with `storeToRefs`  `error`

**Why:** A store is a `reactive` object. Plain destructuring copies the current values, so components silently stop updating (the same failure as VUE-REACT-001). `storeToRefs` creates refs for state and getters. Actions are bound functions and can be destructured directly.
**Source:** https://pinia.vuejs.org/core-concepts/#Destructuring-from-a-Store

```ts
// ❌
const { items, total } = useCartStore()

// ✅
const cart = useCartStore()
const { items, total } = storeToRefs(cart)
const { addItem, removeItem } = cart // actions: destructure directly
// ✅ also fine: no destructuring
cart.total
```

**Applies:** Pinia ≥ 2.0 · **Exceptions:**
- Reading a value once on purpose (`const { locale } = useSettingsStore()` to build a one-off URL).
- `toRefs(store)` is wrong too, because it also wraps actions and internals. Use `storeToRefs`.

---

### VUE-PINIA-002 · Return every state property from a setup store  `error`

**Why:** In a setup store, Pinia only treats the `ref`s you **return** as state. A ref left out of the return value isn't serialized for SSR hydration, isn't visible in devtools, and is ignored by plugins (persistence, `$reset`, `$subscribe`). Pinia's docs: "Not returning all state properties or making them readonly will break SSR, devtools, and other plugins." Stores can't have private state.
**Source:** https://pinia.vuejs.org/core-concepts/#Setup-Stores

```ts
// ❌
export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const token = ref<string | null>(null) // "private" — not returned
  const isLoggedIn = computed(() => !!user.value)
  return { user, isLoggedIn }
})

// ✅
export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const isLoggedIn = computed(() => !!user.value)
  async function login(credentials: Credentials) { /* … */ }
  return { user, isLoggedIn, login }
})
```

**Applies:** Pinia ≥ 2.0 (setup stores) · **Exceptions:**
- Truly private, non-reactive data can live in a module-scope constant or a separate composable.
- Don't keep secrets such as tokens in client-side store state at all. See `VUE-SEC-*`.

---

### VUE-PINIA-003 · Call `useStore()` inside setup, actions, getters or functions, never at module top level  `error`

**Why:**
- A `useStore()` at the top level of a module runs on import, which can be *before* `app.use(pinia)`. In an SPA that throws ("getActivePinia was called with no active Pinia").
- In SSR it can also bind to the wrong request's pinia instance, which mixes users' state.
- In router guards, plugins and other non-component code, call the store *inside* the function. In SSR, pass the request's `pinia`.
- Inside async actions, call other stores **before** the first `await`.

**Source:** https://pinia.vuejs.org/core-concepts/outside-component-usage.html · https://pinia.vuejs.org/cookbook/composing-stores.html#Shared-Actions

```ts
// ❌ router.ts
const auth = useAuthStore()
router.beforeEach((to) => { if (to.meta.requiresAuth && !auth.isLoggedIn) return '/login' })

// ✅
router.beforeEach((to) => {
  const auth = useAuthStore() // pinia is installed by the time navigation runs
  if (to.meta.requiresAuth && !auth.isLoggedIn) return '/login'
})

// ✅ inside an action: other stores before any await
async function checkout() {
  const user = useUserStore()
  await api.checkout(user.id, items.value)
}
```

**Applies:** Pinia ≥ 2.0 · **Exceptions:** none. In Nuxt, stores used in route middleware or plugins are called inside the handler, where the Nuxt app provides pinia.

---

### VUE-PINIA-004 · Don't let two stores read each other's state in their setup functions  `error`

**Why:** If store A reads store B's state while A is being created, and B does the same with A, store creation recurses until it crashes. Reading another store inside getters, computeds and actions is fine.
**Source:** https://pinia.vuejs.org/cookbook/composing-stores.html

```ts
// ❌
export const useA = defineStore('a', () => {
  const b = useB()
  const label = ref(b.name) // reads B's state during A's setup
  return { label }
})
export const useB = defineStore('b', () => {
  const a = useA()
  const name = ref(a.label) // and vice versa → infinite recursion
  return { name }
})

// ✅ read lazily
export const useA = defineStore('a', () => {
  const b = useB()
  const label = computed(() => b.name)
  return { label }
})
```

**Applies:** Pinia ≥ 2.0 · **Exceptions:** one-directional dependencies (A uses B, B never uses A) can read state at setup.

---

### VUE-PINIA-005 · Keep store state serializable in SSR apps  `warn`

**Why:** In SSR, Pinia's state is serialized into the HTML and hydrated on the client (Nuxt uses `devalue`, which handles `Date`, `Map`, `Set` and so on). Functions, class instances with methods, DOM nodes, sockets and third-party client objects can't survive this: they fail to serialize or come back as plain objects. Keep such objects outside state (module scope on the client only, or a composable) and store only plain data.
**Source:** https://pinia.vuejs.org/ssr/#State-hydration

```ts
// ❌
const socket = ref(new WebSocket(url))
const map = ref(new mapboxgl.Map(opts))

// ✅ plain data in state; instance created client-side outside the store state
const connected = ref(false)
```

**Applies:** Pinia ≥ 2.0 in SSR apps (Nuxt with SSR, Vite SSR) · **Exceptions:** SPA-only projects. Pinia's `skipHydrate()` for state that must deliberately not be hydrated.

---

### VUE-PINIA-006 · In Nuxt, load store data with `callOnce`/`useAsyncData`, not `onMounted`  `warn`

**Why:**
- `onMounted` only runs on the client. Data fetched there is missing from the server-rendered HTML (empty content, layout shift, worse SEO), and the fetch waits for hydration.
- `await callOnce('key', () => store.fetchX())` runs the action once during SSR, and the state is hydrated to the client. `{ mode: 'navigation' }` refetches on every navigation.
- `useAsyncData('key', () => store.fetchX())` works too, and gives `status`/`error`.

**Source:** https://pinia.vuejs.org/ssr/nuxt.html#Awaiting-for-actions-in-pages · https://nuxt.com/docs/4.x/api/utils/call-once

```ts
// ❌ pages/profile.vue
const user = useUserStore()
onMounted(() => user.fetchProfile())

// ✅
const user = useUserStore()
await callOnce('user-profile', () => user.fetchProfile())
```

**Applies:** Nuxt ≥ 3.9 (`callOnce`; `mode: 'navigation'` needs ≥ 3.15) with `@pinia/nuxt` · **Exceptions:**
- Data that's intentionally client-only (user-specific widgets on a cached public page).
- `ssr: false` routes.

---

### VUE-PINIA-007 · Put multi-step state changes in actions  `info`

**Why:**
- Direct mutation (`store.count++`) is allowed and fine for single fields.
- A business operation that touches several fields, calls an API or must stay consistent belongs in an action. That keeps it in one place, testable, visible as one unit in devtools, and safe from components updating half the state.
- For grouped ad-hoc updates, use `store.$patch({ … })`.

**Source:** https://pinia.vuejs.org/core-concepts/actions.html · https://pinia.vuejs.org/core-concepts/state.html#Mutating-the-state

```ts
// ❌ component
cart.items.push(item); cart.total += item.price; cart.updatedAt = Date.now()

// ✅ store action
function addItem(item: Item) {
  items.value.push(item)
  updatedAt.value = Date.now()
} // total as a computed
```

**Applies:** Pinia ≥ 2.0 · **Exceptions:** single-field UI state (toggles, filters).
