---
description: Full 11-category scored quality audit with 11 parallel scoring agents; writes a dated report and score history to docs/audits/. --summary and --deep change how much of it is printed.
allowed-tools: [Read, Grep, Glob, Bash, Write, Edit, Task, Agent]
---

Run a complete, scored quality evaluation using **11 parallel scoring agents** — one per category.

## Arguments

```text
/project-audit [--summary | --standard | --deep] [<directory>]
```

Both are optional and order-independent.

**Scope** — a directory to confine the audit to (`/project-audit src/Billing`). Empty means the
whole project. A scoped audit is only ever compared against prior audits of the same scope.

**Detail level** — how much of the result is *printed*:

| Level | What reaches the conversation |
|---|---|
| `--summary` | The snapshot, the score movement, the summary table. Results only — no per-subcriteria evidence, no actions. |
| `--standard` | Default. The above, plus the ten category blocks, the ranked top actions, and the maturity target check. |
| `--deep` | The above, plus **every** gap the agents recorded — worst score first, each expanded into where it is, why it matters, and what to change. |

**The level is a rendering choice and nothing else.** Phases 1 and 2 run identically at all three:
the same evidence, the same ten agents, the same subcriteria against the same anchors. A category
scores what it scores whether or not you asked to read about it — otherwise `docs/audits/history.md`
would be comparing a `--summary` run against a `--deep` one and reporting the difference as
progress. For the same reason the written report is never thinner than `--standard` (§ 3.4): the
agents' evidence has already been paid for, and dropping it to keep a terminal short loses it for
good.

**Execution model:** Phase 1 (gather evidence, sequential) → Phase 2 (11 parallel subagents, one
per category) → Phase 3 (aggregate, persist, report). Scoring is pure reasoning and fully
independent across categories, so it runs concurrently.

**Evidence is sliced, not duplicated.** Phase 1 writes a small shared bundle plus a *manifest* of
the source tree. Each agent reads only the files its category actually needs — a security review
does not need the domain model, and a DDD review does not need the CI config. Never inline the
project source into agent prompts: with 10 agents that costs the whole codebase ten times over.

> ⚠ **Cost:** still a heavy command — ten agents reading real code. On a large project, scope it
> (`/project-audit src/Billing`) rather than sweeping the tree, and run it at decision points, not
> as a routine check. `--summary` is not the cheap option: it prints less, it does not measure less.
> Scope is the only lever on what an audit costs.

---

## Phase 1 — Gather evidence (orchestrator, sequential)

### 1.1 — Parse the arguments, then open a workspace

`$ARGUMENTS` holds whatever followed the command name. Split it on whitespace and classify each
token — one that begins with `--` is a level, anything else is the scope:

- `--summary`, `--standard`, `--deep` → the level, matched against those three literals exactly.
  **Any other token beginning with `--` is an error**: say which token was not understood and stop.
  Do not guess at a near miss, and do not fall through to treating it as a directory.
- Any other token → the scope. It must resolve to an existing directory **inside** the project root:
  reject an absolute path, a path containing `..`, and a path that does not exist, naming which of
  the three it failed.
- Two levels, or two scopes → stop and say so. Silently keeping the last one runs a different audit
  than the one that was asked for.

Neither value is ever interpolated into a command string. The scope is passed to `find` as a quoted
argument; the level selects between branches written out in this file.

Defaults: level `--standard`, scope the whole project. Below, they are *the level* and *the scope*.

```bash
AUDIT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/audit-XXXXXX")
PROJECT_ROOT=$(git rev-parse --show-toplevel)
FRAMEWORK_DIR="$PROJECT_ROOT/.claude/framework"
SCOPE="."   # ← the validated directory from the parse above, or "." for the whole project
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
  sliced in 1.4, because eleven agents reading a 2,300-line standard in full costs the document
  eleven times over for ten elevenths they do not need.
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
- The team shape: the **Team census** block of `.claude/PROJECT_AUDIT_FRAMEWORK.md` if it exists,
  and in either case `git shortlog -sne --since='12 months ago' --no-merges HEAD`, read as identities
  rather than as people — a bot or a shared account is somebody's work, and precondition 5 is the rule
  for one nobody can resolve.
  Precondition 5 — it decides which of 10.12, 10.13 and 10.14 the Cat 10 agent scores at all, and
  a census the shortlog contradicts is itself a finding
- The product documentation index: `ls -R docs/ 2>/dev/null | head -60`, plus every status marker
  found by `grep -rn '^status:' docs/ 2>/dev/null | head -40`. This is Category 0's primary evidence,
  and it is in the shared bundle rather than in that agent's slice alone because it changes how the
  other agents read a gap: a missing check inside a spec marked `todo` is unbuilt work, not a defect.
  If `docs/` does not exist, record that — the absence is the finding, and every agent needs to know
  it before treating an omission as intentional

### 1.4 — Slice the framework by category

Each agent scores one category and needs one category. Write `$AUDIT_DIR/framework/cat-N.md` for
N in 0–10, each holding just that category's section:

```bash
mkdir -p "$AUDIT_DIR/framework"
STD="$FRAMEWORK_DIR/standards/PROJECT_AUDIT_FRAMEWORK.md"
for n in $(seq 0 10); do
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

### 1.5 — Capture declared access (only what is declared)

Two sections of `.claude/PROJECT_AUDIT_FRAMEWORK.md` grant access that configuration cannot
substitute for. Each is read if present and skipped if not — their absence is itself reportable, and
never a reason to go looking for credentials.

#### Database — for 7.9 and 9.8

Read the **Database access for query analysis** section. If it is absent, note it in the report and
skip the rest of this block — do not go looking for credentials.

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

#### Production — for 9.9

Read the **Production access** section. If it is absent, record that in `common.md` — 9.9 is then
scored on what a *person* can reach — and skip the rest of this block.

If it is declared, append to `common.md`:

- The declaration itself: each signal, the path that reaches it, which paths are open to a session,
  and which actions are mutating. **Never the credentials** — name the variable, not its value
- Whether each read-only path **resolves**: the host answers, the dashboard URL is live, the command
  is in the Bash allow-list, the named environment variable is set. A declared path that no longer
  resolves is the 9.9 finding, and worth more than the signal it was supposed to reach
- At most one small read through each path — the current health response, the last few error-level
  lines — as proof the signal is live. Redact identifiers, tokens and payloads before they land in
  the file

> **Read-only, always.** No restart, no rollback, no migration, no purge, not even one the section
> allow-lists: an audit observes production, it does not operate it. Raw production log lines never
> enter the bundle. The rules in `INSTRUCTIONS.md` § *Production access* apply in full.

### 1.6 — Write the source manifest

`$AUDIT_DIR/manifest.md` — an **index**, not the contents. One line per file: path, line count,
and inferred role. Confine it to the scope from 1.1 — `SCOPE` below is that validated directory,
and nothing else may be substituted for it.

```bash
find "${SCOPE:-.}" -type f \( -name '*.php' -o -name '*.js' -o -name '*.ts' -o -name '*.jsx' \
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
- Scope: full project, or the directory from 1.1 — and the level in effect, so the user learns
  before the ten agents launch that they asked for `--summary` when they wanted `--deep`
- Quality gate result: ✓ green / ✗ red / ⚠ partial
- Maturity: Prototype / Early production / Established / Enterprise — one sentence of reasoning
- Team shape: how many people write here, whether a review crosses between two of them, and
  whether anything consumes a version — declared in the **Team census** block, or read from the
  history and said to be. State which subcriteria of Category 10 that puts out of play, before
  the agent reaches the question alone
- Which conditional categories apply: Cat 3 (DDD) if a domain layer exists; Cat 5 (JS/Frontend) if
  JS or TS files are present
- Whether the project writes text for anyone *using* it, and through which surfaces — templates, PDF
  or report builders, mail, product CLI. Output read only by the project's own developers and
  operators does not count. This is what decides 2.9 and 2.10; state it here so the Cat 2 agent does
  not have to reach the N/A call alone
- Whether database evidence was captured — and if not, that 7.9 and 9.8 are capped at 8
- Whether the project is an operated service at all, and if so whether a production path was
  declared and resolved — and if not, that 9.9 is scored on human reach alone
- What the project owns that the repository cannot rebuild — production data, uploads, secrets,
  DNS, hand-configured infrastructure. This is the scope 9.10 is scored against, and naming it
  before the agents launch is what stops the Cat 9 agent from scoring the database alone
- Whether the project has a product documentation home, and what it contains. State it here, before
  the agents launch, because it decides how all eleven read an omission — an unimplemented spec and
  an unfinished feature look identical in the code and score very differently

---

## Phase 2 — Parallel category scoring

Launch **all 11 agents in a single message** (eleven tool calls in one block) so they run
concurrently. One agent per category, `subagent_type: general-purpose`. Category 0 is scored by an
agent like the rest — it is read first by the *reader* of the report, not scored first in time, and
serialising it would cost the whole audit its parallelism for one slice.

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
| 0 | Product Strategy & Delivery Documentation | Where the **Team census** records an area with a single author, score 0.1 knowing the *why* for it has exactly one holder — that is the case the document exists for. Then the documentation tree and status-marker listing captured in `common.md`, then the documents themselves — the context document, the specs, the ADR index, the design artifacts. For 0.4, read the markers, not the prose: the question is whether a fixed field from a closed vocabulary exists, which `grep` answers and reading does not. For 0.5, take the specs marked `implemented` and check the code they name actually exists; take the ones marked `todo` and check they are not already built — a spec silently delivered is the same defect as one silently abandoned. For 0.6, follow the design links: a link to a tool's current canvas and a link pinned to a frame are different scores. For 0.8, read the plan inside the specs for work in flight — an ordered list of steps, each naming its test and what is released once it lands — then stop reading and join it to the history: run the indicators in *How the plan is measured against the history* for the units in the slice and apply its ceilings. They are read-only `git` plus the CI run list, so run them rather than inferring them from `common.md`'s twenty-line log, and quote the numbers in the finding — including the window you read them over, which the section defines and the report must name. A five-step plan delivered as one commit scores the commit, not the list. Apply the adoption provision in the slice: find the commit that created the documentation home, and score 0.3–0.5 and 0.8 against the units of delivery since that date rather than against the whole history — an inherited project cannot be scored on documents it was never going to have |
| 1 | OOP & Design Patterns | Domain and application classes, interfaces, factories, the largest classes in the manifest. For 1.6 and 1.7, grep for overrides that throw "not implemented" or "not supported" and for type checks on subtypes. For 1.8, run the co-change query the subcriteria gives over the whole history rather than `common.md`'s excerpt, and name the decision behind each cross-module pair |
| 2 | Clean Code | A sample across the tree, weighted to the longest files — that is where naming, size and duplication problems concentrate. For 2.8, read the **Domain language** section of `.claude/CODING_STANDARDS.md` *first*, note which context each sampled file belongs to, then sample deliberately across the context boundaries: a declared term inside its context is correct, the same term outside it is a boundary leak, and an undeclared non-English term is drift. For 2.9 and 2.10, read the **User-facing text** section of the same file first — it is the only place the required locale set is declared — then visit *every* surface the orchestrator listed, not a sample: a hardcoded PDF or mail template is the finding, and sampling is how it stays hidden. For 2.10, diff the key sets between catalogs rather than trusting their line counts, and score against the declared set only — nothing outside the repository enters the score. For 2.11, run the subcriteria's query over the last six months, read the flagged commits rather than counting them, and quote the window |
| 3 | Domain-Driven Design | Layer directories, entities, value objects, repository interfaces, domain events, and whatever enforces the boundaries. For 3.9, read the product context for the named core domain before the code, then compare where coverage, value objects and ADRs concentrate |
| 4 | Testing | The whole test tree, the test runner config, plus enough source to judge whether the critical paths are the ones covered. For 4.7 the evidence is not in the tree: run the `git log` queries the subcriteria gives, over the whole history rather than `common.md`'s twenty-line excerpt, and quote the ratio and the window. Then spot-check two or three recent fixes — check out the fix's parent, bring in only the test that fix added, run it. One that passes there did not catch the bug it claims to pin. Read the deletions too: a regression test removed outside the commit that changed the behaviour it guarded is the same finding as one never written |
| 5 | JS / Frontend | JS/TS files only, plus their build and lint config |
| 6 | Framework & Dependencies | Manifests, framework config and bootstrap, the entry points, and any place the framework is bypassed. For 6.9, the lockfile, `.gitmodules` and submodule pins, the declared runtime version, and any Renovate/Dependabot config — then ask the resolver which constraint blocks an upgrade rather than eyeballing version numbers |
| 7 | Tooling & Quality Standards | Tooling config and the quality gate output in `common.md` — plus grep for suppression markers (`@ts-ignore`, `ignoreErrors`, `phpcs:disable`, `noqa`, `filterwarnings`). For 7.9, grep the test suite for query-count assertions and the bootstrap for a lazy-load guard. For 7.10, take the highest-traffic claims from `README.md` and `.claude/*` — the setup command, the quality gate command, the analyser level, the layer rules — and check each against the file that would prove it; then look for any CI job that ties documentation to reality |
| 8 | Application Security | Input boundaries (controllers, request handling, deserialization), auth and authorisation, templates and output encoding, headers, and anywhere secrets are read |
| 9 | Observability & Operability | Logger setup and call sites, error handling and reporting, health endpoints, metrics, log rotation and retention config. For 9.8, the database and ORM config (slow query threshold, statement logging) and whether anything reads it. For 9.9, the **Production access** section of `.claude/PROJECT_AUDIT_FRAMEWORK.md`, the runbook or ops documentation, MCP server configuration and the Bash allow-list in `.claude/settings.json` — then check the declaration resolves (the host and dashboard are named and current, the credential source exists, the command is allow-listed) instead of trusting it. Verification is read-only: never run a mutating command against production to prove access. For 9.10, the backup jobs (cron, scheduler, IaC, provider configuration), where they write, the restore runbook, and the drill receipts — then reconcile the backed-up set against what the repository cannot rebuild (database, uploads, secrets, DNS, hand-configured hosts); the gap is the finding. Score the newest receipts by what emitted them, against the evidence ceilings in the slice, and cross-check one against records written elsewhere — the CI run log, the commit date, whether the drill script existed in the repository on the date claimed. For 9.11, start with the two sources that need no production path — the IaC plan against a clean checkout, and the cost report read per resource — then, only where **Production access** declares a read-only path, enumerate resources and the last-used date of every long-lived credential. Enumerating and planning are read-only; never delete a resource or disable a key to prove a finding, and cap the score at 7 where no path is declared. For 9.4, look for stated objectives and what the alerts fire on. For 9.5, list the outbound clients and find each one's timeout |
| 10 | CI/CD & Version Control | CI config, migrations, deploy and rollback scripts, plus the git log and branch list in `common.md`. Start with the proportionality rule at the top of the slice and the team shape in `common.md`: it decides whether 10.12, 10.13's approval half and 10.14 are scored or N/A, and a project that does not have the problem a practice solves scores full marks without the practice — never mark a gap for ceremony nobody here needs. Run the per-directory author count the same section gives: where 10.12 applies, a live area with a single author ever is a change with no available reviewer, reported as the concentration it is rather than scored as a missing rule. Never read the history for anybody's competence; it records territory. For 10.15, read the **Delivery convention** block of `.claude/PROJECT_AUDIT_FRAMEWORK.md` first — it is the declaration everything else in that subcriteria is scored against — then check that each mechanical claim resolves to a job or a script that would actually fail, and read the log for the conformance signature: a changelog commit landing days after the change it describes, a tag on a different commit from its version bump, install instructions pinning a superseded version, a branch nobody's definition of done required pushing. Score the shape the team declared, never the length of it. For 10.16 run the four ref-and-size commands the subcriteria gives against the live remote — the branch list in `common.md` is a snapshot and says nothing about ages or about refs already gone upstream — and check the host's branch auto-delete setting, the project's documented git configuration, and any scheduled cleanup job for the retention rule it states. For 10.17, look for anything that computes the four measures; where nothing does, compute the first two from the tags as the subcriteria shows and report them as the baseline |

---

## Phase 3 — Aggregate, persist, report (orchestrator, sequential)

### 3.1 — Collect

```bash
for i in $(seq 0 10); do cat "$AUDIT_DIR/cat/$i.md" 2>/dev/null || echo "⚠ Category $i produced no output"; done
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

Seven sections, in this order. **The level decides where it stops** — each level prints everything
the ones before it print, so the order below is also the order of increasing detail:

| | Section | `--summary` | `--standard` | `--deep` |
|---|---|---|---|---|
| 1 | Project snapshot | ✓ | ✓ | ✓ |
| 2 | Score movement | ✓ | ✓ | ✓ |
| 3 | Summary table | ✓ | ✓ | ✓ |
| 4 | Detailed subcriteria scores | | ✓ | ✓ |
| 5 | Top actions | | ✓ | ✓ |
| 6 | Maturity target check | | ✓ | ✓ |
| 7 | Remediation detail | | | ✓ |

The summary table comes before the per-category evidence rather than after it, which is where it
used to sit: the verdict is what a reader wants first, and it is what makes truncating at section 3
a coherent report rather than a report with its conclusion cut off.

**1. Project snapshot** — stack, maturity with reasoning, scope, remediation band and phase with
reasoning, quality gate result (with the failing lines if not green), and any of these warnings that
apply:

The band and phase line is the one in *Recording the order in the audit* in
`.claude/framework/standards/PROJECT_AUDIT_FRAMEWORK.md`, filled in from this audit's scores: band
target, phase, floor (the lowest-scoring category and its score), spread (highest minus lowest), and
the categories below the band target. Compute all four from the summary table — none of them is
stored anywhere, and a figure that disagrees with the table beside it is worse than no figure.

- ⚠ No project-level `.claude/PROJECT_AUDIT_FRAMEWORK.md` — audit uses the global framework only
- ⚠ No project-level `.claude/CODING_STANDARDS.md`
- ⚠ No `.claudeignore` — dependency trees excluded manually
- ⚠ No database declared for query analysis — 7.9 and 9.8 scored from configuration only, capped at 8

**2. Score movement** — the comparison from 3.2, or the baseline note.

**3. Summary table** — one row per category, in this shape:

```text
┌─────┬─────────────────────────────┬─────────────┬─────────┐
│  #  │          Category           │    Score    │ Top gap │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 0   │ Product & Delivery Docs     │ X/10        │ …       │
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

At `--summary` the report ends here, with two closing lines and nothing else:

```text
Band target 6 · Phase 2 · floor Cat 9 (4.0) · spread 5.0
Below the Established target (7/10): Cat 4 (5.0) · Cat 7 (6.5) · Cat 9 (4.0)
Full report: docs/audits/2026-09-05-audit.md — 23 recorded gaps. Re-run with --deep to read them.
```

**4. Detailed subcriteria scores** — the 11 category blocks in order, verbatim from the agents.

**5. Top actions** — ranked by impact/effort **within the project's current band and phase**. For
each: what to fix, where (`file:line`), why it matters, estimated effort (small / medium / large),
and the phase it belongs to.

Band and phase both come from *Remediation order* in
`.claude/framework/standards/PROJECT_AUDIT_FRAMEWORK.md`, and this section is where that order
becomes an instruction rather than a principle. Three rules follow from it:

- **A category already at the band target does not enter the ranking at all.** Not as a blocked
  entry, not as a footnote — the work is real and it is simply not next. The exception is the one
  the standard allows: a fix that is a line of configuration and cannot regress silently, which is
  listed with `out of order — one line` on it so the reader can see it was a deliberate call.
- **A gap in a later phase does not enter the ranking either.** It appears instead as the blocked
  entry the standard describes — the gap named, the prerequisite named, the prerequisite's own
  effort given — and it appears once, below the ranked actions under `Blocked by an earlier phase`.
  The project still gets to see its biggest problem; it does not get to see it presented as this
  quarter's work.
- **An action that is more than one change names its first step.** For anything estimated medium or
  large, give the smallest change that settles the riskiest part of the gap, on its own line —
  `first step: characterise the invoicing use cases with a golden file, one day`. This section is the
  part of the report most likely to be handed to an agent verbatim, and an instruction written at the
  altitude of the end state is the one 0.8 exists to stop. A small action is one step already and
  needs no second line.
- **Where the current band and phase yield fewer than three actions, the list is shorter than
  three.** Do not reach into the next phase, and do not reach past the band target of a category
  that has already met it, to fill the list. A project whose Phase 2 work is two items has two top
  actions, and saying so is more useful than a third that cannot be started or should not be.

**6. Maturity target check** — the assessed maturity, the framework's minimum per category for that
level, every category below it with its actual score, and the current band target with the categories
below *that*. The two lists differ whenever the project is more than one rung from its maturity
minimum, and the difference is the point: the first is the destination, the second is this quarter's
scope.

**7. Remediation detail** — `--deep` only. **Every** subcriteria whose `Gap` column is not `—`,
worst score first, across all categories. The cut is the presence of a recorded gap, not a threshold:
a 7/10 with a named gap is still a named gap, and "everything worth improving" is what this level
was asked for. One entry each:

```markdown
##### 9.2 Structured logging — 4/10 · Category 9 · Principle 16

- **Where:** `src/Infrastructure/Mailer.php:88`, `src/Console/SyncCommand.php:31`
- **The gap:** what is there now, in one sentence
- **Why it matters:** the failure this makes likely, or makes invisible — concrete to this project,
  not the criterion restated
- **What to change:** the smallest change that closes it — or, where the gap cannot be closed in one
  change, the first step and what it settles
- **Effort:** small / medium / large
- **Phase:** 0–4, from *Remediation order*; where it is later than the project's own phase, name the
  prerequisite on the same line — `3 — blocked on Cat 4 coverage of src/Domain`
```

- **Expand from evidence already in hand.** The agents cited `file:line` for every subcriteria they
  scored; this section rewrites those citations into instructions. Do not re-read the tree, and
  never invent a location. Where an agent recorded a gap with no citation, write
  `**Where:** not cited by the Category N agent` and leave it at that — an admitted hole costs a
  reader one line, a fabricated line number costs them the trip.
- **Principle** comes from the traceability table at the end of
  `.claude/framework/standards/CODING_STANDARDS.md`. A criterion with no principle behind it is
  project work rather than write-time work: write `Principle: — (project work)`. That is the same
  distinction 3.5 makes when it decides what may enter the audit focus.
- **Top actions stays as it is.** `--deep` is the long tail underneath the ranking, not a
  replacement for it. Do not re-rank, and do not drop an entry because it already appears above.
- On a full-project audit this section runs long — eighty entries is normal for a codebase scoring
  in the sixes. That is what the level means. If it is more than is useful, the lever is scope:
  `/project-audit --deep src/Billing`.

### 3.4 — Persist

```bash
mkdir -p docs/audits
```

**What is written does not shrink with the level.** At `--summary` compose the whole report through
section 6 and write *that* to disk, then print only sections 1–3. At `--deep` the remediation detail
goes into the file too. The level is not recorded in the report or in `history.md` — the scores in
both are identical either way, and a field nothing reads is a field that goes stale.

- Write the full report to `docs/audits/YYYY-MM-DD-audit.md`. For a scoped audit, append the scope
  as a slug: `2026-09-03-audit-src-billing.md`. If the file already exists (a second audit the same
  day), append `-2`, `-3`, and so on — never overwrite a prior report.
- Append one row to `docs/audits/history.md`, creating it with this header if absent:

```markdown
# Audit score history

| Date | Scope | Maturity | C0 | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C9 | C10 | Avg |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-09-03 | full | Established | 5.0 | 8.0 | 7.5 | 8.0 | 6.0 | N/A | 7.0 | 6.5 | 7.0 | 5.5 | 6.5 | 6.7 |
```

`Avg` excludes `N/A` categories.

**If `history.md` exists without a `C0` column**, it predates Category 0. Add the column to the header
and to the separator row, and fill every existing row with `—` — those audits did not measure it, and
a blank that reads as a score would put a fiction into the trend. Do not recompute their `Avg`: it was
correct for what was scored at the time, and rewriting history to look consistent is how a trend stops
being evidence. Say in the report that the column was added.

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

This step runs at **every** level, `--summary` included. It is derived from the scores rather than
from the prose the level selected, and skipping it would leave the project writing code against a
stale focus while the report on disk says otherwise.

**What goes in it:** the 3–5 weakest criteria **that have a write-time principle behind them** —
look them up in the traceability table at the end of
`.claude/framework/standards/CODING_STANDARDS.md`. A gap in project infrastructure (a missing CI
gate, absent security headers, no health endpoint) cannot be honoured while writing a feature; it
belongs in the report's Top actions as project work, not here. Ranking is by distance below the
band target, severity breaking ties — the same floor-first rule the Top actions follow, so the two
artefacts cannot point a project in different directions.

2.10 is the same shape as those: populating a catalog is backlog work, not a rule someone can honour
while writing a feature, so it belongs in Top actions. 2.9 belongs here — "put the string in the
catalog" applies to the next line of code written.

Overwrite the file completely — it describes the current audit, not an accumulated history. Use
this shape:

```markdown
# Audit focus — 2026-09-03

> Generated by `/project-audit` from `docs/audits/2026-09-03-audit.md`. Regenerated at every
> audit — do not edit by hand, edits are overwritten.
> Scope: full project · Maturity: Established (target 7/10) · Band target 6 · Phase 2

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
