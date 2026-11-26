# vue-power-up — Design Rationale

This document explains **why** each implementation decision and each rule exists. `SPEC.md` says *what* is built, and `tasks/plan.md` says *in what order*. Decision ids (`D*`) come from the SPEC decisions log, architecture ids (`A*`) from the plan, and rule ids (`VUE-*`) from the rule catalog.

All entries are complete as of v1.2.3.

---

## Contents

1. [Product decisions (D1–D15)](#1-product-decisions)
2. [Architecture decisions (A1–A11)](#2-architecture-decisions)
3. [Repository layout and packaging](#3-repository-layout-and-packaging)
4. [Rule system](#4-rule-system)
5. [Rules, by id](#5-rules-by-id)
6. [Evaluation design](#6-evaluation-design)
7. [Known limitations](#7-known-limitations)

---

## 1. Product decisions

### D1: Name: `vue-power-up` everywhere
**Decision:** The plugin (`plugin.json` `name`), the marketplace's plugin entry and the main skill directory are all called `vue-power-up`. The repository folder is still `vue-power`. The marketplace itself was first named `vue-power-up` too, and was later renamed `ml2stjnvc` (see D16).

**Why:**
- Claude Code namespaces every component under the plugin `name`, so the review skill becomes `/vue-power-up:review`. Using one name for the plugin and the skill keeps the command and the skill list predictable. The install id is `<plugin>@<marketplace>`, now `vue-power-up@ml2stjnvc`.
- The folder name doesn't matter. When a manifest exists, the plugin name comes from `plugin.json`, not from the directory. Renaming the folder would only break the user's local paths and IDE project for no gain.
- The name was checked against Claude Code's reserved-name rules: it doesn't start with `claude-`/`anthropic-`, isn't a reserved marketplace name, and contains no `claude`/`anthropic` word. `claude plugin validate` raises no name warning.

### D2: No hooks in this version
**Decision:** Enforcement comes from skill instructions plus a mandatory self-check (workflow step 7). There are no `PostToolUse` or other hooks.

**Why:**
- The user chose this explicitly.
- **Trade-off accepted:** a hook would run deterministically after every edit, while skill guidance depends on the model following it. The skill makes up for this by making the self-check an explicit step with concrete checks: red flags, loaded rules, and the project's own type-check, lint and tests. The report must also state which checks ran.
- Hooks would add shell scripts that run on every edit in every project where the plugin is enabled, including non-Vue ones. Those scripts would need maintaining across platforms, and they'd add latency and noise. Leaving them out keeps the plugin pure Markdown, except the one small script the review skill needs (A10).

### D3: Writing is the primary use
**Decision:** The main skill is built around one write workflow (understand → detect → plan → implement → security pass → tests → self-check → report). Review is a secondary, user-invoked command (D8).

**Why:**
- The user's main use is "describe what needs to be done, get code that follows best practices, guardrails and security". Preventing an anti-pattern while writing is cheaper than catching it in review.
- **Why a fixed workflow and not just a rule list:** a rule list tells the model *what* good code looks like, but not *when* to check. Most real mistakes come from skipped steps: writing before checking the Vue version, not tracing user input to `v-html`, claiming tests pass without running them. Each step closes one of those gaps. The individual steps are explained under [Write workflow](#write-workflow-steps).

### D4: Testing libraries: Testing Library and Vue Test Utils
**Decision:** Both are supported. `references/testing.md` maps goals to libraries:
- Testing Library for user flows
- VTU for component contracts
- `@nuxt/test-utils` for Nuxt-runtime code.

The project's existing stack always wins. See the [Testing rules](#testing-vue-test-referencestestingmd) section for the reasoning, and VUE-TEST-001..006 for the rules.

### D5: Nuxt 4 primary, Nuxt 3 noted
**Decision:** Nuxt rules are written against Nuxt 4 and cite the versioned `nuxt.com/docs/4.x/` pages. Rules whose behaviour differs on Nuxt 3 say so in **Applies**. Examples: `app/` srcDir (NUXT-010), shallow fetch data (NUXT-006), `undefined` defaults and `pending` semantics (NUXT-005), shared refs per key (NUXT-004).

**Why:**
- Nuxt 4 is the current major (the unversioned docs URLs redirect to `4.x`), so new projects are Nuxt 4.
- **Its breaking changes are exactly where generated code goes wrong:** models trained mostly on Nuxt 3 code put pages in the root `pages/` and mutate fetched data in place.
- **Nuxt 3 projects are still common,** so the version detection in SKILL.md step 2 decides which variant applies, including Nuxt 3 with `compatibilityVersion: 4`.
- **Verified by the `write-nuxt-*` evals:** they scaffold a Nuxt 4 project and check that pages land in `app/pages/` and that fetched data isn't mutated in place.

### D6: Publishing metadata left as placeholders
**Decision:** `author`, `repository`, `homepage` and `license` are left out of `plugin.json`. `marketplace.json` `owner.name` was originally the literal placeholder `TODO-owner`. The user has since filled it in (D16).

**Why:**
- The user will configure publishing themselves. Filling in a name, repo URL or license on their behalf would publish identity or legal terms they haven't chosen. The license especially is a legal decision, not a technical one.
- **Leaving out vs placeholder:** `plugin.json` fields are optional, so leaving them out is honest and only produces a validator *warning*. `marketplace.json` `owner.name` is *required* (validation fails without it), so it gets an obvious placeholder that can't be mistaken for a real value.
- Consequence: `claude plugin validate .` reported one `author` warning, and `--strict` failed until these fields were set.
- **Update (D16, D17):** the user has since set the marketplace owner, `author` (Milos Stojanovic) and `license` (MIT). Only `repository`/`homepage` remain unset. The README "Publishing configuration" table shows the current values.

### D16: Marketplace renamed to `ml2stjnvc`
**Decision:** `marketplace.json` `name` is `ml2stjnvc`, `owner.name` is `Milos Stojanovic`, and the description is general rather than specific to this plugin. The plugin keeps the name `vue-power-up`.

**Why:**
- This is the user's choice (2026-10-21). A personal marketplace name with a general description can list more plugins later without another rename.
- Only the marketplace changed, so every command and skill name stays the same (`/vue-power-up:review`, `vue-power-up:vue-power-up`). Only the install id changes, to `vue-power-up@ml2stjnvc`.
- **Migration:** Claude Code tracks installs by marketplace name, so the old `vue-power-up@vue-power-up` install and the `vue-power-up` marketplace were removed, then the folder was added again as `ml2stjnvc` and the plugin reinstalled. Anyone who installed under the old name has to do the same (see the README's Remove and Local marketplace steps).

### D17: Author and license set (MIT)
**Decision:** `plugin.json` has `author: { name: "Milos Stojanovic" }` and `license: "MIT"`, and the repo root has a standard MIT `LICENSE` file (copyright 2026 Milos Stojanovic).

**Why:**
- This is the user's choice (2026-10-21). It's the legal and identity decision D6 deliberately left to them.
- **Both the field and the file:** the plugin directory accepts either one, but the SPDX id in `plugin.json` is machine-readable, while the `LICENSE` file is what MIT itself requires to travel with copies and what GitHub detects.
- **Author name only, no email:** an email address wasn't provided, and it would be published with the plugin.
- **Result:** `claude plugin validate . --strict` now passes, and the directory's `LICENSE_MISSING` refusal is gone. The only remaining directory warning is the optional icon.

### D7: Audit mode excluded
**Decision:** There's no whole-project audit mode in this version.

**Why:** The user scoped it out. Writing (D3) and diff/commit review (D8) cover the main workflows, and an audit mode would add config, dependency and architecture checks that need their own rules and evals. It can be added later on top of the same rule catalog.

### D8: `/vue-power-up:review [commit]`
**Decision:** One command, two scopes. With no argument it reviews everything uncommitted (staged, unstaged and untracked). With a hash it reviews exactly that commit.

**Why:**
- These are the two moments a developer wants a review: *before* committing ("is what I have good?"), and *after*, for a specific change ("what did this commit do?").
- **Untracked files are included** (unless ignored by `.gitignore`), because new components are usually untracked until the first commit. Leaving them out would skip exactly the new code that most needs review. `git ls-files --others --exclude-standard` lists them while respecting ignore rules, so `node_modules`, `.nuxt` etc. never show up.
- **Staged and unstaged together** (`git diff HEAD`): the user asked for "current changes", not "staged changes". Splitting them would make the user think about the index for no benefit.
- **Merge commits are diffed against the first parent** (`--diff-merges=first-parent`). That's "what this merge brought into the branch". The default combined diff shows only conflict resolutions, which isn't what a reviewer expects.
- **Root commits need no special case:** `git show` diffs them against the empty tree.
- **Repos with no commits yet** use `git diff --cached`, because `HEAD` doesn't exist and `git diff HEAD` would fail.

### D9: README is a maintained deliverable
**Decision:** `README.md` exists from T1. Every task that changes behaviour, commands, install steps or requirements updates it in the same task. Sections for features not built yet are marked *(planned)*.

**Why:**
- Marketplace users read the README to decide whether to install. Stale install steps are the most common reason a plugin "doesn't work".
- Updating it in the same task means the README is never behind the code at any checkpoint. A "write docs at the end" task tends to get skipped or rushed.
- The *(planned)* markers keep the skeleton honest: it never claims a feature that doesn't exist yet.
- The README doesn't duplicate the rule list. It links to `rule-catalog.md` (A9), so adding rules doesn't require README edits.

### D10: Review command implemented as a user-invoked skill
**Decision:** `skills/review/SKILL.md` with `disable-model-invocation: true` and `argument-hint: "[commit]"`, rather than a `commands/review.md` file.

**Why:**
- **Claude Code docs:** custom commands "have been merged into skills", and for plugins: "Prefer `skills/` for new plugins". Skills support everything this command needs: `allowed-tools`, `argument-hint`, `$ARGUMENTS`, `!` pre-execution, `${CLAUDE_SKILL_DIR}`, and bundled `scripts/`.
- **Naming:** plugin skills are namespaced as `<plugin>:<skill>`, so a skill directory named `review` gives exactly the `/vue-power-up:review` the user asked for.
- **`disable-model-invocation: true`:**
  - The review is something the user *runs*, not something Claude should start on its own in the middle of a write task.
  - It also keeps the review skill out of the competition for plain-language requests. "Review this component" goes to the main skill, which uses the same `review.md` procedure with the named files as the scope.

### D11: Shared catalog via `${CLAUDE_PLUGIN_ROOT}`
**Decision:** The review skill reads `${CLAUDE_PLUGIN_ROOT}/skills/vue-power-up/references/review.md`, the catalog and the domain files. It has no rule copies of its own.

**Why:**
- Claude Code substitutes `${CLAUDE_PLUGIN_ROOT}` with the installed plugin's absolute path inside plugin skill content. That works wherever the plugin is installed (inline `--plugin-dir`, a marketplace cache, or a different machine), unlike relative paths, which depend on the current working directory.
- One copy of the rules is what makes A2 (shared catalog) actually hold.

### D12: Native `claude plugin eval` format
**Decision:** Evals live in `evals/<case>/prompt.md` + `graders/*.md` (with an optional `case.yaml`) and run with `claude plugin eval`. Run output in `evals/results/` is git-ignored.

**Why:**
- It's the format Claude Code's own eval runner reads (confirmed with `claude plugin eval --help` and the docs). Anyone, including the user doing the full run (D15), can run the suite with one command, no custom harness needed.
- The runner has a built-in no-plugin baseline arm, so it can show what the plugin *adds* over plain Claude, which is the real measure of a skill's value.
- `evals/results/` is ignored because the runner writes a timestamped results directory on every run. Those are local artefacts, not source, and the docs recommend ignoring them.

### D13: Review precondition: git only
**Decision:** Before anything else, check that git is installed and that the working directory is inside a git work tree. If not, stop with a fixed message. There's **no** write-access check.

**Why:**
- **Why check at all:** both scopes are defined in git terms. Without git there's nothing to review, and git's raw error (`fatal: not a git repository`) would be followed by Claude improvising. A fixed message tells the user exactly what's wrong.
- **Why two separate statuses:** "install git" and "cd into a repository" are different fixes.
- **Why no write-access check:** this was considered (the user's first idea) and dropped at the user's direction. The command only reads, so writability doesn't matter for reviewing. Applying proposed changes is a separate step the user asks for, and Claude Code's normal permission system already governs it. A write check would have blocked reviews of read-only checkouts for no benefit.
- **"Inside `.git`" counts as not a repo:** `git rev-parse --is-inside-work-tree` prints `false` there, and there's no working tree to review. Tested.

### D14: Review output is a standard code review
**Decision:**
- **Format:** Scope + versions → Summary → Verdict → Findings by severity → numbered Proposed changes as `diff` blocks → optional "done well" → one closing line on how to apply.
- **Defined once** in `references/review.md`, used by both the command and plain-language reviews.

**Why:**
- **Familiar:** it matches what developers expect from a PR review. First "what is this and is it OK" (summary, verdict), then the details (findings), then concrete help (proposed changes).
- **Verdict derived mechanically from severity:** any `error` → Request changes, `warn` → Approve with suggestions. The verdict is consistent across runs and can be graded, rather than being a mood.
- **Findings cite rule ids and link the official source:** the developer can check the claim instead of trusting it (see the rule-system rationale).
- **`GENERAL` findings:** the catalog can't cover every bug (e.g. `splice(-1, 1)` deleting the last item, which was found in a real test run). A reviewer that ignored real bugs because no rule matched would be worse than useless. Ids are never invented, so catalog ids stay meaningful.
- **Proposed changes as diffs:** a diff is unambiguous about *what* changes and *where*, and the user can apply it by hand or ask Claude to. Missing tests or validation are proposed changes too, which is the "proposal for additional changes" the user asked for.
- **Numbered** (A11), so "apply 1 and 3" is a precise instruction.
- **Changed lines only** (plus pre-existing *security* errors the change touches): reviewing untouched code turns every review into an audit (out of scope, D7) and buries the findings that matter.
- **Repository content is treated as data:** a commit message or code comment saying "ignore previous instructions" must not steer the reviewer. Reviews run on code the user may not have written.

### D15: Full eval run is the user's
**Decision:** During development each task runs only its own cases, once each and without the baseline (`--runs 1 --ablation none`). The full run (3 runs per case, with and without the plugin) is done by the user.

**Why:**
- A full run costs `cases × 3 runs × 2 arms` agent sessions. The user chose to own that cost and its timing.
- Single targeted runs are enough to catch broken prompts and graders during development. Statistical confidence (variance across runs, the baseline delta) only matters once the suite is complete.

---

## 2. Architecture decisions

### A1: Two skills: auto-triggered `vue-power-up` and user-only `review`
See D10. The main skill handles everything model-initiated (writing, plain-language reviews). The review skill handles only the explicit command.

### A2: One rule catalog, shared
**Decision:** All rules live in `skills/vue-power-up/references/`, indexed by `rule-catalog.md`. The write workflow and the review command both use them.

**Why:**
- With two copies (one phrased for writing, one for reviewing), a change to one would sooner or later leave the review flagging what the writer produces, or the other way round. One copy makes that drift impossible.
- The index table gives an overview of every rule (id, severity, applies-range, file) without loading every reference file. Reviewers use it to map a finding back to its full rule.

### A3: Progressive disclosure
**Decision:** `SKILL.md` holds only the workflow, the version table, cross-cutting red flags and a reference map (target ≤ ~300 lines; Claude Code's documented limit is 500). Domain rules live in one file per domain, loaded only when the task touches that domain.

**Why:**
- A skill's `SKILL.md` is loaded every time the skill fires, while files in `references/` are read only when Claude decides it needs them. A task like "add a button component" shouldn't pay the context cost of the Nuxt server-route and SSR rules.
- Less irrelevant text in context means the relevant rules get more attention. A long, mixed rule dump weakens whichever rule matters for the task at hand.
- The reference map in `SKILL.md` lists **only files that exist**. Each domain task adds its row when it adds its file. Pointing Claude at files that don't exist would make it waste a turn or guess.

### A4: Stable rule ids, severity, source, version range
See [Rule system](#4-rule-system).

### A5: No shell pre-execution with user arguments
**Decision:** Only the argument-free precheck script is pre-executed with `` !`…` ``. Every git command that uses the hash is run by Claude through the Bash tool, after Claude has checked the argument against `^[0-9a-fA-F]{4,40}$`.

**Why:**
- `!` commands run *before* Claude sees the skill. If they interpolated `$ARGUMENTS`, a value such as `--output=x` or `$(…)` would reach the shell or git unchecked.
- A failing `!` command aborts the whole skill with a raw error, while Claude can turn a failed `git rev-parse --verify` into a clear "commit not found" message.
- **Verified:** `/vue-power-up:review --output=pwned.txt` replies `Invalid argument …`, runs no git command, and creates no file.

### A6: Narrow `allowed-tools` for the review skill
**Decision:** `allowed-tools` lists the precheck script, `git rev-parse *`, `git status --porcelain`, `git diff HEAD` (with and without `-- *`), `git diff --cached`, `git ls-files --others --exclude-standard`, `git show *`, and `Read`/`Grep`/`Glob`.

**Why:**
- These are exactly the commands the skill prescribes. Pre-approving them means a review runs without permission prompts, while anything else still prompts under the user's normal rules.
- **Known limit:**
  - `allowed-tools` *pre-approves*; it doesn't *restrict*.
  - The wildcard forms (`git show *`, `git rev-parse *`) would also pre-approve a write-capable flag such as `git show --output=<file>`.
  - **Mitigations:**
    - the argument is checked before use, so the user's argument can't add flags (A5)
    - the skill forbids `--output`/`-o`/`--ext-diff`/`--textconv` and redirection, and treats repository content as data
    - evals assert no write-capable git call and no `Write`/`Edit` use.
  - Narrower patterns (one per exact command line) aren't possible because the hash varies.

### A7: Graders: regex for files, LLM for short answers
**Decision:**
- **Produced files:** `regex` graders, pointed at a pinned path (`target: { source: file, path: … }`), check that required APIs are present and anti-patterns absent.
- **`llm` graders:** only for things a regex can't decide. Examples: "does the component mutate the model object in place", "does the final report claim unrun checks passed", "is the review summary accurate".
- **Every case:** has one `tool_used: Skill` grader to show the plugin produced the result.

**Why:**
- The eval docs warn that `llm` verdicts vary more on long text, and recommend regex over files for stable signals.
- Rule ids in review output make review grading regex-friendly too (A4).
- Pinned output paths in the prompts (e.g. `src/components/ProfileForm.vue`) make file graders possible at all.

### A8: Type-checking in a scratch harness, not in eval runs
**Decision:** Generated code is type-checked *outside* the eval runs, in throwaway projects in the scratchpad with real dependencies installed. Write-eval outputs (kept with `--keep-temp`) are copied in and checked with `vue-tsc --noEmit` / `nuxi typecheck`.
- **`spa35`:** Vue 3.5 + Pinia 3 + Vitest + Testing Library + VTU.
- **`spa33`:** Vue 3.3.
- **`nuxt4`:** Nuxt 4.1.

**Why:**
- **Real type errors are the strongest proof** that the generated code is correct for the stated versions. Regex graders can only check patterns.
- **Eval workspaces start empty,** and scaffold scripts have a 120 s limit, too short for `npm install` (Nuxt alone pulls ~670 packages). Installing once in a harness keeps the check real without adding dependencies to this repo or to the eval cases.
- **One harness per version** (3.3 vs 3.5), so version-gated code is checked against the Vue it targets. A 3.3 output that used `defineModel` would fail there.
- **Negative control:** a deliberately broken file is reported in every harness. Without that check, a misconfigured `tsconfig` that silently excluded files could fake a clean result.

**Result (T14):** all 11 write-eval outputs type-check with 0 errors.

### A9: README links to the catalog instead of duplicating it
See D9.

### A10: Git precondition in a bundled script
**Decision:** `skills/review/scripts/precheck.sh` (POSIX `sh`, no arguments, always exits 0, prints one `PRECHECK=` line). It's pre-executed through `` !`${CLAUDE_SKILL_DIR}/scripts/precheck.sh` `` and pre-approved in `allowed-tools`.

**Why:**
- **Deterministic:** the precondition is decided by code before the model acts, not by the model's reading of a git error.
- **Safe to pre-execute:** no user input reaches it (contrast A5).
- **Always exit 0:** a non-zero `!` command aborts the whole skill with a raw error. Exiting 0 with a status line lets the skill give the exact friendly message from the spec.
- **`command -v git`** is a shell builtin, so the "git missing" case is detected without git.
- **Testable without a model:** `tests/precheck.test.sh` covers non-repo, repo root, subdirectory, inside `.git`, and git missing from `PATH`, plus the exit code and the single-line output.
- **Fallback:** if an admin disabled skill shell execution, the placeholder text appears instead of a status, and the skill tells Claude to run the same script through Bash.
- **Requires** a POSIX shell (Git Bash on Windows) and an executable script bit. Git preserves the bit for marketplace installs.

### A11: Numbered, proposal-only review changes
See D14. Proposal-only keeps the command strictly read-only (D13 dropped the write check *because* nothing is written). Numbering turns "apply some of them" into a precise follow-up instruction.

---

## 3. Repository layout and packaging

### Skill under `skills/vue-power-up/`, not at the repo root
**Decision:** The scaffold's root-level `SKILL.md` (loaded through `"skills": ["./"]`) moved to `skills/vue-power-up/SKILL.md`. The `skills` key was removed from `plugin.json`.

**Why:**
- **Clean skill payload.** A skill is its whole directory. With the skill at the repo root, Claude could treat `README.md`, `SPEC.md`, `tasks/`, `docs/` and `evals/` as skill files. Under `skills/vue-power-up/`, only the files written for Claude's context sit beside `SKILL.md`.
- **Room for a second skill.** The review command is a separate skill (`skills/review/`, D10). The root layout supports only one skill.
- **No `skills` key.** Claude Code always scans the default `skills/` directory, and the `skills` key *adds* directories to that scan. Keeping `"./"` would have loaded the plugin root as an extra skill. With the default location the key isn't needed, and leaving it out means one less thing to keep in sync.

### Marketplace in the same repo, `source: "./"`
**Decision:** `.claude-plugin/marketplace.json` lists one plugin whose `source` is the repo root (`"./"`).

**Why:**
- One repo serves both distribution paths the user asked for:
  - local (`--plugin-dir`, or `/plugin marketplace add <path>`)
  - remote (`/plugin marketplace add <owner>/<repo>` once published).
- Relative-path sources work for `directory` (local) and `github`/`git` marketplace sources, which are the two the user will use. They don't work for a bare `url` marketplace source, which isn't planned.
- `plugin.json` stays the authority for components (the default `strict: true`). The marketplace entry only adds a description and a category for the listing, so the two files can't disagree about what the plugin contains.

### Manifest contents
- **`version: "1.2.3"`:** setting a version pins marketplace users to it until it's bumped. That's the predictable behaviour for a published plugin. (It started at `0.1.0`; the maintainer bumped it to `1.2.3`.)
- **`description`:** says the two capabilities (write, review) and the stack in one sentence, because it's what `/plugin` listings show.
- **`keywords`:** discovery tags for the stack (`vue`, `nuxt`, `pinia`, `typescript`, …) and the capabilities (`code-review`, `security`).
- **`$schema`:** kept from the scaffold for editor autocomplete. Claude Code ignores it at load time.

### `.gitignore`: `evals/results/`
See D12.

### Verification performed in T1
- `claude plugin validate .` → *Validation passed with warnings*. The only warning is the expected D6 `author` one, on both the marketplace entry and the plugin manifest.
- `claude --plugin-dir . plugin details vue-power-up` → plugin `vue-power-up 0.1.0`, Skills (1): `vue-power-up`.

---

## 4. Rule system

### Rule ids: `VUE-<DOMAIN>-NNN`, never renumbered
- **Traceability:** a review finding, a code comment such as `// VUE-SEC-001 accepted by user`, and a RATIONALE entry all refer to the same id. If ids were renumbered, old comments and reports would point at the wrong rule.
- **Gradeable:** eval graders can check for a rule id with a simple regex, which is deterministic. Judging free-text descriptions would need an LLM and be less stable (A7).
- **Domain prefixes** tell a reader at a glance which area is affected, and match the one-file-per-domain layout (A3).
- **Retired, not deleted:** a retired rule keeps its row marked *Retired*, so its id is never reused with a different meaning.

### Three severities, tied to behaviour
| Severity | Write mode | Review |
|---|---|---|
| `error` | never produced unless the user insists | Request changes |
| `warn` | avoided unless there's a stated reason | Approve with suggestions |
| `info` | the project's convention wins | never blocks |

- **Why only three:** each level maps to a distinct action in both modes. More levels (e.g. "critical" vs "error") would need extra rules about how they differ, with no difference in what Claude does.
- **`error` = bug, data leak or security issue.** A reviewer must be able to justify blocking a change. "Unidiomatic" alone isn't enough to block, so it's `warn`.
- **Unofficial means `info` at most.** The plugin is published to a marketplace, so its defaults must be neutral. A community convention (e.g. a file-naming style) can be suggested but must never block a review or override the project's own convention. This is also why several rules from the example repo (e.g. "never use `index.vue`") aren't carried over as errors.

### Rule template
Every rule has: **Why**, **Source**, ❌/✅ **example**, **Applies**, **Exceptions**.
- **Why:** the model applies a rule better, and can explain a deviation to the user, when it knows the failure the rule prevents. A bare "do X" invites mechanical application in the wrong places.
- **Source** (official URL): makes each rule verifiable, and protects against teaching outdated or invented APIs (plan risk R3). Every `error` and `warn` rule must have one.
- **❌/✅ example:** one minimal pair communicates a pattern more reliably than prose, and gives the review a concrete before and after for its proposed changes.
- **Applies:** see version gating below.
- **Exceptions:** the main defence against false positives (plan risk R4). Listing the legitimate uses next to the rule stops reviews from flagging correct code.

### Version gating
**Decision:** Every rule states the versions where its recommended fix exists. `SKILL.md` has a minimum-version table for the most important APIs, and the workflow resolves versions *before* writing code.

**Why:**
- Recommending `defineModel` to a Vue 3.3 project, or `useTemplateRef` to 3.4, produces code that doesn't compile. That's worse than the anti-pattern it replaces. Version gating makes "best practice" mean "best practice *for this project*".
- **Why this resolution order (`node_modules` → lockfile → `package.json` range minimum):**
  - `node_modules` holds what actually runs.
  - The lockfile is what will be installed.
  - A range like `^3.4.21` only guarantees its minimum, so assuming more could produce code that breaks on a fresh install that resolves lower.
- **Nuxt ships its own `vue`,** so `vue` is resolved from `node_modules` even when it isn't a direct dependency.
- **Below the range, a rule isn't flagged.** Flagging code for not using an API the project can't use would be noise. In write mode the skill uses the best alternative available and mentions the upgrade path once.

The minimum versions in the `SKILL.md` table come from the Vue changelog and blog announcements:
- **Vue 3.3:** `defineSlots`, `defineOptions`, generic components, imported types in macros, `toValue`
- **Vue 3.4:** stable `defineModel`, `watch` `once`
- **Vue 3.5:** stable reactive props destructure, `useTemplateRef`, `useId`, `onWatcherCleanup`, numeric `deep`
- **Nuxt 4:** `app/` source dir, or opt-in on Nuxt 3 via `future.compatibilityVersion: 4`.

<a id="write-workflow-steps"></a>
### Write workflow steps
| Step | Why it exists |
|---|---|
| 1. Understand | Restating the deliverable catches misunderstandings cheaply. Asking **only** when the answer changes the architecture (SSR vs client, store vs local state) avoids pestering the user about choices that have a sensible default, which is then named in the report so it can be corrected. |
| 2. Detect context | Most "best practice" mistakes depend on context: the version (gating), Nuxt vs SPA (data fetching and SSR rules apply only to Nuxt), the Nuxt 4 `app/` layout (wrong file locations break auto-imports), existing libraries (introducing zod when the project uses valibot fragments the codebase). **Never adding dependencies unasked** respects the user's control over the supply chain and bundle size. |
| 3. Plan files | Listing files before writing forces decisions about structure (component vs composable vs store), where it's cheap to change course, and gives the user a map of the change. |
| 4. Implement | `<script setup lang="ts">` is the officially recommended form for SFCs with TypeScript, and gives the best type inference and least boilerplate. Existing Options API code is left alone so a feature request doesn't turn into an unrequested migration. |
| 5. Security pass | Security bugs come from data flows, not single lines. Checking source → sink catches what line-by-line rules miss (e.g. a route param that reaches `v-html` through a computed). The sinks listed are the ones a Vue/Nuxt app actually has: template HTML, URL attributes, redirects, server handlers, client-visible state, cookies. |
| 6. Tests | Tests are part of "done" in projects that have them. Tests that check what the user sees survive refactors; `setTimeout`-based waits are flaky. When there's no setup, the skill *offers* one rather than installing it, because test tooling is a project-level decision. |
| 7. Self-check | The red flags catch process mistakes, and the project's own type-check, lint and tests catch what reading the code misses. Only **existing** checks are run, so the self-check never installs or reconfigures anything. Pre-existing failures are reported, not fixed, to keep the change focused. |
| 8. Report | "Every guardrail deviation" makes it visible wherever Claude didn't do literally what was asked, which the user is entitled to know about. Listing the checks that ran (and their results) stops unverifiable "all good" claims. |

### Conflict policy: deliver safely, explain, and comply only if the user insists
- **Why not comply silently:** the user gets an anti-pattern or vulnerability without knowing it.
- **Why not refuse:** the user often has context Claude doesn't (a trusted HTML source, a legacy constraint). Blocking them is unhelpful and pushes them to work around the plugin.
- **The middle path:** build the safe version and explain. If the user insists after that, comply, but leave a **code comment with the rule id** so the decision is visible to future maintainers and future reviews rather than lost in chat history.

### Cross-cutting red flags in `SKILL.md`
Only process-level red flags live in `SKILL.md` (versions, dependencies, Options API, unexplained deviations, unchecked data flows, unverified claims). Domain-specific red flags (e.g. destructuring a store) live in their reference files and are added to `SKILL.md` only if they're common and high-impact, so `SKILL.md` stays within its line budget (A3).

### Skill description (frontmatter)
- **Lists concrete triggers:** `.vue` SFCs, `<script setup>`, composables, Pinia stores, Nuxt pages/layouts/server routes/middleware/plugins. The description is what Claude matches requests against, so it names what the user will actually ask for.
- **Includes "reviewing":** plain-language review requests ("review this component") should also use the rules.
- **Explicitly excludes React, Svelte, Angular and Vue 2 Options-API-only maintenance,** so the skill doesn't fire on lookalike frontend tasks.
- **Validated in T13** against 11 trigger cases: 6 that should fire (Pinia store, SFC modal, Nuxt API route, a composable with no "Vue" in the prompt, an Options→Composition conversion, a plain-language component review) and 5 that shouldn't (React, Svelte, Python, Express, Angular). All passed on the first run, so the wording wasn't changed.

## 5. Rules, by id

Each entry covers **why the rule is included**, **why it has this severity**, and any notable design choice. The rule text itself (Why/Source/example) is in the reference file. This section records the *authoring* reasoning that doesn't belong in Claude's context.

### TypeScript in SFCs (`VUE-TS`, `references/typescript-sfc.md`)

#### VUE-TS-001 · `<script setup lang="ts">` for new SFCs
- **Included:** it's the foundation every other TS rule assumes. Type-based macros only exist in `<script setup>`.
- **`warn`, not `error`:** an untyped component isn't a bug in itself.
- The exception (don't migrate untouched Options API files) prevents scope creep. A feature request shouldn't silently become a refactor (see the workflow step 4 rationale).

#### VUE-TS-002 · Type-based `defineProps`
- **Included:** runtime prop objects with `PropType` casts are the most common way TS Vue code loses precision. `Object as PropType<User>` is an unchecked cast.
- **`warn`:** the runtime form works.
- **Applies ≥ 3.3** because imported and complex types in the macro argument only compile from 3.3. On 3.2 the runtime form is the correct fallback, hence the exception.
- "Bind `const props =` only when script reads them" is folded in as guidance rather than a separate rule. An unused binding is harmless, so a rule of its own would just add review noise.

#### VUE-TS-003 · Props defaults
- **Included:** defaults are where version differences bite.
  - 3.5 destructure takes plain values.
  - 3.3–3.4 `withDefaults` needs factories for mutable defaults.
  - Mixing the two forms causes type errors or shared state.
- Verified against the Vue TS guide: "default values for mutable reference types … should be wrapped in functions when using `withDefaults` … **not** necessary when using default values with destructure."
- **`warn`:** the shared-default bug only shows up when an instance mutates the default.
- `withDefaults` is explicitly *not* flagged on 3.5, because it's still supported and flagging it would be churn.

#### VUE-TS-004 · Typed `defineEmits`
- **Included:** array-syntax emits are untyped at both ends, and it's one of the most common patterns in older code and LLM output.
- **`warn`:** there's no runtime failure.
- **Named tuples (3.3+)** were chosen over call signatures because they're shorter and name each payload argument. The 3.2 fallback is noted in Applies.

#### VUE-TS-005 · Explicit `ref<T>` generics
- **Included:** `ref(null)` / `ref([])` inferring `Ref<null>` / `Ref<never[]>` is a frequent source of later `as any` casts.
- **`warn`:** the compiler catches the misuse, but usually in a way that tempts a cast.

#### VUE-TS-006 · Typed template refs
- **Included:** template refs are a common `any` leak, and the not-yet-mounted `null` state is often ignored.
- **Version split:** `useTemplateRef` from 3.5 (docs: types can be auto-inferred with language-tools ≥ 2.1), and `ref<T | null>` before it.
- The example shows the explicit generic, so it compiles without relying on IDE inference.

#### VUE-TS-007 · `InjectionKey` + missing-provider handling
- **Included:** string-key injection yields `unknown`, and `inject()` returns `T | undefined`. Code often hides that with `!` or `as`.
- **The explicit throw** in the example gives a clear error at the misuse site instead of a `Cannot read properties of undefined` later.
- **`warn`:** works at runtime when the provider exists.

#### VUE-TS-008 · `defineSlots`
- **Included:** scoped slot props are the last untyped surface of a typed component.
- **`warn`** (official API, a real type hole) rather than `info`.
- **Exception:** plain default slots, where there's nothing to type.

#### VUE-TS-009 · Generic components
- **Included:** reusable list/select/table components are where `any` most often enters a codebase, and `generic` is the official fix.
- **`warn`.**
- The example combines `generic` with `defineModel` (COMP-001) to show the two working together.

#### VUE-TS-010 · No `any` / unchecked `as` / silencing `!`
- **Included:** these are the escape hatches that undo every other TS rule.
- **`warn`, not `error`:**
  - The type escape itself isn't the bug.
  - *Unvalidated external data* is, and that's covered with `error` severity by the security and Nuxt server rules (cross-referenced).
  - Keeping this rule at `warn` avoids double-counting one problem.
- **Exceptions:** DOM event-target narrowing, `as const` and test doubles are the legitimate uses and would otherwise cause false positives.

#### VUE-TS-011 · `strict` + `vue-tsc`
- **Included:** without `vue-tsc`, none of the template type checking the other rules rely on actually runs. Without `strict`, `null` handling isn't checked.
- **Write mode never changes config unasked** (SKILL.md red flag), so the rule tells Claude to *mention* the gap.
- **Reviews flag it only when the change loosens config**, so every review of a non-strict project doesn't repeat it.

### Component design (`VUE-COMP`, `references/components.md`)

#### VUE-COMP-001 · `defineModel`
- **Included:** the hand-written `modelValue` + emit pattern dominates pre-3.4 code and training data. It's the single most impactful modernization in the example repo this plugin was modelled on.
- **`warn`:** the old pattern works.
- **The pre-3.4 exception** shows the *correct* old form (a computed getter/setter), so on older versions Claude doesn't fall back to a buggy local-copy pattern.

#### VUE-COMP-002 · Never mutate props
- **`error`:** top-level assignment is a runtime warning and has no effect. Nested mutation changes parent state invisibly. Both are real bugs.
- **Three alternatives** (emit, local copy, `defineModel`) are given because the right one depends on who should own the data.

#### VUE-COMP-003 · Multi-word component names
- **Official style guide *Essential*** (collision with HTML elements).
- **`warn`, not `error`:** collisions are rare in practice, while the rule is cheap to follow.
- **Nuxt pages and layouts are excepted** because their file names are routes, not component tags. Flagging `pages/index.vue` would be a false positive in every Nuxt app.

#### VUE-COMP-004 · PascalCase file/tag names
- **Style guide *Strongly recommended*,** but purely a convention, so it's `info` per the severity policy: the project's existing convention wins.

#### VUE-COMP-005 · `defineExpose` only for imperative actions
- **Included:** reaching into child state through template refs is a common workaround that breaks one-way data flow.
- **`info`:** the docs describe `defineExpose` but don't prescribe this limit. It's an architectural recommendation, not an official rule.

#### VUE-COMP-006 · Split multi-responsibility components
- **Included:** the spec lists "oversized multi-responsibility components" as an anti-pattern, and the Vue docs show extracting composables for code organization.
- **`info`:** there's no objective threshold.
- **No line limit:** a hard line count would produce false positives on cohesive components. The exception ("don't extract one-off logic just to shorten a file") guards against over-engineering, which is the opposite failure.

#### VUE-COMP-007 · Avoid prop drilling
- **Included:** the Vue docs name prop drilling as the problem provide/inject solves.
- **`info`:** one intermediate level is often clearer than injection. The exception says so, to avoid pushing provide/inject everywhere.

#### VUE-COMP-008 · Scoped styles
- **Style guide *Essential*;** leaking styles cause real, hard-to-trace regressions.
- **`warn`.**
- **Exceptions:** global-style files, utility-CSS projects and intentional `:deep()`, which are all common legitimate setups.

#### VUE-COMP-009 · SFC block order
- **Style guide *Recommended*,** purely a convention, so `info`.
- **Script-first** follows the current docs' examples and recommendation. Template-first projects are explicitly accepted.

### Reactivity (`VUE-REACT`, `references/reactivity.md`)

#### VUE-REACT-001 · No destructuring `reactive()` without `toRefs`
- **`error`:** the result is stale UI with no error message, one of the most common Vue bugs.
- **The 3.5 props exception** was checked against the docs: the compiler rewrites access to destructured props as `props.x`. It's included so reviews don't flag correct 3.5 code.
- Pinia stores are pointed to `storeToRefs` (PINIA rules), because `toRefs` on a store would also wrap actions.

#### VUE-REACT-002 · Don't replace a `reactive()` object
- **`error`:** after reassignment the template keeps showing the old object.
- **Both fixes are given:** `ref` + reassign, or `Object.assign` on the reactive object. Which one fits depends on whether the state is ever replaced as a whole.

#### VUE-REACT-003 · `.value` in script
- **`error`:** `if (ref)` is always truthy, which is a silent logic bug.
- Kept as an explicit rule even though TypeScript catches *some* cases (arithmetic) but not truthiness checks.
- **Exception:** refs nested in `reactive()` are unwrapped, so they don't need `.value`. Without the exception, correct code would be flagged.

#### VUE-REACT-004 · Prefer `ref()`
- The Vue docs explicitly recommend `ref()` as the primary API.
- **`info`:** `reactive()` used within its limits is correct, and many codebases use it for form state. Forcing a style change would be noise.

#### VUE-REACT-005 · `computed` over watch-and-copy
- **Included:** syncing a ref from a watcher is the typical imperative habit that leads to stale or flickering derived state.
- **`warn`:** it works, but has a window where the two disagree and more code.
- **Async exception:** a computed can't await, so fetching legitimately lives in watchers or composables.

#### VUE-REACT-006 · Pure computed getters
- From the computed guide's "Best Practices" section.
- The `.sort()` example is deliberate: in-place array methods inside a computed are the most common *accidental* side effect, and they mutate the source state.
- **`warn`** rather than `error`, since many side effects are benign, but the pattern is unreliable.

#### VUE-REACT-007 · Watch through a getter
- **`error`:** `watch(props.id, …)` never fires. That's a silent functional bug.
- The 3.5 destructured-prop case is included because the docs call it out ("will not work as expected … the compiler will … throw a warning"). Code generated for 3.5 is especially prone to it.

#### VUE-REACT-008 · Clean up watcher and component side effects
- **`error`:**
  - Stale async responses overwriting newer ones is a real data-correctness race.
  - Un-removed listeners or timers leak and keep running after unmount.
- **Version split:** `onWatcherCleanup` (3.5+, must be called before the first `await`, per the docs) and the `onCleanup` callback argument (all versions).
- **`AbortController`** is the example because it actually cancels the request rather than just ignoring the result.

#### VUE-REACT-009 · Create watchers synchronously
- From the watchers guide ("Stopping a Watcher"): only synchronously created watchers are bound to the component.
- **`warn`:** a leak, but often harmless in short-lived apps.
- The fix shows the idiomatic alternative (conditional logic inside a sync watcher) rather than manual stop handles.

#### VUE-REACT-010 · Avoid broad `deep: true`
- The docs warn deep watching "can be expensive when used on large data structures".
- **`warn`.**
- **Exceptions:** small form models, and direct `reactive()` sources, which are deep by design. Without them nearly every form would be flagged.
- Numeric `deep` (3.5) is shown as the bounded option.

### Templates (`VUE-TPL`, `references/templates.md`)

#### VUE-TPL-001 · No `v-if` with `v-for`
- **`error`:** in Vue 3, `v-if` is evaluated first, so the condition can't access the loop variable. It's a runtime failure, not a style issue. Style guide *Essential*.

#### VUE-TPL-002 · Stable `:key`
- **`error`,** because index or missing keys cause *wrong state on the wrong item* (input values, child state) when lists change. Style guide *Essential*. eslint-plugin-vue enforces missing keys as errors.
- **The static-list exception** keeps plain read-only lists from being flagged.

#### VUE-TPL-003 · Simple template expressions
- Style guide *Strongly recommended*, readability only, so `info`.

#### VUE-TPL-004 · No expensive or side-effecting calls in templates
- **Included:** the docs' "computed caching vs methods" section shows functions re-running on every render.
- **`warn`:** side effects in render can loop, and expensive calls slow every update.
- **Exceptions:** cheap formatters and event handlers, which don't run on render.

#### VUE-TPL-005 · Native interactive elements
- **Included:** the spec asks for a11y basics, and `div @click` is the most frequent accessibility failure in generated UI code.
- **`warn`:** a real usability defect for keyboard and screen-reader users, but not a crash.
- **`type="button"`** is required in the example because buttons default to `submit` inside forms, a frequent accidental-submit bug.

#### VUE-TPL-006 · Labelled form controls
- **Included** for the same reason as TPL-005. The Vue accessibility guide covers labels explicitly.
- **`useId()` (3.5+)** is recommended because hand-made ids often differ between server and client, causing hydration mismatches in SSR apps.
- **The pre-3.5 alternative is explicit** (wrap the input in its `<label>`, no id needed). In the T15 final pass, one of three Vue 3.3 runs matched `useId(`. Spelling out "on Vue < 3.5 don't call `useId`", with a working alternative, removes the temptation. The version graders also now ignore comment lines, since a comment like "defineModel needs 3.4" is correct behaviour. Afterwards: 3/3 runs passed.

#### VUE-TPL-007 · Item-specific names for repeated row actions
- **Ported from react-power-up (2026-11-26).** There, a list output labelled every control but named its expand button just "Show notes" in every row. An accessibility judge failed it, and no rule covered it. vue-power-up has the same gap: VUE-TPL-005's example names an icon-only button after its item, but nothing says that text buttons repeated per row ("Delete") need it too.
- **`warn`:** the control works and has a name. The defect is that identical names are ambiguous (WCAG 2.4.6). That hurts, but doesn't block use. It matches TPL-005/006, which are also `warn`.
- **"Starts with the visible text":** an `aria-label` that drops the visible words breaks voice control (WCAG 2.5.3). Prefixing keeps both working.
- **Eval:** `write-filterable-list` gains `delete-names-task`. The request asks for a delete control on every row, and its existing graders only checked that some label existed somewhere in the file.
- **Not verified by running:** written without an eval run (user's instruction). Run `write-filterable-list` before relying on the new grader.

### Composables (`VUE-CMPS`, `references/composables.md`)

#### VUE-CMPS-001 · `use` prefix
- An official convention, and it has a practical effect: the prefix signals "must be called in setup" (CMPS-004), and Nuxt auto-imports `composables/` exports.
- **`warn`.**
- **The exception** (pure utilities must *not* take the prefix) stops over-application, which would otherwise mislabel stateless helpers.

#### VUE-CMPS-002 · `MaybeRefOrGetter` + `toValue`
- **Included:** composables that take plain values are the usual cause of "my data doesn't refetch when the prop changes".
- **The pattern** (accept value, ref or getter; call `toValue` inside a reactive scope) is the one the Vue docs prescribe.
- **The getter caller form** (`() => props.userId`) also covers 3.5 destructured props, as the props docs recommend.
- **`warn`.**

#### VUE-CMPS-003 · Return refs, not `reactive`
- From the docs' "Return Values" section: returning `reactive` breaks destructuring at every call site.
- **`warn`.**

#### VUE-CMPS-004 · Call composables synchronously in setup
- **`error`:** outside setup, hooks don't register and `inject` fails silently or throws, and in Nuxt it's the well-known "composable that requires access to the Nuxt instance" error.
- **The `<script setup>` top-level `await` exception** was checked against the docs (the compiler restores the instance), so correct code isn't flagged.

#### VUE-CMPS-005 · `onScopeDispose` for cleanup
- **Complements REACT-008 at the composable level.**
- `onScopeDispose` is recommended over `onUnmounted` because composables may run inside `effectScope()` (or Pinia setup stores), where `onUnmounted` does nothing.
- **`warn`,** to avoid double-counting with REACT-008's `error` when reviewing components.

#### VUE-CMPS-006 · No UI side effects in data composables
- The spec lists "UI side effects inside data composables" as an anti-pattern, and the example repo enforced it.
- The Vue docs don't state it as a rule. The async example only *exposes* error state.
- **`info`,** under the "unofficial means `info` at most" policy.
- **Exception:** UI composables (`useToast`, …), so the rule doesn't fight their purpose.

#### VUE-CMPS-007 · Expose loading/error
- The docs' async state example returns `data` and `error`. Composables that hide failures are a common source of "nothing happens" bugs.
- **`warn`.**
- Nuxt projects are pointed to `useFetch`/`useAsyncData`, which already provide `status` and `error`, so Claude doesn't reinvent them.

#### VUE-CMPS-008 · No browser APIs during SSR setup
- **`error`:** the server render crashes (`window is not defined`), or the hydration mismatches.
- **Scoped to SSR apps.** In a pure SPA `localStorage` in setup is fine, and flagging it would be a false positive. The SKILL workflow's project-type detection decides which applies.
- **Nuxt's `useCookie`** is shown as the SSR-friendly persistence alternative.

#### VUE-CMPS-009 · No per-user module-scope state in SSR
- **`error`:** cross-request state pollution leaks one user's data into another user's page. That's a security and privacy bug, and the Vue SSR guide covers it explicitly.
- **SPA module-scope state is explicitly allowed:** it's the documented lightweight global-state pattern, and flagging it there would be wrong.
- Lives in `CMPS` because module-scope composables are where it happens. The Nuxt rules cross-reference it with `useState`.

### Pinia (`VUE-PINIA`, `references/pinia.md`)

All Pinia rules were checked against the current pinia.vuejs.org docs (core concepts, SSR, Nuxt, outside-component usage, composing stores). The quoted requirements are from those pages.

**Option vs setup stores aren't a rule.** Pinia's docs explicitly say to pick either. The reference gives a default (match the project; setup stores for new projects, since they mirror `<script setup>`) without flagging either form. Likewise "does this belong in a store" is guidance, not a rule, because there's no objective test.

#### VUE-PINIA-001 · `storeToRefs`
- **`error`:** destructuring a store silently breaks reactivity, and it's the most common Pinia bug.
- **The actions note** ("destructure actions directly") avoids the over-correction of wrapping everything in `storeToRefs`.
- `toRefs(store)` is called out as wrong too, since it also wraps actions and internals.

#### VUE-PINIA-002 · Return all setup-store state
- **`error`:** the docs state that not returning state "will break SSR, devtools, and other plugins". Developers often try to keep a "private" ref in a setup store, and the docs say stores can't have private state.
- The example uses a token as the "private" state on purpose, which links to the SEC rule: secrets shouldn't be in client store state at all.

#### VUE-PINIA-003 · No top-level `useStore()`
- **`error`:**
  - In an SPA it throws when imported before pinia is installed.
  - In SSR it can bind to the wrong request's pinia, which leaks state between users.
- **The "before any `await`" clause** for calls inside actions comes from the composing-stores cookbook ("could lead to using the wrong pinia instance in SSR apps").

#### VUE-PINIA-004 · No circular state reads in setup
- **`error`:** infinite recursion when the stores are created. Docs: stores "cannot both directly read each other's state in their setup function".
- The fix (read lazily in `computed`) is the docs' own pattern.

#### VUE-PINIA-005 · Serializable state under SSR
- **`warn`:** non-serializable state breaks hydration in ways that are confusing but usually not dangerous.
- **`devalue`** is mentioned because Nuxt uses it (per the Pinia SSR page), so `Date`/`Map`/`Set` are fine there. That prevents a false "Dates aren't serializable" finding.
- **Scoped to SSR.**

#### VUE-PINIA-006 · `callOnce`/`useAsyncData` instead of `onMounted` in Nuxt
- **`warn`:** client-only fetching works, but loses SSR content and delays data.
- **Versions** checked on nuxt.com: `callOnce` since Nuxt 3.9, `mode: 'navigation'` since 3.15.
- **The docs warn** that `callOnce` returns nothing. That's why the store-action pattern is used (the data lands in the store), and `useAsyncData` is offered when the caller needs `status`/`error`.

#### VUE-PINIA-007 · Multi-step changes in actions
- **`info`:** Pinia explicitly allows direct mutation, so flagging it in general would contradict the docs.
- **The rule targets only multi-field business operations,** where consistency and testability are at stake.

### Nuxt (`VUE-NUXT`, `references/nuxt.md`)

All Nuxt rules cite the versioned `nuxt.com/docs/4.x/` pages. Unversioned `nuxt.com/docs/…` URLs now redirect there, and pinning the version keeps the citations stable when Nuxt 5 docs arrive. Version claims were checked against the docs, and claims the docs don't state (e.g. the release that added `status`) were left out instead of guessed.

#### VUE-NUXT-001 · `useFetch`/`useAsyncData` for render data
- The docs' own motivation: a bare `$fetch` in setup fetches twice and isn't in the payload.
- **`warn`:** it works, but wastes a request and can flash content.

#### VUE-NUXT-002 · `$fetch` for user-triggered requests
- **`error`:** `useFetch` in a handler is a composable called outside setup (CMPS-004) and can return stale cached data. The docs recommend `$fetch` for event-based interactions.
- **The example includes error handling and a refresh,** so the fix doesn't introduce a silent failure.

#### VUE-NUXT-003 · Reactive fetch inputs
- **`error`:** stale data after client-side navigation between dynamic routes is a common, silent Nuxt bug, because Nuxt reuses the page component.
- **Fixes** are the docs' computed URL, reactive `query` and `watch` patterns.

#### VUE-NUXT-004 · Explicit, unique keys
- **The Nuxt 4 change** ("all calls … with the same key now share the same `data`, `error` and `status` refs") turned key collisions from a caching quirk into a correctness issue.
- **`warn`.**
- **The `useFetch` exception** exists because its auto-generated key is correct for most uses.

#### VUE-NUXT-005 · Handle `status`/`error`
- **`warn`.**
- **The Nuxt 4 `undefined` default** (was `null`) is noted because migration bugs come from `=== null` checks.
- **`pending` semantics** also changed in Nuxt 4, so the rule uses `status`.

#### VUE-NUXT-006 · No in-place mutation of fetched data (Nuxt 4)
- **`error`:** with `shallowRef` data, in-place edits silently don't update the UI. It's the Nuxt 4 change most likely to break code written for Nuxt 3 or by a model trained mostly on Nuxt 3.
- **Version-gated to Nuxt 4 / compat 4.**

#### VUE-NUXT-007 · `useState`, not module-scope refs
- **`error`:** cross-request pollution (also CMPS-009, kept here in Nuxt terms because `useState` is the Nuxt-native fix).
- **The serialization constraint and the reserved `useState` name** come from the `useState` API page.

#### VUE-NUXT-008 · Identical server and client markup
- **`warn`:** hydration mismatches are visible bugs, but usually not data-corrupting.
- **The fixes listed** are exactly the ones on the Nuxt hydration best-practices page, including CSS media queries instead of `window` checks.

#### VUE-NUXT-009 · `<NuxtLink>`
- **`warn`:** full reloads lose state and performance.
- `$router.push` in a `div` click is shown as a second anti-pattern, because it also fails TPL-005 (semantics).
- `navigateTo` is named for programmatic navigation because it works in setup, middleware and on the server.

#### VUE-NUXT-010 · Version-correct file locations
- **Included:** the Nuxt 4 `app/` move means a model's default (Nuxt 3 layout) silently produces unrouted pages and non-imported composables.
- **`warn`,** not `error`, because existing projects may use custom `srcDir`. The exception says to follow the config.

#### VUE-NUXT-011 · Validate every server input
- **`error`:** unvalidated input is the root of injection, mass-assignment and crash bugs (OWASP input validation).
- **The Nuxt server guide** recommends `readValidatedBody`/`getValidatedQuery`/`getValidatedRouterParams` with a schema validator.
- **The no-library type-guard example** exists because the workflow forbids adding dependencies unasked. Without it, Claude would face a choice between breaking that rule and skipping validation. h3's validated readers accept any validate function, so a type guard works.
- **The h3 citation** is the v1 docs (`v1.h3.dev`), because Nuxt 4 runs on h3 v1. Citing v2 docs would show APIs the project doesn't have.

#### VUE-NUXT-012 · `createError` with correct status
- **`warn`.**
- **200-with-error-body** breaks `useFetch` error handling (NUXT-005), caching and monitoring.
- **"Don't leak internals"** is folded in because `String(e)` in `statusMessage` is the usual way stack and DB details reach clients.

#### VUE-NUXT-013 · Server-side authorization in every handler
- **`error`:** broken access control is OWASP's #1 risk.
- **Ownership check:** the example checks *ownership*, not just login, because IDOR (reading another user's invoice by id) is the typical Nuxt API hole.
- **404 rather than 403** for others' resources avoids confirming that they exist.
- **Exception:** public endpoints are allowed but must be explicit, so reviewers can tell deliberate from forgotten.

#### VUE-NUXT-014 · `useRuntimeConfig` over `process.env`
- **`warn`:** wrong configuration in production, but not inherently a vulnerability.
- **The docs' build-time vs runtime caveat** and the `NUXT_` override convention are the reasons. `useRuntimeConfig(event)` on the server is the docs' recommendation.
- **Exception:** `nuxt.config.ts`, which runs at build time.

#### VUE-NUXT-015 · No secrets in public config
- **`error`:** anything in `runtimeConfig.public` or `app.config` ships to every visitor. Leaked secret keys are an immediate security incident.
- **Exception:** publishable keys, so Stripe's publishable key etc. aren't false positives.

#### VUE-NUXT-016 · Middleware returns navigation; UX only
- **`warn`.**
- **The return-value contract** is how Nuxt route middleware works. Calling `router.push` inside races the ongoing navigation.
- **"Not security"** is stated explicitly and cross-linked to NUXT-013, because client middleware is often mistaken for access control.

#### VUE-NUXT-017 · `.client`/`.server` plugin suffixes
- **`warn`:** browser-only plugins crash SSR, and server-only plugins bloat or leak into the client bundle. The suffix is the documented mechanism.

### Security (`VUE-SEC`, `references/security.md`)

**Scope split:**
- **Server input validation, server auth and public config** live in `nuxt.md` (NUXT-011/013/015), because the fix is Nuxt-specific.
- **`security.md`** holds the framework-level sinks, which apply to any Vue app.
- **Step 5 of SKILL.md** links both sets of ids, so the security pass covers all of them without loading every file.

**Sources:**
- The Vue security guide for Vue-specific sinks.
- OWASP cheat sheets for general web risks, which the Vue docs explicitly leave to the backend (CSRF, XSSI).

All `SEC` rules are `error` except cookies and CSRF (`warn`, below).

#### VUE-SEC-001 · No untrusted `v-html`
- **`error`:** stored XSS, the classic Vue vulnerability.
- **"Render as text first; sanitize only with an approved dependency"** resolves the conflict between "use DOMPurify" and "never add dependencies unasked": the safe option (text) needs no dependency.
- This is exactly what the `write-trap-render-bio-html` eval checks.

#### VUE-SEC-002 · Validate URL bindings
- **`error`:** `javascript:` URLs execute on click. Vue's escaping can't help, as the Vue guide states.
- **`new URL()` + a protocol allowlist** is shown rather than regexes, which are routinely bypassed.

#### VUE-SEC-003 · No untrusted templates, components or styles
- **The Vue guide's "Rule No. 1".**
- **`<component :is>` with user input** is included because it's the realistic modern form of this bug in SFC code (string templates are rare).
- **The allowlist map** is the fix.

#### VUE-SEC-004 · Same-origin redirects only
- **`error`:** open redirect (phishing) and, through `location.href`, script execution.
- **The validation function** rejects `//` and `/\`, the two common bypasses of a naive `startsWith('/')` check, because browsers treat both as protocol-relative.

#### VUE-SEC-005 · Nothing secret in client-reachable places
- **One rule for every channel** that reaches the browser: bundle, `VITE_*`, public config, SSR payload, API responses. Developers often protect one channel and forget another, e.g. hiding a field in the UI while the full row is in the payload.
- **OWASP API3:2023** (excessive data exposure) is cited for the DTO advice.

#### VUE-SEC-006 · No SSRF
- **`error`:** server routes fetching user URLs give access to cloud metadata and internal services.
- **Host allowlist + `redirect: 'manual'`** follows the OWASP SSRF cheat sheet. Redirects would otherwise bypass the host check.

#### VUE-SEC-007 · Session cookies: `httpOnly`, `secure`, `sameSite`
- **`warn`,** not `error`: storing a token in `localStorage` isn't itself exploitable without an XSS, but it turns any XSS into account takeover.
- **`useCookie` is called out** because Nuxt developers reasonably assume it's the "secure" option. It creates JS-readable cookies.

#### VUE-SEC-008 · CSRF for cookie-auth mutations
- **`warn`:** `SameSite=Lax` (the browser default) already blocks most cross-site POSTs. The remaining gaps are state changes on GET and sensitive actions.
- **The `Origin` check** is a dependency-free defence-in-depth the backend can add.

### Performance (`VUE-PERF`, `references/performance.md`)

**Severity policy for performance:**
- Almost all `PERF` rules are `info`. Performance advice without measurement often turns into premature optimization, and every technique here (`v-memo`, virtualization, lazy hydration) adds complexity or correctness risk.
- **Exception:** `PERF-001` is `warn`, because deep-proxying third-party instances can actually *break* them, not just slow them down.
- The reference opens with "never at the expense of correctness".

#### VUE-PERF-001 · `shallowRef`/`markRaw` for large data and instances
- **`warn`.**
- The Vue performance guide's "reduce reactivity overhead" section. Library instances (maps, charts) misbehave behind proxies.
- **Exception:** Nuxt 4 fetch data is already shallow (NUXT-006), which prevents redundant advice.

#### VUE-PERF-002 · Lazy-load heavy components
- **`info`:** the payoff depends on component size and placement.
- **Nuxt's `Lazy` prefix and `defineAsyncComponent`** are the documented mechanisms.

#### VUE-PERF-003 · Lazy hydration
- **`info`.**
- **Versions:** Nuxt `hydrate-*` props since 3.16, Vue `hydrateOn*` strategies since 3.5. The Nuxt docs page doesn't state the version; it comes from the Nuxt 3.16 release.
- **SSR-only,** like the other hydration rules.

#### VUE-PERF-004 · Virtualize long lists
- **`info`,** with "measure first" and "pagination is often simpler".
- **A virtual-list library is a new dependency,** so it falls under the ask-first rule.

#### VUE-PERF-005 · Stable props for list items
- The Vue guide's "props stability" example, a free win once you know it.
- **`info`.**

#### VUE-PERF-006 · `v-once`/`v-memo` for measured hot spots
- **`info`:** an incomplete `v-memo` dependency array shows stale UI, so the risk usually outweighs the gain unless profiling shows a problem.
- **The `v-memo` + `v-for` same-element exception** comes from the Vue API docs.

### Testing (`VUE-TEST`, `references/testing.md`)

**Library choice (D4):**
- The user chose "both". The table at the top of `testing.md` maps each *goal* to a library rather than ranking them:
  - **Testing Library** for user flows (its guiding principle is testing what users see)
  - **Vue Test Utils** for component contracts (`emitted()`, `setProps`), which Testing Library deliberately doesn't expose
  - **`@nuxt/test-utils`** for anything that needs the Nuxt runtime (it offers both `mountSuspended`/VTU and `renderSuspended`/Testing Library).
- "Match the project" comes first, so the plugin never splits a codebase between two styles.

#### VUE-TEST-001 · Test behaviour, not internals
- **`warn`.**
- **Sources:** the Vue testing guide ("test what a component does, not how"), and the Testing Library guiding principles and query priority.
- **Exception:** `defineExpose`d methods are public API, so they may be tested.

#### VUE-TEST-002 · No sleeps
- **`warn`:** `setTimeout` waits are the top source of flaky frontend tests.
- **Fixes** are VTU's async guide (`await trigger`, `flushPromises`) and Testing Library's async utilities.
- **Fake timers** are the exception, for testing time logic.

#### VUE-TEST-003 · Fresh Pinia per test
- **`warn`:** shared store state makes test order matter. Fix from the Pinia testing cookbook.

#### VUE-TEST-004 · `@nuxt/test-utils` for Nuxt-runtime code
- **`warn`:** hand-stubbing auto-imports is fragile.
- **Helper names and setup** were checked against the current Nuxt testing docs: `defineVitestProject`, `environment: 'nuxt'`, `mountSuspended`, `renderSuspended`, `mockNuxtImport`, `registerEndpoint`.

#### VUE-TEST-005 · Mock at the network boundary
- **`warn`.**
- **MSW is mentioned only "if the project uses MSW".** The example repo mandated MSW, but making it a requirement would force a new dependency, which goes against the "existing stack first" policy.

#### VUE-TEST-006 · Test composables directly or via a host
- **`info`.**
- From the Vue testing guide's composables section. The `withSetup` helper is the documented pattern for lifecycle-dependent composables.

#### VUE-TEST-007 · Cleanup when Vitest has no global `afterEach`
- **Ported from react-power-up (2026-11-26).** There, a generated test file type-checked and scored 1.00, but when actually run under Vitest 3 of 4 tests failed ("Found multiple elements"), because nothing cleaned up between tests. The Vue libraries have the same gap. `@testing-library/vue` auto-cleans only when the runner injects a global `afterEach` (Vitest: `globals: true`), and Vue Test Utils never destroys `mount`ed wrappers without `enableAutoUnmount`.
- **Why the evals never caught it:** `write-component-with-tests` sets `globals: true`, so auto-cleanup works there. The new case `write-tests-no-globals` is the same request without `globals`.
- **`warn`, not `error`:** the failure shows up right away as red or flaky tests, not as a production bug. It still makes tests order-dependent and leaks memory.
- **Fix in the setup file, not via `globals: true`:** both are documented. One hook in the existing setup file is the smaller change. Turning on globals changes the project's config and ambient types, which a test-writing task shouldn't do unasked.
- **Eval grader:** `setup-cleanup` requires `cleanup` or `enableAutoUnmount` in `vitest.setup.ts`. Graders can't OR across files, so a correct per-test-file hook would fail it. That's accepted because the rule and both libraries' docs name the setup file, and the prompt points at the existing setup.
- **Not verified by running:** the ✅ example and the new case were written without an eval run or a type-check harness (user's instruction). Run them before relying on them.

## 6. Evaluation design

### Four layers of verification
| Layer | Tool | What it proves | Model involved? |
|---|---|---|---|
| Manifests | `claude plugin validate .` | The plugin and marketplace load | no |
| Catalog consistency | `tests/check_catalog.py` | Every rule follows the template and appears in the index (same severity and file) and in this document | no |
| Sources | `tests/check_links.py` | Every `**Source:**` page resolves | no (network) |
| Precondition | `tests/precheck.test.sh` | `precheck.sh` returns the right status in every environment | no |
| Behaviour | `claude plugin eval` (`evals/`) | The skills change what Claude produces | yes |

**Why deterministic checks first:** they're free, instant and never flaky. Anything that *can* be checked without a model is, so the expensive evals only measure behaviour.

### Eval case families
- **`write-*`:**
  - A realistic request with a pinned output path. A scaffold creates a minimal project (`package.json` with exact version ranges, `tsconfig`), so version detection has something real to read.
  - Graded with: regexes over the produced file (required API present, anti-patterns absent), an `llm` check for subtle semantics, an `llm` check that the final report doesn't claim unrun checks passed, and `tool_used: Skill`.
- **`review-*`:**
  - Scaffolds build **deterministic git repos**: a fixed author/committer identity and dates make commit hashes reproducible, so prompts can name a hash (`/vue-power-up:review 10217ef`).
  - Each case asserts the expected rule ids, the verdict, the presence of `diff` proposals, and safety: no `Write`/`Edit`, no write-capable git subcommand, no `--output`, no redirection.
- **`trigger-*`** *(T13)*: should and shouldn't fire.

### Running
- **During development** (D15): `claude plugin eval . --scaffold --case '<case>' --runs 1 --ablation none --allow-tools Write Edit --trust-plugin --no-publish`
- **`--no-publish`** keeps reports local, so nothing is uploaded during development.
- **Full run** (the user's): `claude plugin eval . --scaffold --allow-tools Bash Write Edit`

### R1 outcome: slash commands in eval prompts work
An eval prompt of `/vue-power-up:review` *does* invoke the user-only skill. The trace's init event lists `vue-power-up:review` among the slash commands, and the `!` precheck ran.

The first attempt failed only because the eval sandbox doesn't grant Bash unless `--allow-tools Bash` is passed. This is also realistic: a session that denies Bash can't run the precheck, which the README documents.

### Environment limitation found during development
In the development environment (an agent shell with its own sandbox), `claude plugin eval` refuses Bash-granting runs: it can't read the user's cloud credential config files to exclude them from its own sandbox (`EACCES`). So:
- **Run here:** every case that needs no Bash: all `write-*` and `trigger-*` cases, and the plain-language `review-*` cases (which use only Read/Grep/Glob through the main skill).
- **Verified by hand instead:** the `review-*` command cases. Headless `claude -p "/vue-power-up:review …" --plugin-dir .` runs in scratch repos covered not-a-repo, an invalid `--output=` argument, uncommitted changes (staged + unstaged + untracked), a commit hash, a root commit, an unknown hash and a clean tree. Git state was hashed before and after each run and was identical.
- **Formally run:** the same scenarios exist as eval cases and run in the user's full run from a normal terminal.

## 7. Known limitations

| Limitation | Why it's acceptable / mitigation |
|---|---|
| **Enforcement is guidance, not a hook** (D2). Claude can still deviate. | The user chose no hooks. Mitigated by the mandatory self-check step, the red flags, running the project's own type-check, lint and tests, and the evals showing the behaviour. A deterministic hook can be added later without changing the rules. |
| **`allowed-tools` pre-approves but doesn't restrict** (A6). `git show *` would also pre-approve `git show --output=…`. | The argument is checked before use, write flags are forbidden in the skill text, and evals assert no write-capable git calls and no file edits. |
| **The review command needs Bash permission** for its precheck. Sessions that deny Bash can't run it. | Documented in README. Plain-language reviews ("review this file") need only read tools. |
| **POSIX shell required** for `precheck.sh`. | Claude Code on Windows uses Git Bash. Documented in README. |
| **Rule coverage is finite.** 91 rules don't cover every Vue bug. | Reviews report non-catalog bugs as `GENERAL` (D14). The catalog can grow without renumbering (A4). |
| **Version detection without `node_modules` or a lockfile uses the range minimum.** A project might really run a newer version. | That direction is safe: assuming *older* never produces code that fails to compile. The upgrade path is mentioned instead. |
| **Docs drift.** Vue, Nuxt and Pinia APIs change. | Every rule has an Applies range and a source. `tests/check_links.py` catches moved pages. Re-verify rules on each major release. |
| **Eval scores here are single runs** (D15). | The user's full run (3 runs, with and without the plugin) is authoritative and gives variance and the plugin's added value. |
| **Bash-granting evals couldn't run in the development sandbox.** | Verified by hand with headless runs (section 6). The cases run in the user's full run. |
| **`llm` graders** (a few per suite) can vary between runs. | Used only where a regex can't decide, with concrete PASS/FAIL criteria (A7). Long outputs are graded by regex. |
