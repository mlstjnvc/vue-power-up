# Composables (`VUE-CMPS-*`)

Rules for writing and calling composables: functions that hold stateful logic using the Composition API.

---

### VUE-CMPS-001 · Name composables `useXxx`, in a `useXxx.ts` file  `warn`

**Why:** The `use` prefix tells readers, tooling and Nuxt auto-imports that the function holds reactive state or lifecycle hooks and must follow the composable call rules (VUE-CMPS-004). A plain `formatUser()` doesn't need the prefix. A stateful `userList()` does.
**Source:** https://vuejs.org/guide/reusability/composables.html#conventions-and-best-practices

```ts
// ❌ src/composables/mouse.ts
export function mousePosition() { /* refs + listeners */ }

// ✅ src/composables/useMouse.ts
export function useMouse() { /* refs + listeners */ }
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** pure utilities with no reactivity or lifecycle shouldn't take the prefix.

---

### VUE-CMPS-002 · Accept refs and getters (`MaybeRefOrGetter`) and read them with `toValue` inside reactive scopes  `warn`

**Why:** A composable that takes a plain value reads it once, and later changes to the caller's ref or prop are ignored. Accepting `MaybeRefOrGetter<T>` and calling `toValue()` *inside* a `watch`/`watchEffect`/`computed` lets callers pass a value, a ref or a getter (`() => props.id`), and the composable stays reactive to it.
**Source:** https://vuejs.org/guide/reusability/composables.html#input-arguments · https://vuejs.org/api/reactivity-utilities.html#tovalue

```ts
// ❌
export function useUser(id: string) {
  const user = ref<User | null>(null)
  fetchUser(id).then((u) => (user.value = u)) // never refetches
  return { user }
}

// ✅
export function useUser(id: MaybeRefOrGetter<string>) {
  const user = ref<User | null>(null)
  watchEffect(async () => {
    user.value = await fetchUser(toValue(id)) // tracked: refetches when id changes
  })
  return { user }
}
// caller: useUser(() => props.userId)
```

**Applies:** Vue ≥ 3.3 (`toValue`, `MaybeRefOrGetter`) · **Exceptions:**
- Arguments that are deliberately read once (e.g. an options object) can stay plain.
- Below 3.3 use `MaybeRef` + `unref`.
- Combine this rule with VUE-REACT-008 (cancel stale requests).

---

### VUE-CMPS-003 · Return a plain object of refs  `warn`

**Why:** Returning `reactive({...})` means callers lose reactivity as soon as they destructure (VUE-REACT-001). A plain object whose properties are refs can be destructured safely (`const { x, y } = useMouse()`). Callers who want property access can wrap it in `reactive()` themselves.
**Source:** https://vuejs.org/guide/reusability/composables.html#return-values

```ts
// ❌
return reactive({ data, error, loading })

// ✅
return { data, error, loading } // all refs; readonly() them if callers shouldn't write
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** composables that return a single value may return the ref directly.

---

### VUE-CMPS-004 · Call composables synchronously in `<script setup>` / `setup()`  `error`

**Why:**
- Composables register lifecycle hooks, watchers and `inject()` calls against the *current component instance*, which only exists during synchronous setup.
- Called inside an event handler, a `setTimeout` or after an `await`, they run with no instance. Hooks silently don't register, `inject()` fails, watchers leak, and in Nuxt the app context is lost ("a composable that requires access to the Nuxt instance…").

**Source:** https://vuejs.org/guide/reusability/composables.html#usage-restrictions

```ts
// ❌
async function onOpen() {
  const { data } = useUser(id) // no active instance
}

// ✅
const { data, refresh } = useUser(id) // top level of setup
async function onOpen() { await refresh() }
```

**Applies:** Vue ≥ 3.0 · **Exceptions:**
- Composables documented as callable anywhere (pure ones without hooks or inject).
- In `<script setup>`, code after a top-level `await` keeps the instance, because the compiler restores it. Inside nested async functions it doesn't.

---

### VUE-CMPS-005 · Clean up a composable's side effects with `onScopeDispose`  `warn`

**Why:** A composable that adds listeners, intervals, observers or subscriptions must remove them when its owner goes away. `onScopeDispose` works both in components and inside a detached `effectScope()`. `onUnmounted` only works in components.
**Source:** https://vuejs.org/api/reactivity-advanced.html#onscopedispose · https://vuejs.org/guide/reusability/composables.html#side-effects

```ts
// ❌
export function useWindowWidth() {
  const width = ref(window.innerWidth)
  window.addEventListener('resize', () => (width.value = window.innerWidth))
  return { width }
}

// ✅
export function useWindowWidth() {
  const width = ref(0)
  const update = () => (width.value = window.innerWidth)
  onMounted(() => { update(); window.addEventListener('resize', update) })
  onScopeDispose(() => window.removeEventListener('resize', update))
  return { width }
}
```

**Applies:** Vue ≥ 3.2 · **Exceptions:** helpers that handle cleanup themselves (e.g. VueUse `useEventListener`).

---

### VUE-CMPS-006 · Keep UI side effects out of data composables; expose state instead  `info`

**Why:** A data composable that shows toasts, opens dialogs, calls `alert()` or navigates decides the UI for every caller. Callers can't show the error inline, suppress it in a background refresh, or test the composable without a UI. Expose `error`/`status` and let the component decide.
**Source:** https://vuejs.org/guide/reusability/composables.html#async-state-example

```ts
// ❌
catch (e) { toast.error('Could not load orders') }

// ✅
catch (e) { error.value = e instanceof Error ? e : new Error(String(e)) }
// component: <ErrorBanner v-if="error" :error="error" />
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** composables whose *purpose* is UI (`useToast`, `useConfirmDialog`, `useNavigation`).

---

### VUE-CMPS-007 · Expose loading and error state from async composables  `warn`

**Why:** An async composable that only returns `data` forces callers to guess whether it's still loading or has failed. Swallowing errors with `console.error` makes failures invisible. Return `error` (and `loading`/`status`) alongside the data, as the docs' async example does.
**Source:** https://vuejs.org/guide/reusability/composables.html#async-state-example

```ts
// ❌
export function useOrders() {
  const orders = ref<Order[]>([])
  fetchOrders().then((o) => (orders.value = o)).catch(console.error)
  return { orders }
}

// ✅
export function useOrders() {
  const orders = ref<Order[]>([])
  const error = ref<Error | null>(null)
  const loading = ref(true)
  fetchOrders()
    .then((o) => (orders.value = o))
    .catch((e) => (error.value = e instanceof Error ? e : new Error(String(e))))
    .finally(() => (loading.value = false))
  return { orders, error, loading }
}
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** in Nuxt, prefer `useFetch`/`useAsyncData`, which already return `status` and `error` (see `VUE-NUXT-*`).

---

### VUE-CMPS-008 · Don't touch browser-only APIs during setup in SSR apps  `error`

**Why:**
- In SSR (Nuxt, or a Vite SSR setup), `setup` and composable bodies run on the server, where `window`, `document`, `localStorage` and `navigator` don't exist. The request crashes with `window is not defined`.
- Access them in `onMounted` (which runs only on the client), or behind `import.meta.client` in Nuxt.
- Initial values that differ between server and client also cause hydration mismatches.

**Source:** https://vuejs.org/guide/scaling-up/ssr.html#access-to-platform-specific-apis · https://nuxt.com/docs/4.x/guide/concepts/rendering#universal-rendering

```ts
// ❌ (SSR)
const theme = ref(localStorage.getItem('theme') ?? 'light')

// ✅
const theme = ref('light')
onMounted(() => { theme.value = localStorage.getItem('theme') ?? 'light' })
// ✅ Nuxt: SSR-friendly persisted value
const themeCookie = useCookie<'light' | 'dark'>('theme', { default: () => 'light' })
```

**Applies:** SSR apps only (Nuxt with `ssr` not `false`, Vite SSR). In SPA-only projects, don't flag · **Exceptions:**
- code inside `onMounted`/`onBeforeMount`, event handlers, `<ClientOnly>`, `.client.vue` components or `.client.ts` plugins
- Nuxt `ssr: false` (whole app or route rule).

---

### VUE-CMPS-009 · Don't keep per-user state in module scope in SSR apps  `error`

**Why:**
- On the server, a module is evaluated **once** and shared by every request.
- A `const user = ref(null)` at module scope (outside the composable function) is shared across all concurrent users. One user's data leaks into another user's rendered page: cross-request state pollution.
- In Nuxt use `useState`, Pinia (`VUE-PINIA-*`) or `useAsyncData`. In other SSR setups, create state per app instance.

**Source:** https://vuejs.org/guide/scaling-up/ssr.html#cross-request-state-pollution · https://nuxt.com/docs/4.x/getting-started/state-management

```ts
// ❌ composables/useCurrentUser.ts (SSR)
const user = ref<User | null>(null) // module scope: shared by all requests
export function useCurrentUser() { return { user } }

// ✅ Nuxt
export function useCurrentUser() {
  const user = useState<User | null>('current-user', () => null) // per request, hydrated to client
  return { user }
}
```

**Applies:** SSR apps only. In an SPA, module-scope refs are a legitimate shared-state pattern · **Exceptions:** module-scope *constants* and caches holding non-user-specific, immutable data.
