# Component Design (`VUE-COMP-*`)

Rules for component APIs (props, events, v-model, exposed methods), component boundaries and SFC conventions.

---

### VUE-COMP-001 · Implement `v-model` with `defineModel`  `warn`

**Why:** Hand-written `modelValue` prop + `update:modelValue` emit plus a local copy is five or more lines per binding, and the local copy easily goes out of sync with the parent. `defineModel` returns a ref that reads the prop and emits on write, so there's nothing to keep in sync.
**Source:** https://vuejs.org/guide/components/v-model.html

```ts
// ❌
const props = defineProps<{ modelValue: string }>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
const value = computed({
  get: () => props.modelValue,
  set: (v) => emit('update:modelValue', v),
})

// ✅
const value = defineModel<string>({ required: true })
// named models: <UserForm v-model:first-name="first" v-model:last-name="last" />
const firstName = defineModel<string>('firstName', { default: '' })
```

**Applies:** Vue ≥ 3.4 · **Exceptions:**
- Vue < 3.4: use the prop + emit pair (a `computed` getter/setter as above is the correct pre-3.4 form).
- Components that need to transform the value *both* ways and keep both forms. Use `defineModel` with `get`/`set` options, or the explicit pair.

---

### VUE-COMP-002 · Never mutate props  `error`

**Why:** Props are one-way: the parent owns the data. Assigning to a prop fails with a warning in development and is ignored. Mutating a nested object or array prop *works* but changes the parent's state behind its back, which makes data flow impossible to follow.
**Source:** https://vuejs.org/guide/components/props.html#one-way-data-flow

```ts
// ❌
const props = defineProps<{ items: Item[]; count: number }>()
props.count++
props.items.push(newItem)

// ✅ ask the parent to change it
const emit = defineEmits<{ add: [item: Item] }>()
emit('add', newItem)

// ✅ or own a local copy that starts from the prop
const draft = ref<Item[]>(structuredClone(toRaw(props.items)))

// ✅ or a two-way binding (VUE-COMP-001)
const items = defineModel<Item[]>('items', { required: true })
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** none. If a child must edit an object, use `defineModel` and assign a *new* value (`items.value = [...items.value, newItem]`).

---

### VUE-COMP-003 · Use multi-word component names  `warn`

**Why:** Single-word names (`Item`, `Table`, `Header`) can collide with current or future HTML elements, which are all single words. Official style guide: *Essential*.
**Source:** https://vuejs.org/style-guide/rules-essential.html#use-multi-word-component-names

```
❌ components/Item.vue, components/Header.vue
✅ components/TodoItem.vue, components/AppHeader.vue
```

**Applies:** Vue ≥ 3.0 · **Exceptions:**
- the root `App.vue`
- Nuxt route and layout files (`pages/index.vue`, `pages/[id].vue`, `layouts/default.vue`), whose names are routes, not component tags
- Vue built-ins.

---

### VUE-COMP-004 · Name SFC files and template component tags in PascalCase  `info`

**Why:** PascalCase file names make components easy to find and match their import names. PascalCase tags in SFC templates set components apart from native elements. Official style guide: *Strongly recommended*. It's still a style choice, so the project's existing convention wins.
**Source:** https://vuejs.org/style-guide/rules-strongly-recommended.html#single-file-component-filename-casing · https://vuejs.org/style-guide/rules-strongly-recommended.html#component-name-casing-in-templates

```vue
<!-- ✅ -->
<UserAvatar :user="user" />
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** Nuxt `pages/`, `layouts/` and `middleware/` files, which follow route and file conventions. Projects that consistently use kebab-case.

---

### VUE-COMP-005 · Keep the component API to props, events, slots and `v-model`; use `defineExpose` only for imperative actions  `info`

**Why:** A parent that reads or writes a child's internal state through a template ref couples the two tightly and gets around the one-way data flow. `defineExpose` is meant for imperative actions that props can't express well: `focus()`, `reset()`, `scrollToTop()`.
**Source:** https://vuejs.org/api/sfc-script-setup.html#defineexpose

```ts
// ❌ exposing state for the parent to manipulate
defineExpose({ formData, errors })

// ✅
defineExpose({ focus: () => input.value?.focus(), reset })
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** none.

---

### VUE-COMP-006 · Split components that mix several responsibilities; extract logic into composables  `info`

**Why:** A component that fetches data, holds business rules *and* renders a large template is hard to test and reuse. Moving stateful logic into a composable (`use*`) groups it by concern. Splitting markup into child components keeps each template readable. These are guidelines rather than hard limits: a 150-line SFC with one clear job is fine.
**Source:** https://vuejs.org/guide/reusability/composables.html#extracting-composables-for-code-organization

```
✅ OrdersPage.vue        → layout + wiring
   OrdersFilters.vue     → filter controls (v-model)
   OrdersTable.vue       → presentation
   useOrders.ts          → fetching, paging, filtering state
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** don't extract one-off logic just to shorten a file. Extract when it's reused or forms a clear unit.

---

### VUE-COMP-007 · Avoid prop drilling through intermediate components  `info`

**Why:** Passing a prop through components that don't use it, just to reach a deep descendant, couples every layer to data it doesn't care about. Use provide/inject (typed, `VUE-TS-007`) for subtree-scoped context, or a Pinia store for app-wide state.
**Source:** https://vuejs.org/guide/components/provide-inject.html#prop-drilling

**Applies:** Vue ≥ 3.0 · **Exceptions:** one intermediate level is fine. Explicit props are easier to trace than injection for shallow trees.

---

### VUE-COMP-008 · Scope component styles  `warn`

**Why:** Unscoped styles in a component leak into the whole app, and later components break in ways that are hard to trace. Use `<style scoped>` or CSS modules. Official style guide: *Essential*.
**Source:** https://vuejs.org/style-guide/rules-essential.html#use-component-scoped-styling

```vue
<!-- ❌ -->
<style>.button { color: red }</style>

<!-- ✅ -->
<style scoped>.button { color: red }</style>
```

**Applies:** Vue ≥ 3.0 · **Exceptions:**
- `App.vue` and layouts holding deliberate global styles
- utility-CSS projects (e.g. Tailwind) with no component `<style>` block
- `:deep()` used on purpose to style child internals.

---

### VUE-COMP-009 · Order SFC blocks consistently: `<script setup>`, `<template>`, `<style>`  `info`

**Why:** A consistent block order makes files predictable to scan. The official style guide recommends `<script>` first, then `<template>`, then `<style>` last. The project's existing order wins.
**Source:** https://vuejs.org/style-guide/rules-recommended.html#single-file-component-top-level-element-order

**Applies:** Vue ≥ 3.0 · **Exceptions:** a project that consistently uses template-first.
