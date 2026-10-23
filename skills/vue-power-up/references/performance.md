# Performance (`VUE-PERF-*`)

Rules for avoiding needless reactivity and rendering work and for loading less JavaScript. Apply them where the cost is real: large data, long lists, heavy components. Never apply them at the expense of correctness. Watcher cost is in `reactivity.md` (VUE-REACT-010).

---

### VUE-PERF-001 · Use `shallowRef`/`markRaw` for large immutable data and third-party instances  `warn`

**Why:**
- `ref()` and `reactive()` make every nested property reactive.
- For large datasets that are replaced as a whole (API results, chart series, geo data), deep conversion costs CPU and memory for no gain.
- For third-party instances (map, chart, editor, SDK clients), deep proxies can break them, because libraries compare identities or mutate internals.
- Use `shallowRef` for the data (replace `.value` to update) and `markRaw` for instances.

**Source:** https://vuejs.org/guide/best-practices/performance.html#reduce-reactivity-overhead-for-large-immutable-structures · https://vuejs.org/api/reactivity-advanced.html#shallowref

```ts
// ❌
const rows = ref<Row[]>(await loadRows()) // 50k rows, deeply proxied
const map = ref(new maplibregl.Map(opts))

// ✅
const rows = shallowRef<Row[]>(await loadRows())
rows.value = [...rows.value, newRow] // replace to trigger
const map = shallowRef<maplibregl.Map | null>(null)
onMounted(() => { map.value = markRaw(new maplibregl.Map(opts)) })
```

**Applies:** Vue ≥ 3.0 · **Exceptions:**
- Small or frequently edited-in-place state (forms).
- Nuxt 4's `useFetch`/`useAsyncData` `data` is already shallow (VUE-NUXT-006).

---

### VUE-PERF-002 · Lazy-load heavy components that aren't needed for the first render  `info`

**Why:** Rich editors, charts, maps, modals and admin-only panels can make up most of a page's JavaScript. Loading them on demand shrinks the initial bundle. In Nuxt, prefix the component with `Lazy`. In plain Vue, use `defineAsyncComponent`. Routes are code-split automatically by Vue Router lazy routes and Nuxt pages.
**Source:** https://vuejs.org/guide/best-practices/performance.html#code-splitting · https://nuxt.com/docs/4.x/directory-structure/app/components#dynamic-imports

```vue
<!-- ✅ Nuxt -->
<LazyRichTextEditor v-if="editing" v-model="body" />

<!-- ✅ Vue -->
<script setup lang="ts">
const RichTextEditor = defineAsyncComponent(() => import('./RichTextEditor.vue'))
</script>
```

**Applies:** Vue ≥ 3.0, Nuxt ≥ 3.0 · **Exceptions:** small components, and components that are always visible above the fold.

---

### VUE-PERF-003 · Delay hydration of below-the-fold interactive components in SSR apps  `info`

**Why:** On an SSR page, every component hydrates on load even if it's far below the fold. Lazy hydration renders the HTML on the server but hydrates the component only when it's visible, idle, or interacted with, which cuts time-to-interactive.
**Source:** https://nuxt.com/docs/4.x/directory-structure/app/components#delayed-or-lazy-hydration · https://vuejs.org/guide/components/async.html#lazy-hydration

```vue
<!-- ✅ Nuxt -->
<LazyProductReviews hydrate-on-visible :product-id="id" />
<LazyNewsletterForm hydrate-on-interaction="focus" />
```

**Applies:** Nuxt ≥ 3.16 (`hydrate-*` props); Vue ≥ 3.5 (`hydrateOnVisible` etc. with `defineAsyncComponent`) · **Exceptions:** components that must be interactive immediately, and SPA-only projects.

---

### VUE-PERF-004 · Virtualize very long lists  `info`

**Why:** Rendering thousands of rows creates thousands of DOM nodes and component instances, which makes the page slow to render and scroll. Virtualization renders only the visible window. Use the project's existing virtual-list component, or propose one (it's a new dependency, so ask first). Pagination is often the simpler answer.
**Source:** https://vuejs.org/guide/best-practices/performance.html#virtualize-large-lists

**Applies:** Vue ≥ 3.0 · **Exceptions:** lists of a few hundred simple rows usually don't need it. Measure first.

---

### VUE-PERF-005 · Keep props stable for list items  `info`

**Why:** A child re-renders when any of its props change. Passing a value that changes for *every* item (e.g. `:active-id="activeId"`, so each item compares itself) re-renders the whole list on every selection. Passing the already-computed boolean (`:active="item.id === activeId"`) re-renders only the two items whose value changed.
**Source:** https://vuejs.org/guide/best-practices/performance.html#props-stability

```vue
<!-- ❌ --> <ListItem v-for="item in list" :key="item.id" :id="item.id" :active-id="activeId" />
<!-- ✅ --> <ListItem v-for="item in list" :key="item.id" :id="item.id" :active="item.id === activeId" />
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** short lists.

---

### VUE-PERF-006 · Use `v-once`/`v-memo` only for measured hot spots  `info`

**Why:** `v-once` renders static content once. `v-memo` skips re-rendering a subtree (typically huge `v-for` rows) unless its listed dependencies change. Both trade correctness risk for speed: a missing `v-memo` dependency shows stale UI. Use them only where profiling shows render cost.
**Source:** https://vuejs.org/guide/best-practices/performance.html#update-optimizations · https://vuejs.org/api/built-in-directives.html#v-memo

```vue
<div v-for="row in rows" :key="row.id" v-memo="[row.id === selectedId, row.updatedAt]">…</div>
```

**Applies:** Vue ≥ 3.2 (`v-memo`) · **Exceptions:** never use `v-memo` together with `v-for` on the *same* element.
