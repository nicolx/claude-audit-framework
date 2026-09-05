# claude-audit-framework

Instructions for Claude Code in any project that uses `claude-audit-framework` as a submodule.
This file is included via `@.claude/framework/INSTRUCTIONS.md` in the project's `CLAUDE.md`.

---

## Session start — one notice, not seven

Several sections below describe a condition worth raising when a session opens: a stale command
copy, an upstream release, a missing developer profile, a competency review due, absent
specialization files, no `.claudeignore`, an audit older than three months. Each is individually
reasonable. Together they would greet a freshly installed project with five warning blocks before
answering its first question.

So treat them as inputs, not as outputs. Collect whatever applies, then:

- **Emit at most one block**, never a sequence of separate warnings.
- **Three lines maximum**, most consequential first — something that stops the framework working at
  all outranks something merely not set up yet. If more than three apply, give the top two and add
  `(+N more — run bash .claude/framework/scripts/check-install.sh)`.
- **Once per session.** Never repeat it, and never re-run these checks later in the same session.
- **Nothing applies → say nothing.** No "everything looks fine" line.
- **The developer's question comes first.** If they opened with a task, do the task and put the
  notice after it. A setup notice is never worth delaying an answer.

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

The version marker is one signal among several. `bash .claude/framework/scripts/check-install.sh` is
the full read-only answer — the `@`-include, the command copies compared byte for byte, the
specialization files, hook coherence — and it names the fix for each failure. Suggest it whenever an
install looks wrong.

### Upgrading the framework in this project

**Updating the submodule is not enough.** The `@`-include in `CLAUDE.md` and the command copies in
`.claude/commands/` live outside it; a submodule bumped without them is a framework that is present
and loads nothing at all. If asked to upgrade, run all four steps in this order:

```bash
bash .claude/framework/scripts/check-updates.sh    # what is new, and which releases broke things
cd .claude/framework && git fetch --tags && git checkout <tag> && cd ../..
bash .claude/framework/scripts/init-project.sh     # migrates the @-include, refreshes the copies
bash .claude/framework/scripts/check-install.sh    # verify — do not skip, this is the whole point
```

Then report what `check-install.sh` said, including its warnings, and leave the commit to the
developer. There is no version-by-version path to walk: `init-project.sh` is idempotent and migrates
from any earlier state, so any old version goes straight to the newest.

If `check-install.sh` reports breaking changes between the recorded install and the new version,
read those `CHANGELOG.md` entries and say what they require — `init-project.sh` handles what can be
automated, and what it names is what cannot.

The rationale for all of this is in `.claude/framework/README.md` § *Upgrading an existing install*;
these four lines are the part you need to get right.

### Upstream drift

The check above compares the copied commands against the **pinned** submodule. It cannot tell you
that upstream has released since — a project pinned at `v1.0.0` looks perfectly consistent while
four releases have shipped. That is subcriteria 6.9 applied to this framework itself.

**Use only local information.** Never run `git fetch` to find out; a session start is not the place
for a network call, and the developer did not ask for one. From refs already present:

```bash
git -C .claude/framework describe --tags --exact-match HEAD 2>/dev/null; git -C .claude/framework tag -l 'v*' | sort -V | tail -1
```

- **Pinned at the newest tag you can see, or no tags fetched** — say nothing.
- **A newer tag is present locally, or HEAD is not at any tag** — flag once:
  > ℹ Framework pinned at `<current>`, and `<newer>` exists locally. Run `bash .claude/framework/scripts/check-updates.sh` to see what changed.

`check-updates.sh` is the deliberate version of this check: it fetches, reports both kinds of drift,
lists the releases in between with their commit subjects, and prints the upgrade commands. Suggest
it; do not run it unprompted, because it contacts the remote.

---

## Developer profile

If `~/.claude/context/user_profile.md` exists, read it in full before proposing any technical solution, architectural choice, or implementation strategy. Most of it is competency levels, which calibrate how a proposal is delivered; one section — **User-facing language** — is not a level at all, and is covered separately below.

Calibrate every response to the competency levels defined inside:

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

### The one field that is not a competency level

The profile's **User-facing language** section records the developer's primary natural language. It has exactly one use: seeding the required locale set a project declares for subcriteria 2.10. Its own disclaimer, written into the profile, is the authority — this file only points at it, because the profile is global and is read in projects where this framework is not installed.

It does **not** change the language of anything you write. Code, identifiers, comments, commit messages, documents and replies are unaffected — those follow principle 20 and the conversation. It is not a conversation-language preference.

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
| 2 | Clean Code | Yes (2.9–2.10 unless the project writes no text for anyone using it) |
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

The 22 principles in `CODING_STANDARDS.md` are the write-time half of the framework; the 10
categories in `PROJECT_AUDIT_FRAMEWORK.md` are the measurement half. The traceability table at the
end of `CODING_STANDARDS.md` maps one to the other.

This matters when writing code that reaches a category the developer is not thinking about.
Security and observability are the usual cases: nobody asks for input validation or a structured log
line, and both are written, not discovered. Apply principles 15 and 16 to new code by default, the
same way you apply naming and SRP — waiting for an audit to reveal a missing log is waiting too long.

### Keeping the instruction files true

`CLAUDE.md` and the files in `.claude/` are loaded into every session and applied as fact. Nobody
reads them end to end, so when they stop describing the system, nothing surfaces it — the drift just
shapes every later proposal. Principle 22 puts the fix in the change that caused it; these are the
two situations where that lands on you.

**A change you make invalidates an instruction file.** Update it in the same change. If you raise
the analyser level, move a directory, rename the quality gate command, or add a layer rule, the file
that names the old one names the new one before you are done. Say what you updated — do not do it
silently, because the developer needs to know their instructions moved.

**You find an instruction file contradicting the code.** Say so; it is a finding. Then stop, because
a contradiction has two readings and they lead to opposite actions:

- The document is **stale** — the code moved, the file was not updated. The fix is in the document.
- The document is **aspirational** — it records what the project has decided to reach, and the
  config has not caught up. The fix is in the config.

`.claude/CODING_STANDARDS.md` naming PHPStan level 8 while `phpstan.neon` says 6 is exactly this
ambiguity. Do not pick a reading and act on it: the two fixes change different files and one of them
would quietly undo a decision. Name the contradiction, name both readings, and ask which it is.

Meanwhile, follow the code for what *is* true. Never apply a stale instruction just because it is
written down.

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

### User-facing text

Naming is one half of the language question; the text the product shows its users is the other, and it has its own rule. Before writing a string a person will read — a label, a PDF heading, an email body, a line of CLI output, a validation message that reaches a screen — find the project's translation catalog and put the string there, in the same change. Never inline it, not even provisionally.

The **User-facing text** section of `.claude/CODING_STANDARDS.md` names the mechanism, where the catalogs live, and which locales the project has committed to serving. Then:

- **The project declares a locale set** → the change is not finished until the new keys exist in every catalog in it, not only the English one.
- **No such section exists** → say so once, propose it, and use the mechanism the framework already provides rather than inventing one. Subcriteria 2.9 and 2.10 both start from that section.
- **The declared set omits your own working language** → say so once and propose adding it, with the reason. Never add a locale to the set yourself, and never treat an undeclared locale as required.
- **Existing code hardcodes its strings** → put new text through the catalog and mention the inconsistency. Retrofitting the existing strings is a separate change, and the developer's call.

Author the text in English: it is the source and the fallback, so a locale missing a key still renders something readable. Terms declared in the **Domain language** section stay whole inside the text — the English catalog says `FatturaElettronica`.

### Database access

Some projects declare a database for query analysis, in the **Database access for query analysis**
section of `.claude/PROJECT_AUDIT_FRAMEWORK.md`. It exists so that subcriteria 7.9 and 9.8 can be
answered from reality rather than from configuration. Treat it as narrowly as it was granted.

**What it is for:** schema and index inventory, `EXPLAIN` on a query whose plan is in question, row
counts and table sizes, and the statement statistics the engine already aggregates
(`pg_stat_statements`, `performance_schema`, the slow query log).

**Rules, all of them hard:**

- **Never read application data.** Query analysis needs statistics, not rows. If you catch yourself
  writing `SELECT` against an application table to "see what the data looks like", stop — use
  `COUNT(*)`, `information_schema`, or the planner's own statistics instead.
- **`EXPLAIN`, not `EXPLAIN ANALYZE`**, unless the statement is a plain `SELECT` *and* the target is
  not production. `EXPLAIN ANALYZE` executes the statement.
- **Nothing that writes.** No `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `ALTER`, `VACUUM`, `ANALYZE`,
  no session settings. Not even to test whether the grant would refuse — if it would not, that is a
  finding to report, not a permission to use.
- **Never put row data in the audit evidence bundle.** It lands in a scratch file and in ten agents'
  context. Schema, counts and plans only.
- **Never print, echo or log the connection string or its credentials**, in output, in a report, or
  in a committed file. Read it from the environment the declaration names.
- **Ask before anything outside this list.** Widening the scope of database access is the user's
  call, in the moment, every time.

**If the section is absent,** do not go looking for credentials in `.env` files, config, or the
history. Score 7.9 and 9.8 from configuration, say so, and mention once that declaring a database
would let those two be verified.

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
