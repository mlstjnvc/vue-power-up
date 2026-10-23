---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a shopping cart. Create a Pinia store in `src/stores/cart.ts` holding cart lines (a `Product` from `src/types.ts` plus a quantity), with a way to add a product, change a quantity and remove a line, and the cart total. Then create `src/components/CartSummary.vue` that lists the lines with their quantities, shows the total, and lets the user remove a line.
