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

If the field is **absent**, the profile predates it. Treat that as a review due and flag the same line — `/competency-review` renames the row as it writes. Never infer anything else from a missing field: **a profile file that exists is never a reason to suggest `/init-profile`**, in whatever shape its contents are. That command builds a profile from scratch, the file is per machine rather than per project, and a developer opening a newly installed project already has theirs.

### The one field that is not a competency level

The profile's **User-facing language** section records the developer's primary natural language. It has two uses.

**It is the language of the conversation.** Everything addressed to the developer in the session is written in it — replies, questions, progress lines, plans, the reports a command prints, and every notice this framework quotes in English (the `⚠` and `💡` lines included): render them in that language and keep paths, commands, block names and identifiers verbatim. English is never the default because the tools are in English. The developer asking in the session for another language overrides it for that session; with no profile, or no such section, reply in the language the developer writes in.

**It seeds the required locale set** a project declares for subcriteria 2.10.

**If the profile exists without the section**, it predates it. Ask once, at the start of the session, in the language the developer writes in: *what natural language do you work in day to day, and which others do you read fluently?* Then propose writing the section with the block and disclaimer exactly as `/init-profile` gives them, and write it only when they confirm. Until they answer, reply in the language they write in.

It does **not** change the language of anything written into the repository. Code, identifiers, comments, commit messages and documents follow principle 20, whatever language the conversation is in.

**If the file does NOT exist:** mention it once at the start of the session — `> 💡 No developer profile found. Run /init-profile to enable skill-level calibration.` — then proceed normally without repeating it.

---

## Enterprise Quality Standard

An 11-category quality framework is active in this project, numbered 0 to 10.

**Full document:** `.claude/framework/standards/PROJECT_AUDIT_FRAMEWORK.md`

Read it before conducting any quality evaluation or scoring. Do not score from memory alone.

### The 11 categories

Category 0 is the frame the rest are scored inside: it asks what the project says it is building and
how much of that exists. Read it and score it first — whether a gap in Categories 1–10 is a defect or
simply unbuilt work is a question only the product documentation answers.

| # | Category | Always evaluated? |
|---|---|---|
| 0 | Product Strategy & Delivery Documentation | Yes |
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
4. Identify top 3 improvement opportunities by impact/effort ratio, ranked within the project's current remediation band and phase
5. Produce a category summary table with score, top gap, and recommended action
6. Re-score only after changes are implemented and verified — not for planned work

### Closing a gap is a sequenced job, not a free choice

The order in which scores are improved is part of the framework, not left to whoever picks up the
work. Recorded intent and a working safety net come before any change to code that already exists:
refactoring, renaming into the declared domain language, restructuring a layer, or replacing a
framework are all spending something Categories 0, 4, 7 and 10 have to earn first.

The phases, what each one gates, and what clears a gate are in the **Remediation order** section of
`.claude/framework/standards/PROJECT_AUDIT_FRAMEWORK.md`. Read it before proposing or starting
quality work, including when the request arrives outside an audit — *"let's clean this file up"* is
Phase 3 work and is subject to the same gate as the version of it that came from a report.

The order has a second half, and it is the one a team is likelier to get wrong on its own: **how far
to take a category before starting the next.** A project raises its floor, not its best number.
Every scored category reaches the target of the band the project is on — 4, 6, 7, 8, read as rungs —
before any category is taken past it, so a quarter that moves CI/CD from 1 to 9 while design
patterns sit at 2 is not progress however much it improves the average. The same section states the
rule, what it does and does not forbid, and why the floor and the spread are the numbers to steer by
when the average will happily endorse the opposite.

Two things neither half gates, because both are routinely misread: new code is written to the full
standard in every phase and at every band, and every category is scored at its real value in every
phase and at every band.

And the order governs *which* gap and *when*, never the shape of the change that closes it. A phase
is a direction, not a commit: remediation is delivered in the steps of principle 24 like any other
work, and gets no exemption for being quality work — it is the work that needs the rule most, because
it changes code that already runs. The same section states it, under *How remediation work is
delivered*.

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

The 27 principles in `CODING_STANDARDS.md` are the write-time half of the framework; the 11
categories in `PROJECT_AUDIT_FRAMEWORK.md` are the measurement half. The traceability table at the
end of `CODING_STANDARDS.md` maps one to the other.

This matters when writing code that reaches a category the developer is not thinking about.
Security and observability are the usual cases: nobody asks for input validation or a structured log
line, and both are written, not discovered. Apply principles 15 and 16 to new code by default, the
same way you apply naming and SRP — waiting for an audit to reveal a missing log is waiting too long.

### Every change ends with two checks

Before a change is done, read its diff twice:

- **The code speaks for itself** — principle 1. A comment you added is a contract or a present-tense
  constraint, or it goes. What you did, why you changed it, what it replaced and which session
  produced it go in the commit body (principle 19), never in the code.
- **The documents are still true** — principle 22. If the change made a README, `CLAUDE.md` or
  `.claude/*` statement false, it corrects it in the same change. If nothing it says became false,
  nothing is written: a README is updated when it is wrong, not to log the work.

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

### Product documentation and delivery status

Principle 23 governs this and defines the vocabulary; what follows is where it lands in a session.

**Before implementing anything larger than a fix**, look for the document that already describes it —
the product documentation home, usually `docs/`, laid out per Category 0. If one exists it is the
specification: read it before proposing an approach, and if what you are about to build contradicts
it, say so rather than routing around it. A spec and an implementation that disagree is a finding
with two possible fixes, exactly like the stale-or-aspirational ambiguity above, and the developer
picks which.

**When you finish**, move that document's status marker in the same change as the code — and say you
moved it. A marker nobody maintains is a claim the team acts on and is wrong about; leaving it for
later is how it stops being true.

**If the project has no documentation home at all**, flag it **once**, at the first substantial piece
of work rather than at session start — a warning fired before there is anything to document is noise:

> ⚠ No product documentation home found (`docs/` or equivalent). Implementation specs and their
> status markers are what Category 0 scores, and what tells the next session which work already
> exists. See Category 0 in `.claude/framework/standards/PROJECT_AUDIT_FRAMEWORK.md`.

Then carry on. Do not scaffold a documentation tree unasked — the layout is the team's decision, and
an empty `docs/` created by an agent is a worse signal than no `docs/` at all.

### Before the first line: the step list is the deliverable

Principle 24 governs this; what follows is where it lands in a session.

Anything larger than a fix is proposed as an ordered list of steps before any of it is written, and
each step names the change it makes, the test that proves it, and the state the system is released
in once it lands. Get agreement on the list first, in its own exchange.

A request that names an end state — *"rewrite the importer"*, *"migrate everything to the new
client"* — names a destination, not a step. Answer with the route, and say which step is first: the
smallest change that settles the assumption most likely to be wrong, not the easiest file on the
list. Never read agreement on a destination as agreement to reach it in one pass.

Then hold the sequence. A stated plan collapsed into a single change because it looked small from
inside is the failure this principle exists to prevent, and it is not visible to the developer until
the diff arrives. If they ask for the single cutover anyway, having seen the sequence, that is their
call — build it, and say which part of it nobody can verify until the end.

### Delivering it: the convention is the authorization

Principle 25 governs this; what follows is where it lands in a session.

Read the **Delivery convention** block of `.claude/PROJECT_AUDIT_FRAMEWORK.md` before the first
commit of the session. It states what a finished change carries in this project and which of commit,
push, branch, pull request and tag a session may perform unattended, onto which refs.

**Inside it, act.** Commit at the step boundaries of principle 24, push where it permits, open the
pull request where it permits, and report each action in one line — the commit, the ref, the pull
request. Do not ask for a permission the declaration already granted; that friction is what the team
removed by writing the block.

**Outside it, stop at the last permitted action** and say what remains, naming the command the
developer would run. Never infer an adjacent permission — commit does not imply push, a feature
branch does not imply `main`, and neither implies a tag or a release.

**Release artifacts ride with the change**, never behind it: the version bump, the changelog entry,
and the install or upgrade instructions that name a version, in the same commit as whatever made them
wrong. This is principle 22 applied to the artifacts of a release.

**If the block is absent**, flag it once per session, at the first moment there is something worth
committing — not at session start:

> ⚠ No **Delivery convention** declared in `.claude/PROJECT_AUDIT_FRAMEWORK.md`. I will commit and
> push this branch to its upstream without force, and ask before anything else. The block is scored
> by 10.15 and its shape is in `.claude/framework/templates/PROJECT_AUDIT_FRAMEWORK.md`.

Then carry on within the default principle 25 states — commit and a non-force push of the
checked-out branch, nothing further.

### After it lands: removing what the change left behind

Principle 27 governs this; what follows is where it lands in a session.

The session that made the change is the one that still knows which files were residue and which
were the work. Before reporting it done, remove what this change created and no longer needs — the
scratch file, the fixture copied in to reproduce a bug, the one-off script, anything provisioned to
make the change work (a scratch bucket, a throwaway environment, a token issued for one migration)
— and, where the delivery convention permits that ref, the branch once it is merged. Never a branch whose commits are not in
the mainline, whatever its date says, and never a tag.

**Finding yourself tidying by hand is itself the finding.** If the merge did not delete the branch,
the host's auto-delete setting is off. If `git fetch` prints refs for branches that no longer exist,
`fetch.prune` was never configured. If a full build leaves `git status` dirty, an ignore rule is
missing. Say so once, naming the one-time setting that removes the step — doing the same manual
cleanup a second time is the session accepting a job that should not have needed a person. The
repository's side of this is scored by 10.16.

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

### Production access

Some projects open a path to the running system, in the **Production access** section of
`.claude/PROJECT_AUDIT_FRAMEWORK.md`. It exists so that a question about production can be answered
from production — logs, metrics, health, error tracking — instead of from a pasted excerpt. The
section is also the boundary: it is the list of what may be used, not an example of it.

**Rules, all of them hard:**

- **Only the paths the section declares.** A credential that happens to work, an SSH host found in a
  deploy script, a dashboard URL in the README — none of those are grants. If it is not in the
  section, it is not available, and finding it is a 9.9 finding to report rather than a door to use.
- **Read-only unless the section names the action.** Reading logs, metrics, health and error reports
  is the default. A mutating action — restart, rollback, migration, purge, scaling, anything that
  writes — must be named in the section *and* approved in the moment, every single time. "It is
  allow-listed" is not approval; it is permission to ask.
- **Say what you are about to run, before you run it**, naming the host or service it will touch.
- **Never widen the grant to get an answer.** No shelling into a host whose declared path is a
  command, no reading a file the command does not expose, no second hop from the host you reached.
- **Never print, echo or log a credential or a connection string** — in output, in a report, or in a
  committed file. Read them from the environment the declaration names.
- **Production data stays out of the repository and out of the evidence bundle.** Log lines carry
  customer identifiers, tokens and payloads. Quote the minimum a finding needs, redacted, and never
  paste a raw excerpt into a committed file.
- **Report what the access told you, including when it contradicts the declaration.** A host that
  does not answer, a dashboard that has been empty for months, a token with more rights than the
  section claims — each is a finding about 9.9, and more useful than the diagnosis you were after.

**If the section is absent,** do not go looking for a way in — not in `.env`, not in deploy scripts,
not in the shell history. Work from the code, say that production was not reachable, and mention once
that declaring a path would let 9.9 be scored above its human-only ceiling.

### Team census

The **Team census** block of `.claude/PROJECT_AUDIT_FRAMEWORK.md` records who writes, who reviews,
who releases, and who consumes a version of this project. It exists for one reason: four of Category
10's subcriteria measure practices that protect people from each other, and the proportionality rule
at the top of that category uses the census to decide which of them are in play. `/team-census`
writes it; precondition 5 of the standard states what it must answer.

Never substitute the developer profile for it. `~/.claude/context/user_profile.md` describes one
person's competencies on one machine and says nothing about who else commits here.

**If the block is absent**, read the shape from the git history when a question needs it, and say
that is where it came from. Do not raise it at session start — `check-install.sh` already lists the
declarations a project is missing, and a census is not needed until something is being scored.

**If the history contradicts it** — a contributor the census does not name, or a named contributor
whose last commit is a year old — say so once, as a finding. Do not update the block in passing: it
is a declaration, and `/team-census` is how it changes.

### Explaining what the product does

`/product-tour` is reached by intent, not by name. When the developer asks for something that would
be a document, a deck or a recording of **what the software does** — a manual, onboarding material
for a new colleague, slides for a client or a manager, a demo, a video, *"help me explain this to
the stakeholders"* — invoke it, scoped to the request as its *Arguments* section describes. Say in
one line that you are using it; do not ask whether to.

It is not for a question answered in the conversation. *"What does this endpoint do?"* gets an
answer, not a manual. Offer it once when the answer turns out to be the product's whole surface, or
when the developer says it is for someone else to read.

Never write a manual, a deck or a demo script for this project outside it. A description of the
product composed from memory of the conversation has no inventory beneath it, which is the failure
the command exists to prevent.

### Implementing the spec backlog

`/drain-backlog` is reached by intent, like `/product-tour`. When the developer asks to build the
pending specs, work through the backlog, or implement what was dropped in the inbox, invoke it and
say so in one line. A request to build one named spec, or anything asked for in the conversation, is
ordinary work for this session — the drain is a second route, never a replacement for the first.

Only the drain reads the **Backlog drain** block, and only the drain dispatches `implementer`. A
session working from the conversation still agrees its step list with the developer first, whatever
the block grants: principle 24's standing agreement covers specs that went through review before
they arrived, which a request in the chat has not.

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

## Which agent, and when

This project installs agents in `.claude/agents/`. Each is a subagent with its own mandate, its own
tool grant, and its own isolated context. What each one does is in its own file — read it there,
not here. This section answers the only question the files cannot: which one, and when.

**The default is none.** Ordinary work — answering a question, writing a function, reading a file —
is done by this session. An agent costs a second context reading real files, so routing to one is a
decision, not a reflex.

The table is in the order a change meets them, not in order of importance:

| Agent | Route to it when | It returns |
|---|---|---|
| `architect` | Before writing anything larger than a fix — a feature, a migration, a new integration, a restructure. A request that names an end state (*rewrite the importer*, *move everything to the new client*) names a destination, and this is what produces the route | The five evolution questions answered, two routes with the cheaper one first and a recommendation, and the ordered step list of principle 24 — plus a drafted ADR when the decision is expensive to reverse |
| `scalability-devops` | A change touches data access, a queue, a cache, an external call, or anything else that runs in production under load | Per dimension — rows, requests, concurrency, payload, fan-out, retention — what breaks first and at roughly what multiple |
| `security-reviewer` | A change touches the attack surface — a new input or endpoint, authentication, authorisation, sessions, an upload, a secret, a header policy, a new dependency | Ranked findings with file, line, the attack, and the ASVS requirement by versioned identifier — an L1 gap exploitable on its own first |
| `pr-critic` | A change is finished and somebody is about to merge it: *review this*, *look over the diff*, a pull request number | Ranked findings with file, line, rule, and whether each was traced or suspected |
| `hotfix` | **Never by routing** — only when the developer invokes it by name. See below | The diff, the test, the delivery actions taken, and one line naming what the lane skipped |
| `implementer` | **Never by routing** — only `/drain-backlog` dispatches it, with a spec and an approved plan | One commit per step with its test, the spec's status per requirement, and where it stopped if it fell out of the plan |

Two of them on one piece of work is normal when they meet it at different moments — `architect`
before it is written, `pr-critic` after — or when they ask it different questions: `pr-critic`,
`security-reviewer` and `scalability-devops` on the same finished diff are three lenses — the first
on every diff, the other two only when it touches what they look at. Two asking the same question is the
duplication the last rule below forbids. When their findings land on the same line, report it once,
under the lens that names the attack or the breaking point.

### The fast lane is taken, never assigned

`hotfix` skips the design pass, the ADR and the step-list exchange. That is what it is for, and it
is why **this session never routes to it.** A lane that an agent can assign to itself is the lane
every change ends up in, each time for a reason that looked good at the time, and nothing in the
history afterwards distinguishes the changes that were small from the changes that were called
small.

So: the developer invokes it, by name, having decided. If a task looks like fast-lane work and they
have not asked for it, do the work the ordinary way — or say in one line that `hotfix` exists, and
let them choose. Never suggest it as a way around a review somebody is waiting on.

Two things it does not skip, and a session should not expect it to. It **refuses to start** unless
`.claude/PROJECT_AUDIT_FRAMEWORK.md` declares a **Fast-lane gate** — an absent gate is not an open
one, and the block is read by 10.15 as well, which scores a departure inside a declared gate as
conformance and one with no gate as a breach. And it holds the floor the gate's *Carries anyway* line names, which always includes the
regression test of principle 26 and the project's Delivery convention in full. Fast means less
ceremony, never less change.

**Say which one you picked, in one line, before it runs.** A session that silently delegates has
moved the work somewhere the developer cannot see it, and the answer that comes back reads as yours.

### What routing never does

**An agent is a lens, not a permission upgrade.** Nothing an agent does exceeds what this project
has already declared. The **Database access**, **Production access** and **Delivery convention**
blocks of `.claude/PROJECT_AUDIT_FRAMEWORK.md` bound every session in this project, and a subagent
is a session. Routing to one is never the way a grant gets widened, and an agent that reports it
could not reach something is giving you a finding, not asking for a credential.

**An agent does not decide.** It returns evidence, or a plan, or a list. What happens next — merge,
change the approach, accept the risk — is the developer's, and this session's to carry out. Never
report an agent's output as a verdict, and never act on one without saying what it said.

**An agent is not a second opinion on a question you can answer.** Two agents on the same work, or
an agent dispatched to confirm something already established, buys nothing and costs two contexts.

### When the project disagrees

An agent file is a copy, like a command: `init-project.sh` overwrites it on every run. If one of
them is wrong for this project, that is a finding about the framework — say so. Editing the copy
produces an agent that works until the next upgrade and then silently reverts, and
`check-install.sh` reports it as drift in the meantime. A project that wants its own agent adds one
under its own name in `.claude/agents/`, where nothing the framework does will touch it.

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
