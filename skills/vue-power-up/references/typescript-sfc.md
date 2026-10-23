# TypeScript in Vue SFCs (`VUE-TS-*`)

Rules for typing components, refs, injections and templates. They apply to every `.vue` file and every `.ts` file that uses Vue APIs.

---

### VUE-TS-001 · Write new SFCs with `<script setup lang="ts">`  `warn`

**Why:** `<script setup>` with TypeScript gives the best type inference for props, emits and template expressions, and the least boilerplate. A plain `<script>` or an untyped block loses checking everywhere downstream.
**Source:** https://vuejs.org/api/sfc-script-setup.html · https://vuejs.org/guide/typescript/overview.html

```vue
<!-- ❌ untyped options object -->
<script>
export default { props: ['userId'], data() { return { user: null } } }
</script>

<!-- ✅ -->
<script setup lang="ts">
const props = defineProps<{ userId: string }>()
</script>
```

**Applies:** Vue ≥ 3.2 · **Exceptions:** existing Options API files the task doesn't otherwise change. Don't migrate them unasked.

---

### VUE-TS-002 · Declare props with a type, not a runtime object  `warn`

**Why:** Type-based `defineProps<T>()` is checked at compile time and in templates, and gives exact types such as unions and nested objects. The runtime object form needs `PropType` casts to express the same thing, and its checks only run in development.
**Source:** https://vuejs.org/guide/typescript/composition-api.html#typing-component-props

```ts
// ❌
const props = defineProps({
  user: { type: Object as PropType<User>, required: true },
  size: { type: String, default: 'md' },
})

// ✅
const props = defineProps<{ user: User; size?: 'sm' | 'md' | 'lg' }>()
```

**Applies:** Vue ≥ 3.3 · **Exceptions:** Vue 3.2 with a type the compiler can't resolve. In that case use the runtime form with `PropType`. Bind `const props =` only when script code reads the props.

---

### VUE-TS-003 · Give props defaults the version-appropriate way, and use factories for object/array defaults  `warn`

**Why:**
- **Vue ≥ 3.5:** destructured props keep reactivity and take native default values.
- **Vue 3.3–3.4:** use `withDefaults`. There, an object or array default written as a literal is a shared reference, so wrap it in a factory function.
- **Either version:** never declare defaults twice.

**Source:** https://vuejs.org/guide/typescript/composition-api.html#props-default-values · https://vuejs.org/guide/components/props.html#reactive-props-destructure

```ts
// ❌ (3.3–3.4) literal array default
const props = withDefaults(defineProps<{ tags?: string[] }>(), { tags: [] })

// ✅ Vue ≥ 3.5: destructure defaults are written as plain values (no factory needed)
const { size = 'md', tags = [] } = defineProps<{ size?: 'sm' | 'md'; tags?: string[] }>()

// ✅ Vue 3.3–3.4
const props = withDefaults(defineProps<{ size?: 'sm' | 'md'; tags?: string[] }>(), {
  size: 'md',
  tags: () => [],
})
```

**Applies:** Vue ≥ 3.3 · **Exceptions:** `withDefaults` is still valid in 3.5. Don't flag it, only the literal mutable default. When passing a destructured prop to a `watch` or a composable in 3.5, wrap it in a getter (`() => size`). See `VUE-REACT-*`.

---

### VUE-TS-004 · Type emits with the named-tuple syntax  `warn`

**Why:** `defineEmits(['change'])` leaves every payload untyped. Callers and listeners can pass anything, and renames aren't caught. The typed form checks both the `emit()` calls and the parent's `@event` handlers.
**Source:** https://vuejs.org/guide/typescript/composition-api.html#typing-component-emits

```ts
// ❌
const emit = defineEmits(['change', 'delete'])

// ✅
const emit = defineEmits<{
  change: [id: string, value: number]
  delete: [id: string]
}>()
```

**Applies:** Vue ≥ 3.3 (Vue 3.2: call-signature form `(e: 'change', id: string): void`) · **Exceptions:** none.

---

### VUE-TS-005 · Type explicit `ref`s whose initial value doesn't cover the full type  `warn`

**Why:** `ref(null)` is inferred as `Ref<null>`, so assigning a `User` later is a type error, or with a cast it silently becomes `any`-like. Give the generic when the initial value is narrower than what will be stored.
**Source:** https://vuejs.org/guide/typescript/composition-api.html#typing-ref

```ts
// ❌
const user = ref(null)
const items = ref([]) // Ref<never[]>

// ✅
const user = ref<User | null>(null)
const items = ref<Item[]>([])
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** when the initial value already has the full type (`ref(0)`, `ref('')`).

---

### VUE-TS-006 · Type template refs  `warn`

**Why:** Untyped template refs are `any` or `unknown`, so calls like `input.value.focus()` or `child.value.reset()` aren't checked. The element or component may also not be mounted yet, so the type must include `null`.
**Source:** https://vuejs.org/guide/typescript/composition-api.html#typing-template-refs · https://vuejs.org/api/composition-api-helpers.html#usetemplateref

```ts
// ❌
const input = ref()
onMounted(() => input.value.focus())

// ✅ Vue ≥ 3.5 (type inferred from the template when using Vue language tools; explicit generic shown)
const input = useTemplateRef<HTMLInputElement>('input')
onMounted(() => input.value?.focus())

// ✅ Vue < 3.5
const input = ref<HTMLInputElement | null>(null)

// ✅ component instance
const dialog = useTemplateRef<InstanceType<typeof ConfirmDialog>>('dialog')
```

**Applies:** Vue ≥ 3.0 (`useTemplateRef` form: Vue ≥ 3.5) · **Exceptions:** none.

---

### VUE-TS-007 · Type provide/inject with `InjectionKey` and handle a missing provider  `warn`

**Why:**
- String keys give `inject()` the type `unknown`, so each consumer has to guess.
- An `InjectionKey<T>` symbol ties the provider and consumers to one type.
- `inject()` returns `undefined` when there's no provider. Consumers must handle that with a default or an explicit error, not `!`.

**Source:** https://vuejs.org/guide/typescript/composition-api.html#typing-provide-inject

```ts
// ❌
provide('theme', theme)
const theme = inject('theme') as Ref<Theme>

// ✅ keys.ts
export const ThemeKey: InjectionKey<Ref<Theme>> = Symbol('theme')

// provider
provide(ThemeKey, theme)

// consumer
const theme = inject(ThemeKey)
if (!theme) throw new Error('useTheme() must be used inside <ThemeProvider>')
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** `inject(key, defaultValue)` is fine when a sensible default exists.

---

### VUE-TS-008 · Type scoped slots with `defineSlots`  `warn`

**Why:** Without `defineSlots`, the props a component passes to its scoped slots aren't checked. Consumers get loosely typed slot props, and renames break them silently.
**Source:** https://vuejs.org/api/sfc-script-setup.html#defineslots

```vue
<script setup lang="ts" generic="T">
defineProps<{ items: T[] }>()
defineSlots<{
  item(props: { item: T; index: number }): any
  empty(): any
}>()
</script>
```

**Applies:** Vue ≥ 3.3 · **Exceptions:** components with only a plain default slot and no slot props.

---

### VUE-TS-009 · Use `generic` for components parameterized by a type  `warn`

**Why:** A list, select or table component typed with `any`/`unknown` items loses the caller's item type in events and slots. A generic component keeps it end to end.
**Source:** https://vuejs.org/api/sfc-script-setup.html#generics

```vue
<!-- ❌ -->
<script setup lang="ts">
defineProps<{ options: any[]; modelValue: any }>()
</script>

<!-- ✅ -->
<script setup lang="ts" generic="T extends { id: string }">
defineProps<{ options: T[] }>()
const selected = defineModel<T | null>({ default: null })
</script>
```

**Applies:** Vue ≥ 3.3 · **Exceptions:** none.

---

### VUE-TS-010 · No `any`, no unchecked `as`, no `!` to silence the compiler  `warn`

**Why:** Each one turns off type checking at exactly the spot where the compiler found a doubt. `as` on external data (API responses, `JSON.parse`, route params) claims a shape nobody checked. For data crossing a trust boundary, see `VUE-SEC-*` and `VUE-NUXT-*`.
**Source:** https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#any · https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions · https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#non-null-assertion-operator-postfix-

```ts
// ❌
const data: any = await res.json()
const user = data as User
el.value!.focus()

// ✅
const data: unknown = await res.json()
const user = parseUser(data) // validates, throws on bad shape
el.value?.focus()
```

**Applies:** TypeScript ≥ 4.x · **Exceptions:**
- narrowing DOM event targets (`event.target as HTMLInputElement`) in a handler bound to that element
- `as const`
- test doubles.

---

### VUE-TS-011 · Keep `strict` on and type-check `.vue` files with `vue-tsc`  `warn`

**Why:** `tsc` alone doesn't check `.vue` files or templates, and without `strict`, `null`/`undefined` errors pass silently. This rule is about project config. In write mode **don't change it unasked**; mention it in the report if it's missing.
**Source:** https://vuejs.org/guide/typescript/overview.html#configuring-tsconfig-json · https://vuejs.org/guide/typescript/overview.html#ide-support

```jsonc
// ✅ tsconfig.json (Vite SPA); Nuxt generates strict config by default
{ "compilerOptions": { "strict": true, "isolatedModules": true, "verbatimModuleSyntax": true } }
// package.json: "typecheck": "vue-tsc --noEmit" (Nuxt: "nuxi typecheck")
```

**Applies:** any TS project · **Exceptions:** none. In reviews, flag it only when the change itself loosens the config.
