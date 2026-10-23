#!/usr/bin/env bash
set -euo pipefail
git init -q
git config user.email eval@example.com
git config user.name "Eval"
mkdir -p src
printf '<script setup lang="ts">\ndefineProps<{ title: string }>()\n</script>\n\n<template><h1>{{ title }}</h1></template>\n' > src/PageTitle.vue
printf '{ "name": "x", "private": true, "dependencies": { "vue": "^3.5.13" } }\n' > package.json
git add -A && git commit -qm "init"
