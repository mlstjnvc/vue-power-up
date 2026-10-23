---
type: regex
pattern: 'props\.tasks\s*\.\s*(splice|push|pop|shift|unshift|sort|reverse)\b|\.done\s*=(?!=)'
match: not_contains
target: { source: file, path: src/components/TaskList.vue }
---
