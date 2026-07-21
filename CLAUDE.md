# claude-audit-framework

Instructions for Claude Code in any project that uses `claude-audit-framework` as a submodule.
This file is included via `@.claude/framework/CLAUDE.md` in the project's `CLAUDE.md`.

---

## Developer profile

If `~/.claude/context/user_profile.md` exists, read it in full before proposing any technical solution, architectural choice, or implementation strategy. Calibrate every response to the competency levels defined inside:
- **Fluente** — propose advanced patterns freely; skip basic explanations; use domain terms without glossing
- **Operativo** — use in proposals but explain non-obvious choices; avoid advanced patterns without rationale
- **Base** — avoid as the primary technology; prefer alternatives where available; when unavoidable, use simple patterns and explain clearly

Entries marked with `*` are gaps the developer intends to fill. When a task genuinely requires one, flag it explicitly before proceeding — the goal is to grow the competency in context, not to avoid it.

At the start of each session, check the `next_review_date` field. If today's date is on or past that date, flag it once:
> 📋 Competency review due — run `/competency-review` when ready.

**If the file does NOT exist:** mention it once at the start of the session — `> 💡 No developer profile found. Run /init-profile to enable skill-level calibration.` — then proceed normally without repeating it.

---

## Enterprise Quality Standard

A 10-category quality framework is active in this project.

**Full document:** `.claude/framework/standards/PROJECT_AUDIT_FRAMEWORK.md`

Read it before conducting any quality evaluation or scoring. Do not score from memory alone.

### The 10 categories

| # | Category | Always evaluated? |
|---|---|---|
| 1 | OOP & Design Patterns | Yes |
| 2 | Clean Code | Yes |
| 3 | Domain-Driven Design (DDD) | If domain layer is present |
| 4 | Testing | Yes |
| 5 | JavaScript / Frontend Quality | If JS/TS is present |
| 6 | Framework, Library & Dependency Fitness | Yes (6.7 and 6.8 always; 6.1–6.6 if a framework is in use) |
| 7 | Tooling & Quality Standards | Yes |
| 8 | Application Security | Yes |
| 9 | Observability & Operability | Yes |
| 10 | CI/CD & Version Control Discipline | Yes |

### Score targets by project maturity

| Maturity | Min target per category |
|---|---|
| Prototype | 4/10 |
| Early production | 6/10 |
| Established | 7/10 |
| Enterprise | 8/10 |

### How to conduct an evaluation

1. Read `.claude/framework/standards/PROJECT_AUDIT_FRAMEWORK.md` in full before scoring
2. Check for `PROJECT_AUDIT_FRAMEWORK.md` in the project root — if present, it extends the global framework; apply both
3. Score each subcategory with specific file/line evidence — no vague scores
4. Identify top 3 improvement opportunities by impact/effort ratio
5. Produce a category summary table with score, top gap, and recommended action
6. Re-score only after changes are implemented and verified — not for planned work

---

## Coding standards

Apply `.claude/framework/standards/CODING_STANDARDS.md` before every implementation decision. Every code proposal must reflect these standards — this is not optional and does not require an explicit request.

**Before writing code in any project, check:**
- Does a `CODING_STANDARDS.md` exist in the project root? If not, flag it **once per session**:
  > ⚠ No project-level `CODING_STANDARDS.md` found. Stack-specific coding conventions are not defined. See `.claude/framework/templates/CODING_STANDARDS.md` for the format.
- Does a `PROJECT_AUDIT_FRAMEWORK.md` exist in the project root? If not, flag it **once per session**:
  > ⚠ No project-level `PROJECT_AUDIT_FRAMEWORK.md` found. Quality evaluation will use only the global framework.

If a project-level `CODING_STANDARDS.md` or `PROJECT_AUDIT_FRAMEWORK.md` exists, it takes precedence over the global framework where they conflict.

---

## Large project analysis protocol

These rules apply to **exploratory and general analysis**.

> **Exception — `/project-audit`:** that command intentionally reads the full project source before scoring. Do not apply the block-reading rules when running `/project-audit`.

### Prerequisite — verify `.claudeignore` before any analysis

Do not begin any analysis on a project until a `.claudeignore` exists at its root. Without it, traversals include dependency trees (`vendor/`, `node_modules/`), build artefacts, caches, and logs. If missing, create it or ask the user before proceeding.

Minimum contents for a web/backend project:
```
vendor/
node_modules/
.git/
var/
storage/
dist/
build/
coverage/
*.lock
*.log
```

### Context is finite — work in blocks

- **Scoped reads** over full-project reads: analyse `src/Billing/` before `src/`
- **Targeted searches** (`Grep`, `Glob`) over directory listings
- **Summary-first, detail-on-demand**: understand the structure before reading file contents
- **One concern at a time**: deprecations, then architecture, then security

### Use the Explore subagent for structural analysis

For tasks that require understanding project structure, finding patterns across many files, or answering architectural questions, launch an `Explore` subagent. It runs in an isolated context and returns a focused summary without consuming the main session window.

### Use static analysis tools before asking Claude to read source

| Concern | Run first |
|---|---|
| PHP deprecations | `vendor/bin/phpstan analyse --level=max src 2>&1 \| grep -i deprecated` |
| JS/TS deprecations | `npx tsc --noEmit 2>&1 \| grep deprecated` |
| Dependency vulnerabilities | `composer audit` / `npm audit` / `pip-audit` |
| Architecture violations | `vendor/bin/deptrac analyse` / `npx eslint --rule 'import/no-restricted-paths'` |
| Dead code | `vendor/bin/phpstan analyse --level=max` / `npx ts-prune` |
