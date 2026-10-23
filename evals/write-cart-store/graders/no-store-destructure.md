---
type: llm
focus: { source: file, path: src/components/CartSummary.vue }
---

This Vue component uses a Pinia cart store.

PASS if state or getters from the store are either accessed through the store object (e.g. `cart.total`, `cart.lines`) or extracted with `storeToRefs(...)`. Destructuring only actions directly from the store (e.g. `const { removeLine } = cart`) is fine.

FAIL if the component destructures state or getters directly from the store without `storeToRefs` (e.g. `const { lines, total } = useCartStore()`), or uses `toRefs` on the store.
