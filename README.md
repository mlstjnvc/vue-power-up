# vue-power-up

A Claude Code plugin that helps Claude write **secure, idiomatic Vue 3 + TypeScript** code (including **Pinia** and **Nuxt**) and review changes against the same rule set.

> **Status: v1.2.3, feature-complete.** MIT licensed. Not yet published to GitHub (see [Publishing configuration](#publishing-configuration)).

## What it does

- **Writing (automatic).** Describe what you need ("add a paginated orders table backed by a Pinia store"). The `vue-power-up` skill fires on Vue/Nuxt/Pinia work and has Claude:
  - detect your Vue, Nuxt, Pinia and TypeScript versions
  - follow version-appropriate best practices
  - avoid known antipatterns
  - check every data flow for security issues
  - add tests when your project has a test setup.

- **Reviewing (on demand).** `/vue-power-up:review` reviews your uncommitted changes, and `/vue-power-up:review <commit>` reviews one commit. You get a standard code review: an analysis and numbered proposed changes. Nothing is applied unless you ask.

## Requirements

- Claude Code (developed against v2.1.301)
- For `/vue-power-up:review`: `git`, and a POSIX shell (on Windows, Git Bash, which Claude Code uses for shell commands)

## Installation

### Local, without installing (development)

```bash
claude --plugin-dir /path/to/vue-power
```

### Local marketplace

```text
/plugin marketplace add /path/to/vue-power
/plugin install vue-power-up@ml2stjnvc
/reload-plugins
```

The install id is `<plugin>@<marketplace>`: the plugin is `vue-power-up` and the marketplace is `ml2stjnvc`. The plugin is active right after install.

**Check it's installed:**

```bash
claude plugin list    # shows vue-power-up@ml2stjnvc, "Read from: /path/to/vue-power", Status: enabled
```

In a session, typing `/vue-power-up:` should autocomplete `review`. The writing skill has no command, so it doesn't appear there. It shows up in the skill list as `vue-power-up:vue-power-up`.

**After editing the plugin:** a folder marketplace reads the plugin straight from disk, so run `/reload-plugins` to pick up changes.

**Remove it:**

```text
/plugin uninstall vue-power-up@ml2stjnvc
/plugin marketplace remove ml2stjnvc
```

### GitHub marketplace

Not published yet (see [Publishing configuration](#publishing-configuration)). Once it is:

```text
/plugin marketplace add <owner>/<repo>
/plugin install vue-power-up@ml2stjnvc
```

## Usage

### Writing code

You don't need a command. Describe the change and the skill fires on Vue, Nuxt or Pinia work:

```text
Add a paginated orders table with status filters, backed by a Pinia store.
Create a login form that posts to a new Nuxt API route.
Extract the search logic from SearchPage.vue into a composable.
```

Claude then follows a fixed workflow:

1. **Understand.** Restates the deliverable, and asks only if the answer would change the architecture.
2. **Detect.** Resolves your Vue, Nuxt, Pinia and TypeScript versions (from `node_modules`, then the lockfile, then `package.json`), the project type (Nuxt or Vite SPA, Nuxt 4 `app/` layout), and your existing conventions and libraries.
3. **Plan.** Lists the files it will create or change.
4. **Implement.** `<script setup lang="ts">`, applying the rules only where your versions support them.
5. **Security pass.** Traces each new data flow to its sink: `v-html`, URL attributes, redirects, server handlers, client-visible state, cookies.
6. **Tests.** Adds tests if your project has a test setup. Otherwise it offers to add one.
7. **Self-check.** Checks against the red flags, then runs your **existing** type-check, lint and tests.
8. **Report.** What was built, the defaults chosen, the checks run, and any place it deliberately didn't follow your request literally.

**When a request conflicts with a guardrail** (e.g. "render this user HTML"), Claude builds the safe version and explains why. If you insist, it does what you asked and leaves a code comment naming the rule id.

**It never** adds dependencies or changes `tsconfig` or lint config without asking.

### Reviewing: `/vue-power-up:review [commit]`

```text
/vue-power-up:review            # all uncommitted changes: staged, unstaged and untracked (respects .gitignore)
/vue-power-up:review 1a2b3c4    # exactly what that commit changed (merge commits: diff vs first parent)
```

**Precondition:** git must be installed and you must be inside a git repository. Otherwise the command stops:

- `/vue-power-up:review needs git installed; \`git\` was not found on PATH.`
- `/vue-power-up:review must run inside a git repository; <cwd> isn't one.`

**Other early stops:**
- an argument that isn't a 4–40 character hex hash: `Invalid argument "…"`
- an unknown or ambiguous hash
- a clean working tree: `Nothing to review…`

**Output: a standard code review**
1. **Scope** (files or commit) and the detected Vue / Nuxt / Pinia / TypeScript versions. For a commit, versions are read from that commit's `package.json`.
2. **Summary** of what the change does.
3. **Verdict:** *Request changes* (any `error`), *Approve with suggestions* (`warn`), or *Approve*.
4. **Findings** by severity: `[error] VUE-COMP-002 src/components/ItemList.vue:6`, with why it matters (linked to the official source) and a suggestion. Bugs outside the catalog are reported as `GENERAL`.
5. **Proposed changes:** numbered `diff` blocks, including missing pieces such as tests or validation.
6. Optionally, what's done well.

Excerpt from a real run:

````text
### Verdict
**Request changes**: `ItemList` changes the parent's array through a prop, and can delete the wrong item.

#### error
- **[error] VUE-COMP-002** `src/components/ItemList.vue:6`: Never mutate props
  - *Why:* `props.items.splice(i, 1)` changes the parent's array in place. …
  - *Suggestion:* emit a typed `remove` event and let the parent drop the item (see Proposed change 1).
…
### Proposed changes
1. **Emit `remove` instead of mutating the prop** (resolves VUE-COMP-002, …), `src/components/ItemList.vue`
   ```diff
   -const props = defineProps<{ items: Item[] }>()
   +defineProps<{ items: Item[] }>()
   +const emit = defineEmits<{ remove: [id: string] }>()
   ```
---
To apply any of these, tell me which (e.g. "apply 1 and 3").
````

**The command never changes anything.**
- It doesn't edit, stage, commit, stash or check out.
- It only uses read-only git commands. Those are pre-approved, so they run without permission prompts.
- To apply proposals, reply e.g. `apply 1 and 3`. Those edits then go through your normal Claude Code permissions.

**Permissions:** the precondition runs a bundled script through the Bash tool. If your settings deny Bash, the command can't run.

You can also ask in plain language ("review `src/components/Cart.vue`"). The same procedure and format are used, with the named files as the scope.

## Cost and usage

The plugin only costs the tokens Claude reads and writes while using it. They count against your plan's usage limits on Pro/Max, or are billed per token with an API key. Nothing else is billed. The eval suite never runs for users: it runs only when a maintainer runs `claude plugin eval`.

| When | Approx. tokens |
|---|---|
| Every session, just from being installed (the two skill descriptions) | ~260 |
| The writing skill fires (`SKILL.md`) | ~4.2k |
| `/vue-power-up:review` runs | ~1.9k |
| Each reference file, loaded only when the task needs it | ~1.1k–4.8k |

*Source: `claude plugin details vue-power-up@ml2stjnvc` (estimates). Reference sizes are estimated from file size.*

What keeps it small:
- **Details load on demand.** A simple component task doesn't load the Nuxt server-route or security references.
- **The skill doesn't fire for unrelated work.** React, Svelte, Angular and plain backend requests don't trigger it (checked by the `trigger-*` evals).
- **The review only runs when you ask.** It is user-invoked only, so Claude never starts a review on its own.
- **No hooks, MCP servers or background processes.**

**The workflow costs more than the skill text.** When the skill fires, Claude does more than a quick answer would: it detects versions, does a security pass, writes tests and runs your type-check, lint and tests. That uses more tokens than an unguided reply, and it's the point of the plugin.

## Rules

91 rules in 10 domains. Every rule has:
- a stable id (`VUE-<DOMAIN>-NNN`) and a severity (`error` / `warn` / `info`)
- an official source link
- a ❌/✅ example
- the versions it **applies** to, and its exceptions.

Rules are version-gated: Claude never suggests an API your installed version lacks.

| Domain | Rules | Covers | Reference |
|---|---|---|---|
| `TS` | 11 | typed props/emits/refs/slots/inject, generics, no `any`, `strict` + `vue-tsc` | [typescript-sfc.md](skills/vue-power-up/references/typescript-sfc.md) |
| `COMP` | 9 | `defineModel`, no prop mutation, naming, `defineExpose`, scoped styles | [components.md](skills/vue-power-up/references/components.md) |
| `REACT` | 10 | destructuring, `.value`, computed vs watch, watcher sources and cleanup | [reactivity.md](skills/vue-power-up/references/reactivity.md) |
| `TPL` | 7 | `v-if`+`v-for`, keys, template logic, accessible controls, labels and row-action names | [templates.md](skills/vue-power-up/references/templates.md) |
| `CMPS` | 9 | composable naming, inputs, return shape, call context, SSR safety | [composables.md](skills/vue-power-up/references/composables.md) |
| `PINIA` | 7 | `storeToRefs`, setup-store state, store calls outside components, SSR, Nuxt | [pinia.md](skills/vue-power-up/references/pinia.md) |
| `NUXT` | 17 | data fetching, keys, Nuxt 4 shallow data, `useState`, hydration, server validation and auth, runtime config, middleware, plugins | [nuxt.md](skills/vue-power-up/references/nuxt.md) |
| `SEC` | 8 | XSS (`v-html`, URLs, templates), open redirects, secrets, SSRF, cookies, CSRF | [security.md](skills/vue-power-up/references/security.md) |
| `PERF` | 6 | `shallowRef`, lazy loading and hydration, long lists, `v-memo` | [performance.md](skills/vue-power-up/references/performance.md) |
| `TEST` | 7 | behaviour tests, async waits, Pinia isolation, `@nuxt/test-utils`, mocking, cleanup without Vitest globals | [testing.md](skills/vue-power-up/references/testing.md) |

The full index is in [`rule-catalog.md`](skills/vue-power-up/references/rule-catalog.md). The reasoning behind each rule is in [`docs/RATIONALE.md`](docs/RATIONALE.md#5-rules-by-id).

## Development checks

```bash
claude plugin validate .            # manifests (expected warning: author not set)
python3 tests/check_catalog.py      # every rule: template, catalog index, RATIONALE entry
python3 tests/check_catalog.py --write-index   # regenerate the catalog index after adding rules
python3 tests/check_links.py        # every rule source URL resolves (network)
sh tests/precheck.test.sh           # review-command precondition script
```

## Running the evals

36 cases in [`evals/`](evals/), in `claude plugin eval` format:

| Family | Cases | What they check |
|---|---|---|
| `write-*` | 12 | Generated code: required APIs present, anti-patterns absent, version-gating (Vue 3.3 vs 3.5), Nuxt 4 layout, test cleanup without Vitest `globals`, and two **trap** prompts (render user HTML, redirect to `?next=`) that must produce the safe variant plus an explanation |
| `review-*` (plain language) | 7 | Reviews of seeded files find the expected rule ids and the right verdict, and never edit |
| `review-*` (`/vue-power-up:review`) | 6 | Not a repo, invalid argument, uncommitted changes, a commit hash, a root commit, a clean tree. No git writes and no file edits |
| `trigger-*` | 11 | The skill fires for Vue/Nuxt/Pinia requests (6) and doesn't for React/Svelte/Python/Express/Angular (5) |

```bash
# quick: one case, one run, no baseline
claude plugin eval . --scaffold --case write-cart-store --runs 1 --ablation none --allow-tools Write Edit

# full run: 3 runs per case, with vs. without the plugin
claude plugin eval . --scaffold --allow-tools Bash Write Edit
```

`--scaffold` is needed because cases build their fixture projects and git repos with bundled scripts. The six `/vue-power-up:review` cases need `--allow-tools Bash`. Results go to `evals/results/` (git-ignored).

## Limitations

- **Guidance, not hard enforcement.** There are no hooks: Claude follows the rules through the skill and a mandatory self-check, and can still deviate.
- **The review command needs Bash permission** (for its git precheck) **and a POSIX shell** (Git Bash on Windows). Plain-language reviews need only read access.
- **Rule coverage is finite.** Reviews report bugs outside the catalog as `GENERAL` findings.
- **Without `node_modules` or a lockfile**, versions are taken as the minimum of the `package.json` range. That's conservative: it never produces code your install can't compile.
- **No whole-project audit mode** (out of scope for now).

Details: [`docs/RATIONALE.md` § Known limitations](docs/RATIONALE.md#7-known-limitations).

## Publishing configuration

| Field | File | Value |
|---|---|---|
| marketplace `name`, `owner.name` | `.claude-plugin/marketplace.json` | `ml2stjnvc`, Milos Stojanovic |
| `author` | `.claude-plugin/plugin.json` | Milos Stojanovic |
| `license` | `.claude-plugin/plugin.json` + [`LICENSE`](LICENSE) | MIT |
| `repository`, `homepage` | `.claude-plugin/plugin.json` | not set yet (add once the GitHub repo exists) |
| icon | `.claude-plugin/icon.png` | not set; optional, but the plugin directory warns without it (square PNG, 512–2048 px) |

`claude plugin validate .` and `claude plugin validate . --strict` both pass.

## Design rationale

Every decision and rule is explained in [`docs/RATIONALE.md`](docs/RATIONALE.md). The specification is in [`SPEC.md`](SPEC.md).
