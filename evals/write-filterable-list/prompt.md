---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create `src/components/TaskList.vue`. It receives `tasks: Task[]` (type in `src/types.ts`) and shows them as a list. Add a text box that filters by title and a "show completed" toggle; completed tasks are hidden unless the toggle is on. Each row needs a checkbox to toggle done and a delete control. The parent owns the tasks.
