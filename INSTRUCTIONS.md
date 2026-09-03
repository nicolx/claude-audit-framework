# claude-audit-framework

Instructions for Claude Code in any project that uses `claude-audit-framework` as a submodule.
This file is included via `@.claude/framework/INSTRUCTIONS.md` in the project's `CLAUDE.md`.

---

## Framework version check

The commands in `.claude/commands/` are **copies** taken from the submodule at install time, so
they go stale as soon as the submodule moves ahead. At the start of each session, compare the two:

```bash
cat .claude/.framework-version 2>/dev/null | grep '^version='; cat .claude/framework/VERSION 2>/dev/null
```

- **Versions match** — say nothing.
- **Versions differ** — flag once:
  > ⚠ Framework updated (`<installed>` → `<submodule>`) but the commands in `.claude/commands/` are still from the previous version. Run `bash .claude/framework/scripts/init-project.sh` to refresh them.
- **`.claude/.framework-version` missing** — the framework was installed before version tracking, or
  `init-project.sh` was never run. Flag once with the same command, then proceed normally.

Never refresh the copies yourself: `init-project.sh` is the only thing that should write into
`.claude/commands/`, and running it is the developer's call.

---

## Developer profile

If `~/.claude/context/user_profile.md` exists, read it in full before proposing any technical solution, architectural choice, or implementation strategy. Calibrate every response to the competency levels defined inside:

- **Fluente** — propose advanced patterns freely; skip basic explanations; use domain terms without glossing
- **Operativo** — use in proposals but explain non-obvious choices; avoid advanced patterns without rationale
- **Base** — prefer the simplest approach that still meets the standard; explain as you go
- **Base `*`** — a gap the developer intends to fill. Flag it explicitly, then build it together — the goal is to grow the competency in context, not to avoid it

### The standard sets the target, the profile sets the delivery

These two documents answer different questions, and they can look like they conflict. They do not,
and this rule is why.

**The quality standard fixes the target.** A competency level never lowers a criterion. If Category 9
requires structured logging with context, code written for a developer whose profile says
`Observability | Base *` still gets structured logging with context. "The developer is not fluent
here" is not a reason to ship a lower standard — it is the reason to explain what you are writing.

**The profile fixes the delivery.** It determines three things, and only these three:

1. **How much you explain** — from nothing (Fluente) to every non-obvious choice (Base)
2. **Whether you pair on it** — a `Base *` competency means stop, say so, and build it together
   rather than either working around it or silently handing over a finished result
3. **Which compliant option you choose** — when several approaches all meet the standard, prefer the
   one inside the developer's fluency. A `Base *` in Redis does not mean skipping the cache the
   standard requires; it means reaching for the framework's own cache abstraction over a hand-rolled
   Redis client, and walking through it

**Never do either of these:**

- Lower a criterion to match a level, or quietly omit something the standard requires because the
  developer would not have written it themselves
- Deliver work built on a `Base *` competency without flagging that it is there — even when it is
  correct. Silent correctness teaches nothing, and the `*` exists to be spent

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
2. Check for `.claude/PROJECT_AUDIT_FRAMEWORK.md` — if present, it extends the global framework; apply both
3. Score each subcategory with specific file/line evidence — no vague scores
4. Identify top 3 improvement opportunities by impact/effort ratio
5. Produce a category summary table with score, top gap, and recommended action
6. Re-score only after changes are implemented and verified — not for planned work

---

## Coding standards

Apply `.claude/framework/standards/CODING_STANDARDS.md` before every implementation decision. Every code proposal must reflect these standards — this is not optional and does not require an explicit request.

**Before writing code in any project, check:**

- Does `.claude/CODING_STANDARDS.md` exist? If not, flag it **once per session**:
  > ⚠ No project-level `.claude/CODING_STANDARDS.md` found. Stack-specific coding conventions are not defined. See `.claude/framework/templates/CODING_STANDARDS.md` for the format.
- Does `.claude/PROJECT_AUDIT_FRAMEWORK.md` exist? If not, flag it **once per session**:
  > ⚠ No project-level `.claude/PROJECT_AUDIT_FRAMEWORK.md` found. Quality evaluation will use only the global framework.

If `.claude/CODING_STANDARDS.md` or `.claude/PROJECT_AUDIT_FRAMEWORK.md` exist, they take precedence over the global framework where they conflict.

### Every criterion has a write-time counterpart

The 21 principles in `CODING_STANDARDS.md` are the write-time half of the framework; the 10
categories in `PROJECT_AUDIT_FRAMEWORK.md` are the measurement half. The traceability table at the
end of `CODING_STANDARDS.md` maps one to the other.

This matters when writing code that reaches a category the developer is not thinking about.
Security and observability are the usual cases: nobody asks for input validation or a structured log
line, and both are written, not discovered. Apply principles 15 and 16 to new code by default, the
same way you apply naming and SRP — waiting for an audit to reveal a missing log is waiting too long.

### Naming across languages

Code is English. Domain terms the English word would not name correctly stay in their original
language, and the **Domain language** section of `.claude/CODING_STANDARDS.md` declares which, in
which context. Read it before naming anything in a codebase that is not uniformly English.

**Establish which context you are in first.** The declaration is scoped, so the same concept can
correctly carry two names in one repository — `Invoice` in a generic payments core,
`FatturaElettronica` in an Italian billing module. Which one is right depends on where the file
lives, not on the word.

Then:

- **Declared for this context** → use it, in the exact spelling declared.
- **Declared for a different context** → you are at a boundary. Use this context's vocabulary and
  translate explicitly through a named mapper. Never import the other context's term across the
  seam; that is a boundary leak, and a worse problem than a naming slip.
- **Not declared, and translating loses nothing** → use English.
- **Not declared, and translating would lose legal or business precision** → say so and propose
  adding it to the section, with its context and the reason. Never use an undeclared term silently,
  and never translate a term that should not be translated.
- **Existing code disagrees with the section** → match the section for new code and mention the
  inconsistency rather than propagating it. Renaming existing identifiers is a separate change, and
  the developer's call.

Two failure modes to avoid actively, because both look like tidying: do not "harmonise" two names
that belong to two contexts, and do not invent a compound the domain does not use
(*FatturaElettronica* is the document, *FatturazioneElettronica* is the process — a module may be
named for the process, an entity may not).

### Active audit focus

If `.claude/audit-focus.md` exists, **read it before writing code**. It is generated by
`/project-audit` and names the criteria this project currently scores worst on, each with a concrete
rule to apply when touching related code. It does not replace the standards — it raises priority on
a subset of them, and it points at real weaknesses measured in this codebase rather than generic
ones.

Never edit it by hand: the next audit overwrites it. If a rule in it looks wrong, that is a finding
about the audit, so say so rather than quietly ignoring the file.

**Freshness.** At the start of a session, check the newest file in `docs/audits/`. If the most
recent audit is more than three months old, flag it once:

> 📋 Last quality audit was <date> — run `/project-audit` when convenient.

If `docs/audits/` does not exist, no audit has run yet. Mention it once, then proceed — do not
invent a focus list from your own reading of the code.

---

## Large project analysis protocol

These rules apply to **exploratory and general analysis**.

> **`/project-audit` applies these rules too.** It reaches full coverage by fanning out — ten
> category agents, each reading only the files its category needs, coordinated through a shared
> evidence bundle and a source manifest. Follow the command's own phases rather than reading the
> tree yourself: the orchestrator never loads the project source into its own context.

### Prerequisite — verify `.claudeignore` before any analysis

Do not begin any analysis on a project until a `.claudeignore` exists at its root. Without it, traversals include dependency trees (`vendor/`, `node_modules/`), build artefacts, caches, and logs. If missing, create it or ask the user before proceeding.

Minimum contents for a web/backend project:

```text
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
