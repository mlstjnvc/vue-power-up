# Testing (`VUE-TEST-*`)

Rules for testing Vue, Pinia and Nuxt code with Vitest. **Use the project's existing test stack.** Never install or reconfigure test tooling without asking (SKILL.md step 6).

**Which library (both are fine; match the project):**

| Goal | Use |
|---|---|
| User flows: type, click, see the result | `@testing-library/vue` (`render`, `screen.findByRole`, `@testing-library/user-event`) |
| Component contract: emitted events, props → output, slots | `@vue/test-utils` (`mount`, `wrapper.emitted()`, `setProps`) |
| Components or composables that use Nuxt auto-imports, `useFetch`, plugins, route | `@nuxt/test-utils` (`mountSuspended` / `renderSuspended`, `mockNuxtImport`, `registerEndpoint`) |
| Stores | `@pinia/testing` (`createTestingPinia`), or a fresh `createPinia()` per test |
| Composables without lifecycle or inject | call them directly in the test |

---

### VUE-TEST-001 · Test behaviour through the rendered output, not component internals  `warn`

**Why:**
- Asserting on `wrapper.vm.someRef`, calling internal methods, or checking private state ties tests to implementation details, so they break on harmless refactors and miss real bugs.
- Drive the component the way a user (or parent) does: find elements by role, label or text, interact, assert what's rendered or emitted.

**Source:** https://vuejs.org/guide/scaling-up/testing.html#component-testing · https://testing-library.com/docs/guiding-principles · https://testing-library.com/docs/queries/about/#priority

```ts
// ❌
wrapper.vm.count = 5
expect(wrapper.vm.isValid).toBe(true)

// ✅ Testing Library
await user.type(screen.getByLabelText('Email'), 'ada@example.com')
await user.click(screen.getByRole('button', { name: 'Save' }))
expect(await screen.findByText('Saved')).toBeTruthy()

// ✅ Vue Test Utils (contract)
await wrapper.get('button[type="submit"]').trigger('submit')
expect(wrapper.emitted('submit')?.[0]).toEqual([{ email: 'ada@example.com' }])
```

**Applies:** Vitest + VTU ≥ 2 / Testing Library ≥ 8 · **Exceptions:** `defineExpose`d public methods are part of the component API and may be called.

---

### VUE-TEST-002 · Wait for async updates explicitly; never sleep  `warn`

**Why:** DOM updates after state changes are async (next tick), and so are promises and network mocks. `setTimeout`/`sleep` waits are flaky (too short on CI) and slow (too long locally). Await the interaction, use `findBy*`/`waitFor`, or `flushPromises()` + `nextTick()`.
**Source:** https://test-utils.vuejs.org/guide/advanced/async-suspense · https://testing-library.com/docs/dom-testing-library/api-async/

```ts
// ❌
await wrapper.find('button').trigger('click')
await new Promise((r) => setTimeout(r, 500))

// ✅
await wrapper.find('button').trigger('click') // awaits nextTick
await flushPromises()                          // resolves mocked requests
// ✅ Testing Library
expect(await screen.findByRole('alert')).toHaveTextContent('Failed')
```

**Applies:** any · **Exceptions:** testing timer logic itself. Use `vi.useFakeTimers()` and `vi.advanceTimersByTime()`, not real waits.

---

### VUE-TEST-003 · Give every test a fresh Pinia  `warn`

**Why:** Pinia stores are singletons per pinia instance. Sharing one instance across tests leaks state between them, so results depend on test order. Use `createTestingPinia()` (actions stubbed by default, `stubActions: false` to run them) or `setActivePinia(createPinia())` in `beforeEach`.
**Source:** https://pinia.vuejs.org/cookbook/testing.html

```ts
// ✅ component test
mount(CartSummary, { global: { plugins: [createTestingPinia({ initialState: { cart: { lines } }, createSpy: vi.fn })] } })

// ✅ store unit test
beforeEach(() => setActivePinia(createPinia()))
```

**Applies:** Pinia ≥ 2.0 · **Exceptions:** none.

---

### VUE-TEST-004 · Use `@nuxt/test-utils` for code that depends on the Nuxt runtime  `warn`

**Why:** Components and composables using auto-imports (`useFetch`, `useState`, `useRoute`, `navigateTo`), plugins or runtime config fail, or need fragile manual stubs, under a plain Vue mount. `@nuxt/test-utils` provides a Nuxt environment (`environment: 'nuxt'`), `mountSuspended`/`renderSuspended` for async setup, `mockNuxtImport` for auto-imports, and `registerEndpoint` for API routes.
**Source:** https://nuxt.com/docs/4.x/getting-started/testing

```ts
// ✅ test/nuxt/UserPage.test.ts
registerEndpoint('/api/users/1', () => ({ id: '1', name: 'Ada' }))
const wrapper = await mountSuspended(UserPage, { route: '/users/1' })
expect(wrapper.text()).toContain('Ada')
```

**Applies:** Nuxt ≥ 3.0 · **Exceptions:** pure functions, and components with no Nuxt dependencies. Test those with plain Vitest + VTU.

---

### VUE-TEST-005 · Mock the network at the boundary, never call real APIs  `warn`

**Why:** Tests that hit real services are slow and flaky, depend on data you don't control, and can mutate real systems. Mock at the HTTP or module boundary: `registerEndpoint` (Nuxt), an MSW handler if the project uses MSW, or `vi.mock` of the API module. Then assert both success and failure paths.
**Source:** https://vitest.dev/guide/mocking

```ts
// ✅ Vitest module mock
vi.mock('@/api', () => ({ searchUsers: vi.fn().mockResolvedValue([{ id: '1', name: 'Ada' }]) }))
```

**Applies:** any · **Exceptions:** dedicated end-to-end suites run against a test environment.

---

### VUE-TEST-006 · Test composables directly, or through a host component when they need lifecycle or inject  `info`

**Why:** A composable that uses only reactivity APIs can be called and asserted directly. One that uses lifecycle hooks or `inject` needs an active component: mount a tiny host component (or use a `withSetup` helper) so hooks run, and unmount it to test cleanup.
**Source:** https://vuejs.org/guide/scaling-up/testing.html#testing-composables

```ts
function withSetup<T>(composable: () => T) {
  let result!: T
  const app = createApp({ setup() { result = composable(); return () => {} } })
  app.mount(document.createElement('div'))
  return [result, app] as const
}
const [{ width }, app] = withSetup(() => useWindowWidth())
app.unmount() // asserts cleanup ran
```

**Applies:** Vue ≥ 3.0 · **Exceptions:** none.

---

### VUE-TEST-007 · Clean up mounted components when Vitest has no global `afterEach`  `warn`

**Why:** Neither test library unmounts on its own in every setup:
- **`@testing-library/vue`** runs `cleanup` automatically only when the runner injects a global `afterEach`. Jest does; **Vitest does only with `globals: true`.** Without it, every `render` stays in the document, so later tests find earlier components ("Found multiple elements…"), results depend on test order, and memory leaks.
- **`@vue/test-utils`** never destroys `mount`ed wrappers by itself. Leftover watchers, timers and `window` listeners keep running, and `attachTo` mounts stay in the DOM. `enableAutoUnmount(afterEach)` destroys them after each test.

Before writing tests, check `vitest.config.*` for `globals: true` and the setup files for `cleanup` / `enableAutoUnmount`. If neither is there, add the hook to the existing setup file: one top-level hook covers every test file. Don't turn on `globals` just for this, because it changes the project's config and its TS types (`vitest/globals`).
**Source:** https://testing-library.com/docs/vue-testing-library/setup#vitest · https://testing-library.com/docs/vue-testing-library/api#cleanup · https://test-utils.vuejs.org/api/#enableAutoUnmount

```ts
// ❌ vitest.config.ts has no `globals: true`, and the setup never cleans up
// vitest.setup.ts
import '@testing-library/jest-dom/vitest'

// ✅ vitest.setup.ts
import '@testing-library/jest-dom/vitest'
import { afterEach } from 'vitest'
import { cleanup } from '@testing-library/vue'
import { enableAutoUnmount } from '@vue/test-utils'

afterEach(() => cleanup())      // Testing Library: render()
enableAutoUnmount(afterEach)    // Vue Test Utils: mount()
```

**Applies:** Vitest without `globals: true`, or any runner without a global `afterEach` (`@testing-library/vue` ≥ 6, `@vue/test-utils` ≥ 2.0) · **Exceptions:** Jest, or Vitest with `globals: true`, for Testing Library. Register only the hook for the libraries the project uses. A suite that unmounts every wrapper itself (`wrapper.unmount()`) doesn't need `enableAutoUnmount`.
