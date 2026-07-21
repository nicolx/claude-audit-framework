Run a complete, scored quality evaluation using **10 parallel scoring agents** — one per category.

> **Execution model:** Phase 1 (gather evidence, sequential) → Phase 2 (10 parallel `claude -p` subagents, one per category) → Phase 3 (aggregate report, sequential). The scoring phase — pure reasoning, fully independent across categories — runs concurrently.

---

## Phase 1 — Gather evidence (orchestrator, sequential)

### 1.1 — Workspace

```bash
AUDIT_ID=$(date +%s)
AUDIT_DIR="/tmp/audit-$AUDIT_ID"
FRAMEWORK_DIR="$(git rev-parse --show-toplevel)/.claude/framework"
mkdir -p "$AUDIT_DIR"
```

### 1.2 — Verify .claudeignore

If `.claudeignore` is absent from the project root, note it in the final report and exclude `vendor/`, `node_modules/`, `.git/`, `dist/`, `build/`, `var/`, `storage/`, `*.lock`, `*.log` from all traversals.

### 1.3 — Write the evidence bundle

Collect all of the following into `$AUDIT_DIR/evidence.md` (append each section with a clear separator):

- `cat "$FRAMEWORK_DIR/standards/PROJECT_AUDIT_FRAMEWORK.md"` — global framework
- `cat PROJECT_AUDIT_FRAMEWORK.md` — project-local framework (if present; note if missing)
- `cat CLAUDE.md` and `cat README.md` — project context
- Dependency manifest: `composer.json`, `package.json`, or `pyproject.toml`
- CI/CD config: all files under `.github/workflows/`, `Makefile`
- Quality gate output: `composer qa 2>&1` (or `make qa`, `npm run lint && npm test`, etc.)
- All source and test files (PHP, JS, TS, Python) — excluding `vendor/`, `.git/`, `node_modules/`, `dist/`, `build/`
- `git log --oneline -20` and `git branch -a`

### 1.4 — State preconditions

Before launching Phase 2, explicitly state:
- Technology stack and primary language(s)
- Architectural pattern and layer structure
- Quality gate result (✓ green / ✗ red / ⚠ partial)
- Maturity assessment: Prototype / Early production / Established / Enterprise — one sentence of reasoning
- Which conditional categories apply: Cat 3 (DDD) if a domain layer exists; Cat 5 (JS/Frontend) if JS or TS files are present

---

## Phase 2 — Parallel category scoring

Read evidence once:

```bash
EVIDENCE=$(cat "$AUDIT_DIR/evidence.md")
```

Launch all 10 agents before calling `wait`. Each agent receives the full evidence plus category-specific instructions and writes only its category block to `$AUDIT_DIR/cat-N.md`.

Agent pattern (substitute category number N and name for each):

```bash
claude -p "You are a senior software architect performing a focused quality review.

TASK: Score ONLY Category N — [Name].

INSTRUCTIONS:
- Find your category's subcriteria in the GLOBAL AUDIT FRAMEWORK section of the evidence below.
- Apply any project-specific specializations from the PROJECT AUDIT FRAMEWORK section.
- Score each subcriteria individually (0–10), anchored to the scale defined in the framework.
- Cite specific evidence for each subcriteria: file:line or a named observable behaviour.
- Derive the category score as a weighted judgement — do not mechanically average subcriteria.
- Cat 3 (DDD): if no domain layer is present, output 'N/A — no domain layer detected' and stop.
- Cat 5 (JS/Frontend): if no JS/TS files are present, output 'N/A — no JS/TS detected' and stop.
- Output ONLY the block below — no preamble, no conclusion, nothing else.

OUTPUT FORMAT:
#### Category N — [Name] — **X/10**

| Subcriteria | Score | Evidence | Gap |
|---|---|---|---|
| N.1 Name | X/10 | \`file:line\` | gap description or — |
| N.2 Name | X/10 | \`file:line\` | gap description or — |

> **Category verdict:** one sentence naming the dominant strength and the dominant gap.

--- EVIDENCE BUNDLE START ---
$EVIDENCE
--- EVIDENCE BUNDLE END ---" \
  > "$AUDIT_DIR/cat-N.md" &
```

Apply for all 10 categories in sequence (1 through 10), each ending with `&` to background it. Then:

```bash
wait
echo "All 10 category agents completed."
```

---

## Phase 3 — Aggregate and render report (orchestrator, sequential)

Read all outputs: `for i in $(seq 1 10); do cat "$AUDIT_DIR/cat-$i.md"; done`

Compose the final report in this exact order.

### Project snapshot

- Stack: detected languages, frameworks, runtime
- Maturity: assessed level with one sentence of reasoning
- Quality gate: ✓ green / ✗ red / ⚠ partial — include relevant failing lines if not green
- Warnings (if applicable):
  - ⚠ No project-level `PROJECT_AUDIT_FRAMEWORK.md` found — audit uses global framework only
  - ⚠ No project-level `CODING_STANDARDS.md` found
  - ⚠ No `.claudeignore` found — dependency trees excluded manually

### Detailed subcriteria scores

Paste the 10 category blocks in order (1–10) from `$AUDIT_DIR/cat-1.md` through `cat-10.md`. Do not re-score — use each subagent's output verbatim.

### Summary table

```
┌─────┬─────────────────────────────┬─────────────┬─────────┐
│  #  │          Category           │    Score    │ Top gap │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 1   │ OOP & Design Patterns       │ X/10        │ …       │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 2   │ Clean Code                  │ X/10        │ …       │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 3   │ Domain-Driven Design        │ X/10 or N/A │ …       │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 4   │ Testing                     │ X/10        │ …       │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 5   │ JS / Frontend Quality       │ X/10 or N/A │ …       │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 6   │ Framework & Dependencies    │ X/10        │ …       │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 7   │ Tooling & Quality Standards │ X/10        │ …       │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 8   │ Application Security        │ X/10        │ …       │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 9   │ Observability & Operability │ X/10        │ …       │
├─────┼─────────────────────────────┼─────────────┼─────────┤
│ 10  │ CI/CD & Version Control     │ X/10        │ …       │
└─────┴─────────────────────────────┴─────────────┴─────────┘
```

### Top actions

Ranked by impact/effort ratio. For each: what to fix, where (file:line), why it matters, estimated effort.

```
┌──────────┬────────┬───────────┬─────┬────────────────────┐
│ Priority │ Action │   Where   │ Why │       Effort       │
├──────────┼────────┼───────────┼─────┼────────────────────┤
│ 1        │ …      │ file:line │ …   │ small/medium/large │
├──────────┼────────┼───────────┼─────┼────────────────────┤
│ 2        │ …      │ file:line │ …   │ small/medium/large │
├──────────┼────────┼───────────┼─────┼────────────────────┤
│ 3        │ …      │ file:line │ …   │ small/medium/large │
└──────────┴────────┴───────────┴─────┴────────────────────┘
```

### Maturity target check

State the assessed maturity level and the minimum score per category from the global framework. List every category that falls below the minimum with its actual score.

### Clean up

```bash
rm -rf "$AUDIT_DIR"
```
