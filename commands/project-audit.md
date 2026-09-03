---
description: Full 10-category scored quality audit with 10 parallel scoring agents; writes a dated report and score history to docs/audits/
allowed-tools: [Read, Grep, Glob, Bash, Write, Task, Agent]
---

Run a complete, scored quality evaluation using **10 parallel scoring agents** — one per category.

Optional scope: `$ARGUMENTS` — a directory to confine the audit to (e.g. `/project-audit src/Billing`).
Empty means the whole project.

**Execution model:** Phase 1 (gather evidence, sequential) → Phase 2 (10 parallel subagents, one
per category) → Phase 3 (aggregate, persist, report). Scoring is pure reasoning and fully
independent across categories, so it runs concurrently.

**Evidence is sliced, not duplicated.** Phase 1 writes a small shared bundle plus a *manifest* of
the source tree. Each agent reads only the files its category actually needs — a security review
does not need the domain model, and a DDD review does not need the CI config. Never inline the
project source into agent prompts: with 10 agents that costs the whole codebase ten times over.

> ⚠ **Cost:** still a heavy command — ten agents reading real code. On a large project, scope it
> (`/project-audit src/Billing`) rather than sweeping the tree, and run it at decision points, not
> as a routine check.

---

## Phase 1 — Gather evidence (orchestrator, sequential)

### 1.1 — Workspace

```bash
AUDIT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/audit-XXXXXX")
PROJECT_ROOT=$(git rev-parse --show-toplevel)
FRAMEWORK_DIR="$PROJECT_ROOT/.claude/framework"
mkdir -p "$AUDIT_DIR/cat"
echo "$AUDIT_DIR"
```

### 1.2 — Verify `.claudeignore`

If `.claudeignore` is absent from the project root, note it in the final report and exclude
`vendor/`, `node_modules/`, `.git/`, `dist/`, `build/`, `var/`, `storage/`, `*.lock`, `*.log` from
all traversals.

### 1.3 — Write the shared bundle

Everything in `$AUDIT_DIR/common.md`, each section under a clear `##` separator. This file is
small and every agent reads all of it:

- `$FRAMEWORK_DIR/standards/PROJECT_AUDIT_FRAMEWORK.md` — the global framework
- `.claude/PROJECT_AUDIT_FRAMEWORK.md` — project specializations (note explicitly if absent)
- `CLAUDE.md`, `README.md` — project context
- Dependency manifests: `composer.json`, `package.json`, `pyproject.toml`, `go.mod`, `build.gradle`
- Tooling config: `phpstan.neon`, `.eslintrc*`, `tsconfig.json`, `deptrac.yaml`, `.php-cs-fixer*`,
  `phpunit.xml`, `pytest.ini`, `ruff.toml` — whichever exist
- CI/CD config: everything under `.github/workflows/`, plus `Makefile`, `Jenkinsfile`, `.gitlab-ci.yml`
- Quality gate output: `composer qa 2>&1` / `make qa` / `npm run qa` — whichever the project defines.
  Capture the output verbatim, including failures. If no gate exists, record that as the finding it is.
- `git log --oneline -20`, `git branch -a`, and `git log -1 --format=%cd` (last commit date)

### 1.4 — Write the source manifest

`$AUDIT_DIR/manifest.md` — an **index**, not the contents. One line per file: path, line count,
and inferred role. Confine to `$ARGUMENTS` when a scope was given.

```bash
find "${ARGUMENTS:-.}" -type f \( -name '*.php' -o -name '*.js' -o -name '*.ts' -o -name '*.jsx' \
     -o -name '*.tsx' -o -name '*.py' -o -name '*.go' -o -name '*.kt' -o -name '*.swift' \) \
  -not -path '*/vendor/*' -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -path '*/var/*' -not -path '*/dist/*' -not -path '*/build/*' \
  | xargs wc -l | sort -rn
```

Group the result by directory and annotate each group with what it appears to be (domain,
application, infrastructure, controllers/http, tests, config, views). The annotation is what lets
an agent pick its files without reading everything.

### 1.5 — State preconditions

Before launching Phase 2, state explicitly:

- Technology stack and primary language(s)
- Architectural pattern and layer structure
- Scope: full project, or the directory given in `$ARGUMENTS`
- Quality gate result: ✓ green / ✗ red / ⚠ partial
- Maturity: Prototype / Early production / Established / Enterprise — one sentence of reasoning
- Which conditional categories apply: Cat 3 (DDD) if a domain layer exists; Cat 5 (JS/Frontend) if
  JS or TS files are present

---

## Phase 2 — Parallel category scoring

Launch **all 10 agents in a single message** (ten tool calls in one block) so they run concurrently.
One agent per category, `subagent_type: general-purpose`.

Give each agent this prompt, substituting the category number, name, and evidence focus:

> You are a senior software architect performing a focused quality review.
>
> **Task:** score ONLY Category N — [Name]. Nothing else.
>
> **Evidence:**
>
> - Read `$AUDIT_DIR/common.md` in full — it contains the audit framework, the project's
>   specializations, its manifests, tooling and CI config, and the quality gate output.
> - Read `$AUDIT_DIR/manifest.md` — an index of the source tree with line counts and inferred roles.
> - Then read from the project **only the files your category needs**: [focus for category N].
>   Do not read the whole tree. If the manifest shows more candidates than you need, sample the
>   largest and the most central, and say in your evidence what you sampled.
>
> **Scoring:**
>
> - Find your category's subcriteria in the framework and score each one 0–10 against the anchors
>   defined there.
> - Cite specific evidence per subcriteria: `file:line`, or a named observable behaviour.
> - Derive the category score as a weighted judgement — do not mechanically average subcriteria.
> - Cat 3: if no domain layer exists, output `N/A — no domain layer detected` and stop.
> - Cat 5: if no JS/TS files exist, output `N/A — no JS/TS detected` and stop.
>
> **Output:** write the block below to `$AUDIT_DIR/cat/N.md` and return the same block as your
> final message. No preamble, no conclusion, nothing else.
>
> ```markdown
> #### Category N — [Name] — **X/10**
>
> | Subcriteria | Score | Evidence | Gap |
> |---|---|---|---|
> | N.1 Name | X/10 | `file:line` | gap description or — |
> | N.2 Name | X/10 | `file:line` | gap description or — |
>
> > **Category verdict:** one sentence naming the dominant strength and the dominant gap.
> ```

### Evidence focus per category

This is what keeps each agent's reading narrow. Adapt the paths to the project's actual layout as
recorded in the manifest.

| # | Category | Evidence focus |
|---|---|---|
| 1 | OOP & Design Patterns | Domain and application classes, interfaces, factories, the largest classes in the manifest |
| 2 | Clean Code | A sample across the tree, weighted to the longest files — that is where naming, size and duplication problems concentrate. For 2.8, read the **Domain language** section of `.claude/CODING_STANDARDS.md` *first*, note which context each sampled file belongs to, then sample deliberately across the context boundaries: a declared term inside its context is correct, the same term outside it is a boundary leak, and an undeclared non-English term is drift |
| 3 | Domain-Driven Design | Layer directories, entities, value objects, repository interfaces, domain events, and whatever enforces the boundaries |
| 4 | Testing | The whole test tree, the test runner config, plus enough source to judge whether the critical paths are the ones covered |
| 5 | JS / Frontend | JS/TS files only, plus their build and lint config |
| 6 | Framework & Dependencies | Manifests, framework config and bootstrap, the entry points, and any place the framework is bypassed |
| 7 | Tooling & Quality Standards | Tooling config and the quality gate output in `common.md` — plus grep for suppression markers (`@ts-ignore`, `ignoreErrors`, `phpcs:disable`, `noqa`, `filterwarnings`) |
| 8 | Application Security | Input boundaries (controllers, request handling, deserialization), auth and authorisation, templates and output encoding, headers, and anywhere secrets are read |
| 9 | Observability & Operability | Logger setup and call sites, error handling and reporting, health endpoints, metrics, log rotation and retention config |
| 10 | CI/CD & Version Control | CI config, migrations, deploy and rollback scripts, plus the git log and branch list in `common.md` |

---

## Phase 3 — Aggregate, persist, report (orchestrator, sequential)

### 3.1 — Collect

```bash
for i in $(seq 1 10); do cat "$AUDIT_DIR/cat/$i.md" 2>/dev/null || echo "⚠ Category $i produced no output"; done
```

Use each agent's output **verbatim**. Do not re-score. If an agent's file is missing, use the block
it returned in its final message; if both are missing, mark the category `⚠ not scored` and say so
in the report rather than filling the gap with a guess.

### 3.2 — Compare with the previous audit

```bash
cat docs/audits/history.md 2>/dev/null
```

Compare only against the most recent entry **with the same scope** — a `src/Billing` audit and a
full-project audit are not comparable, and presenting a delta between them would be misleading.
Show per-category movement as `7.0 → 8.0 ▲`, `8.0 → 8.0 =`, `8.0 → 6.5 ▼`. With no comparable
prior entry, state `baseline — first audit at this scope`.

### 3.3 — Compose the report

In this order:

**Project snapshot** — stack, maturity with reasoning, scope, quality gate result (with the failing
lines if not green), and any of these warnings that apply:

- ⚠ No project-level `.claude/PROJECT_AUDIT_FRAMEWORK.md` — audit uses the global framework only
- ⚠ No project-level `.claude/CODING_STANDARDS.md`
- ⚠ No `.claudeignore` — dependency trees excluded manually

**Score movement** — the comparison from 3.2, or the baseline note.

**Detailed subcriteria scores** — the 10 category blocks in order.

**Summary table** — one row per category, in this shape:

```text
┌─────┬─────────────────────────────┬─────────────┬─────────┐
│  #  │          Category           │    Score    │ Top gap │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 1   │ OOP & Design Patterns       │ X/10        │ …       │
│ 2   │ Clean Code                  │ X/10        │ …       │
│ 3   │ Domain-Driven Design        │ X/10 or N/A │ …       │
│ 4   │ Testing                     │ X/10        │ …       │
│ 5   │ JS / Frontend Quality       │ X/10 or N/A │ …       │
│ 6   │ Framework & Dependencies    │ X/10        │ …       │
│ 7   │ Tooling & Quality Standards │ X/10        │ …       │
│ 8   │ Application Security        │ X/10        │ …       │
│ 9   │ Observability & Operability │ X/10        │ …       │
│ 10  │ CI/CD & Version Control     │ X/10        │ …       │
└─────┴─────────────────────────────┴─────────────┴─────────┘
```

**Top actions** — ranked by impact/effort. For each: what to fix, where (`file:line`), why it
matters, estimated effort (small / medium / large).

**Maturity target check** — the assessed maturity, the framework's minimum per category for that
level, and every category below it with its actual score.

### 3.4 — Persist

```bash
mkdir -p docs/audits
```

- Write the full report to `docs/audits/YYYY-MM-DD-audit.md`. For a scoped audit, append the scope
  as a slug: `2026-09-03-audit-src-billing.md`. If the file already exists (a second audit the same
  day), append `-2`, `-3`, and so on — never overwrite a prior report.
- Append one row to `docs/audits/history.md`, creating it with this header if absent:

```markdown
# Audit score history

| Date | Scope | Maturity | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C9 | C10 | Avg |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-09-03 | full | Established | 8.0 | 7.5 | 8.0 | 6.0 | N/A | 7.0 | 6.5 | 7.0 | 5.5 | 6.5 | 6.9 |
```

`Avg` excludes `N/A` categories. Both files are meant to be committed — the history is what turns a
one-off score into a trend. Tell the user the two paths at the end, and leave committing to them.

### 3.5 — Write the active audit focus

An audit that only produces a report changes nothing about the code written after it. Turn the
findings into instructions that apply while writing, in `.claude/audit-focus.md`.

**What goes in it:** the 3–5 weakest criteria **that have a write-time principle behind them** —
look them up in the traceability table at the end of
`.claude/framework/standards/CODING_STANDARDS.md`. A gap in project infrastructure (a missing CI
gate, absent security headers, no health endpoint) cannot be honoured while writing a feature; it
belongs in the report's Top actions as project work, not here. Ranking is by distance below the
maturity target, severity breaking ties.

Overwrite the file completely — it describes the current audit, not an accumulated history. Use
this shape:

```markdown
# Audit focus — 2026-09-03

> Generated by `/project-audit` from `docs/audits/2026-09-03-audit.md`. Regenerated at every
> audit — do not edit by hand, edits are overwritten.
> Scope: full project · Maturity: Established (target 7/10)

## 1. Category 9 — Observability & Operability — 4/10

**When you touch:** any path that can fail; any scheduled or long-running task
**Apply:** every failure path emits one structured record carrying the ids needed to trace it,
through the injected logger — never `error_log()` or `print`. Scheduled work gets bounded output.
**Principle:** 16 — Observability is part of the feature
**Criteria:** 9.1, 9.2, 9.6

## 2. Category 4 — Testing — 5/10

**When you touch:** `src/Billing/` — the manifest shows no tests for it
**Apply:** state the expected behaviour before implementing; double only the payment gateway, use
real `Money` and `Invoice` objects
**Principle:** 10, 17
**Criteria:** 4.2, 4.6
```

Each **Apply** line must be a rule someone can follow without reopening the audit report — name the
concrete thing to do in this project, not the criterion restated.

Tell the user the file was written and that it now applies to every session in this project.

### 3.6 — Clean up

```bash
rm -rf "$AUDIT_DIR"
```

Only the scratch bundle is removed. The report and history stay.
