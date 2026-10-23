# Templates (`VUE-TPL-*`)

Rules for template directives, list rendering, template logic and basic accessibility. For untrusted data in `v-html` and URL attributes, see `security.md` (`VUE-SEC-*`).

---

### VUE-TPL-001 · Never put `v-if` and `v-for` on the same element  `error`

**Why:**
- In Vue 3, `v-if` has higher priority than `v-for` on the same element, so the condition can't see the loop variable. That's a runtime error, or a condition that's silently always undefined.
- Even when it works, it hides a filter that belongs in a `computed`.
- Official style guide: *Essential*.

**Source:** https://vuejs.org/guide/essentials/list.html#v-for-with-v-if · https://vuejs.org/style-guide/rules-essential.html#avoid-v-if-with-v-for

```vue
<!-- ❌ -->
<li v-for="user in users" v-if="user.active" :key="user.id">{{ user.name }}</li>

<!-- ✅ filter in script -->
<li v-for="user in activeUsers" :key="user.id">{{ user.name }}</li>
<!-- const activeUsers = computed(() => users.value.filter((u) => u.active)) -->

<!-- ✅ or hide the whole list: wrap -->
<template v-if="showList">
  <li v-for="user in users" :key="user.id">{{ user.name }}</li>
</template>
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** none.

---

### VUE-TPL-002 · Key `v-for` with a stable, unique id  `error`

**Why:**
- Without a key, or with the array index as the key, Vue reuses DOM nodes and component instances *by position*.
- When items are inserted, removed or reordered, input values, focus, transitions and child component state end up on the wrong item.

**Source:** https://vuejs.org/guide/essentials/list.html#maintaining-state-with-key · https://vuejs.org/style-guide/rules-essential.html#use-keyed-v-for

```vue
<!-- ❌ -->
<TodoItem v-for="(todo, i) in todos" :key="i" :todo="todo" />
<li v-for="todo in todos">{{ todo.title }}</li>

<!-- ✅ -->
<TodoItem v-for="todo in todos" :key="todo.id" :todo="todo" />
```

**Applies:** Vue ≥ 3.0 · **Exceptions:**
- Index or no key is fine for static lists that are never reordered, filtered, inserted into or removed from, *and* whose items hold no state (plain text rows).
- If items have no id, derive a stable one when loading the data, not at render time.

---

### VUE-TPL-003 · Keep template expressions simple; move logic to `computed`  `info`

**Why:** Long expressions in templates (chained filters, formatting, nested ternaries) are hard to read, can't be reused, and aren't cached. Official style guide: *Strongly recommended*.
**Source:** https://vuejs.org/style-guide/rules-strongly-recommended.html#simple-expressions-in-templates

```vue
<!-- ❌ -->
<p>{{ items.filter(i => i.done).length }} / {{ items.length }} ({{ Math.round(items.filter(i => i.done).length / items.length * 100) }}%)</p>

<!-- ✅ -->
<p>{{ doneCount }} / {{ items.length }} ({{ donePercent }}%)</p>
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** a short ternary or a single method call for formatting.

---

### VUE-TPL-004 · Don't call expensive or side-effecting functions in templates  `warn`

**Why:** Function calls in the template run again on **every** re-render of the component, unlike `computed`, which is cached until its dependencies change. Expensive work there slows every update. Side effects there (mutating state, logging, fetching) cause render loops or repeated requests.
**Source:** https://vuejs.org/guide/essentials/computed.html#computed-caching-vs-methods

```vue
<!-- ❌ -->
<Chart :data="buildChartData(rawRows)" />
<span>{{ markSeen(notification) }}</span>

<!-- ✅ -->
<Chart :data="chartData" />  <!-- const chartData = computed(() => buildChartData(rawRows.value)) -->
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** cheap pure formatters (`formatDate(d)`) and event handlers (`@click="save()"`), which run only on the event.

---

### VUE-TPL-005 · Use native interactive elements for interactive UI  `warn`

**Why:** A `<div @click>` or `<span @click>` can't be focused with the keyboard, isn't announced as a control by screen readers, and doesn't respond to Enter or Space. A `<button type="button">` (or `<a href>`/`<NuxtLink>`/`<RouterLink>` for navigation) gives all of that for free. `type="button"` stops a button inside a form from submitting it by accident.
**Source:** https://vuejs.org/guide/best-practices/accessibility.html#semantic-html · https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/

```vue
<!-- ❌ -->
<div class="btn" @click="remove(item.id)">×</div>

<!-- ✅ -->
<button type="button" :aria-label="`Remove ${item.name}`" @click="remove(item.id)">×</button>
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** a UI library component that renders a native control or handles keyboard and ARIA itself.

---

### VUE-TPL-006 · Give every form control an accessible label  `warn`

**Why:**
- An input without an associated `<label>` (or `aria-label`/`aria-labelledby`) is announced only as "edit text".
- A placeholder isn't a label: it disappears on input and many screen readers don't read it.
- Use `useId()` (Vue ≥ 3.5) for SSR-safe `id`/`for` pairs.

**Source:** https://vuejs.org/guide/best-practices/accessibility.html#labels · https://vuejs.org/api/composition-api-helpers.html#useid

```vue
<!-- ❌ -->
<input v-model="email" placeholder="Email" />

<!-- ✅ -->
<script setup lang="ts">
const emailId = useId()
</script>
<template>
  <label :for="emailId">Email</label>
  <input :id="emailId" v-model="email" type="email" autocomplete="email" />
</template>
```

**Applies:** Vue ≥ 3.0 (`useId`: Vue ≥ 3.5 only; on Vue < 3.5 **don't call `useId`**: wrap the input in its `<label>`, which needs no id, or take an `id` prop) · **Exceptions:** inputs wrapped by a `<label>` element, or labelled by a UI library component.

```vue
<!-- ✅ Vue < 3.5: implicit label, no id needed -->
<label>Email <input v-model="email" type="email" autocomplete="email" /></label>
```
