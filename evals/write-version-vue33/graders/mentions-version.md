---
type: llm
---

The project uses Vue 3.3 (no defineModel, which needs 3.4; no useTemplateRef/useId, which need 3.5).

PASS if the final message indicates the Vue version was taken into account (e.g. mentions Vue 3.3 and that defineModel/useTemplateRef were not used, or mentions an upgrade path).

FAIL if it does not mention the version constraint at all.
