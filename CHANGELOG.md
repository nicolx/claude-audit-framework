# Changelog

All notable changes to this framework are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Because consumer projects load this framework into every Claude Code session, a version bump is
about *their* sessions: **major** means they must change something in their own project,
**minor** adds criteria or commands, **patch** corrects and clarifies.

## [1.7.1] — 2026-09-03

### Fixed

- **`init-project.sh` still told people to upgrade with `git pull origin main`** — the pre-1.0 path,
  replaced by pinned tags in 1.0.0, and omitting `check-install.sh` entirely. It survived seven
  releases in the installer's own closing output: the one place every new install reads. This is
  principle 22 failing inside the release that introduced 7.10 — the model changed and the text
  describing it did not.
- `git pull origin main` is now in `check-consistency.sh`'s retired-pattern list, so the
  contradiction cannot reappear. Its failure message no longer assumes the only retired things are
  the two old filenames.

### Added

- **The upgrade procedure now reaches Claude, not only human readers.** The README carried the four
  steps from 1.7.0, but the framework's README is never `@`-included — a consumer session loads only
  `INSTRUCTIONS.md`, where the three scripts were mentioned in three separate places with no ordered
  sequence. Asked to upgrade, Claude would have had to reconstruct the order and could plausibly
  have skipped the verification step. `INSTRUCTIONS.md` now carries the four commands in order, the
  invariant that makes them matter, and the instruction to report what the check said rather than
  declare success.

The split between the two documents is deliberate: `INSTRUCTIONS.md` gets the commands and the
order, the README keeps the rationale and the comparison table. Duplicating the reasoning in both
would be a second copy to drift — which is the defect this release exists to fix.

## [1.7.0] — 2026-09-03

Updating the submodule was never sufficient, and nothing said so. Two things live outside it — the
`@`-include in the project's `CLAUDE.md` and the command copies in `.claude/commands/` — so a
project could pull v1.6.0, commit the bump, and run a framework that loads nothing at all. The
1.0.0 `@`-include split made that failure mode concrete, and it was recoverable only by re-running
the installer, which mutates and therefore cannot be used to *check*.

### Added

- **`scripts/check-install.sh`** — read-only conformance of an install against the version it has
  checked out. Safe in CI, safe to run any time. It verifies the `@`-include is present and is not
  the pre-1.0 one, that the command copies are **byte-identical** to the version (a marker can be
  accurate while a file was hand-edited), the version marker, the specialization files, that a wired
  hook still has its script, `.claudeignore`, and the `git archive` exclusion. Every failure prints
  the command that fixes it. Exit 0 conformant, 1 errors, 2 cannot tell.
- **Breaking-change reporting.** When the recorded install version differs from the current one,
  `check-install.sh` names the releases in between whose changelog entry has a `### Breaking`
  section — so the entries that need reading are identified rather than hunted for.
- An "Upgrading an existing install" section in the README with the four-step sequence and a table
  of which script answers which question.

### Changed

- `init-project.sh` no longer carries its own verification block: it calls `check-install.sh` and
  reports its exit code. The conformance rules now exist in exactly one place, which is also the
  place a developer can run without changing anything.
- `check-updates.sh` recommends `check-install.sh` after an upgrade, closing the loop between
  "a newer version exists" and "the upgrade actually took".

### Why not a version-by-version upgrade path

`init-project.sh` is idempotent and migrates from any earlier state, so a stepped path would be
machinery for a problem that does not exist — you can go from any older version straight to the
newest. And the conformance rules ship *inside* each version rather than in a separate migration
matrix: checking out `v1.7.0` gets you `v1.7.0`'s checks, with no lookup table that could itself go
stale. Release notes were never the missing piece either; the CHANGELOG already had them. What was
missing was a way to verify, and a way to be told which entries apply to you.

### Why this is a script and not a slash command

The commands are copies in `.claude/commands/`. A `/framework-doctor` command would be one of the
stale copies it is meant to diagnose — it cannot be relied on to report that it is itself out of
date. Invoked by path from the submodule, the checker is always the version the submodule holds.

## [1.6.0] — 2026-09-03

Documentation currency was almost entirely uncovered: 10.15 scored ADRs, 2.5 scored self-documenting
*code*, and two incidental lines mentioned `CONTRIBUTING.md` and a hand-written CHANGELOG. Nothing
asked whether the README still works, whether an API contract matches the routes, or whether
*anything* notices when a document stops being true. `OpenAPI` did not appear in the document at all.

### Added

- **7.10 Documentation currency and drift detection.** Not how much is written — whether anything
  keeps it true. It sits in Category 7 because the criterion is about a mechanism, and a quality that
  relies only on remembering is the gap 7.7 already names. What counts is making the documentation's
  factual claims executable: paths that resolve, a README setup path that runs in CI, an API contract
  generated from the routes or held by a contract test, generated docs whose stale diff fails the
  build. Scoring anchor: **thin but true documentation with a check that keeps it true scores above
  extensive documentation with no mechanism.**
- **Principle 22 — Documentation is part of the change that invalidated it.** Narrower than "write
  documentation": you renamed the make target, so rename it in the README, in that commit. The only
  moment anyone reliably knows which documents a change has falsified is the moment they make it. It
  also asks for claims a machine can check — name the command rather than describing it.
- **Session behaviour for the AI-facing half** (`INSTRUCTIONS.md`): update an instruction file in the
  same change that invalidates it and say so; and when a file contradicts the code, stop rather than
  guess.

### Why the AI-facing half is called out separately

The two audiences fail differently, and the quieter one fails worse. A stale README is read by a
person who runs the wrong command, notices, and goes to look at the code — expensive, but
self-revealing. `CLAUDE.md` and `.claude/*` are loaded into every session and applied as fact by a
reader who never questions them and never reads them end to end. A `.claude/CODING_STANDARDS.md`
naming an analyser level the project has left, or a layer rule its config no longer enforces, shapes
every future proposal with nobody disagreeing. 7.10 therefore weights that half at least as heavily
as the human one.

### The ambiguity that must not be resolved silently

An instruction file contradicting the config has two readings with opposite fixes: the document is
**stale** (the code moved, fix the document) or **aspirational** (the project decided to reach this,
fix the config). `.claude/CODING_STANDARDS.md` naming PHPStan level 8 while `phpstan.neon` says 6 is
exactly that. Claude is now told to name the contradiction and both readings and ask — because
picking one would quietly undo a decision — while following the code for what is currently true.

## [1.5.0] — 2026-09-03

Dependency updates were covered unevenly: 7.4 scored whether dependencies are *vulnerable*, 6.7
flagged an end-of-life *framework*, 6.8 mentioned abandoned forks. Nothing asked whether the
dependencies are current, whether the runtime is supported, or whether an upgrade is still possible
at all. Submodules appeared nowhere in the document.

### Added

- **6.9 Dependency currency and upgrade path.** The measure is not "how new" but "how far, and is
  the road still open". Its most valuable question is which single dependency closes the road for
  all the others — a package pinning `php <8.2` blocks the runtime and through it every other
  upgrade, and that is a structural constraint rather than a ranking of staleness. Also covers the
  runtime, base image and database engine as dependencies with support windows, and submodules as
  dependencies no package manager watches: a pin is fine, a pin nobody can name is a dependency
  frozen by accident. Scoring weights the blocker and the EOL above ordinary staleness — being
  behind is a cost, being unable to move is a risk.
- **Principle 14 extended** to the write-time half: check that a dependency is still alive before
  adding it, not only that it fits. Release history, archived status, and what it constrains — a
  package that pins an old runtime does not just age, it freezes everything else.
- **`scripts/check-updates.sh`** — the real check, closing the framework's own instance of 6.9. The
  existing session-start check compared the copied commands against the *pinned* submodule, so a
  project sitting on `v1.0.0` looked perfectly consistent while four releases had shipped. The new
  script answers both levels, lists the releases in between with their commit subjects, prints the
  upgrade commands, and warns when the submodule follows a branch, is pinned to an untagged commit,
  or has uncommitted local edits that an upgrade would discard. Exit codes: 0 nothing to do, 1
  action recommended, 2 cannot tell.
- **A local-only session check** in `INSTRUCTIONS.md`: Claude compares the pin against tags already
  fetched and points at the script. It never runs `git fetch` on its own — a session start is not
  the place for a network call the developer did not ask for.

### Fixed

- `check-updates.sh` trusted `git -C <framework> rev-parse`, which walks up to a parent repository.
  With the framework copied rather than added as a submodule, every git query answered from the
  *project's* repo — so it would have compared the project's tags against the framework's version
  and produced confident nonsense. It now requires the repository found to be the framework's own.
  Caught by a new case in `test-install-cycle.sh`, whose sandbox reproduces exactly that layout.

## [1.4.0] — 2026-09-03

7.9 and 9.8 shipped in 1.3.0 with nothing to read. Configuration records what a project *intends*: a
migration declares an index, and whether that index exists in the database — and whether the planner
chooses it — are two further questions. Both criteria needed a way to be answered from reality, and a
rule for what happens when there is none.

### Added

- **Precondition 4 — database access must be declared, or its absence acknowledged.** With a
  representative database, 7.9 and 9.8 are answerable. Without one they are scored from intent, the
  evidence says so, and **neither may exceed 8**: an unverified claim is not comprehensive evidence.
  Recording the limit is the point — a score that hides it is worse than a lower score that explains
  itself.
- **A `Database access for query analysis` section in the project framework template** — the command
  to reach it, which environment, what volume, what the grant allows, and what is out of bounds. Or
  the explicit statement that none is available.
- **Phase 1.4 of `/project-audit`** captures index inventory, row counts, the engine's aggregated
  statement statistics, the slow-query settings actually in effect, and `EXPLAIN` plans for the query
  paths in question — only when declared, and never by hunting for credentials in `.env` files.
- **Usage rules in `INSTRUCTIONS.md`**, all hard: never read application data; `EXPLAIN` not
  `EXPLAIN ANALYZE` unless the statement is a plain `SELECT` against a non-production target; nothing
  that writes, not even to test whether the grant would refuse; never put row data in the evidence
  bundle, which ten agents read; never print the connection string; ask before anything outside the
  list.

### Note on scope of access

The access this needs is **narrower than read-only**, which is worth stating because "at least read
access" invites a wider grant than the job requires. Query analysis reads schema and statistics —
`information_schema`, index inventory, `EXPLAIN`, row counts, `pg_stat_statements` — and almost
nothing in 7.9 or 9.8 requires a single row of application data. So the grant should not permit
reading it, and the template's example grant does not.

The environment matters as much as the grant: a development database with two hundred rows produces
query plans that are worse than no evidence, because they look like evidence. Representative volume
is what makes a plan mean anything, and an anonymised replica gets there without handing an agent
production.

## [1.3.0] — 2026-09-03

Covers data-access cost, which the framework measured nowhere. A project could score 8/10 across all
ten categories while running an N+1 that issues 400 queries for one list, an unindexed `WHERE` on a
two-million-row table, and an unpaginated `findAll()` — with no slow query log to notice any of it.
The only prior mentions were incidental: N+1 as an argument *for* using a mature ORM (6.8), a
`latency_ms` field in a health-check example (9.3), and a 200ms fitness function named in passing
(10.9). None of them produced a finding.

### Added

- **7.9 Query analysis in the quality gate** — data-access defects are the one class that reading
  code does not reliably find, because the defect is not in any single line: an N+1 is a loop in one
  file and a lazily loaded association declared in another, each correct alone. What finds it is
  counting queries. The criterion asks for query-count assertions on the routes that matter, a
  lazy-load guard that raises in dev and test (`preventLazyLoading`, `nplusone`, `bullet`), indexes
  shipped in the change that needs them, and `EXPLAIN` run at realistic volume. It also rejects
  duration assertions on a developer machine: those measure the laptop, not the query plan.
- **9.8 Slow query visibility** — a query that was fast at ten thousand rows and takes four seconds
  at two million degraded in public while nobody measured. Requires a threshold tuned to the
  application rather than the engine's 10-second default, attribution to the request or job that
  issued the query, aggregation by query shape (one fingerprint at 4,000 executions is the finding,
  per-execution lines hide it), **p95 and p99 rather than the mean**, row counts alongside duration,
  and somebody actually reading it.
- **Principle 21 — Know the cost of your data access.** The write-time counterpart, mapped to 7.9
  and 9.8. Its rule is not "optimise early" but "be able to say how this query behaves at a hundred
  times the current row count": no query inside a loop, every collection read bounded, aggregation
  where the data is, and an index shipped in the change that introduces the query path.
- The audit's shared evidence bundle now includes database and ORM configuration — small files, and
  the only evidence 7.9 and 9.8 have.

### Note on shape

Performance is arguably a quality dimension in its own right, and this release deliberately does not
give it a category. Data-access defects are design defects, detectable by reading code and counting
queries, so they sit where the framework already puts detection (Cat 7) and visibility (Cat 9), with
a principle for the code shape — the same three-part structure used for security and observability.
The ten categories stay ten. Broader performance work (load behaviour, latency budgets, caching
strategy) remains uncovered, and would need its own category.

## [1.2.1] — 2026-09-03

### Fixed

- **2.8's declaration was repository-global, which authorised the leak it should catch.** The same
  concept legitimately carries different names in different bounded contexts: `Invoice` in a generic
  payments core, `FatturaElettronica` in a module implementing Italian e-invoicing law — there the
  English word names a superset. With a flat glossary, `FatturaElettronica` appearing in the payments
  core read as a declared exception rather than as a concept that crossed a boundary without being
  translated. The Domain language table now carries a **Context** column, a term is correct only
  inside its context, and 2.8 weights a boundary leak above a local naming slip: the first says the
  architecture is eroding, the second says someone was in a hurry.

### Changed

- **The test is now stated explicitly and scoped:** *in this context, does the English word name the
  same thing?* Yes → English; broader, narrower or different → keep the original term. It replaces
  the unfalsifiable "is this domain jargon", and being context-local is what makes two names for one
  concept correct rather than an inconsistency to unify.
- **Seams are named as where this actually breaks.** Half-translated identifiers
  (`getFatturaList()`, `ElectronicInvoiceFattura`) appear almost exclusively at context boundaries,
  where the translation was spread across renamed fields instead of living in a named mapper.
- **Not translating means keeping the domain's grammar.** *FatturaElettronica* is the document,
  *FatturazioneElettronica* the process: a module may be named for the process, an entity may not.
  A compound the domain does not use loses exactly what a translation would have lost.
- One term, one spelling: declaring `FatturaElettronica` rules out `fattura_elettronica` and
  `FattElettr` elsewhere. A glossary row with a meaning but no reason is called out as declaring
  nothing.
- `INSTRUCTIONS.md` now has Claude establish which context a file belongs to *before* consulting the
  glossary, and names the two failure modes that look like tidying: harmonising two names that belong
  to two contexts, and inventing a compound the domain does not use.

## [1.2.0] — 2026-09-03

Adds the language dimension the framework had no opinion on: code in English, domain terms in their
own language, and the exceptions declared rather than improvised.

### Added

- **Subcriteria 2.8 — Language of identifiers.** Code is written in English; domain terms whose
  meaning translation would destroy are kept in their original language and declared. Covers
  identifiers, comments, test names, developer-facing messages and technical documentation.
  Explicitly does *not* cover user-facing text, which belongs to the product's language and is an
  internationalisation concern. A uniformly English codebase with nothing to declare scores full
  marks with no glossary — the criterion measures consistency and intent, not paperwork.
- **Principle 20 — Code speaks English, the domain speaks its own language.** The write-time
  counterpart, mapped to 2.8 in the traceability table.
- **A `Domain language` section in the project `CODING_STANDARDS.md` template** — the declaration
  mechanism: one row per term kept in the local language, with the reason it is not translated. The
  template says to delete the section outright if the codebase is uniformly English.
- **Session behaviour for the cases the glossary does not settle** (`INSTRUCTIONS.md`): a needed term
  that is not declared gets proposed, never used silently and never translated when translation
  loses precision; existing code that disagrees with the glossary is matched for new code and
  flagged rather than propagated.
- An optional non-ASCII-identifier check in the hook stub — the one mechanically detectable part of
  2.8, since accented characters in identifiers are never intentional and break greps and tooling.

### Why both halves of the rule are needed

English-only would be simpler and wrong. A *Codice Fiscale* is not a tax code and a *Cedolino* is not
a payslip: these are legally defined artefacts, and translating them discards the precision the
domain depends on — the ubiquitous language of Category 3 outranks uniformity. Equally, a codebase
where `getUtenti()` sits beside `findOrders()` makes every reader guess which convention applies.
The declared list is what lets both rules hold at once, and 2.8 scores the glossary too: one that has
grown to cover every local word is an amnesty for not renaming, not a glossary.

## [1.1.1] — 2026-09-03

### Fixed

- The hook stub's `report()` helper tripped an unreachable-code warning, because every call site
  ships commented out. Rather than suppress it, the stub now exposes
  `bash .claude/hooks/on-file-edit.sh --selftest`, which exercises the reporting path and prints the
  envelope Claude Code reads context back from — so a developer can confirm the plumbing before
  wiring any real check, and the helper is genuinely reachable.
- CI installed shellcheck from apt, whose version drifts. Different versions report *different codes
  for the same finding* (0.11.0 says SC2329, older ones SC2317), so a run went red on findings that
  were green locally. The version is now pinned to 0.11.0, matching what the quality gate documents.
- `shellcheck` now also covers `templates/hooks/*.sh`; the shipped hook is shell code like any other.
- `check-consistency.sh` fails when the version the README tells people to pin is not the current
  one — the staleness this release had to fix by hand.

## [1.1.0] — 2026-09-03

Closes the gap between measuring quality and writing it. Before this release the framework had a
write-time layer covering 6 of its 10 audited categories, and an audit whose findings reached no
later session. Security and observability — the two categories where a rule while writing matters
most, because a vulnerability and a missing log are written rather than discovered — had no
write-time counterpart at all.

### Added

- **Six coding principles** covering the categories that had none: check what already exists (14),
  validate at the boundary (15), observability is part of the feature (16), test doubles at the
  boundary (17), a deprecation is a deadline (18), history is part of the deliverable (19).
- **A traceability table** in `CODING_STANDARDS.md` mapping every principle to the subcriteria that
  measure it, plus an explicit list of criteria that are audit-only by nature and why. It is the
  single cross-reference between the two halves of the framework, and `check-consistency.sh` now
  fails if it drifts from either document — a new principle without a mapping, or a cited
  subcriteria that does not exist.
- **`.claude/audit-focus.md`**, written by `/project-audit`: the 3–5 weakest criteria *that have a
  write-time principle behind them*, each with a concrete rule for code that touches them.
  `INSTRUCTIONS.md` has Claude read it before writing. Infrastructure gaps stay in the report as
  project work, since no rule can honour them mid-feature. Regenerated at each audit; removed on
  uninstall.
- **Audit freshness check** — Claude flags once when the newest report in `docs/audits/` is more
  than three months old.
- **`init-project.sh --with-hooks`** — an opt-in `PostToolUse` hook running fast per-file checks
  after each edit. Beyond formatting, a failing check reports back through
  `hookSpecificOutput.additionalContext`, so the error reaches Claude in the same turn instead of
  surfacing in CI. Ships as a stub with nothing enabled; never modifies an existing
  `.claude/settings.json`, printing the snippet to merge instead. Four new cases in
  `test-install-cycle.sh` cover opt-in, wiring, non-clobbering and cleanup.

### Changed

- **The precedence rule between the quality standard and the developer profile is now explicit:**
  the standard fixes the target, the profile fixes the delivery. A competency level decides how much
  is explained, whether the work is done jointly, and which of several compliant options is chosen —
  it never lowers a criterion. Previously the two documents could be read as contradicting each
  other: a profile entry of `Base` said "avoid as a primary technology" while the audit demanded
  7/10 in that category, and nothing said which won.
- `Base` in the profile template no longer reads "avoid as a primary technology"; it reads "prefer
  the simplest approach that still meets the standard, and explain as you go". `Base *` now
  forbids silently handing over correct work as well as working around the gap — silent correctness
  teaches nothing.
- `INSTRUCTIONS.md` no longer exempts `/project-audit` from the block-reading protocol; since 1.0.0
  the command reaches coverage by fanning out, not by reading the whole tree.
- `uninstall.sh` keeps `docs/audits/` and says so — the quality history belongs to the project, not
  to the framework.

## [1.0.0] — 2026-09-03

First versioned release. Consolidates the framework after two migrations — global install →
git submodule, and symlinked commands → copied commands — each of which left inconsistencies
behind.

### Breaking

- **The `@`-include target moved.** Consumer projects must include
  `@.claude/framework/INSTRUCTIONS.md` instead of `@.claude/framework/CLAUDE.md`.
  `CLAUDE.md` in this repo is now the framework's own development file and must not be loaded
  into a consumer session.
  **Migration:** run `bash .claude/framework/scripts/init-project.sh` — it rewrites the line in
  place. No manual edit needed. An un-migrated project still works: the new `CLAUDE.md` opens with
  a guard that detects the situation and redirects Claude to `INSTRUCTIONS.md`.

### Added

- `VERSION` and this changelog; releases are now tagged, so a project can pin a version instead of
  tracking `main`.
- `.claude/.framework-version`, written by `init-project.sh`. Because commands are *copied* into
  `.claude/commands/`, they go stale when the submodule moves ahead; Claude now compares the marker
  against `VERSION` and flags the drift once per session.
- `scripts/check-consistency.sh` — the framework's own quality gate. Fails on retired names, false
  symlink claims, non-portable `sed -i`, broken path references, an `@`-include target that
  disagrees with what `init-project.sh` installs, and a `VERSION`/`CHANGELOG` mismatch.
- `scripts/test-install-cycle.sh` — exercises install, re-install, pre-1.0 migration and uninstall
  against throwaway projects. It is what caught the `sed` alternation bug below, which no amount of
  reading would have: BSD sed silently does nothing rather than reporting an error.
- CI (`.github/workflows/ci.yml`): shellcheck, markdownlint, the consistency check, and the
  install/uninstall cycle on every push — the last one runs on Linux, where the `sed` differences bite.
- `.claudeignore` — the framework now satisfies the precondition it imposes on the projects it audits.
- `/project-audit` writes a dated report to `docs/audits/` and maintains `docs/audits/history.md`,
  so score movement between audits is visible instead of being lost with the chat.

### Changed

- **`/project-audit` execution model.** The 10 scoring agents are now native subagents launched in a
  single message, and the evidence is sliced: a small shared `common.md` plus a *manifest* of source
  files, which each agent reads from selectively. Previously the entire project source was inlined
  into 10 separate `claude -p` invocations, so a project's code was paid for ten times over.
- `/project-audit` gained the frontmatter (`description`, `allowed-tools`) the other two commands
  already had, and writes intermediates to the session scratchpad rather than `/tmp`.
- Project-level specialization files are documented where they actually live — `.claude/` — instead
  of the project root, in both `standards/` documents.
- The specialization format is no longer inlined in `standards/PROJECT_AUDIT_FRAMEWORK.md`; it
  points at `templates/PROJECT_AUDIT_FRAMEWORK.md`, so the two cannot drift apart again.
- `README.md` describes copied commands (not symlinks), states that re-running `init-project.sh`
  after an update is required, and documents versioning and removal.

### Fixed

- Dead references to `~/.claude/CLAUDE.md` and `~/.claude/standards/CODE_QUALITY_STANDARDS.md` in
  the evaluation preconditions — paths from the pre-submodule layout that no longer existed.
- `uninstall.sh` used `sed -i ''`, which fails on GNU sed (Linux, CI). Replaced with a portable
  temp-file helper using `sed -E` — BSD sed does not support `\|` alternation in basic regexes, so
  the first replacement silently failed to remove the `@`-include on macOS.
- `uninstall.sh` deleted `.claude/commands/` wholesale, taking project-owned commands with it. It
  now removes only the files it installed and keeps the directory unless it is empty.
