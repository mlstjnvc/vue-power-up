# Implementation Plan: vue-power-up

> Source of truth: `SPEC.md` (approved v3 + v3.3 adjustments D10–D15). Task checklist: `tasks/todo.md`.
> No commits at any point. All work stays in the working tree.

## Overview

Build the `vue-power-up` Claude Code plugin with:
- **Main skill:** `skills/vue-power-up`, auto-triggered. It helps Claude write Vue + TS + Pinia + Nuxt code with guardrails and security.
- **Review skill:** `skills/review`, invoked only by the user as `/vue-power-up:review [commit]`.
- **Shared rule catalog** that both skills use.
- **Eval suite** run with `claude plugin eval`.
- **Docs:** `README.md` and `docs/RATIONALE.md`.

The work goes in vertical slices. Each rule domain lands as a complete unit: the rules, their catalog entries, the reasoning in RATIONALE, and at least one write eval plus one review fixture. That way every slice can be tested on its own, and the plugin is usable after every task.

## Architecture Decisions

| # | Decision | Rationale (expanded in `docs/RATIONALE.md`) |
|---|---|---|
| A1 | Two skills: `vue-power-up` (auto) and `review` (user-only, `disable-model-invocation: true`) | Claude Code docs merged commands into skills and recommend `skills/`. User-only invocation stops the review procedure from firing on its own during write tasks. It also stops the review skill competing with the main skill for "review this component" requests, which the main skill handles. |
| A2 | One rule catalog in `skills/vue-power-up/references/`. The review skill reads it through `${CLAUDE_PLUGIN_ROOT}` | Single source of truth, so rules can't drift between writing and reviewing |
| A3 | Progressive disclosure: SKILL.md stays ≤ ~300 lines (docs hard limit is 500), with one reference file per domain | A "write a button" task shouldn't load Nuxt server-security docs, which keeps context cost proportional to the task |
| A4 | Rules have stable ids `VUE-<DOMAIN>-NNN`, a severity, an official source and a version range | Findings stay traceable and can be graded by regex in evals. Version gating stops Claude suggesting APIs the project doesn't have. |
| A5 | No `!`-injection of git output in the review skill. Claude runs the git commands itself after validating the argument | `!` injection runs before Claude can validate `$ARGUMENTS`. Interpolating a user argument into a pre-executed shell command is an injection risk, and a failing command aborts the whole skill instead of giving a friendly message. |
| A6 | `allowed-tools` on the review skill pre-approves exact read-only git forms only | It removes permission prompts for safe commands. `allowed-tools` doesn't *restrict* tools, so the skill text also forbids every write-capable flag (e.g. `--output`) and command. |
| A7 | Evals are native `claude plugin eval` cases (D12). Files Claude produces are graded with `regex` graders; short final answers with `llm` graders | Following the docs' guidance on stable signals: regex over files is deterministic, and the LLM judge only sees short text |
| A8 | Generated code is type-checked in a **scratch harness** (Vue 3.5 SPA + Nuxt 4 projects in the scratchpad, deps installed once), not inside eval runs | Eval workspaces start empty and scaffolds have a 120 s limit, too short for `npm install`. A separate harness keeps the type-check real without adding deps to this repo. |
| A10 | The review precondition (D13, git only) lives in a bundled `scripts/precheck.sh`, pre-executed via `` !`${CLAUDE_SKILL_DIR}/scripts/precheck.sh` `` and pre-approved in `allowed-tools` | The check is deterministic and runs before the model does anything. It takes no user input, so pre-execution is safe (unlike A5). It always exits 0, so a failed check gives a friendly message instead of aborting the skill. It can be unit-tested as plain shell. |
| A11 | Review output is a standard code review (D14) with numbered proposed changes as `diff` blocks, and nothing is applied | Matches how human code review works: analysis, then suggestions. Numbering lets the user say "apply 1 and 3". Proposal-only keeps the command read-only. |
| A9 | README links to `rule-catalog.md` rather than duplicating the rule list | Domain tasks don't have to edit the README each time, while it still stays accurate (D9) |

## Dependency Graph

```
T1 Manifests + layout + README/RATIONALE skeletons
 └─ T2 Main SKILL.md core + rule format + catalog skeleton
     └─ T3 Slice: TypeScript & components (first rules + first write eval)
         ├─ T4 Review skill: precheck.sh + tests, scope resolution   ← high risk, early
         │   └─ T5 Review procedure + standard-review output + review evals
         │
         ├─ T6 Slice: reactivity & templates
         ├─ T7 Slice: composables
         ├─ T8 Slice: Pinia
         ├─ T9 Slice: Nuxt data fetching & SSR state
         │   └─ T10 Slice: Nuxt server routes & config
         ├─ T11 Slice: security (cross-cutting checklist + trap evals; needs T9/T10 rules to reference)
         └─ T12 Slice: performance & testing
                └─ T13 Version + trigger evals, description tuning
                    └─ T14 Type-check harness run over write-eval outputs
                        └─ T15 Single-run pass over all cases, gap fixes, README/RATIONALE finalization (full run: user, D15)
```

T6–T9 and T12 depend only on T3–T5 and are independent of each other. They're sequential here because each edits `rule-catalog.md` and `RATIONALE.md`, and editing those in parallel would cause conflicts.

## Task List

### Phase 1: Foundation and riskiest path
- [x] T1: Manifests, layout, doc skeletons
- [x] T2: Main SKILL.md core and rule-catalog format
- [x] T3: Slice: TypeScript and components
- [x] T4: Review skill: preconditions and scope resolution
- [x] T5: Review procedure and standard-review output

### Checkpoint A (after T1–T5)
- [x] `claude plugin validate .` passes
- [x] Plugin loads via `--plugin-dir`, and both skills show up
- [x] `precheck.sh` shell tests pass (3 statuses)
- [x] `/vue-power-up:review` stops correctly without git or outside a repo, and produces a standard review for uncommitted changes and for a hash in a scratch repo, with git state unchanged
- [x] Human review before continuing

### Phase 2: Rule domains
- [x] T6: Reactivity and templates
- [x] T7: Composables
- [x] T8: Pinia
- [x] T9: Nuxt data fetching and SSR state

### Checkpoint B (after T6–T9)
- [x] All eval cases so far pass with `--runs 1 --ablation none`
- [x] SKILL.md ≤ ~300 lines
- [x] Human review

### Phase 3: Nuxt server, security, perf/testing
- [x] T10: Nuxt server routes and config
- [x] T11: Security
- [x] T12: Performance and testing

### Checkpoint C (after T10–T12)
- [x] All eval cases pass at `--runs 1`
- [x] Every rule has an id, severity, source, example, applies-range, a catalog entry and a RATIONALE entry
- [x] Human review

### Phase 4: Verification and polish
- [x] T13: Version and trigger evals, description tuning
- [x] T14: Type-check harness over generated code
- [x] T15: Single-run pass over all cases, gap fixes, docs finalization (the full run is yours, D15)

### Checkpoint: Complete
- [x] Every Success Criterion in SPEC.md is checked off, with evidence (eval scores from single runs; the user's full run is authoritative)
- [x] `claude plugin validate .` passes, with only the documented D6 placeholder warnings (`--strict` passes once you fill in author/license)
- [x] Nothing committed (`git log` is empty)
- [ ] Human sign-off

## Risks and Mitigations

| # | Risk | Impact | Mitigation |
|---|---|---|---|
| R1 | An eval prompt may not be able to invoke a user-only skill via `/vue-power-up:review` | Med: review-command evals can't run | Verify first in T4. Fallback: test the review procedure through the main skill ("review the uncommitted changes") and test the slash command manually in a scratch repo, recording the evidence in `tasks/todo.md`. |
| R2 | `allowed-tools` grants like `Bash(git diff *)` also pre-approve write-capable flags (`--output=<file>`) | Med: an unprompted file write in the user's repo | Grant only the narrowest patterns. The skill text prescribes exact commands and forbids `--output`, `-o` and other write flags. An eval asserts no file is created and git state is unchanged. |
| R3 | Rule content goes stale or is wrong (Nuxt 4 / Pinia 3 APIs change) | High: the skill teaches wrong patterns | Every `error`/`warn` rule cites an official doc URL that was checked during the task. Verify uncertain APIs against current docs when writing them. Version ranges on every rule. |
| R4 | Too many or overly strict rules cause false positives and noisy reviews | Med | Clean-control fixtures with 0 `error` findings required. Non-official conventions are capped at `info`. |
| R5 | SKILL.md bloats past its budget as domains land | Med: context cost, worse triggering | Line-count check at each checkpoint. Detail goes in references, and SKILL.md keeps only the red flags and pointers. |
| R6 | Eval cost (3 runs × 2 arms × ~20 cases) | Low | During development, only targeted cases with `--runs 1 --ablation none`. The full run is the user's (D15). |
| R10 | Precheck needs a POSIX shell, which native Windows lacks without Git Bash | Low | Claude Code on Windows uses Git Bash for shell commands. Documented as a requirement in README. |
| R7 | Write evals are judged on file contents that differ between runs | Med: flaky scores | Prompts pin the output file paths. Graders use regexes for *absence* of anti-patterns plus presence of required APIs, and `llm` graders only judge the short final message. |
| R8 | The type-check harness needs network and `npm install` in the scratchpad | Low | One-time setup outside the repo. If installs aren't possible, report it and fall back to static review of the outputs. |

## Open Questions

None blocking. R1 gets resolved inside T4.
