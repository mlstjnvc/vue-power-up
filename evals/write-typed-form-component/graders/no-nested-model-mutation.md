---
type: llm
focus: { source: file, path: src/components/ProfileForm.vue }
---

This is a Vue component that receives the parent's `Profile` object via `defineModel` (v-model).

PASS if the component never mutates the parent's object in place. Acceptable approaches: the inputs edit a local copy (e.g. a `ref`/`reactive` cloned from the model) and the model or `submit` gets a new object; or each field writes a new object to the model (e.g. `model.value = { ...model.value, name: v }`, or computed getters/setters doing that).

FAIL if any input binds directly to a nested property of the model ref (e.g. `v-model="model.name"` or `v-model="profile.email"` where that variable is the defineModel ref), or script code assigns to a property of the model's value (e.g. `model.value.name = ...`).
