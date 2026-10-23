---
max_turns: 35
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a user profile page at `/users/:id` that loads the user from the existing API (`GET /api/users/:id`), shows a loading and an error state, and has a form to edit the name and email that saves with `PUT /api/users/:id`. After saving, the page should show the updated data. Users navigate between profiles via links on the page, e.g. "next user".
