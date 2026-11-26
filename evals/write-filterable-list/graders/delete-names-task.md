---
type: llm
focus: { source: file, path: src/components/TaskList.vue }
---

This Vue component renders a list of tasks, and every row has a delete control (VUE-TPL-007).

PASS if each row's delete control has an accessible name that identifies its task, for example `:aria-label="\`Delete ${task.title}\`"`, visually hidden text containing the title inside the button, `aria-labelledby` pointing at the title, or visible text that already includes the title. If an `aria-label` is used, it should start with (or contain) the button's visible text.

FAIL if the delete control's accessible name is only a generic word or icon ("Delete", "Remove", "×", "🗑") that is the same in every row.
