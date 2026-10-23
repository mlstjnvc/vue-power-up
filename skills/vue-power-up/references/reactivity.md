# Reactivity (`VUE-REACT-*`)

Rules for `ref`, `reactive`, `computed` and watchers: how to keep state reactive, keep derived state declarative, and keep side effects under control.

---

### VUE-REACT-001 · Don't destructure reactive objects without `toRefs`  `error`

**Why:** Destructuring a `reactive()` object (or, before Vue 3.5, props) copies the current values into plain variables. They stop updating, and the UI silently shows stale data.
**Source:** https://vuejs.org/guide/essentials/reactivity-fundamentals.html#limitations-of-reactive

```ts
// ❌
const state = reactive({ count: 0, name: '' })
const { count } = state // a plain number, never updates

// ✅
const { count, name } = toRefs(state) // Ref<number>, Ref<string>, linked to state
```

**Applies:** Vue ≥ 3.0 · **Exceptions:**
- Props destructured in `<script setup>` on **Vue ≥ 3.5** stay reactive (the compiler rewrites access to `props.x`). Pass them to watchers and composables as getters (`() => x`), see VUE-REACT-007.
- Destructuring to read a value once (e.g. for an initial value) is fine when that's the intent.
- For Pinia stores, see `VUE-PINIA-*` (`storeToRefs`).

---

### VUE-REACT-002 · Don't replace a `reactive()` object; mutate it, or use a `ref`  `error`

**Why:** Reassigning the variable that holds a `reactive()` proxy breaks the connection. Templates, computeds and watchers keep tracking the *old* proxy.
**Source:** https://vuejs.org/guide/essentials/reactivity-fundamentals.html#limitations-of-reactive

```ts
// ❌
let filters = reactive({ status: 'all', q: '' })
function reset() { filters = reactive({ status: 'all', q: '' }) }

// ✅ ref: replace the whole value freely
const filters = ref({ status: 'all', q: '' })
function reset() { filters.value = { status: 'all', q: '' } }

// ✅ reactive: mutate in place
const form = reactive({ status: 'all', q: '' })
function resetForm() { Object.assign(form, { status: 'all', q: '' }) }
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** none.

---

### VUE-REACT-003 · Use `.value` for refs in script  `error`

**Why:**
- In `<script>` a ref is an object, so `if (isOpen)` is always true and `count + 1` is string concatenation or `NaN`.
- Templates unwrap top-level refs automatically, which makes this an easy mistake when moving code from the template into script.

**Source:** https://vuejs.org/guide/essentials/reactivity-fundamentals.html#declaring-reactive-state

```ts
// ❌
const isOpen = ref(false)
if (isOpen) close()
const next = count + 1

// ✅
if (isOpen.value) close()
const next = count.value + 1
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** refs nested inside a `reactive()` object are unwrapped (`state.count`, not `state.count.value`).

---

### VUE-REACT-004 · Prefer `ref()` as the default state primitive  `info`

**Why:**
- The Vue docs recommend `ref()` as the primary API.
- It works for any value type, can be reassigned, and survives destructuring and passing into functions.
- `reactive()` has these limits (VUE-REACT-001, VUE-REACT-002) and only holds objects.

**Source:** https://vuejs.org/guide/essentials/reactivity-fundamentals.html#limitations-of-reactive

**Applies:** Vue ≥ 3.0 · **Exceptions:** grouped form state that's always mutated in place, and never reassigned or destructured, is a reasonable use of `reactive()`. Follow the project's existing style.

---

### VUE-REACT-005 · Derive state with `computed`, not `watch` + a copied `ref`  `warn`

**Why:**
- Copying a derived value into a ref and syncing it from a watcher adds a moment where the two disagree, and more code to keep in sync.
- `computed` is declarative, cached and always consistent with its sources.

**Source:** https://vuejs.org/guide/essentials/computed.html · https://vuejs.org/guide/essentials/watchers.html

```ts
// ❌
const visible = ref<Todo[]>([])
watch(() => [todos.value, filter.value], () => {
  visible.value = todos.value.filter((t) => matches(t, filter.value))
}, { immediate: true })

// ✅
const visible = computed(() => todos.value.filter((t) => matches(t, filter.value)))
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** derived state that needs async work (fetching) belongs in a watcher or a data-fetching composable. A computed must stay synchronous.

---

### VUE-REACT-006 · Keep `computed` getters pure  `warn`

**Why:** A computed getter can run at any time, or not at all (it's cached and lazy). Side effects inside it (mutating state, fetching, touching the DOM, emitting) happen unpredictably and can cause update loops. Don't mutate a computed's returned value either; it's derived, so edit the sources instead.
**Source:** https://vuejs.org/guide/essentials/computed.html#best-practices

```ts
// ❌
const total = computed(() => {
  cart.lastCalculated = Date.now() // side effect
  return items.value.reduce((s, i) => s + i.price, 0)
})
const sorted = computed(() => items.value.sort(byName)) // sort() mutates the source

// ✅
const total = computed(() => items.value.reduce((s, i) => s + i.price, 0))
const sorted = computed(() => [...items.value].sort(byName))
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** writable computeds (`get`/`set`) may update their sources in `set`.

---

### VUE-REACT-007 · Watch props and reactive properties through a getter  `error`

**Why:** `watch(props.id, …)` or `watch(state.count, …)` passes a *plain value* that was read once, so the watcher never fires. The same applies to a destructured prop on Vue 3.5. Watch a getter (or a ref, or a whole reactive object).
**Source:** https://vuejs.org/guide/essentials/watchers.html#watch-source-types

```ts
// ❌
watch(props.userId, load)
const { userId } = defineProps<{ userId: string }>()
watch(userId, load) // passes the current string, not a source (the 3.5 compiler warns)

// ✅
watch(() => props.userId, load)
watch(() => userId, load) // destructured prop (Vue ≥ 3.5)
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** none.

---

### VUE-REACT-008 · Clean up side effects started by watchers and components  `error`

**Why:**
- An async watcher that fetches on every change can let a slow, stale response overwrite a newer one (a race).
- Timers, listeners and subscriptions not removed on unmount leak and keep firing.
- Cancel previous work in the watcher's cleanup, and tear down in `onUnmounted` (or `onScopeDispose` in composables, see `VUE-CMPS-*`).

**Source:** https://vuejs.org/guide/essentials/watchers.html#side-effect-cleanup · https://vuejs.org/guide/essentials/lifecycle.html

```ts
// ❌
watch(query, async (q) => {
  results.value = await search(q) // older request may resolve last
})
onMounted(() => window.addEventListener('resize', onResize)) // never removed

// ✅ Vue ≥ 3.5
watch(query, async (q) => {
  const controller = new AbortController()
  onWatcherCleanup(() => controller.abort())
  results.value = await search(q, { signal: controller.signal })
})
// ✅ Vue < 3.5: third callback argument
watch(query, async (q, _old, onCleanup) => {
  const controller = new AbortController()
  onCleanup(() => controller.abort())
  results.value = await search(q, { signal: controller.signal })
})
onMounted(() => window.addEventListener('resize', onResize))
onUnmounted(() => window.removeEventListener('resize', onResize))
```

**Applies:** Vue ≥ 3.0 (`onWatcherCleanup`: Vue ≥ 3.5) · **Exceptions:**
- `onWatcherCleanup` must be called before the first `await`. Register the abort first, as shown.
- A composable such as VueUse's `useEventListener` that cleans up for you satisfies this rule.

---

### VUE-REACT-009 · Create watchers synchronously in setup  `warn`

**Why:** Watchers created synchronously in `setup` are bound to the component and stop when it unmounts. A watcher created inside an async callback (after an `await`, or in a `setTimeout`) isn't bound, so it outlives the component and leaks unless it's stopped by hand.
**Source:** https://vuejs.org/guide/essentials/watchers.html#stopping-a-watcher

```ts
// ❌
onMounted(async () => {
  await loadConfig()
  watch(source, handler) // never stopped
})

// ✅ create it synchronously and make it conditional instead
watch(source, (value) => { if (configLoaded.value) handler(value) })
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** an async-created watcher whose returned stop handle is called on unmount.

---

### VUE-REACT-010 · Avoid `deep: true` on large or broad structures  `warn`

**Why:** A deep watcher walks every nested property on each change, which costs a lot on large data. It also fires on changes you don't care about. Watch the specific property through a getter, or limit the depth.
**Source:** https://vuejs.org/guide/essentials/watchers.html#deep-watchers

```ts
// ❌
watch(settings, save, { deep: true }) // whole settings tree, every nested change

// ✅
watch(() => settings.value.theme, save)
watch(() => [settings.value.locale, settings.value.timezone], save)
// ✅ Vue ≥ 3.5: bounded depth
watch(settings, save, { deep: 1 })
```

**Applies:** Vue ≥ 3.0 (numeric `deep`: Vue ≥ 3.5) · **Exceptions:**
- small objects where any change matters (e.g. a form model of a few fields saved as a whole)
- watching a `reactive()` object directly, which is deep by design.
