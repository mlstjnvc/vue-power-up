# Spec: vue-power-up

> Status: **APPROVED (v3), with v3.3 adjustments (D10–D15). Implemented as v1.2.3. See the success criteria for evidence.**
> Nothing in this repo gets committed (user instruction). All changes stay in the working tree.

## Decisions log

| # | Decision | Source |
|---|---|---|
| D1 | Plugin and skill are named **`vue-power-up`**. (The marketplace originally had the same name; D16 renamed it.) | User, review 1 |
| D2 | **No hooks** in this version. Enforcement is through skill guidance plus a mandatory self-check | User, review 1 |
| D3 | **Primary use is writing code.** The user describes what's needed and the skill delivers it following best practices, guardrails and security. Review is secondary. | User, review 1 |
| D4 | Testing: **both** `@testing-library/vue` (behaviour) and `@vue/test-utils` (when internals or emitted events matter), plus `@nuxt/test-utils` for Nuxt-context code | User, review 1 |
| D5 | **Nuxt 4 is primary**, with Nuxt 3 differences noted | User, review 1 |
| D6 | Publishing config (GitHub owner/repo, author, license) is **left as placeholders**. The user fills them in later. | User, review 1 |
| D7 | **Audit mode is excluded** for now | User, review 1 |
| D8 | Writing is auto-triggered by the skill (no command). Review gets **one slash command: `/vue-power-up:review [commit]`**. With no argument it reviews the current uncommitted changes; with a commit hash it reviews that commit. | User, review 2 |
| D10 | The review command is implemented as a **user-invoked plugin skill** (`skills/review/SKILL.md`, `disable-model-invocation: true`), not a legacy `commands/*.md` file. Plugin skills are namespaced, so it runs as `/vue-power-up:review`. | Claude Code docs: custom commands are merged into skills; "Prefer `skills/` for new plugins" |
| D11 | The review skill loads the shared catalog through `${CLAUDE_PLUGIN_ROOT}/skills/vue-power-up/references/…`, which Claude Code substitutes inside plugin skill content. The rules stay single-sourced. | Claude Code docs: plugin env vars |
| D12 | Evals use the native `claude plugin eval` format: `evals/<case>/prompt.md` + `graders/*.md`, with an optional `case.yaml` for scaffold scripts and fixture dirs | `claude plugin eval --help` + docs |
| D13 | **Review precondition:** `/vue-power-up:review` first checks that git is available and the working directory is inside a git work tree. If not, it stops with a clear message and does no review. **No write-access check:** the review only reads and proposes, so writability is irrelevant. Applying changes is a separate step the user asks for, and Claude Code's normal permissions govern it. | User, reviews 4–5 |
| D14 | **Review output is a standard code review:** an analysis of the change, findings, and a proposal of additional changes (suggested code as diffs). It proposes and never applies. A user who wants changes applied says so afterwards (e.g. "apply 1 and 3"). | User, reviews 4–5 |
| D15 | **The full eval run (3 runs, with/without baseline) is done by the user.** During development, only targeted single-run cases are run per task. | User, review 4 |
| D16 | The marketplace is named **`ml2stjnvc`**, owner **Milos Stojanovic**, with a general description, so it can list more plugins later. The plugin name stays `vue-power-up`, so the install id is `vue-power-up@ml2stjnvc`. This partly supersedes D1 and D6 (the marketplace owner is no longer a placeholder). | User, 2026-10-21 |
| D17 | `plugin.json` `author` is **Milos Stojanovic** and `license` is **MIT**, with a matching `LICENSE` file at the repo root. `repository`/`homepage` stay unset until the GitHub repo exists. This partly supersedes D6. | User, 2026-10-21 |
| D9 | **README.md** is a deliverable. It is created with the plugin and updated in the same task as any change to behaviour, commands or install steps. | User, review 2 |

## Assumptions

1. **One skill.** Write and review share one rule catalog. The catalog is the single source of truth, so the two can't diverge.
2. **Target versions:** Vue **3.5+**, TypeScript **5.x** with `strict`, Pinia **3.x** (Pinia 2 accepted), Nuxt **4** (Nuxt 3 noted). Older versions are detected and handled, not rejected.
3. **New code is always Composition API with `<script setup lang="ts">`.** Existing Options API code is left alone unless the task touches it.
4. **Rules are grounded in official sources** (Vue docs and style guide, Nuxt docs, Pinia docs, TypeScript handbook, eslint-plugin-vue rule docs, OWASP for security). Opinionated conventions that the official docs don't back are at most `info`.
5. **The example repo (`~/projects/claude-skill-vue-development-main`, MIT) is a structural reference only.** No text is copied verbatim.
6. **The repo directory stays `~/projects/vue-power`.** The plugin name comes from `plugin.json`, not from the folder name.

## Objective

Build a Claude Code plugin, **vue-power-up**, containing one skill. The user describes a feature or change in plain language ("add a paginated orders table with filters backed by a Pinia store", "create a login form that posts to our Nuxt API"). The skill makes Claude deliver production-quality Vue + TypeScript code that:

- follows current best practices for Vue, TypeScript, Pinia and Nuxt
- avoids known anti-patterns (guardrails)
- is **secure by default**: no XSS sinks, no leaked secrets, validated server input, safe redirects
- fits the project it's in: detected versions, existing conventions, existing libraries
- comes with tests when the project has a test setup.

Secondary: the **`/vue-power-up:review`** command reviews the current changes, or a given commit, against the same rule catalog and returns a findings list.

**Users:** Vue/Nuxt developers using Claude Code, locally and via the marketplace. Defaults must be neutral and well-sourced.

### User stories

- *As a developer*, I say "add a user settings form with Pinia" in a Nuxt app. Claude uses `defineModel`, typed `defineProps`/`defineEmits`, a setup store consumed with `storeToRefs`, `$fetch` in the submit handler, and a validated `server/api` handler. It adds a behaviour test, and I never had to ask for any of it.
- *As a developer*, I ask for something that would be insecure if taken literally ("render the user's bio HTML"). Claude flags the risk, implements the safe variant (sanitization or plain text), and explains why.
- *As a developer*, I ask for something my Vue version doesn't support (e.g. `useTemplateRef` on 3.3). Claude uses the version-appropriate API and mentions the upgrade path.
- *As a developer*, before committing I run `/vue-power-up:review`. I get findings for my uncommitted Vue/TS changes, each with rule id, `file:line`, why, and a fix.
- *As a reviewer*, I run `/vue-power-up:review a1b2c3d` to review exactly what a specific commit changed.

## Tech Stack (of the plugin itself)

- Markdown skill files (`SKILL.md` + `references/*.md`), a second, user-invoked skill (`skills/review/SKILL.md`) for `/vue-power-up:review`, and JSON manifests. No runtime code and no hooks.
- Eval material: prompts and small `.vue`/`.ts` fixtures, used to check the skill's behaviour.

## Commands

```bash
# Validate plugin + marketplace manifests (--strict: warnings fail)
claude plugin validate .
claude plugin validate . --strict

# Show the plugin's component inventory
claude plugin details <plugin>

# Use locally without installing (dev loop)
claude --plugin-dir ~/projects/vue-power

# Review current uncommitted changes / a specific commit (inside a Claude Code session)
/vue-power-up:review
/vue-power-up:review <commit-hash>

# Run eval suite (from repo root); --scaffold needed for git-repo fixtures
claude plugin eval . --scaffold --runs 1 --ablation none   # fast iteration
claude plugin eval . --scaffold                            # full: 3 runs, with/without baseline (run by the user, D15)

# Install via local marketplace
/plugin marketplace add ~/projects/vue-power
/plugin install vue-power-up@ml2stjnvc

# Install via GitHub marketplace (once the user configures and publishes; see D6)
/plugin marketplace add <owner>/<repo>
/plugin install vue-power-up@ml2stjnvc
```

> I'll check the exact CLI syntax for `validate` and for running evals against the current Claude Code docs during the Plan phase and fix it here if it differs.

## Project Structure

```
.claude-plugin/
  plugin.json             → manifest: name vue-power-up, version, description, author, license MIT (D17); repository/homepage unset until published (D6)
  marketplace.json        → marketplace "ml2stjnvc" listing this plugin (D16) (source "./")
skills/
  review/
    SKILL.md              → /vue-power-up:review [commit] (user-invoked only): preconditions, scope via read-only git, then references/review.md
    scripts/precheck.sh   → git precondition check (D13), prints one PRECHECK= status line
  vue-power-up/
    SKILL.md              → triggers, write workflow, version detection, top guardrails, security checklist, self-check, review mode
    references/
      typescript-sfc.md   → strict TS, <script setup lang="ts">, typing props/emits/slots/refs/provide-inject, generic components
      reactivity.md       → ref vs reactive, destructuring, computed vs watch, watcher hygiene, shallowRef, toRefs/toValue
      components.md       → props, emits, defineModel, slots, provide/inject, component size/splitting, naming, SFC layout
      composables.md      → naming, MaybeRefOrGetter inputs, return shape, cleanup, no UI side-effects, SSR-safe composables
      pinia.md            → setup stores, storeToRefs, actions, store composition, SSR/hydration, usage outside components
      nuxt.md             → useFetch/useAsyncData/$fetch, useState, SSR safety, runtimeConfig, server/ routes, middleware, plugins, Nuxt 3 vs 4
      templates.md        → keys, v-if+v-for, event handlers, template complexity, accessibility basics
      security.md         → XSS sinks, URL/redirect safety, secrets, server input validation, auth in server routes, cookies, SSRF
      performance.md      → shallowRef, v-memo/v-once, async/lazy components, lazy hydration, large lists, watcher costs
      testing.md          → Vitest; Testing Library vs VTU (when each); @nuxt/test-utils; createTestingPinia; async patterns
      review.md           → review procedure, severity model, finding format (used by the command and by "review this…" requests)
      rule-catalog.md     → index of every rule: id, severity, summary, applies-range, source, reference file
evals/                    → `claude plugin eval` suite (D12); results/ is gitignored
  write-<topic>/          → prompt.md + graders/ (regex over produced files, llm rubric, tool_used Skill)
  review-<topic>/         → case.yaml scaffold builds a git repo seeded with anti-patterns; graders check rule ids
  trigger-<topic>/        → should / shouldn't fire the skill
tests/
  precheck.test.sh        → plain-shell tests for precheck.sh (no model involved); not part of any skill payload
docs/
  RATIONALE.md            → detailed explanation and reasoning for EVERY implementation decision and rule (user requirement)
LICENSE                   → MIT (D17)
README.md                 → what it does, install (local + marketplace), write-mode usage examples, /vue-power-up:review usage, rule overview, limitations (D9)
SPEC.md                   → this file
tasks/plan.md, tasks/todo.md
```

**Change to the current scaffold:** move the root `SKILL.md` to `skills/vue-power-up/SKILL.md`, rename the plugin in `plugin.json`, and point `skills` at `./skills/vue-power-up`. **Why:** a root-level skill dir would ship README, SPEC, docs, evals and tasks as skill content. The `skills/<name>/` layout keeps the payload clean.

## Behaviour

### Write workflow (primary). SKILL.md makes Claude follow these steps in order
1. **Understand the request.** Restate the deliverable in one line. If the request is ambiguous in a way that changes the architecture (e.g. client-only vs SSR, a new store vs local state), ask. Otherwise pick the sensible default and say which one.
2. **Detect context:**
   - read `package.json` for the `vue`, `nuxt`, `pinia`, `typescript` and test-library versions
   - check `tsconfig` strictness
   - work out the project type (Nuxt vs Vite SPA) and the existing conventions (folder layout, validation library such as zod/valibot if already present, UI lib, test setup)
   - load only the references the task needs.
3. **Plan the files.** List which components, composables, stores, server routes and tests will be created or changed, and why each lives where it does.
4. **Implement with the guardrails** from the rule catalog, version-gated.
5. **Security pass.** Run the security checklist over every new data flow: user input → template, URL, redirect, server handler, storage.
6. **Tests.** If a test setup exists, write tests using the D4 strategy. If none exists, say so and offer to set one up. Never add dependencies without asking.
7. **Self-check.** Run through the red-flag list against the produced code. If the project has them installed, run its own `vue-tsc --noEmit` / `nuxi typecheck`, lint and tests.
8. **Report.** Summarize what was built, any non-obvious decisions and their reasons, and any request that was deliberately not followed literally because of a guardrail.

### When a request conflicts with a guardrail
Claude implements the safe or idiomatic version and explains the deviation. It does not silently comply and does not silently refuse. The exception is when the user explicitly insists after the explanation. Claude then complies, but leaves a code comment noting the risk.

### Version awareness
Rules carry an "Applies" range. Claude never emits an API the installed version lacks (`defineModel` needs ≥ 3.4; `useTemplateRef`, `useId` and reactive props destructure need ≥ 3.5; Nuxt 3 vs 4 directory layout differs). When a version blocks a better API, it mentions the upgrade path in one line.

### Review: `/vue-power-up:review [commit]` (secondary)

**Scope resolution, read-only git only:**

| Invocation | What gets reviewed | Git commands |
|---|---|---|
| `/vue-power-up:review` | All uncommitted changes: staged + unstaged changes to tracked files, plus untracked files not ignored by `.gitignore` | `git status --porcelain`, `git diff HEAD`, read untracked files |
| `/vue-power-up:review <hash>` | Exactly what that commit changed, compared with its first parent (a root commit is compared with the empty tree) | `git rev-parse --verify "<hash>^{commit}"`, then `git show <hash>` |

**Precondition (D13).** This runs before anything else, through a bundled script `skills/review/scripts/precheck.sh`. It's injected with `` !`…` `` and takes no user input, so it's safe to pre-execute. It's pre-approved through `allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/precheck.sh)`. It always exits 0 and prints exactly one status line:

| Status | Condition | Command response |
|---|---|---|
| `PRECHECK=OK` | git on PATH and inside a work tree | proceed |
| `PRECHECK=NO_GIT_BINARY` | `git` not found | stop: "/vue-power-up:review needs git installed; `git` was not found on PATH." |
| `PRECHECK=NOT_A_REPO` | not inside a git work tree | stop: "/vue-power-up:review must run inside a git repository; `<cwd>` isn't one." |

If shell injection is disabled by policy (`disableSkillShellExecution`), the placeholder text appears instead of a status line. The skill then runs the same script through the Bash tool and applies the same table.

**Edge cases (after the precondition passes):**
- **No changes:** report "nothing to review" and stop.
- **Invalid or ambiguous hash:** report it and stop. The argument must match `^[0-9a-fA-F]{4,40}$` before it's passed to git, so the argument can't inject options or shell content.
- **Merge commit:** review the diff against the first parent and mention that this is what was reviewed.
- **Huge diff:** review the Vue/TS-relevant files first, and say if any were skipped.

**Filtering:** review `.vue`, `.ts`, `.tsx`, `.js`, `.mjs` files, plus `nuxt.config.*`, `server/**`, `package.json` (for version context) and `tsconfig*.json`. Skip lockfiles, generated output (`.nuxt/`, `.output/`, `dist/`) and binary files.

**Reviewing:**
- Apply the rule catalog, version-gated against the project's `package.json` *as of the reviewed state* (for a commit, read it with `git show <hash>:package.json`).
- Report on changed lines and their immediate context. Pre-existing issues in untouched code are mentioned only when they're `error`-severity security issues.
- **Read-only:** the command never edits files, stages, commits or checks out.

**Output: a standard code review (D14)**
1. **Scope:** "uncommitted changes (N files: …)" or "commit `abc1234` — <subject> (<author>, <date>)", plus the detected Vue/Nuxt/Pinia/TS versions.
2. **Summary:** 2–4 sentences on what the change does and its overall quality.
3. **Verdict:** `Approve`, `Approve with suggestions`, or `Request changes` (any `error` finding means `Request changes`).
4. **Findings,** grouped by severity (`error` → `warn` → `info`). Each one is `[severity] RULE-ID file:line — title`, then *Why* (one or two lines, with the source link) and *Suggestion*.
5. **Proposed changes:** concrete suggested edits as fenced `diff` blocks per file, in priority order, plus any additions outside the diff that the change needs (missing tests, a missing validation schema, a missing type). Each is tied to the finding ids it resolves. This is a proposal only, and nothing is applied.
6. **What's done well** (optional, at most 3 bullets): patterns worth keeping, so the review isn't only negative.
7. **Next step:** one line: "To apply any of these, tell me which (e.g. 'apply 1 and 3')." Proposed changes are numbered so they can be referred to. Applying happens only on that explicit instruction, under the user's normal Claude Code permissions.

The same procedure (`references/review.md`) is used when the user asks in plain language ("review this component"). In that case the scope is the named files.

### Content coverage (anti-patterns the skill must prevent, non-exhaustive)
- **TS:**
  - `any` and unsafe `as` casts
  - runtime-object `defineProps` where the type-based form works
  - untyped `defineEmits` arrays
  - missing `InjectionKey<T>`
  - untyped template refs
  - non-null `!` used to silence errors.
- **Reactivity:**
  - destructuring reactive objects or props (version-gated)
  - reassigning a `reactive()` variable
  - a missing `.value` in script
  - mutating props
  - side effects in `computed`
  - `watch` used where `computed` fits
  - unnecessary `deep: true`
  - un-cleaned watchers, listeners or timers.
- **Components:**
  - manual `modelValue` + emit instead of `defineModel`
  - oversized multi-responsibility components
  - untyped slots (`defineSlots`)
  - deep prop drilling.
- **Templates:**
  - `v-if` and `v-for` on the same element
  - missing `:key`, or an index used as key on mutable lists
  - heavy logic in templates
  - non-semantic clickable elements (a11y basics).
- **Composables:**
  - not named `use*`
  - raw-value-only inputs instead of `MaybeRefOrGetter` + `toValue`
  - UI side effects (toasts, routing) inside data composables
  - missing cleanup
  - calls outside the setup context.
- **Pinia:**
  - destructuring a store without `storeToRefs`
  - mutating state from components in multi-step operations (prefer actions)
  - circular store usage at setup top level
  - using a store outside setup without passing `pinia` (SSR)
  - non-serializable state under SSR.
- **Nuxt:**
  - `useFetch`/`useAsyncData` in event handlers or `onMounted` (use `$fetch`)
  - missing keys or reactive params
  - module-scope mutable state (cross-request pollution) instead of `useState`
  - `window`/`document` during SSR
  - `process.env` instead of `useRuntimeConfig`
  - secrets in `runtimeConfig.public`
  - unvalidated `server/api` input
  - `<a>` instead of `<NuxtLink>` for internal links.
- **Security:**
  - `v-html` with untrusted data
  - `:href`/`:src` bound to user input (`javascript:` URLs)
  - open redirects through `navigateTo`/`router.push` with user-controlled URLs
  - secrets in client bundles
  - unvalidated server input
  - missing auth checks in server routes
  - SSRF via `$fetch(userUrl)` on the server
  - insecure cookie flags
  - sensitive data in `useState` or the Pinia payload (serialized to the client).
- **Testing:**
  - asserting on `wrapper.vm` internals for behaviour
  - arbitrary `setTimeout` waits
  - un-isolated Pinia (`createTestingPinia` / fresh `createPinia` per test)
  - Nuxt-context code tested without `@nuxt/test-utils`.

## Code Style (of the skill content)

- **SKILL.md stays lean** (target ≤ ~300 lines). Detail lives in references and is loaded on demand, so a "write a button" task doesn't pull in server-route security docs.
- **Every rule has the same shape:** id · title · severity, **Why**, **Source** (official link), ❌/✅ minimal TS example, **Applies** (version range), **Exceptions**.

```markdown
### VUE-PINIA-001 · Destructure stores with `storeToRefs`  `error`
**Why:** A store is a `reactive` object, so plain destructuring copies the values and drops reactivity.
**Source:** https://pinia.vuejs.org/core-concepts/#Destructuring-from-a-Store
​```ts
// ❌
const { items, total } = useCartStore()
// ✅
const cart = useCartStore()
const { items, total } = storeToRefs(cart)
const { addItem } = cart // actions can be destructured directly
​```
**Applies:** Pinia 2.x, 3.x · **Exceptions:** none.
```

- Rule ids: `VUE-<DOMAIN>-NNN`, with domains `TS`, `REACT`, `COMP`, `CMPS`, `PINIA`, `NUXT`, `TPL`, `SEC`, `PERF`, `TEST`. Ids are stable and never renumbered.
- Severities: `error` (bug, data leak or security issue), `warn` (fragile, legacy or unidiomatic), `info` (style or opinion).

## Testing Strategy (for the skill itself)

Skills are prompts, so verification is **behavioural evals**, weighted toward write mode (D3):

1. **Write evals (primary):** 8–10 realistic feature prompts covering SPA and Nuxt, Pinia, server routes, forms, lists, and at least 2 **"trap" prompts** whose literal wording invites an anti-pattern or security hole. Each has a grading checklist (rule ids that must not be violated, plus required behaviours such as "explains the deviation"). The generated code must pass `vue-tsc --noEmit` in a scratch project in the scratchpad directory, never in this repo.
2. **Version eval:** the same prompt against a Vue 3.3 `package.json` and a Vue 3.5 one. The output must use version-appropriate APIs.
3. **Review evals (secondary):** about 10 fixtures, each seeded with 1–3 anti-patterns, plus 3 clean controls. Graders check the D14 structure (verdict, findings with rule ids, numbered proposed changes in `diff` blocks) and that nothing was written.
   - **Precondition tests:** `precheck.sh` is tested directly as a shell script (no model involved) against a non-git dir, a git repo, and a PATH with no git. There's also an eval case for the not-a-repo stop, checking the message and that no review is produced.
4. **Review command evals:** in a throwaway git repo in the scratchpad, cover:
   - (a) uncommitted changes: staged, unstaged and untracked together
   - (b) a specific commit hash
   - (c) a root commit
   - (d) an invalid hash and an option-like argument such as `--output=x` (must be rejected)
   - (e) a clean tree (reports "nothing to review").

   Each case must report the correct scope, and git state must be unchanged afterwards (`git status` and HEAD identical before and after).
5. **Trigger evals:** prompts that should trigger the skill ("build a Vue component that…", "add a Pinia store", "create a Nuxt API route") and prompts that shouldn't (React, Svelte, Python).
6. **Manifest validation:** `claude plugin validate .`

## Boundaries

- **Always:**
  - Cite an official source for every `error`/`warn` rule, and record the reasoning in `docs/RATIONALE.md`.
  - Version-gate rules.
  - Keep examples valid TypeScript.
  - Keep SKILL.md lean.
  - Update README.md in the same task as any change to behaviour, commands, install steps or the rule set (D9).
- **Ask first:**
  - Adding hooks, commands, agents or MCP servers.
  - Adding any dependency.
  - Changing names.
  - Filling in publishing metadata (D6).
  - Making any non-official rule stricter than `info`.
- **Never:**
  - `git commit`, push or tag. This applies to *this repo* during development, and the review command must never run a git write operation in the user's repo either.
  - Copy the example repo's text verbatim.
  - Have the skill install packages without the user's consent.
  - Fill in author, repo or license on the user's behalf.

## Success Criteria

- [x] `claude plugin validate .` passes for `plugin.json` and `marketplace.json`. *(Passes. Since D17, both `validate` and `validate --strict` pass with no warnings.)*
- [x] The plugin loads via `--plugin-dir` and via `/plugin marketplace add ~/projects/vue-power`, and the skill appears as `vue-power-up`. *(`--plugin-dir` ✓: both skills listed. Local marketplace ✓, done by the user on 2026-10-21: `claude plugin list` shows `vue-power-up@vue-power-up` as enabled, read from the repo folder, and the session lists the skill `vue-power-up:vue-power-up`. After the D16 rename, the old plugin and marketplace were removed and `vue-power-up@ml2stjnvc` was installed, enabled and read from the repo folder.)*
- [x] Trigger evals: the skill triggers on all positive prompts and on none of the negative ones. *(11/11: 6 positive, 5 negative.)*
- [x] Write evals: 0 `error`-rule violations across all prompts, the code passes `vue-tsc --noEmit`, and every trap prompt produces the safe variant plus an explanation. *(11 write cases at 1.00. All 11 outputs type-check (`vue-tsc` / `nuxi typecheck`) in the T14 harnesses, with a negative control. Both traps pass.)*
- [x] Version eval: no API above the detected version is used. *(Vue 3.3 case: 1 of 3 runs in the final pass matched `useId(`. TPL-006 was clarified and the graders now ignore comments, after which 3/3 runs passed. Vue 3.5 case: 1.00.)*
- [x] Review evals: ≥ 90% recall on seeded `error` rules, and 0 `error` false positives on controls (measured on single runs during development; the user's full run is authoritative, D15). *(The 7 plain-language review cases found 100% of seeded rule ids. False-positive guards: the root-commit review approved with no `[error]`, and the SPA composable review raised no SSR rules. Only 2 clean controls exist, fewer than the 3–5 the strategy planned.)*
- [x] `precheck.sh` passes its shell tests for all three statuses, and `/vue-power-up:review` stops with the right message when there's no git or no repo. *(9/9 shell assertions; headless not-a-repo run ✓.)*
- [ ] `/vue-power-up:review` appears in Claude Code after install. It passes all command evals (uncommitted / hash / root commit / invalid and option-like argument / clean tree) and leaves git state unchanged. *(Appears via `--plugin-dir`, and every scenario was verified by hand with headless runs, git state unchanged. The 6 formal eval cases need `--allow-tools Bash`, which couldn't be granted in the development sandbox, so they're pending the user's full run.)*
- [x] SKILL.md is ≤ ~300 lines. Every rule has an id, severity, why, source, example and applies-range, and is listed in `rule-catalog.md`. *(Main skill 159 lines, review skill 95. `tests/check_catalog.py`: 89 rules consistent. `tests/check_links.py`: 70 sources resolve.)*
- [x] `docs/RATIONALE.md` explains every structural decision (D1–D15, review scope and safety rules, layout, workflow steps, severity model, version gating, progressive disclosure, eval design) and every rule, linked by id.
- [x] README.md exists and covers: what the plugin does, local and marketplace install, write-mode examples, `/vue-power-up:review` with and without a hash, a rule overview linked to `rule-catalog.md`, and limitations. It matches the final behaviour (D9).
- [x] Nothing is committed. *(`git log`: no commits on `main`.)*

## Open Questions

None blocking. To verify during the Plan phase, against the current Claude Code docs:
- ~~whether a command can reference skill files~~ → yes, via `${CLAUDE_PLUGIN_ROOT}` (D11)
- ~~`allowed-tools` syntax~~ → space-separated rules such as `Bash(git diff *)`. Note: it only *pre-approves* tools and doesn't restrict them, so read-only behaviour is enforced by the skill's instructions (see plan, risk R2)
- ~~validate / eval CLI~~ → confirmed (Commands section, D12)
- **Still to verify in implementation:** whether an eval prompt can start with a slash command (`/vue-power-up:review`) to invoke a user-only skill (plan, risk R1).
