---
description: Full 10-category scored quality audit with 10 parallel scoring agents; writes a dated report and score history to docs/audits/
allowed-tools: [Read, Grep, Glob, Bash, Write, Edit, Task, Agent]
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

- From `$FRAMEWORK_DIR/standards/PROJECT_AUDIT_FRAMEWORK.md`, **only the shared parts**: the
  preconditions, the score anchors table, and the N/A rules. Not the categories — those are
  sliced in 1.4, because ten agents reading a 2,000-line standard in full costs the document
  ten times over for nine tenths they do not need.
- `.claude/PROJECT_AUDIT_FRAMEWORK.md` — project specializations (note explicitly if absent)
- `CLAUDE.md`, `README.md` — project context
- Dependency manifests: `composer.json`, `package.json`, `pyproject.toml`, `go.mod`, `build.gradle`
- Tooling config: `phpstan.neon`, `.eslintrc*`, `tsconfig.json`, `deptrac.yaml`, `.php-cs-fixer*`,
  `phpunit.xml`, `pytest.ini`, `ruff.toml` — whichever exist
- CI/CD config: everything under `.github/workflows/`, plus `Makefile`, `Jenkinsfile`, `.gitlab-ci.yml`
- Database and ORM config: `doctrine.yaml`, `database.php`, `settings.py` DATABASES, `schema.prisma`,
  plus any slow-query or statement-logging setting — what the project *intends*, which 1.5 then checks against reality
- Quality gate output: `composer qa 2>&1` / `make qa` / `npm run qa` — whichever the project defines.
  Capture the output verbatim, including failures. If no gate exists, record that as the finding it is.
- `git log --oneline -20`, `git branch -a`, and `git log -1 --format=%cd` (last commit date)

### 1.4 — Slice the framework by category

Each agent scores one category and needs one category. Write `$AUDIT_DIR/framework/cat-N.md` for
N in 1–10, each holding just that category's section:

```bash
mkdir -p "$AUDIT_DIR/framework"
STD="$FRAMEWORK_DIR/standards/PROJECT_AUDIT_FRAMEWORK.md"
for n in $(seq 1 10); do
    next=$((n + 1))
    if [ "$n" -eq 10 ]; then
        awk '/^## Category 10 —/,/^## How to conduct a quality evaluation/' "$STD" > "$AUDIT_DIR/framework/cat-10.md"
    else
        awk -v a="^## Category $n —" -v b="^## Category $next —" '$0 ~ a {p=1} $0 ~ b {p=0} p' "$STD" \
            > "$AUDIT_DIR/framework/cat-$n.md"
    fi
done
wc -l "$AUDIT_DIR"/framework/cat-*.md
```

If a project-level `.claude/PROJECT_AUDIT_FRAMEWORK.md` exists, append its matching
`## Category N` section to the corresponding slice — the specializations must travel with the
criteria they specialise, not sit in a file the agent has to correlate by hand.

Sanity-check the output: an empty or single-line slice means the awk ranges no longer match the
standard's headings, and an agent handed an empty slice will invent criteria rather than report the
problem.

### 1.5 — Capture database evidence (only if declared)

Read the **Database access for query analysis** section of `.claude/PROJECT_AUDIT_FRAMEWORK.md`. If
it is absent, note it in the report and skip this step — do not go looking for credentials.

If it is declared, append to `common.md`:

- Index inventory per table (`pg_indexes`, `SHOW INDEX FROM`, `information_schema.statistics`)
- Approximate row counts and table sizes, so "a table that grows" is a fact rather than a guess
- The engine's aggregated statement statistics, ordered by total time: `pg_stat_statements`,
  `performance_schema.events_statements_summary_by_digest`, or a `pt-query-digest` summary
- The slow-query settings actually in effect (`SHOW slow_query_log`, `log_min_duration_statement`)
- `EXPLAIN` output for the query paths that Cat 7 or Cat 9 puts in question — plans only, no
  `EXPLAIN ANALYZE` except on a plain `SELECT` against a non-production target

> **Never put application rows in the bundle.** This file is read by ten agents; row data in it is a
> disclosure, not evidence. Schema, counts, statistics and plans only. The rules in
> `INSTRUCTIONS.md` § *Database access* apply in full.

### 1.6 — Write the source manifest

`$AUDIT_DIR/manifest.md` — an **index**, not the contents. One line per file: path, line count,
and inferred role. Confine to `$ARGUMENTS` when a scope was given.

```bash
find "${ARGUMENTS:-.}" -type f \( -name '*.php' -o -name '*.js' -o -name '*.ts' -o -name '*.jsx' \
     -o -name '*.tsx' -o -name '*.py' -o -name '*.go' -o -name '*.kt' -o -name '*.swift' \
     -o -name '*.rb' -o -name '*.java' -o -name '*.cs' -o -name '*.rs' -o -name '*.sh' \
     -o -name '*.vue' -o -name '*.svelte' \) \
  -not -path '*/vendor/*' -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -path '*/var/*' -not -path '*/dist/*' -not -path '*/build/*' \
  | xargs wc -l | sort -rn
```

Group the result by directory and annotate each group with what it appears to be (domain,
application, infrastructure, controllers/http, tests, config, views). The annotation is what lets
an agent pick its files without reading everything.

**If the manifest comes back empty**, do not hand the agents an empty file and let them guess. Say
what the project actually consists of — documents, shell scripts, configuration, generated code —
and record it in `common.md`. A project with no application source is a legitimate thing to audit,
but several categories will be N/A and the agents need to be told why rather than deducing it from
an absence.

### 1.7 — State preconditions

Before launching Phase 2, state explicitly:

- Technology stack and primary language(s)
- Architectural pattern and layer structure
- Scope: full project, or the directory given in `$ARGUMENTS`
- Quality gate result: ✓ green / ✗ red / ⚠ partial
- Maturity: Prototype / Early production / Established / Enterprise — one sentence of reasoning
- Which conditional categories apply: Cat 3 (DDD) if a domain layer exists; Cat 5 (JS/Frontend) if
  JS or TS files are present
- Whether the project writes text for anyone *using* it, and through which surfaces — templates, PDF
  or report builders, mail, product CLI. Output read only by the project's own developers and
  operators does not count. This is what decides 2.9 and 2.10; state it here so the Cat 2 agent does
  not have to reach the N/A call alone
- Whether database evidence was captured — and if not, that 7.9 and 9.8 are capped at 8

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
> - Read `$AUDIT_DIR/framework/cat-N.md` — your category's criteria, and the project's
>   specializations for it. This is the standard you score against; do not score from memory.
> - Read `$AUDIT_DIR/common.md` in full — the scoring anchors and N/A rules, the project's context,
>   its manifests, tooling and CI config, and the quality gate output.
> - Read `$AUDIT_DIR/manifest.md` — an index of the source tree with line counts and inferred roles.
> - Then read from the project **only the files your category needs**: [focus for category N].
>   Do not read the whole tree. If the manifest shows more candidates than you need, sample the
>   largest and the most central, and say in your evidence what you sampled.
>
> **Scoring:**
>
> - Score every subcriteria in your slice, 0–10 against the anchors in `common.md`. If the slice
>   looks empty or truncated, say so and stop — do not reconstruct the criteria from memory.
> - Cite specific evidence per subcriteria: `file:line`, or a named observable behaviour.
> - Derive the category score as a weighted judgement — do not mechanically average subcriteria.
> - **Any category can be N/A**, not only 3 and 5. The rule is the one in `common.md`:
>   structurally absent, never "hard to evaluate". A project with no application source has no
>   Category 1 to score; a CLI has no Category 8 HTTP surface; a library has no Category 9 runtime.
>   Output `N/A — <what is absent>`, for a subcriteria or the whole category, with one sentence of
>   justification, and do not stretch to find something to score. An invented score is worse than an
>   honest N/A, because it enters `docs/audits/history.md` as if it meant something.
> - Cat 3 and Cat 5 are the common cases — no domain layer, no JS/TS. Stop immediately on those.
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
| 2 | Clean Code | A sample across the tree, weighted to the longest files — that is where naming, size and duplication problems concentrate. For 2.8, read the **Domain language** section of `.claude/CODING_STANDARDS.md` *first*, note which context each sampled file belongs to, then sample deliberately across the context boundaries: a declared term inside its context is correct, the same term outside it is a boundary leak, and an undeclared non-English term is drift. For 2.9 and 2.10, read the **User-facing text** section of the same file first — it is the only place the required locale set is declared — then visit *every* surface the orchestrator listed, not a sample: a hardcoded PDF or mail template is the finding, and sampling is how it stays hidden. For 2.10, diff the key sets between catalogs rather than trusting their line counts, and score against the declared set only — nothing outside the repository enters the score |
| 3 | Domain-Driven Design | Layer directories, entities, value objects, repository interfaces, domain events, and whatever enforces the boundaries |
| 4 | Testing | The whole test tree, the test runner config, plus enough source to judge whether the critical paths are the ones covered |
| 5 | JS / Frontend | JS/TS files only, plus their build and lint config |
| 6 | Framework & Dependencies | Manifests, framework config and bootstrap, the entry points, and any place the framework is bypassed. For 6.9, the lockfile, `.gitmodules` and submodule pins, the declared runtime version, and any Renovate/Dependabot config — then ask the resolver which constraint blocks an upgrade rather than eyeballing version numbers |
| 7 | Tooling & Quality Standards | Tooling config and the quality gate output in `common.md` — plus grep for suppression markers (`@ts-ignore`, `ignoreErrors`, `phpcs:disable`, `noqa`, `filterwarnings`). For 7.9, grep the test suite for query-count assertions and the bootstrap for a lazy-load guard. For 7.10, take the highest-traffic claims from `README.md` and `.claude/*` — the setup command, the quality gate command, the analyser level, the layer rules — and check each against the file that would prove it; then look for any CI job that ties documentation to reality |
| 8 | Application Security | Input boundaries (controllers, request handling, deserialization), auth and authorisation, templates and output encoding, headers, and anywhere secrets are read |
| 9 | Observability & Operability | Logger setup and call sites, error handling and reporting, health endpoints, metrics, log rotation and retention config. For 9.8, the database and ORM config (slow query threshold, statement logging) and whether anything reads it |
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
- ⚠ No database declared for query analysis — 7.9 and 9.8 scored from configuration only, capped at 8

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

`Avg` excludes `N/A` categories.

**Before recommending a commit, say this out loud.** An audit report names security weaknesses with
file and line — `8.3 authorisation checked on the route, not the operation, src/Http/Admin.php:42`
is a map for whoever reads it. In a private repository the history is worth having: it turns a
one-off score into a trend, and 6.9 and 7.10 rely on it. In a **public** repository it is a
disclosure.

So: tell the user both paths, state plainly that the report contains security findings and code
references, and ask whether the repository is public before recommending a commit. If it is, offer
the alternatives — keep the reports out of version control via `.gitignore`, or keep only
`history.md` (scores, no evidence) and drop the detailed reports. Leave committing to them either
way; never commit it yourself.

### 3.5 — Write the active audit focus

An audit that only produces a report changes nothing about the code written after it. Turn the
findings into instructions that apply while writing, in `.claude/audit-focus.md`.

**What goes in it:** the 3–5 weakest criteria **that have a write-time principle behind them** —
look them up in the traceability table at the end of
`.claude/framework/standards/CODING_STANDARDS.md`. A gap in project infrastructure (a missing CI
gate, absent security headers, no health endpoint) cannot be honoured while writing a feature; it
belongs in the report's Top actions as project work, not here. Ranking is by distance below the
maturity target, severity breaking ties.

2.10 is the same shape as those: populating a catalog is backlog work, not a rule someone can honour
while writing a feature, so it belongs in Top actions. 2.9 belongs here — "put the string in the
catalog" applies to the next line of code written.

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
