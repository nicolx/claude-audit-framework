# Changelog

All notable changes to this framework are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Because consumer projects load this framework into every Claude Code session, a version bump is
about *their* sessions: **major** means they must change something in their own project,
**minor** adds criteria or commands, **patch** corrects and clarifies.

## [1.33.0] — 2026-10-18

Category 0 scored what the product declares it is for, and nothing scored whether anyone can find
out what it does. That account lived in the code and in the heads of the people who wrote it — and
an agent can now read every entry point cheaply enough to write it down in the change that makes it
stale, which is the only time a manual stays true.

### Added

- **0.9 What the product does is written down for the people who use it** — a task-organised manual
  for users and for developers joining the team, every task traced to an entry point and every
  reachable entry point in a task, stamped with the commit it describes. A manual derived from code
  is legitimate here and nowhere else in the category: it is never evidence of intent, and what it
  shows that 0.1 does not declare is a finding against 0.1. A consumer's Category 0 may move on
  upgrade with no change to its code.
- **`/product-tour`** — builds the entry-point inventory, writes `user-guide.md` and
  `developer-tour.md` from it, derives Marp slides from the guide, and reports where the code and the
  product context disagree without deciding which is right. Where declared, records the real
  application against a non-production target on synthetic data, in the project's own end-to-end
  harness, with captions taken from the guide — never generated imagery. A failed recorded step is
  reported, not repaired. `--check` writes nothing and is how `/project-audit` scores 0.9.
- **The `Product tour` declaration block** in `templates/PROJECT_AUDIT_FRAMEWORK.md`. Without it the
  command writes documents only; it sets no ceiling on 0.9. `check-install.sh` reports it as absent
  on existing installs.
- **Sources** — a *Documentation* section: Procida's *Diátaxis*, with the departure that the
  generated manual writes only how-to and reference; Gentle's *Docs Like Code*.

## [1.32.0] — 2026-10-18

Principle 1 said what a comment should not explain, and stopped there. The comment it did not name —
the one recording how the code came to be — is the commonest in code an AI assistant writes, and
this repository's own scripts were full of it.

### Changed

- **Principle 1** names history as drift: comments that narrate the past, cite a release, a ticket,
  a review or the session that produced the code, and commented-out code. A non-obvious *why* is
  written as a constraint that holds today; the history of a line lives in its commit.
- **2.5 Self-documenting code** — *Comments are not a changelog*: a `git grep` an auditor runs, every
  hit read rather than counted, and a cap of 6 when the hits are mostly narrative. A consumer's 2.5
  may move on upgrade with no change to its code.
- **`INSTRUCTIONS.md`** — *Every change ends with two checks*: before a change is done, its diff is
  read for principle 1 and principle 22. A README is corrected when the change made it wrong, never
  written to log the work.
- **`scripts/`** — narrative and stale comments removed; constraints kept, in the present tense.

## [1.31.0] — 2026-10-18

8.7 told the auditor to *evaluate the codebase against the current OWASP Top 10*. The Top 10 is an
awareness document: it ranks what goes wrong most often, and it gives an auditor nothing to point at
— which is the one thing this framework requires of every criterion. Two audits of the same code
could reach any score and both be defensible.

### Changed

- **8.7 is now *Verified against a declared ASVS level*.** The OWASP Application Security
  Verification Standard is the Top 10's counterpart written for verification: 345 requirements in
  v5.0.0, each passing or failing, in seventeen chapters and three levels — L1 (70), L2 (253, L1
  included), L3 (all). The project declares the version, the level it targets and why, and the
  chapters it does not expose; findings cite versioned identifiers such as `v5.0.0-8.2.1`.
- **Proportionate twice over.** The level is set by risk — the data the product holds — and how far
  along the road the project must already be is set by the existing maturity minimums: the bands put
  L1 in progress at 4, L1 complete at 6, the declared level mostly and fully met at 7 and 8. One
  exception jumps the queue: an exploitable L1 gap in an exposed chapter is Phase 0, at any maturity.
- **Scored once.** A requirement already a finding under 8.1–8.6 is cited there and not deducted
  again; 8.7 carries the rest. Runtime-only requirements are capped at 8 without a declared
  production path, the same rule as 7.9. The Top 10 stays, as the explanation beside an identifier.

### Added

- **`standards/asvs/`** ships the v5.0.0 requirement list — the official release asset, unmodified,
  under its CC BY-SA 4.0 licence, with a README carrying the attribution and a `grep` that filters it
  by chapter and level. Shipped rather than fetched, so an audit is reproducible and works offline.
- **The `Security verification` declaration block** in `templates/PROJECT_AUDIT_FRAMEWORK.md`.
  `check-install.sh` already names any block the template offers and a project lacks, so existing
  installs see it as a warning. **Without the block, 8.7 is scored against L1 and capped at 6** — a
  consumer's 8.7 may move on upgrade with no change to its code, and the `Framework` column added in
  1.30.0 now shows why.
- **`commands/project-audit.md`** tells the Category 8 agent how to read the block and the shipped
  list.

## [1.30.0] — 2026-10-18

1.29.0 changed the composition of five categories and told consumers to read the next audit as a new
baseline for them — advice the audit itself could not follow, because `history.md` never recorded
which version of the framework produced a score. A category that dropped a point after an upgrade
was indistinguishable from one that dropped a point because the code got worse, and the trend line
reported both as regression.

### Added

- **`history.md` gains a `Framework` column** — the version the scores were measured against, read
  from the framework's `VERSION` file, the checkout actually loaded, rather than from the install
  marker. An existing file gets the column with `—` in every earlier row: those versions were never
  recorded, and guessing them from the date would put a fiction into the column that exists to
  prevent one.
- **The comparison reads it.** When the previous entry at the same scope was scored against another
  version, `/project-audit` reads the changelog entries in between, and every category whose
  subcriteria changed in that span is shown with the reason beside its movement and treated as a new
  baseline — never as progress or regression. Categories the changelog does not touch compare as
  before.
- **The project snapshot** names the framework version the audit was scored against.

## [1.29.0] — 2026-10-18

1.28.1 named the framework's sources. This release takes from them what the framework was missing —
and the list was not short. Category 1 measured three of the five SOLID principles. Category 2 said
*technical debt management without refactoring discipline is a wishlist* and then measured no
refactoring discipline. 2.2 told a reader to extract a function whenever one could be extracted,
which is the rule Ousterhout spends a book showing produces code that is harder to read. Category 9
had no service level objective anywhere, and Category 10 scored sixteen practices and not one of the
outcomes they exist to produce.

**Five categories change composition — 1, 2, 3, 9 and 10.** A project re-audited on this version may
see a category move with no change to its code. That is the framework, not the project: read the
first audit after upgrading as a new baseline for those five, not as a trend.

### Added

- **2.11 — Refactoring proceeds in behaviour-preserving steps** (Fowler, Beck). Read from the log: a
  `refactor:` commit that changes what the tests assert was not a refactoring; steps are compared for
  size and checked green with 0.8's indicators; structural commits should precede the behaviour change
  they make room for. Applies wherever the history restructures existing code.
- **1.6 — Liskov Substitution**, **1.7 — Interface Segregation**. An override that throws "not
  implemented" or a type check on a subtype is evidence; it is scored once, under the cause.
- **1.8 — Modules hide design decisions** (Parnas, Ousterhout). A decision likely to change has one
  owner, behind an interface simpler than what it hides. The evidence includes a co-change query over
  the history: two production files in different modules that keep moving together are one decision
  with two owners.
- **3.9 — The core domain is named, and gets the investment** (Evans's distillation). N/A wherever
  3.8 is.
- **10.17 — Delivery outcomes are measured** (*Accelerate*). The four measures — deployment
  frequency, lead time, change failure rate, time to restore — are scored on being measured, visible
  and read as a set, **never on their values**, because a measure turned into a target stops
  measuring. Applies to anything that ships; a library reads releases as deployments.
- **Principles 11 and 24** — a refactoring pass moves in named steps, each green and each its own
  commit; and when a change is hard to make, the step before it makes it easy.
- **Sprout and wrap** (Feathers) in *What the order does not gate*: new code that has to live inside a
  class with no seam is written as a new, tested unit called from one line, rather than waiting for a
  seam.
- **Six sources** in the appendix — Ousterhout, Parnas, Liskov and Wing, *Accelerate*, the SRE book,
  Goodhart — and the rows of Fowler, Beck, Feathers, Evans, Nygard and Martin extended to the places
  that now use them.

### Changed

- **2.2 no longer treats length as the criterion.** A function that does one thing in a straight line
  is fine at forty lines; a chain of one-line functions that pass their arguments through, or a helper
  called once whose name says no more than its body, is now a finding. The test changed with it: an
  extraction is made when the reader can understand the parent *without* reading the extracted
  function. *Clean Code*'s row in the appendix records this as a departure.
- **2.5 and principle 1** — a comment on an interface stating what the signature cannot is part of
  the interface, not drift.
- **9.4** adds saturation as the fourth signal and expects a service level objective wherever people
  wait on the service in real time, with alerts on budget burn rather than raw thresholds. A batch
  states its objective as completion and lateness.
- **9.5 and principle 8** — every call across the process boundary carries an explicit timeout;
  retries are bounded and idempotent; circuit breakers and bulkheads where a dependency fails slowly.
  *The library has a default* stays a finding until somebody names the value.
- **Principles 4 and 7** gained the write-time side of 1.6–1.8 and 3.9; the traceability table maps
  the new subcriteria, and 10.17 joins the criteria with no write-time principle, with the reason.
- **`commands/project-audit.md`** tells the Category 1, 2, 3, 9 and 10 agents where the new evidence
  is, including which queries to run over the whole history rather than the twenty-line excerpt.

## [1.28.1] — 2026-10-18

The framework draws on thirty-six books, papers and standards and named a handful of them — three of
those credits to the wrong author. This release names its sources, corrects the attributions that
were wrong, and changes no criterion, no principle and no score.

### Added

- **`PROJECT_AUDIT_FRAMEWORK.md` — *Appendix — Sources*.** Every work the framework draws on, with
  the criteria and principles that use it and one line on why it is worth reading — a reading list
  for a developer early in their career as much as a record of credit. It is the only place sources
  are listed; a criterion may name one inline, and the full reference lives here. **Where the
  framework departs from a source, the row says so**: the *Rule of Three* (principle 2 decides by
  complexity, not by counting), *plan to throw one away* (principle 12 refactors, never rewrites),
  test-first as a mandatory cycle (principle 10 asks for agreed behaviour, not a ritual), and the
  case against levelled logs (9.1 keeps the levels). The OWASP ASVS is listed as the verifiable
  counterpart of the Top 10 and marked as not yet used for scoring.
- **`CODING_STANDARDS.md`** points at that appendix from its header, rather than keeping a second
  list.

### Fixed

- **4.6** attributed the five kinds of test double to Freeman & Pryce. The taxonomy is Meszaros's,
  from *xUnit Test Patterns*; Freeman & Pryce keep the rule they did write, *mock only the types you
  own*, now credited where it is stated.
- **10.9** credited evolutionary architecture to "Fowler, Ford, Parsons". *Building Evolutionary
  Architectures* is by Ford, Parsons and Kua. The Strangler Fig stays Fowler's.
- **3.8** credited the context-integration patterns to "Vernon's Strategic Design". They are Evans's,
  from *Domain-Driven Design*; Vernon elaborated them.
- **4.2** named Khorikov's third testing style *interaction-based*. His term is *communication-based*;
  the common name is kept beside it.
- **2.6** used the 1999 names for smells and refactorings, and two fixes that are not in the
  catalogue at all. The table now uses the second edition's: Long Function, Extract Function, Move
  Function, Repeated Switches, Split Phase, Inline Function, Introduce Special Case — and Data Clumps
  resolves to Extract Class or Introduce Parameter Object, with the Value Object of 3.3 named as the
  usual destination. The catalogue is credited to Fowler and Beck, who wrote that chapter together.
- **10.12** said "studies consistently show" with nothing cited. It now cites the SmartBear study of
  review at Cisco (Cohen, 2006) and states its finding — defect detection falls off beyond roughly
  200–400 lines — rather than a stronger claim no study was named for.
- **2.3** gave the definition of DRY without its authors. It is Hunt and Thomas's, and says so. The
  seam of 2.6 and the characterisation tests of *Remediation order* are credited to Feathers in the
  same way.

## [1.28.0] — 2026-10-11

1.27.0 added the `Fast-lane gate` and left it the only declaration block no subcriteria read. The
obvious fix was a new one — 10.17, *the fast lane is bounded*. It would have been the wrong fix: it
would have scored the same deviation, from the same log and the same convention block, that 10.15
question 3 already scores. One fact in two places is this framework's most frequent defect, and
adding a number is the easiest way to commit it.

The actual defect was in 10.15, and it is a measurement error rather than a gap. Question 3 could
read a departure from the convention only as a breach. So a team with a written emergency path, used
three times in a year, each time inside its bounds and each time with the regression test, scored
level with a team that departs whenever it feels like it — and below a team that has simply never
had an emergency. That is the measurement backwards: it penalises the team that wrote down when the
ceremony may be shortened, which is the only one of the three that can be held to anything.

### Changed

- **10.15 question 3 now reads the history against the convention *including its declared
  exception*.** Four readings, stated: a departure inside a declared gate carrying what the gate says
  it carries is conformance, not an exception to be forgiven; a departure with no gate declared is a
  breach whatever reason the commit gives, because the reason is always good at the time and that is
  why the bound is written in advance; a gate whose bounds the diffs contradict is worse than no
  gate, since the declaration is now evidence the team knew; and declaring no gate at all is a
  complete answer that costs nothing, scored on whether the history agrees.
- **10.15's good, bad and scoring notes** gained the corresponding entries — among them the two
  failure modes the block exists to prevent: a fast lane with no floor, where *small* comes to mean
  the test and the log line can wait as well as the review, and a `Never qualifies` list the diffs
  contradict. **The band is neither raised by declaring a gate nor lowered by leaving one out**;
  what moves is the reading of the departures the log already contains.
- **`templates/PROJECT_AUDIT_FRAMEWORK.md`, `INSTRUCTIONS.md` and the README** now name 10.15 where
  they introduce the block, the way every other declaration block names the subcriteria that reads
  it.

## [1.27.0] — 2026-10-11

The fourth agent is the one that needed the gate built first.

`hotfix` skips the design pass, the ADR and the step-list exchange, which is exactly what makes it
dangerous: a lane that skips the ceremony is the lane every change ends up in, each time for a
reason that looked good at the time, and nothing in the history afterwards tells the changes that
were small apart from the changes that were *called* small.

Two things stop that. **The gate is the project's, not the agent's** — a new `Fast-lane gate` block
declares what qualifies, what never does, and what the change carries anyway, written once by the
team in the calm rather than by whoever is under pressure at 6pm about the change they are under
pressure to ship. **An absent block is not an open gate**: with no declaration, `hotfix` refuses to
start and the change goes the ordinary route. And this session never routes to it — the developer
invokes it by name, having decided, because a lane an agent can assign to itself has no gate at all.

Fast means less ceremony. It never means less change: the regression test of principle 26, the
boundary of 15 and 16, the document of 22 and the project's Delivery convention in full all ride
with a fast-lane change, and the agent says out loud what the lane skipped so the next reader can
tell this change from a reviewed one.

### Added

- **The `Fast-lane gate` declaration block**, in `templates/PROJECT_AUDIT_FRAMEWORK.md` with two
  worked examples, and in this repo's own `CLAUDE.md`. Five fields: what qualifies in terms somebody
  can check against a diff, what never qualifies (absolute — a one-line change to an authorization
  check is not a small change, it is a one-line change), what the change carries anyway, what makes
  it fall out of the lane, and what checks it. `check-install.sh` already compares the template's
  blocks against the project's, so existing installs will be told the block exists without a line of
  new code.
- **`agents/hotfix.md`** — reads the gate before touching a file, names the line it matched, and
  treats borderline as a stop rather than a lean. Falling out of the lane mid-fix is a correct
  outcome: it reports, leaves the tree readable, and hands back to `architect` instead of finishing
  it anyway, because a change that grew past the gate has had neither the fast lane's honesty nor
  the slow lane's review.
- **`### The fast lane is taken, never assigned`** in `INSTRUCTIONS.md` — `hotfix` is the one agent
  routing never selects. If a task looks like fast-lane work and the developer has not asked, do it
  the ordinary way or mention in one line that the agent exists. Never offer it as a way around a
  review somebody is waiting on.

## [1.26.0] — 2026-10-11

Two more agents, and between them they cover the two moments a change is cheapest to get right:
before it is written, and before it meets volume.

`architect` exists for the failure nobody sees at the time — a change that works, ships, and quietly
fixes a decision nobody knew they were making. It answers five questions in writing, and the third
one does most of the work: *what does it cost to reverse?* An hour, a migration, or a coordinated
release with a consumer. That number decides how much evidence the decision deserves, and whether it
earns an ADR. It never writes code and never writes a file; the ADR is drafted as text and belongs
in the change that enacts the decision.

`scalability-devops` refuses to say "this might not scale". It names the dimension — rows, requests,
concurrency, payload, fan-out, retention — the thing that breaks first, and roughly the multiple at
which it breaks. Where the project has declared a read-only database or a production path it
measures; where it has not, it reasons from the code and says which numbers are inferred. It never
generates load, because the one reliable way to turn a scalability review into an outage is to run
one.

### Added

- **`agents/architect.md`** — reads the product documentation home, the ADRs and what already exists
  before proposing anything (principle 14), then answers what the change commits the system to,
  which seam it crosses, what it costs to reverse, which assumption is most likely wrong, and how
  the shape evolves. Always two routes with the simpler one first (principle 12) **and a
  recommendation** — a menu with no recommendation hands the hard part back. The deliverable is the
  step list of principle 24, whose first step settles the assumption rather than being the easiest
  file. Calibrated by `~/.claude/context/user_profile.md` on delivery only: a `Base *` competency is
  named in the step that needs it and built jointly, never routed around.
- **`agents/scalability-devops.md`** — principle 21 as a checklist, plus what principle 21 does not
  cover: state that does not survive a second instance, retries without idempotency, caches that
  stampede, metric labels with unbounded cardinality, a log line per item in a loop, and what
  accumulates with nothing deleting it (9.6, 9.7, 9.11). Bounded by the **Database access** and
  **Production access** declarations, which it reads before using and never widens — being unable to
  reach something is reported as a finding, not routed around.

### Changed

- **The routing table is in lifecycle order** — `architect` before the work, `scalability-devops`
  across it, `pr-critic` after. Two agents on one change is normal when they meet it at different
  moments; two at the same moment is the duplication the section already forbids.

## [1.25.0] — 2026-10-11

An agent nobody dispatches is a file. 1.24.0 shipped `pr-critic` and left the question of when to
reach for it to whoever remembered it existed, which under pressure is nobody.

So INSTRUCTIONS.md now carries the routing — and, deliberately, only the routing. What an agent does
stays in its own file; this section answers the one question a file cannot answer about itself,
which is when to prefer it over the session already running. The default is still none: an agent
costs a second context reading real files, and that is a decision rather than a reflex.

The two rules worth more than the table: **an agent is a lens, not a permission upgrade** — a
subagent is a session, bounded by the same declaration blocks as any other, and routing is never how
a grant gets widened — and **an agent does not decide**. It returns evidence or a plan. Merge, change
course, accept the risk: still the developer's.

### Added

- **`## Which agent, and when` in `INSTRUCTIONS.md`** — the routing table, the rule that a session
  names the agent it picked before it runs, and what routing never does: widen a grant, settle a
  decision, or buy a second opinion on something already established.
- **Check 11 in `check-consistency.sh`** — the routing table and `agents/` must agree in both
  directions. An agent shipped without a row is never dispatched; a row without a file sends a
  session to a name Claude Code cannot resolve. Neither is visible from inside either file, and the
  check fails on each independently.
- **What to do when an agent is wrong for a project** — say so, as a finding about the framework.
  The copy is overwritten on the next `init-project.sh` run and reported as drift by
  `check-install.sh` until then, so editing it buys an agent that silently reverts. A project's own
  agent goes under its own name, where nothing the framework does will touch it.

## [1.24.0] — 2026-10-11

A command is a script the session runs in its own context. It is the wrong shape for a reviewer,
because a reviewer's value comes from what it is *not* allowed to do: a critic that can edit the
file it is criticising will fix the thing instead of reporting it, and the finding is never written
down. So this release opens `agents/` — subagents with their own mandate, their own tool grant, and
their own isolated context, installed as copies the same way commands are.

The first one is `pr-critic`, and its whole design is a set of refusals. It never edits. It never
approves. It deletes a finding it cannot locate to a line rather than softening it into a sentence
about the service layer. It marks what it actually traced apart from what merely looks wrong, which
is the distinction a review loses first and the one that decides whether anybody acts on it.

### Added

- **`agents/` and `.claude/agents/`** — the framework now ships agents alongside commands.
  `init-project.sh` copies them, always overwriting: they belong to the framework, and an agent the
  project wrote under its own name is never touched. `uninstall.sh` removes the same list and leaves
  a project-owned agent where it is, taking the directory only if it ends up empty.
- **`agents/pr-critic.md`** — adversarial review of a diff or a pull request. Reads the branch
  against the mainline with no network by default, or a numbered pull request through `gh`, in which
  case it reads the existing comments first, because a finding somebody already made is noise rather
  than a second opinion. Measures against the 27 principles, the 11 categories, the project's own
  two files, and `.claude/audit-focus.md` where it exists — in that order, later overriding earlier.
  Every finding carries where, what breaks, and which rule, and is marked CONFIRMED or PLAUSIBLE.
- **Byte-for-byte verification of the agent copies** in `check-install.sh`, with the same reasoning
  that covers commands: a hand-edited agent still answers, with rules this version no longer ships.
  A framework checkout carrying no `agents/` at all is reported as incomplete rather than passing
  vacuously against zero.

### Changed

- **`check-consistency.sh` check 5** now resolves `agents/...` paths cited in documents, so a moved
  or renamed agent file fails the gate like any other load-bearing path.

## [1.23.0] — 2026-10-11

*More than one person writes* puts 10.12 in play for a repository. It does not make a review
available everywhere inside it, and the gap between those two is invisible in every artifact the
subcriteria looks at: the pull request opens, somebody approves, the branch protection records an
approval. What it does not record is that the approver had never been in that directory.

The same data that answers *who writes here* answers *where could anybody review this*, and it is
the one reading of a commit history that is about the repository rather than about the people in it.
The other reading — inferring a developer's competence from their commits — stays out of the
framework, and now says so in writing: the history records which parts of the tree somebody was
assigned, and territory is not ability.

### Added

- **Per-area review reachability**, in Category 10's proportionality section. A directory one person
  has ever touched has no reviewer, and raising the required approval count does not reach it
  because the missing thing is not a rule. **The finding is the concentration**, and it lands on the
  criteria that would have made the knowledge available to a second person — the *why* written down
  (0.1) and onboarding that is a document rather than a conversation (7.10). 10.12 is scored on the
  changes that could be reviewed.
- **The evidence, as one `awk` over `git log`**: distinct authors per directory, lowest first, with
  a tunable depth for deep trees. Read each single-author area against its last commit date — two
  years of silence is dormant code and a question for 7.5, last week is the live half worth
  reporting — and check `CODEOWNERS` against the active author list, because an owner who has not
  committed in a year is review routed to nobody with the routing still on display.
- **A `Knowledge concentration` row** in the Team census block, and the fourth question in
  `/team-census`: is a single-author area ownership somebody chose, or simply where nobody else has
  had reason to go? A chosen owner needs the knowledge written down; an accidental one needs a
  second person in there. Only a person knows which.
- **The boundary, stated once in the standard.** Nothing in the framework scores an individual's
  competence from a log, and a reading of the history that produces one is outside it. The
  competency profile is self-declared, per machine, and never committed — that is what makes it both
  safe and accurate, and a teammate who wants one runs `/init-profile` themselves.

## [1.22.0] — 2026-10-11

1.21.0 made Category 10 proportional to who works on a project, and answered *who writes here* with
`git shortlog`. That answer counts **identities**, and the census needs **people**. Between the two
sit a bot, an agent, a shared deploy account and a web interface, and the instruction 1.21.0 gave —
*exclude the bots* — was the wrong one in the most common case: a bot's commits are somebody's work,
and dropping them drops a writer.

The two errors are not symmetric. Counting one person's four identities as four people costs a
project some N/A it had earned. Counting four people behind one `deploy-bot` as one writer removes
10.12 from the audit entirely, and the framework then certifies a team that reviews nothing. So the
resolution rule runs one way.

### Added

- **Identity resolution in precondition 5.** An identity in the log is a credential, not a person,
  and the mapping breaks in both directions. The rule that follows is one-directional: **an
  unresolved identity is never resolved downward** — record it as unresolved, keep scoring the
  subcriteria it would otherwise have excused, because marking 10.12 N/A needs a positive finding
  that nobody else writes here, not an absence of evidence about who does.
- **An AI co-author is a tool, not a contributor.** A commit authored by a developer and trailed by
  `Co-authored-by: Claude …` has one writer. Nor does a human approving an agent's diff satisfy
  10.12: that subcriteria asks for a review by somebody who did not write the change, and a
  developer directing an agent is its author. The reverse shape — an agent identity on the commit,
  a person in the trailer — makes the person in the trailer the writer.
- **`/team-census` Step 3 — the resolution ladder**, five rungs, stop at the first that answers:
  author against committer (two identities per commit, and `shortlog` shows only the first); the
  commit trailers; the account id encoded in a `…+name@users.noreply.github.com` address, including
  what a `[bot]` suffix means — an app acting for an installation, with the human in the host's
  audit log; the signature, which outranks any name field, except the host's web-flow key that
  signs everything committed through the web interface; and the pull request the commit arrived in.
  Plus the honest limit: **who pushed is not in the repository at all**, so an identity that
  survives all five is a question for a person. A timezone-spread check is offered for the dangerous
  case, a single identity carrying an improbable share of the history.

### Fixed

- **`git shortlog` without a revision argument hangs.** With no revision and a non-terminal stdin it
  reads standard input, which is exactly the shape of an agent session — so the command shipped in
  1.21.0's precondition 5, census block and `/team-census` would have waited forever rather than
  answering. Every occurrence now passes `HEAD`.
- **`check-consistency.sh` could not see a document before it was staged.** `git ls-files` lists
  tracked files only, so a newly written command file was invisible to every path check — and
  1.21.0 shipped a broken path reference through a gate that ran green on it. The file lists now
  include `--others --exclude-standard`.
- **A consumer-project path cited as a framework path.** `/team-census` named `.github/CODEOWNERS`,
  which exists in the project being censused and not in this repository; it now finds the file
  wherever the host accepts it.

## [1.21.0] — 2026-10-11

Category 10 was written as though every project were a team with releases. Four of its subcriteria
measure practices that exist because of *other people* — a pull request carries a review between two
of them, a protected branch stops a change arriving unseen, a tag names a version somebody
downstream runs — and a one-developer repository deployed continuously from `main` was being scored
against all four. It lost points for not holding reviews with itself, and the honest fix was always
available to it: adopt the ceremony, score higher, protect nobody. A standard that can be satisfied
that way teaches projects to perform compliance, which is the one outcome worse than a low score.

The missing piece was never a rule, it was an input. *How many people write here, and does anything
consume a version* are facts about a project, observable in its history and its deployment, and
nothing in the framework asked. So this release adds the question, the block that answers it, and
the one place where the answer is allowed to change what gets scored.

### Added

- **Precondition 5 — *The team must be declared, or read from the history***. Four things to
  establish before Category 10 is scored: who writes, who reviews, who releases, who consumes a
  version. Declared in the new **Team census** block, or read from `git shortlog` and said to be —
  with the limit of the log stated, because it knows who committed and not who is still here. A
  declaration the history contradicts is a finding, reported like a production path that no longer
  resolves.
- **The proportionality rule at the top of Category 10.** Two questions — *who writes* and *who
  consumes a version* — decide which practices are load-bearing. 10.12 is **N/A** where a review
  crosses nobody, and what it asks of the change itself survives in 10.11. 10.13 splits: the approval
  half is N/A with one writer, the gate half (status checks, no force-push, linear history, signed
  commits) protects a lone developer from their own worst afternoon and is scored. 10.14 is **N/A**
  until something pins a version. 10.10 is never N/A — *"trunk, straight to `main`"* is a complete
  strategy once it is written down; what that subcriteria fails is silence, not simplicity. The rule
  states three things it is not: not a discount on 10.1–10.9, which do not care who writes the code;
  not permanent, because a census has a date and a project that gained a second writer gained two
  subcriteria back; and not an argument a project makes for itself — *we are small* is not a
  structural condition, and the N/A doctrine already refuses it.
- **The `Team census` declaration block**, fifth in `.claude/PROJECT_AUDIT_FRAMEWORK.md`, with a
  worked example for a solo repository and for a team of nine. It is the only one of the five that
  grants nothing: it states who the project's people are. Existing installs see it through
  `check-install.sh`, which compares the template's blocks against the project's and needs no
  migration to do it.
- **`/team-census`** — drafts the block from the history (`shortlog` over a year, who merges, each
  author's last commit, `CODEOWNERS`) and asks only the four things the log cannot answer. It reads
  bots out of the contributor count, because `dependabot[bot]` as a second writer would put 10.12
  back in play for a repository where nobody reviews anything, and it proposes a `.mailmap` when one
  person appears under three addresses. A refresh presents the difference against the existing block
  rather than re-running the interview. It names contradictions — a census of one beside a delivery
  convention requiring an approval — and resolves none of them.

### Fixed

- **`uninstall.sh` left `/dr-drill` behind** when the submodule was already gone. The fallback list of
  command names, used only on that path, had not been updated since the command was added; it now
  carries every shipped command.

## [1.20.0] — 2026-10-10

1.19.0 gave the framework a cleanup trigger and pointed it at git. The pattern it found there is not
a git pattern. Almost everything a system accumulates is the **second half of a two-phase change
that nobody scheduled**: the column added nullable and never dropped, the annotation written and the
call sites never migrated, the flag shipped to roll a change out and never retired, the test skipped
*for now*, the environment stood up for a demo and the key issued for one migration — both still
valid two years later. The first half is always forced, because the work does not function without
it. The second half is a change whose entire visible effect is that something stops existing, so
nobody is waiting for it, and *never urgent* is not a schedule.

The framework already scored four of those residues — dead code in 7.5, deprecations in 7.8,
datasets in 9.7, logs in 9.6 — and had no place at all for what a project provisions outside its own
repository. So the account was the one thing no criterion looked at, which is also where an unused
credential lives: the full blast radius of a used one, and none of the attention, because nothing
breaks when it is compromised.

### Added

- **Subcriteria 9.11 — *Orphaned infrastructure and unused access*** *(Operated services, N/A for a
  library)*. Two accumulations, and only one is about money. Resources attached to nothing — where
  the cost is not the bill but that nobody can tell the orphan from the load-bearing resource, and
  the dangling DNS record is a subdomain takeover rather than a line item. And access: deploy keys
  for archived repositories, tokens for providers the team left, identities from a finished
  migration, a personal token belonging to someone who no longer works here. 8.6 scores how a secret
  is stored; 9.11 scores whether it should still exist. Evidence starts with the two sources needing
  no production path — the IaC plan against a clean checkout, and the cost report read per resource —
  and caps at 7 where no read-only path is declared, because the repository can only show the
  declared half. Enumerating and planning are read-only; deleting a resource or disabling a key is
  never part of scoring it.

### Changed

- **Principle 27 names the pattern** rather than only its git case, and states the rule it implies:
  decide the second half's trigger while writing the first — the condition that retires the flag,
  the release after which the column drops, the date the environment dies — because that is the only
  moment anybody knows what it was for.
- **10.4 scores the contract phase**, not just the expand. Expand-contract is two deployments, and
  scoring the first one rewards half a pattern. Two `pg_stat_*` queries for indexes never used and
  tables never read, plus the migration directory read as a sequence: one that only ever adds is a
  project that ran the expand half of every change it ever made. An abandoned column is a decision
  every developer who touches that table has to make, and a retention obligation (9.7) where it held
  personal data the application no longer uses.
- **7.8 scores feature flags as deprecations with a different word.** A flag past its rollout is
  deprecated code whose dead side is still *reachable in production* — selectable by a config value,
  an environment variable or a stale row, while nobody has exercised it in a year. Same rule as a
  `@deprecated` annotation: a removal condition decided when the flag is created. A deliberate kill
  switch stays legitimate and belongs in the inventory *as* a kill switch, with its reason.
- **4.5 scores whether a skip can end.** A suite's organisation includes which groups CI actually
  runs, and that is where tests go to disappear: a skip added during a release crunch removes a test
  from the suite without removing it from the repository, where it still counts in the total and
  still looks like coverage. 4.4's runtime `markTestSkipped()` is the correct opposite case — it
  lifts itself the moment its condition clears.
- **The `/project-audit` evidence slice for Category 9** sends the no-access sources first and states
  the read-only boundary explicitly, since this is the first criterion in the category whose evidence
  lives in a provider account rather than in the repository.
- **A session removes what it provisioned**, not only what it wrote: `INSTRUCTIONS.md` now names the
  scratch bucket, the throwaway environment and the one-migration token alongside the scratch file.

## [1.19.0] — 2026-10-10

A repository accumulates, and none of what it accumulates is a defect on the day it appears — which
is why it is all still there a year later. The branch list that has sixty entries and three live
ones. The `git fetch` that prints refs for branches deleted months ago, on every machine, every
time. The `dist/` directory somebody committed once and nobody removed, now in every clone forever.
Each of them is cheap to prevent at the moment it is created and expensive to undo afterwards, and
each of them waits on the same thing: a person noticing. Noticing is the first resource the
accumulation consumes.

The framework had the practices that produce the residue — branching in 10.10, tags in 10.14, the
pipeline in 10.3 — and nothing about removing it. So the criterion was passing projects that merge
cleanly and leave the remains of every merge behind them.

### Added

- **Principle 27 — *Cleanup runs on a trigger, not on a reminder*.** Two triggers cover all of it:
  the change removes what the change created — its branch via the host setting turned on once, its
  scratch files in the commit that stops needing them, its build output in the ignore file the day
  the build first writes it — and what no single change can reach runs on a schedule. Then the line
  automation does not cross, because cleanup that destroys work is worse than the mess it removes:
  nothing unmerged whatever its age, no tags, no rewritten history, nothing silent and nothing
  without a dry run.
- **Subcriteria 10.16 — *The repository cleans up after itself*.** 10.10 scores whether a branching
  strategy exists; this scores whether the repository still looks like one after six months of a
  team following it. Four commands carry it — merged remote branches, branches by age, refs whose
  upstream is gone, repository size — plus the cheapest check in the category and the one least
  often run: a clean checkout, a full build, `git status`. A job that deletes branches by age alone
  scores *below* having no automation at all. A solo repository worked straight on `main` marks the
  branch half N/A rather than scoring it zero.
- **The session's half, in `INSTRUCTIONS.md`.** A change's residue leaves with the change, and
  tidying by hand is read as a finding rather than as a chore: a branch that survived its merge
  means the host setting is off, a noisy fetch means `fetch.prune` was never configured, a dirty
  `git status` after a build means an ignore rule is missing. Each one gets named once, with the
  one-time setting that removes the step.
- **The `/project-audit` evidence slice for Category 10** sends the ref-and-size commands to the
  live remote: `common.md`'s branch list is a snapshot with no ages in it, and says nothing about
  refs that are already gone upstream.

## [1.18.0] — 2026-10-10

The framework scored how well a suite covers the code as it stands and said nothing about the one
test everybody agrees should exist and nobody checks for: the one written when a bug was fixed. A
defect that reaches production has already proved the suite could not see it, and a fix that changes
only production code leaves that blindness exactly where it was. The second time the same bug is
reported is not bad luck — it is the first fix's missing test, arriving late.

The lifetime is half the rule and the half that gets lost. A regression test is the only test whose
reason to exist is invisible in the code it covers, so it is the one a suite reorganisation, a flaky
sweep, or a well-meant consolidation into a broader test removes without anyone noticing the
guarantee leaving with it.

### Added

- **Principle 26 — *Every bug fix leaves a test behind*.** A four-step protocol: reproduce the defect
  as a test that fails *for the reported reason* before the fix exists, at the lowest level that
  reproduces it, aimed at the root principle 9 sends the fix to rather than at the reported call site,
  and naming the defect so the next reader can see why a test exists for an input nobody would think
  to try. Then the removal rule, with the four non-reasons spelled out: not because it is red, not
  because it is old, not because a broader test covers it, not because it is slow. It goes in the
  commit that deliberately changes the behaviour it pinned, and nowhere else.
- **Subcriteria 4.7 — *Bug fixes leave regression tests behind*.** The rest of Category 4 scores the
  suite against the code as it is today; this scores it against the project's own history, and the
  evidence is the log rather than an opinion. Three queries: what share of fix commits touched a test
  file, whether a sample of those tests actually fails when checked out against the fix's parent, and
  whether deleted tests were deleted by a behaviour change. The same defect appearing twice in the
  log carries the score on its own. N/A only where the history is too short to contain bug fixes —
  unlabelled commits make the query harder, not the question inapplicable.
- **The `/project-audit` evidence slice for Category 4 says where to look**, since 4.7 is the first
  thing in that category that is not in the test tree: the whole log rather than `common.md`'s
  twenty-line excerpt, the parent-commit spot check, and the deletions.

## [1.17.1] — 2026-10-10

1.17.0 added a declaration block and shipped no mechanism that would tell an existing project it
exists. The changelog said so, which reaches whoever reads changelogs. `init-project.sh` cannot write
it — the file belongs to the project the moment it is scaffolded. And the breaking-change range in
`check-install.sh` does not name it, correctly: a new block is additive, so the release has no
`### Breaking` section. The comment above that check has claimed since it was written that *a new
declaration* is among the things it exists to surface. It only ever surfaced the ones that broke
something.

### Fixed

- **`check-install.sh` compares the template's declaration blocks against the project's file**, and
  names the ones the project does not carry together with the line that adds them. Version-independent
  by construction — it reads the template shipped with the version checked out — so every future block
  surfaces without being documented release by release. A warning and never an error: declining a block
  is a legitimate answer that sets a ceiling. `init-project.sh` runs this check as its verification
  step, so an upgrade reports it on the spot.
- **The README's upgrade section says what is not automatic.** It promised that `init-project.sh`
  migrates everything it can and that there is no version-by-version path to walk — true of everything
  except a declaration block, which is exactly the thing only the developer can fill in.
- **`test-install-cycle.sh` covers both directions:** a freshly scaffolded project carries every block,
  and a project missing one is told which, at exit 0.
- **Its section headers no longer number the cases they contain.** The ranges were maintained by hand
  and had already drifted — `Cases 11–14` sat above seven of them — so inserting a case silently
  falsified the headers below it. The runner prints the real numbers.

## [1.17.0] — 2026-10-10

1.16.0 scored whether the work was cut into steps that could ship. It said nothing about whether they
then *did* — and a step that works on a laptop has not been delivered, it has been written. Nothing
in the framework scored work left uncommitted at the end of a session, a changelog swept together
from the log the morning of a release, a tag sitting on a different commit from the version bump it
justifies, or install instructions pinning the version before last. Categories 10.11 to 10.14 all
measure the *quality* of an artifact; none of them asks whether the artifact exists.

The other half of it is an agent problem, and this repo's own sessions are the evidence: a session
with no statement of what it may do asks before every commit, every push and every tag. A hundred
confirmations later the team has not gained any safety it did not have — the decision was always the
same one — and has paid for the asking every time. The fix is not for the agent to be bolder. It is
for the project to say, once and in writing, what *done* means here and how far a session may carry
it.

### Added

- **`standards/PROJECT_AUDIT_FRAMEWORK.md` § *10.15 The definition of done is declared, and its
  mechanical half is automated*.** Three questions: is it declared, is everything in it a machine
  could check checked by one, and does the history conform. The shape is the team's and **more
  ceremony is not a higher score** — a three-line convention fully automated scores above a
  fifteen-step one enforced by review comments. The bad list leads with the failure that leaves no
  artifact to find later: finished work nobody's definition of done required pushing.
- **`standards/CODING_STANDARDS.md` § *25. A change is delivered, not finished*.** The step of
  principle 24 ends in the state the project calls done. Where the declaration permits an action,
  take it without asking — the declaration *is* the authorization — and report it in one line. Where
  it does not, stop at the last permitted action and name what remains. Permissions are never
  inferred from adjacent ones: commit does not imply push, a feature branch does not imply `main`,
  neither implies a tag. With no declaration, prepare and ask, exactly as before.
- **`templates/PROJECT_AUDIT_FRAMEWORK.md` § *Delivery convention*** — the fourth declaration block,
  with two worked examples because the right answer depends on the team's size: a solo trunk-based
  repository and a team of nine, both complete, neither scoring higher for being longer. It
  enumerates what a session may do *and what it may not*, ref by ref.
- **`INSTRUCTIONS.md` § *Delivering it: the convention is the authorization*** — where principle 25
  lands in a session, including the once-per-session flag when the block is absent and the rule that
  an absent declaration is never read as permission.
- **An evidence focus for 10.15 in `/project-audit`** — read the declaration first, check each
  mechanical claim resolves to a job that would actually fail, then read the log for the conformance
  signature. Score the shape the team declared, never the length of it.

- **This repo declares its own convention**, in its `CLAUDE.md`: trunk, gate green before the push,
  version and changelog in the same commit, annotated tag on the commit that declares the version,
  and a session that may release but may never rewrite published history. 10.15 asks every project
  for this block; dogfooding it is how the framework finds out what the block costs to write.

### Changed

- **The principle count is 25**, and the README's declaration table has four rows.

**If you are upgrading**, the new block is not scaffolded into an existing
`.claude/PROJECT_AUDIT_FRAMEWORK.md` — `init-project.sh` never overwrites a file the project owns.
Copy *Delivery convention* from the template and fill it in. Until you do, nothing changes: sessions
keep asking before they commit, and 10.15 is scored on what the history already shows.

## [1.16.1] — 2026-10-10

1.16.0 shipped with the README's counts and version pins updated and nothing in it saying what the
release had added. A reader of the README alone still saw the remediation order as the newest idea in
the framework, and the tag is what a prospective consumer browses before deciding to install
anything.

**No shipped document changed.** `standards/`, `commands/`, `templates/` and `INSTRUCTIONS.md` are
byte-identical to 1.16.0, so a project already on 1.16.0 gains nothing from moving and loses nothing
by staying. Upgrading is worth it only to have the pin examples in the README match the tag you are
reading them from.

### Fixed

- **The README names the plan criterion**, beside the remediation order it belongs with: a unit of
  work is measured on whether it arrived as a sequence of releasable steps or as one flip, read from
  the git log and the CI runs rather than from the document that described it — the one criterion a
  project cannot repair retroactively, and one the framework holds its own remediation output to.
- **The install, upgrade and commit-message examples pin `v1.16.1`.**

## [1.16.0] — 2026-10-10

The framework scored whether the work was written down and whether its status was true, and said
nothing about the one property of a plan that decides how the week actually goes: whether it is a
sequence of steps or a single flip. That gap is older than agents and survivable with people, who
ask what to do first. An agent does not ask. Handed *"rebuild the billing module"* it rebuilds the
billing module, in one pass, and the first moment anyone can tell whether it was right is the moment
there is nothing left to compare it against.

So the plan is now scored, and sequencing the work is now a principle. A step is one change, the one
test that proves it, and a state the system can be released in — three things at once, or it is not
a step. And the first one is chosen the way an A3 chooses it: the smallest change that settles the
assumption most likely to be wrong.

### Added

- **`standards/PROJECT_AUDIT_FRAMEWORK.md` § *0.8 The plan decomposes into steps that each ship*.**
  0.3 scores whether the work is specified; 0.8 scores whether it is sequenced. Scored on the units
  of work large enough to carry a spec under 0.3's threshold, so a small change passes with a
  one-step plan rather than failing for not having a list. The bad list names the failures that look
  like plans: the layer-by-layer split where nothing is observable until the last step, the cutover
  written as a line item, verification deferred to a phase of its own, and the done condition that
  is *"it works"*.
- **`standards/CODING_STANDARDS.md` § *24. Cut the work into steps that ship*.** The write-time half:
  decompose before writing, agree the list in its own exchange, cut by behaviour rather than by
  layer, and open on the riskiest assumption. States what to do when the request *is* the
  destination — answer with the route, and never read agreement on a destination as agreement to
  reach it in one pass. A developer who still wants the single cutover gets it, with a plain
  statement of what cannot be verified until the end.
- **`INSTRUCTIONS.md` § *Before the first line: the step list is the deliverable*.** Where principle
  24 lands in a session, including the drift a developer cannot see coming: a sequence that was
  stated and then collapsed into one change because it looked small from inside.
- **§ *How the plan is measured against the history*,** inside 0.8. A plan read on its own scores the
  writing, so the criterion joins the document to the record of how the work arrived — six indicators,
  all read-only `git` plus the CI run list: whether the declared steps were the steps that landed,
  whether one of them is the cutover wearing a step's number, whether each brought its own test,
  whether the gate was green at each one, what was released between the first and the last, and
  whether the plan was revised as the work reported back. Ceilings price what the history can support,
  from *nothing cites the unit* (5) up to *every step separate, green and tested* (8) and *released
  along the way* (10). It also says what the numbers cannot say: the counts are cheap to satisfy
  without changing anything — five commits authored in ten minutes and merged together pass indicator
  1 and fail 4 and 5 — and no command can tell you whether the first step was the one worth taking
  first. Squash-on-merge destroys the step record before it reaches `main`, so the measurement moves
  to the pull request, and a project that squashes one pull request per unit of work has no step
  record at all.
- **§ *The window*, inside the same section** — the half that makes the criterion actionable rather
  than merely measurable. Scored over a rolling window of the **last five units of delivery**,
  bounded at six months or the audit before last, with a short sample (under three units) capped at
  6 rather than guessed at. Inside it the response is arithmetic a team can plan against: one unit
  changes nothing, three of five lift the collapsed-delivery ceiling, five of five leave the ceilings
  binding on nothing. Three raise and two lower — deliberately not mirrored, because a practice is
  harder to demonstrate than to abandon. The report names the window it read, or two audits compare
  different measurements and call the difference progress.
- **§ *What the history is evidence of*.** Why the join exists at all: a plan read on its own agrees
  with itself, exactly as a spec reconstructed from code agrees with the code, and the history is the
  second hand. 0.8 is consequently the one criterion here that cannot be repaired retroactively — a
  backfilled plan for a unit that shipped as one change scores the change — which is also what makes
  it among the cheapest to raise going forward: five sequenced units, no infrastructure. And the
  scope is stated: the delivery inside the window, never the people in it.
- **An evidence focus for 0.8 in `/project-audit`** — read the step list in the specs for work in
  flight, then run the indicators against the units in the slice rather than inferring them from
  `common.md`'s twenty-line log, and quote the numbers. A five-step plan delivered as one commit
  scores the commit, not the list.

- **§ *How remediation work is delivered*,** in *Remediation order*. The order decides which gap and
  when, and said nothing about the shape of the change that closes it — which is how a correctly
  ordered programme still ships ninety files in one change and loses the quarter to the first
  regression. Three rules: a phase is a direction and not a commit, the audit's own recommendation
  names a first step, and size is not the test — uniformity is. Remediation gets no exemption from
  0.8, and is the work that needs it most, because it changes code that already runs.
- **§ *How it is cut*, in *The mass rename is the most ordered change of all*.** One term per step,
  never the glossary in one change, and nothing else in the step: a behaviour change riding along
  destroys the one property that made the diff reviewable, that every hunk is the same edit. The
  resolution sites the compiler cannot see — container keys, serialized payloads, ORM mappings,
  catalog keys, route names, the column a migration renames with the property — become the step's
  checklist instead of its surprise. Per term that list is finite; across forty terms it is the blast
  radius. This is what makes the rename ordered rather than merely large: it does one thing many
  times.

### Changed

- **The audit's own output is held to 0.8.** In `/project-audit`, a Top action estimated medium or
  large names its first step on its own line, and a `--deep` remediation entry that cannot be closed
  in one change names the first step and what it settles. Top actions is the part of the report most
  likely to be handed to an agent verbatim, and an instruction written at the altitude of the end
  state is the artefact 0.8 exists to stop.
- **Indicator 2 tests uniformity rather than size.** A step that does one thing many times is ordered
  at any size; a step that does many things once is the cutover. Previously it exempted the mass
  rename by name, which read as an exemption for large changes rather than for mechanical ones.
- **Principle 9 says where the fix goes, not how much arrives at once.** A fix that generalises
  across forty call sites is still delivered in steps — 11 for the shape, 24 for the sequence.
- **`INSTRUCTIONS.md` carries the same boundary in the remediation paragraph:** the order governs
  which gap and when, never the shape of the change that closes it.
- **10.9 points at 0.8 rather than restating it.** 10.9 measures whether the architecture admits an
  incremental sequence at all; 0.8 measures the plan that uses one. A system with no seams leaves no
  plan available but the cutover, which is why both exist.
- **The adoption provision covers 0.8**, on the same terms as 0.3–0.5: scored against the units of
  delivery since the practice started. Step 3 of the adoption order now names the step list as the
  half of the spec worth writing first — it changes what happens this week, rather than what is on
  record about it.
- **The principle count is 24** in `README.md`, `INSTRUCTIONS.md` and `CLAUDE.md`.

## [1.15.0] — 2026-10-10

The previous release gave the remediation list an order and left the question of depth open. Those
are different questions, and a project can answer the first perfectly while failing on the second in
a way everybody recognises once it is named: the team that owns the pipeline takes Category 10 from
1 to 9 in a quarter — that being the work it already knows how to do — and Category 1 is still at 2.
Phase order permitted it. The average applauded it. Nothing a user touches got better, and no future
refactoring got safer, because what made it unsafe was never the pipeline.

So the framework now says how far as well as in what order. A project raises its floor, not its best
number: every scored category reaches the target of the band it is on before any category is taken
past it.

### Added

- **`standards/PROJECT_AUDIT_FRAMEWORK.md` § *How far to take a category before starting the next*.**
  The maturity minimums already in *Quick reference* — 4, 6, 7, 8 — are re-read as rungs rather than
  labels, and a project climbs them one at a time, stopping at the rung its own maturity requires.
  Band and phase compose in one direction only: the band decides which categories are in scope, the
  phase orders the ones that are. Which makes a phase complete *for a band* when its categories reach
  that band's target rather than when they reach 10 — so every phase reopens at the next rung, and
  the second pass is shorter than the first.
- **§ *What the band rule governs, and what it does not*.** It governs where the next unit of effort
  goes, tested by one question: does this change raise the lowest score? It does not forbid a category
  sitting above the band — scores are not a budget and nothing is lowered to level a profile — and it
  does not forbid free overshoot, because declining an afternoon's configuration to keep the profile
  flat is the rule worn as a costume. It is *paid* overshoot that waits. The exemptions are the four
  the phase order already names, pointed at rather than restated. Also handles the category that
  resists the ladder on principle: a framework two majors behind is upgraded or it is not, and there
  the band rule and the phase order agree, because Category 6 is Phase 4 and last regardless.
- **§ *Why the floor and the spread, and not the average*.** Across eleven categories, taking one of
  them from 6 to 10 and taking four of them from 5 to 6 are the same +0.36, and only the second is
  progress — so the average will reliably endorse the behaviour the band rule exists to stop. Report
  it, steer by the floor and the spread. Both are derived from the scores in `history.md` rather than
  stored beside them: a number derived from the same row twice eventually disagrees with itself, and
  the `C0` column is the standing reminder of what repairing a history file costs.
- **A band-and-phase headline for the audit**, in *Recording the order in the audit* — band target,
  phase, floor, spread, and the categories below target, in one line. Two audits apart it answers for
  the programme what the blocked-gap paragraph already answers for a single gap: a band target that
  has not moved in three audits is the finding, whatever the average did.

### Changed

- **The phase is read against the band target, not the maturity minimum.** An Established project
  with Category 4 at 5/10 and nothing lower is at band target 6 and leaves Phase 2 when 4, 7 and 10
  reach 6 — then re-enters Phase 2 at band 7. Previously the rule read the maturity minimum directly,
  which made every phase a single long pass and left no room for the ladder.
- **Step 3 of the evaluation procedure ranks inside the band and inside the phase.** The band selects
  the categories still short of target, the phase orders them, impact per unit of effort chooses among
  what is left. A top three leading with a category already at the band target is worse than one
  leading with blocked work: it reads as a plan, works as one, and leaves the project as fragile as it
  was.
- **The framework-replacement row of the gate table asks for the maturity minimum explicitly**, not
  merely the current band. It is the one piece of work the ladder does not let a project take early —
  too expensive to do twice, too hard to reverse once.
- **`/project-audit` § *Top actions* is band-aware.** A category already at the band target does not
  enter the ranking at all — not as a blocked entry, not as a footnote — unless it is the one-line
  configuration fix the standard allows out of order, which is labelled `out of order — one line` so
  the reader can see the call was deliberate. And the list does not reach past the band to reach three.
- **The project snapshot and the `--summary` closing lines carry band, phase, floor and spread**, all
  four computed from the summary table in the same report rather than from anything stored.
- **§ *Maturity target check* reports two lists** — the categories below the maturity minimum and the
  categories below the current band target. They differ whenever the project is more than one rung
  out, and the difference is the point: destination against this quarter's scope.
- **`.claude/audit-focus.md` ranks by distance below the band target**, not below the maturity
  minimum, so the write-time focus and the report's Top actions cannot point a project in two
  directions.
- **`INSTRUCTIONS.md` § *Closing a gap is a sequenced job, not a free choice*** gained the second
  half of the order, and the two carve-outs it already stated now say *in every phase and at every
  band*.

## [1.14.0] — 2026-10-10

Eleven categories told a project what was wrong with it and ranked the findings by impact per unit
of effort. Nothing told it what order to fix them in, and the ranking quietly implied there wasn't
one: the biggest number goes first. For most projects the biggest number is Category 2, and acting
on it means a large refactoring on a codebase whose test suite, by the same report, scores 5.

That is the sequence that makes a quality programme fail in a way the team reads as the framework's
fault. Six weeks of renaming and decomposing, a regression nobody can localise because thirty files
moved in one diff, and a conclusion that the audit costs more than it returns. The scores were
right. The order was the team's to invent, and the report gave them no reason to think it mattered.

So the framework now says it. Recorded intent and a working safety net are earned before any change
to existing code spends them, and the audit's recommendations are ranked inside that order rather
than across it.

### Added

- **`standards/PROJECT_AUDIT_FRAMEWORK.md` § *Remediation order*.** Five phases: stop the bleeding
  (Cat 8, and the parts of 9 and 10 where something is actively being lost), record the intent
  (Cat 0), build the net (Cat 4, 7, 10, plus the Cat 9 signals where the planned change alters
  runtime behaviour), change the code (Cat 1, 2, 3, 5), change the platform (Cat 6). Phase 4 is last
  because it invalidates more of the net than anything else and is the hardest change to reverse.
- **A rule for reading a project's phase off its own scores** — the earliest phase that still has a
  category below the minimum for the project's maturity. Not a judgement anybody has to defend: an
  Established project with Category 4 at 5/10 is in Phase 2 no matter how bad Category 2 looks, and
  it leaves Phase 2 on a date the score history can be asked for.
- **A gate scoped to the change, not to the project**, as a table of planned work against what must
  be true before it starts and how to check it. "We cannot refactor until Category 4 is 7/10" is the
  misreading that turns the order into an excuse, and the table exists to foreclose it: a team that
  covered one module on Monday has cleared the gate for that module on Tuesday and for nothing else.
  The project phase and the per-change gate are allowed to disagree — one reports, the other decides.
- **An answer to the standing objection — code that cannot be tested until it has been refactored.**
  Left unanswered the order is a sentence rather than a plan, and a team that accepts it has a
  principled reason to change nothing. A test does not have to be a good test to be a net: Phase 2
  asks for the ability to detect a regression, not a well-factored suite. So the net goes at the
  coarsest seam the code already has — the endpoint, the CLI command, the database state before and
  after, a golden file over a hundred real inputs — which requires the code to be callable rather
  than well designed, and is written to be deleted once real tests can replace it. With one
  condition that is the whole point of the technique: it is captured before the refactoring, never
  after.
- **The mass rename, written up as the case the order exists for.** Translating identifiers into the
  declared domain language looks like the safest item on any remediation list and is close to the
  opposite: a uniform diff nobody reviews past the first page, a blast radius of the whole tree, and
  a compiler that does not see string-keyed container lookups, serialized payloads already in a
  queue, ORM mappings inferred from a property name, catalog keys, reflection, or a column a
  migration will not rename with the property. It also carries the one Phase 1 prerequisite the rest
  of Phase 3 does not: the term that most needs translating is the one whose meaning is least
  recoverable from the code, and `Fattura` → `Invoice` is wrong twice if the entity is a credit note.
- **What the order does not gate, stated where it cannot be missed** — new code is written to the
  full standard in every phase, every category is scored at its real value in every phase, Phase 0
  bypasses everything, and a fix that is one line of configuration and cannot regress silently is
  taken out of order and said to have been. Both of the first two are routine misreadings, and both
  invert the section if left implicit.
- **`INSTRUCTIONS.md` § *Closing a gap is a sequenced job, not a free choice*** — a pointer, so the
  order applies in the sessions where quality work actually starts. *"Let's clean this file up"* is
  Phase 3 work and meets the same gate as the version of it that came out of a report.

### Changed

- **Step 3 of the evaluation procedure ranks inside a phase, not across phases.** Impact per unit of
  effort still chooses among the improvements available; it no longer chooses which are available.
- **`/project-audit` § *Top actions* is phase-aware.** A gap in a later phase leaves the ranking and
  appears once below it under `Blocked by an earlier phase`, with its prerequisite and that
  prerequisite's effort — the project still sees its biggest problem, it just stops seeing it
  presented as this quarter's work. Where the current phase yields fewer than three actions the list
  is shorter than three; reaching into the next phase to reach a round number is what this change is
  against.
- **The project snapshot carries the remediation phase**, and each `--deep` remediation entry carries
  its own phase and, when that is later than the project's, the prerequisite holding it.

## [1.13.0] — 2026-10-10

Category 9 measured eight ways a system can produce signals and no way of reaching them. A project
could score well across structured logging, error tracking, metrics and retention while the only
person who could open the dashboard was on holiday, and the audit would have nothing to say about
it — the signals were all there, behind a door with one key. The gap showed up most clearly in the
sessions that follow an audit: asked to diagnose a production problem, Claude was reading a log
excerpt somebody had pasted, which is the one piece of the log already filtered by what that person
suspected.

The same blind spot had a second half. Nothing in eleven categories asked whether the data survives
the loss of the machine holding it: 9.7 scored what a project *deletes* on a schedule, 10.6 scored
undoing a bad deploy, and a project with no backup at all could pass both.

So Category 9 gains the two questions that come after "is it healthy?" — can anyone reach it, and
what comes back if it is gone — and with them the rules for using an access the project chooses to
open, and a command for rehearsing the recovery it claims to have.

### Added

- **Subcriteria 9.9 — Operational access to the running system.** Three questions, scored as the
  weakest: do the production mechanisms exist (logs readable off the machine, a metrics dashboard,
  an uptime check that alerts someone, process and deploy state), can more than one person reach
  each of them today without asking, and can the agent working on the code reach the read-only half
  directly. The bands run from "the answer to *how do I see the logs?* is a person's name" through
  precarious single-holder access, documented human-only access, read-only reach from the
  development loop, and at 9–10 an agent that can carry out *named* operational procedures with a
  documented blast radius and an attributable trail.
- **A ceiling condition, so the criterion cannot be gamed by granting more.** The top of the scale
  is access that is scoped, attributable and read-first. An unrestricted `root` key, a shared admin
  login, or a production token committed next to the code scores **below** having no agent access at
  all: it is reach the project cannot bound, attribute or revoke, which is what 8.x and 10.7 already
  say from their own side.
- **A cap that ties 9.9 to the rest of the category.** Access cannot outrun the signals behind it —
  where 9.1, 9.2 and 9.4 are low, 9.9 is capped at 6. A shell on a box whose application logs are
  unstructured `echo` statements gives the operator a terminal, not an answer.
- **A `## Production access` block in `templates/PROJECT_AUDIT_FRAMEWORK.md`** — the declaration
  9.9 is scored against: every signal, the path that reaches it, which paths a session may use,
  which actions mutate, and where the credentials come from. Read-only is its default.
- **`INSTRUCTIONS.md` § *Production access*** — the operating rules for that grant, in the same
  shape as the database ones: only declared paths, read-only unless the section names the action
  *and* it is approved in the moment, say what you are about to run before running it, never widen
  the grant to get an answer, never print a credential, and never let raw production log lines into
  the repository or an evidence bundle. A credential that happens to work is not a grant — finding
  one is a 9.9 finding to report.
- **Subcriteria 9.10 — Disaster recovery.** It starts from the list most projects have never
  written: *what, if it disappeared tonight, could not be rebuilt from the repository?* — database,
  uploads, secrets, DNS zone, certificates, the hand-configured parts of a host, the provider
  account. Every item maps to a backup job or is declared accepted loss; the gap between those two
  lists is the first finding. Then separation (a copy sharing the fate of its original is not a
  backup), RPO and RTO as stated numbers rather than inherited defaults, a failed backup that alerts
  instead of failing silently, and a runbook a second person can execute without the author —
  including where the restore credentials come from, since a backup encrypted with a key that lived
  only inside the lost system is discovered exactly once.
- **An evidence ladder, because the hard half of 9.10 is what anyone can *know*.** A restore that
  happened and left nothing behind is indistinguishable from one that did not — and not only to an
  auditor: the team has no duration to compare the next drill against and nothing to alert on. So
  the evidence is scored by what produced it, as ceilings applied after the properties above: never
  exercised **5**; somebody remembers doing it **6**; a receipt written by hand after the fact **6**,
  because a claim in the shape of evidence is still a claim; a receipt emitted by a committed drill
  script **8**; that script run by a scheduler or CI, recorded automatically and alerting on failure,
  **10**. The step from 8 to 10 is not ceremony — a drill that runs because somebody remembered
  answers "did it work in June", and an RTO is only ever written in the present tense.
- **`exit 0` is not a restored system**, stated as a scoring rule: an empty backup restores perfectly
  and reports success. A drill counts where it asserts — row counts against the recorded source, a
  canary record, a checksum over restored files, the application booting with its health endpoint
  green, the smoke tests of 10.8 against the restored environment. Without assertions what was
  measured is the restore *command*, and the receipt's outcome is `unverified` rather than `pass`.
- **What an audit can and cannot verify, said out loud.** A receipt can be typed by hand and no
  amount of reading reveals it. What an audit can do is check it against records written by a
  different hand — the artefact exists in the store, the duration appears in a CI run log, the commit
  dates from when it claims, the drill script existed in the repository on that date, the receipt's
  shape matches what the script emits. Consistency across independent records raises the cost of a
  fiction without removing the possibility, and a report says which of the two it is looking at.
- **`/dr-drill`** — a new command that rehearses the recovery 9.10 scores. It runs **the project's
  committed drill script** against the disposable target declared in the new
  `## Disaster recovery drill` section, and transcribes what that run reported. It refuses to start
  without the declaration (a restore improvised against an undeclared target is the accident the
  drill exists to rehearse for), stops if the target overlaps any production identifier, keeps the
  backup store read-only, destroys the target afterwards, and writes a fixed-shape receipt — backup
  age against RPO, duration against RTO, every assertion with its result, deviations, and what the
  drill did *not* cover. `--dry-run` validates the setup without restoring.
- **Two rules inside that command carry most of its value.** It never repairs a failing run to make
  the drill pass: a drill that fails in rehearsal has done its job, and patching around the failure
  converts the one useful output into a formality. And it never writes a receipt for a run that did
  not happen, never edits a result, never fills a field by inference — writing one by hand cannot
  raise the score, it only destroys the chance of ever measuring the real one.

### Changed

- **`/project-audit` step 1.5 is now "Capture declared access"**, with a Database block (unchanged,
  for 7.9 and 9.8) and a Production block for 9.9. The production block records the declaration
  without its credentials, checks that each read-only path still *resolves* — a runbook entry
  pointing at a decommissioned host is the finding — and takes at most one small redacted read per
  path as proof the signal is live. An audit observes production; it never operates it, not even
  through an action the section allow-lists.
- **Phase 1 preconditions state whether a production path was declared and resolved**, next to the
  database line, so the Category 9 agent knows before it starts whether 9.9 has a human-only ceiling.
- **Category 9's framing gains its third and fourth questions** — *can whoever is on call reach those
  signals at 3am without waking a second person to get in?*, and *if the machine or the data is not
  there tomorrow morning, what comes back, and how long does that take?*
- **Two boundaries are now written down where they were previously assumed.** 10.6 carries a line
  saying rollback is for a deployment that went wrong while the data and the machine are still
  there, and that losing either is 9.10. And 9.10 names its tie to 9.7: retention bounds what is
  kept, recovery guarantees it can come back — a purge job with no backup and a backup that has
  never restored are the same data loss at different speeds.
- **`/project-audit` preconditions state what the repository cannot rebuild**, next to the database
  and production-path lines. Naming production data, uploads, secrets, DNS and hand-configured
  infrastructure before the agents launch is what stops the Category 9 agent from scoring the
  database alone and calling it disaster recovery.

### Notes

- **No new precondition.** Precondition 4 exists because without a database, 7.9 and 9.8 are scored
  from intent; 9.9 and 9.10 are the opposite case — the absence of access, and the absence of a
  drill, *are* the score, so a precondition would only have restated the criteria.
- **The drill is a script, and the agent is not the drill.** `/dr-drill` runs what the repository
  committed rather than composing a restore from what it can infer. A restore improvised afresh each
  time is not comparable with the last one, cannot be handed to a person at 3am, and cannot be moved
  into CI — and CI running the *same script* is what takes 9.10 from 8 to 10. The agent makes the
  rehearsal cheap enough to actually perform; it does not make the rehearsal.
- **No write-time principle for either.** `CODING_STANDARDS.md` is about what gets written, and
  nothing in it grants an SSH account or takes a backup. Principle 16 keeps its existing mapping,
  and both 9.9 and 9.10 are recorded in the *Criteria with no write-time principle* table with their
  reason — they are established by whoever operates the system, and no change to a feature opens an
  access path or restores a database.

### Migration

**One step is required, and it is the usual one.** This release adds a command, and commands are
*copies* in `.claude/commands/` rather than links into the submodule — so a submodule bumped on its
own leaves the project on 1.13.0 without `/dr-drill`:

```bash
cd .claude/framework && git fetch --tags && git checkout v1.13.0 && cd ../..
bash .claude/framework/scripts/init-project.sh      # installs the new command
bash .claude/framework/scripts/check-install.sh     # read-only: confirms it landed
```

`check-install.sh` reports the command as missing until the installer has run. That is the normal
path for every release that adds one, not a special case for this one.

**Nothing else is required, and no file of yours needs editing.** Both new subcriteria score without
any change to the project: the next `/project-audit` reads 9.9 from what a person can reach and 9.10
from the backup configuration, the runbook, and whether a restore has ever happened. Expect C9 to
*drop* on that audit — it is measuring two more things, not measuring worse. `docs/audits/history.md`
needs no migration either: no category was added, so no column changes, and prior C9 scores stay as
they were measured.

**Then two optional declarations, which decide how far 9.9 and 9.10 can be scored.** A project
installing for the first time gets both blocks, with a worked example each, inside the
`.claude/PROJECT_AUDIT_FRAMEWORK.md` the installer scaffolds. An *existing* project does not: that
file belongs to the project, so `init-project.sh` leaves it exactly as it found it — copy the two
blocks out of `.claude/framework/templates/PROJECT_AUDIT_FRAMEWORK.md` by hand. Both are worth
reading before writing:

- **`## Production access`** — the signals a session may reach and how. Without it, no production
  path is open and 9.9 is scored on human reach alone, which caps it at 6. Declare only what you
  mean to grant: the section *is* the boundary, nothing outside it is available to a session, and
  read-only is its default. A project that genuinely has no reachable production is not failing this
  criterion by declining to write the block — it is recording where it stands.
- **`## Disaster recovery drill`** — the committed script, the disposable target, the assertions, the
  receipts directory, and the RPO/RTO the drill is measured against. It is needed only to *run*
  `/dr-drill`; the command refuses to start without it rather than improvising a restore. Writing the
  script is the real work here, and it is also the step that moves 9.10 off the untested ceiling of
  5: run it once by hand, keep the receipt, then move the same script into CI for the top band.

**If you are upgrading from before 1.12.0**, read that entry too — Category 0 was added there, and
`history.md` does gain a column.

## [1.12.1] — 2026-09-08

The developer profile is one file per machine, at `~/.claude/context/user_profile.md`, shared by
every project that installs this framework. The code already behaved that way — `init-project.sh`
and `INSTRUCTIONS.md` both suggest `/init-profile` only when the file is absent — but nothing said
so, and two places implied the opposite: the README opened its setup section with "the first time
you open Claude Code in a project with this framework", and the installer, having found a profile,
said nothing at all. A developer installing their second project read a per-project step and silence
where the previous run had printed a warning.

### Fixed

- **`init-project.sh` reports a profile it found**, instead of only a profile it missed —
  `✓ Developer profile found … — reused as is`, with the reason: it is per machine, so the project
  needs no profile setup. The missing-profile warning and the optional next step are unchanged.
- **The README's setup section is scoped to the machine, not the project** — once per machine, and
  explicitly nothing to do when installing into a new project on a machine that already has one.
- **`/init-profile` says the same thing when a profile exists**, before offering to overwrite it. The
  command was already safe; the message read as though a new project were a reason to make a second
  profile.
- **`INSTRUCTIONS.md` now has a branch for a profile that exists but has no `next_review_date`.**
  1.9.1 fixed the template that wrote the row under the wrong name; profiles created before it still
  carry `Next review`, and the session-start check looked up a field that was not there and fell
  through to nothing. An absent field now reads as a review due, and the rule that covers the whole
  class is stated with it: an existing profile file is never a reason to suggest `/init-profile`,
  whatever shape its contents are in.
- **`/competency-review` renames a legacy `Next review` row** as it updates the date, so a profile
  that predates 1.9.1 stops being invisible to the session-start check after one review.

## [1.12.0] — 2026-09-07

Ten categories measured how well a thing was built. None of them could say whether it was the thing
the team meant to build, or whether the half that was missing was missing on purpose — and that
second question changes the severity of findings in every other category. A missing authorisation
check is a Category 8 defect if the feature shipped and a non-finding if it belongs to a spec still
marked `todo`; with no product documentation in the repository, an audit cannot tell those apart and
scores them the same.

So the framework gains a category at the top rather than at the end. Category **0** is the frame the
other ten are scored inside: what the product is for, what is planned, and which of it exists.

### Added

- **Category 0 — Product Strategy & Delivery Documentation**, seven subcriteria: product context
  written down (0.1), a discoverable documentation home (0.2), an implementation spec for work in
  flight (0.3), a status marker on every implementation document (0.4), that marker being *true*
  (0.5), design artifacts versioned with the code (0.6), and ADRs (0.7).
- **The status marker as a scored, machine-readable field.** 0.4 asks for a fixed location and a
  **closed** vocabulary — `todo`, `in-progress`, `implemented`, `superseded`, `abandoned` — because
  the point of the field is that `grep -rl 'status: todo' docs/product/` answers *what is left* for
  the whole team without opening a file. Status in prose, or conveyed by which folder a file sits in,
  scores 3–4: it is not aggregatable, and a marker updated only by moving a file is a marker nobody
  updates. Partial delivery is marked per requirement — `in-progress` that does not say which half is
  a status nobody can act on.
- **0.5, the drift half.** A marker that is not maintained is worse than none: it is a claim, and
  readers act on claims. It scores whether status moves in the same change as the code, whether an
  `implemented` spec names what implements it, and whether anything checks mechanically.
- **Principle 23 — "A spec is delivered when its status says so."** Principle 22 put a documentation
  correction in the change that caused it; 23 is the same rule for what a document says about
  *itself*. Look for the spec before building, treat a contradiction between spec and intended
  implementation as a finding rather than something to route around, move the marker in the same
  diff, and say you moved it. Without a write-time half, the markers would be discovered only by an
  audit and maintained by nobody — the exact failure 7.10 describes for quality checks that rely on
  someone remembering.
- **A once-per-session flag for a missing documentation home**, in `INSTRUCTIONS.md` — fired at the
  first substantial piece of work rather than at session start, because a warning that arrives before
  there is anything to document is noise. It flags and carries on; it never scaffolds a `docs/` tree
  unasked, since an empty documentation directory created by an agent is a worse signal than none.
- **"Adopting this category on an existing project"** — Category 0's remediation path, because a
  criterion that scores a past nobody can change is one teams correctly learn to ignore. It names the
  trap first: reconstructing the missing specs from the code scores *below* the gap it fills, since
  documentation reverse-engineered from an implementation cannot contradict that implementation, and
  a spec that cannot disagree with the code is the one thing a spec is not. The path runs forward —
  product context first, then the home, then specs from the next unit of work — with a bounded
  backfill of exactly two things: ADRs for decisions that still constrain the code *and* that someone
  still remembers the reasoning for, and the design artifacts that are currently live.
- **The adoption provision in scoring.** 0.3, 0.4 and 0.5 are scored against the units of delivery
  **since the practice started**, not against the project's whole history — the same shape as
  measuring coverage on changed lines rather than on a legacy tree. It is available on two conditions:
  the adoption date is a commit in the repository rather than a claim, and what gets scored is the
  distance between shipping and specifying, so a project that created a directory in March and shipped
  eleven undocumented features has adopted nothing. Three months of the practice held honestly scores
  8; five years of documents nobody updates scores 4.
- **A Category 0 block in `templates/PROJECT_AUDIT_FRAMEWORK.md`** for projects to declare their own
  documentation home, spec format and status vocabulary — the standard's example vocabulary is an
  example, and 0.4 scores consistency against the project's declared set, not against ours.

### Changed

- **ADRs moved from 10.15 to 0.7.** A decision record is a planning and design artifact; it was in
  Category 10 because that is where version-control discipline lived, not because a pipeline
  measures it. The criterion text is unchanged apart from two ties it can now make: an ADR is
  explicitly *not* an implementation spec (0.3), and a superseded ADR uses the same `superseded`
  marker 0.4 defines, so one vocabulary covers every document in the tree. Category 10 carries a
  one-line pointer at 0.7 — enough to find it, not enough to become a second copy of it.
- **`/project-audit` runs eleven agents**, slices `cat-0.md` through `cat-10.md`, and captures the
  documentation tree and every `status:` marker into the *shared* bundle rather than into Category 0's
  slice alone. That placement is the point: an omission inside a spec marked `todo` is unbuilt work
  rather than a defect, and all eleven agents need to know that before they score one.
- **Evaluation order.** Step 1 of the standard now reads the product documentation first, before the
  code — it is the only account of intent the code cannot supply. Step 3 ranks improvements against
  the product context where one exists, and says so explicitly when one does not: "impact" without it
  is an engineering judgement presented as a product one.
- **7.10 and 0.5 divide the drift problem explicitly.** 7.10 owns what a document asserts about the
  *system* — paths, commands, analyser levels; 0.5 owns what it asserts about its own *delivery
  state*. Both files now say so, because the overlap is exactly where a duplicate criterion would
  have grown.

### Migration

Nothing in a consumer project needs editing for the framework to keep working. Two things are worth
knowing:

- **`docs/audits/history.md` gains a `C0` column.** `/project-audit` adds it to an existing file and
  fills prior rows with `—`, because those audits did not measure it and a blank that reads as a
  score would put a fiction into the trend. It does **not** recompute their `Avg`: that number was
  correct for what was scored at the time, and rewriting history to look consistent is how a trend
  stops being evidence.
- **A `.claude/PROJECT_AUDIT_FRAMEWORK.md` that specialises ADRs under `## Category 10`** should move
  that section to `## Category 0`. Nothing breaks if it does not — the specialization is simply
  appended to a slice whose criteria no longer mention ADRs, so the Category 0 agent scores 0.7
  against the global standard alone.
- **Category 10 scores are not comparable across this version.** It lost a subcriteria, so a movement
  arrow on C10 in the next audit is measuring a different category, not a change in the project.

## [1.11.0] — 2026-09-05

`/project-audit` had one output shape: every subcriteria, every category, every time. That is the
right depth at a decision point and far too much for the check you run before a sprint, so the
command was answering one question well and two questions badly.

### Added

- **A detail level on `/project-audit`** — `--summary`, `--standard` (the default, unchanged
  behaviour) and `--deep`, in any order alongside the existing directory scope. `--summary` prints
  the snapshot, the score movement and the summary table, then stops. `--deep` adds a remediation
  section covering *every* subcriteria the agents recorded a gap against, worst score first, each
  expanded into where it is, why it matters in this project, what to change and the effort.
- **An argument grammar and its validation.** `$ARGUMENTS` used to be passed straight to `find` as
  a scope; it is now parsed against an allow-list — three level literals, one directory that must
  exist inside the project root and contain no `..`. An unrecognised `--flag`, a second level or a
  second scope stops the audit and says which token was not understood, rather than quietly running
  a different audit than the one requested.

### Changed

- **The summary table now precedes the per-category detail** in the report. The verdict is what a
  reader wants first, and it is what makes stopping at `--summary` a whole report rather than one
  with its conclusion cut off.

### Notes

- **The level never changes a score.** Phases 1 and 2 are identical at all three: the same evidence
  bundle, the same ten agents, the same anchors. Making `--summary` cheaper by scoring less would
  have put incomparable numbers into `docs/audits/history.md` and reported the difference as
  progress. Scope remains the only lever on what an audit costs.
- **The written report never shrinks.** At `--summary` the full standard report still goes to
  `docs/audits/`, and only the printing is short — the agents' evidence has already been paid for.
  `history.md` is unchanged and needs no migration; `.claude/audit-focus.md` is still regenerated at
  every level.

## [1.10.0] — 2026-09-05

Adds the other half of the language question. Since 1.2.0 the framework has had an opinion about the
language of *code* and said, in three separate files, that the language of *output* was somebody
else's problem. That gap let a project score 10/10 on 2.8 with every label, PDF heading and email
body typed straight into a template — untranslatable, and expensive to discover late.

### Added

- **Subcriteria 2.9 — Translatability of user-facing text.** Every string a person reads goes
  through a translation mechanism, and the mechanism reaches every surface: templates, PDFs, mail,
  CLI, and validation messages that reach a screen. English is the source text and the fallback that
  never fails. The failure mode it is built to catch is the pocket — a translated web UI whose emails
  and CLI output are hardcoded — so it is scored by visiting every surface, not by sampling.
- **Subcriteria 2.10 — Locale coverage.** The project declares which languages it serves and the
  catalogs are complete for every one of them. A project whose domain is defined by another
  country's law is serving people who work in that language: a codebase built on
  `FatturaElettronica` has Italian users, and English-only is a coverage gap rather than a decision.
- **A `User-facing text` section in the project `CODING_STANDARDS.md` template** — the declaration:
  the mechanism, the catalogs, the completeness check, and one row per required locale with the
  reason it is required. Delete it outright if the project produces no human-readable output.
- **A `User-facing language` block in the developer profile** (`/init-profile`, `/competency-review`).
  It is the one field in that file which is not a competency level, and its disclaimer lives inside
  the profile rather than in `INSTRUCTIONS.md`, because the profile is global and gets read in
  projects where this framework is not installed. It does not change the language of code, comments,
  documents or replies.
- **Principle 20 gains its third clause** — *the product speaks the user's* — and now maps to 2.8,
  2.9 and 2.10. Wrap the string when you write it: a user-facing string enters the catalog in the
  change that introduces it, in every declared locale, never "for now".
- **An i18n row in the Appendix and in the mobile notes** — the mechanism and, more importantly, the
  command that lists the missing keys, per stack. A mechanism with no way to enumerate what is
  missing cannot be shown to be complete.

### Fixed

- The N/A rule was written about categories only, while three subcriteria already carried their own
  scope lines and `/project-audit` already said "for a subcriteria or the whole category". Stated
  once, where the rule lives.
- Step 1's reading list did not include the translation catalogs, which 2.9 and 2.10 cannot be
  scored without.
- `/init-profile` wrote a `Next review` row while `INSTRUCTIONS.md` and `/competency-review` read a
  `next_review_date` field. Three files named a field the template never created; the template now
  creates it. Pre-existing, and fixed here because this change edits all four.

### Why the developer's language seeds the score but never moves it

The requirement was that catalogs be populated in the language the developer works in, and the
obvious implementation — read the language, expect a catalog for it — would have made the score
depend on which laptop ran the audit. `docs/audits/history.md` records a trend; a number that moves
because someone else ran the same audit does not just differ, it poisons the delta permanently, in a
committed file. So the profile acts one step earlier than scoring: a language in real use and missing
from the declared set is a finding about the *declaration*, and the declaration — which lives in the
repository, where everyone sees it — is what 2.10 measures. The catalogs still get populated; the
route runs through the artefact the team shares.

## [1.9.1] — 2026-09-03

The adversarial pass was re-run against the 1.9.0 redesign. It broke two of the three targets again.
Both findings were mine: one was the same class one level up, the other a construction bug in the
helper 1.9.0 introduced.

### Fixed — the guard validated the route, not the target

1.9.0 secured a symlinked `.claude/framework` and never dereferenced **`.claude` itself**. Every
write and delete is issued as the string `"$PROJECT_ROOT/.claude/…"`, and the filesystem follows a
symlink in the middle of it, so

```text
ln -s ../victim/.claude .claude
```

let the guard pass, `PROJECT_ROOT` point at the operator's own project, and `uninstall.sh` delete
the victim's commands and marker — while `announce_target` printed the *reassuring, wrong* answer.
The safety net added in 1.9.0 misreported in precisely the scenario it existed for.

Now the target is checked rather than the route: `.claude` must be a real directory whose physical
parent is the physical project root, and both mutating scripts refuse otherwise with exit 2.
`announce_target` gained a **`Writing:`** row naming the directory actually being written to, with
its resolved form when they differ — the line an operator can verify by eye.

### Fixed — sanitize_display was a deny-list, and an incomplete one

The 1.9.0 filter removed a curated set of control bytes. Two holes, both demonstrated end to end:

- The range `\000-\010\013\014\016-\037` **skips 0x0D**, so CR survived and could return the
  cursor to column 0 and overwrite the start of its own line.
- Every byte ≥ 0x80 survived, which carries C1 controls encoded as UTF-8 — U+009B is the CSI
  introducer — and the bidirectional overrides, where U+202E reverses the text an operator reads.

Enumerating what is dangerous is a game lost one codepoint at a time, so it is now an **allow-list**:
tab and printable ASCII, everything else dropped. The cost is stated rather than hidden — a commit
subject in Italian or Japanese prints with those characters missing, which is a far smaller problem
than a forged line, and `CHANGELOG.md` remains the authoritative text because it is read as a file
rather than echoed into a terminal.

- **`read_marker_version` was not sanitised**, sitting directly beside `read_framework_version`,
  which was. A committed `.framework-version` carrying ESC injected a forged green
  "✓ Install verified by vendor" line into the operator's terminal. The marker is repository
  content, so it is exactly as remote as a commit subject.

### Fixed — one more hook re-rooting

A symlinked `.claude/hooks` moved the project boundary two levels above the link target, widening
confinement for every later edit — the same root-relocation risk closed for `GIT_WORK_TREE` in
1.9.0, through a different door. Refused, and added to the enumerated list rather than left implicit.

### Held under attack

The tag allowlist held at its core: the `case` form rejects the multi-line value that defeated
`grep -qE`. Hook confinement held against every payload-driven attack — absolute paths, `..`
traversal, mid-path and final-component symlinks, disagreeing payload fields, a directory or a
trailing slash as the path. `CDPATH`, `PWD`/`OLDPWD` spoofing, crafted `$0` and `..` in the
invocation path were all tried against the new guard and all failed. The hardlink and
check-then-use cases behave exactly as documented — the adversarial pass confirmed the comment does
not overclaim.

### A note on where the defects live

Every serious finding across four adversarial rounds has been in the same place: a shell script
computing a filesystem path and then mutating it. `uninstall.sh` is the only destructive component
in the framework, and it has produced the two data-loss findings. That is an observation about the
design, not about any one bug, and it is recorded here rather than acted on.

## [1.9.0] — 2026-09-03

An adversarial pass — one agent told to break three fixes rather than score them — broke all three,
with reproductions. One was destructive, and the cause was a fix from the previous release.

### Fixed — the guard was designed wrong, not implemented wrong

`pwd -P` was added in 1.8.1 to reconcile a macOS logical/physical path mismatch. It answers *where
does this script live*, and the guard silently used it for *which project asked*. With
`.claude/framework` as a symlink the guard therefore passed **for the wrong project**:

- **Two projects sharing one framework checkout.** `uninstall.sh` run from project B deleted project
  A's commands, both specialization files, the marker, the `@`-include, and `.gitattributes`
  outright. Project B was untouched, and the operator saw ten green checkmarks in project B's
  terminal.
- **A supply-chain vector.** Git stores symlinks, and a relative one may escape the repository. A
  repository containing a single committed `.claude/framework -> ../../victim/.claude/framework`
  plus a README carrying the framework's own documented install line was enough: clone it as a
  sibling, follow the README, and the neighbouring project is stripped. No attacker code runs — the
  scripts are the victim's own, only the path is redirected.
- **And the mirror image:** the legitimate "one shared clone symlinked into each project" layout was
  *refused*, with a message contradicting what the operator had typed.

The fix is a redesign, in the new `scripts/lib/framework-paths.sh`. The project is derived from the
**logical** invocation path — `cd` without `-P` keeps the path as typed, symlink and all, which is
precisely "who asked" — and the physical form is kept separately for the one comparison that needs
it, against `git rev-parse`, which resolves. Both mutating scripts now **print the project and
framework directories before touching anything**, with the symlink target shown when there is one:
that is what turns a redirection from silent into obvious. All three cases are regression-tested,
including the layout that must be *accepted*.

### Fixed — the paste vector the allowlist did not cover

The 1.8.1 tag allowlist held under attack, but its stated purpose — nothing remote reaches the
operator's terminal unfiltered — was still open through two other channels, neither bounded by
git's refname rules:

- **Commit subjects.** A subject carrying `\033[1A\033[2K` moves the cursor up and erases the line
  the script just printed, forging a line directly above the block of four commands the operator is
  told to paste.
- **The `VERSION` file**, which is submodule content and therefore equally remote. `tr -d
  '[:space:]'` does not remove `ESC`, and the value was then written verbatim into
  `.claude/.framework-version`, a file Claude reads.

Every remote-derived display string now passes through `sanitize_display`. Verified: zero `ESC`
bytes reach the terminal from either channel.

- **The allowlist was also not self-sufficient.** `grep -qE` matches if *any line* matches, so a
  value containing a newline followed by `v1.0.0` passed. Git's refname rules forbid newlines, which
  meant the check was safe by git's construction rather than its own — and would have become an
  injection primitive the moment the same helper met a value git does not bound. Replaced by a
  `case` test that rejects the multi-line form.

### Fixed — the hook

- **`GIT_WORK_TREE` widened the confinement.** `git rev-parse --show-toplevel` obeys the
  environment, so a variable reachable through a repository's own settings, direnv, or the user's
  shell could move the project root up to `$HOME`. The hook now derives its project root from its
  own installed location and does not consult git at all.
- **The jq and python3 branches disagreed.** The python branch guarded each container with
  `isinstance`; the jq filter did not, so a payload whose `tool_response` was a string aborted the
  whole filter before the fallback and **silently suppressed every check on a jq machine** while
  running normally on a python one. Same hook, two behaviours, and `--selftest` could not surface it.
- The `php-cs-fixer` example contradicted its own instruction, passing `--quiet` after `--` so the
  formatter read it as a second path.
- **Two residual bypasses are now documented rather than implied away**: a hardlink to a file
  outside the project, and a swap between the check and the tool's use of the path — measured at 11%
  and 28% hit rates by a plain local racer. Neither is closable with path-string checks in bash. The
  comment said `pwd -P` "handles the other half"; it does not, and now says so.
- `report()` is documented as what it is: a channel into the model's context. A linter quotes the
  source it read, so passing tool output through sends file content into the conversation.

### Changed — the duplication the last re-audit measured

Category 2's `2.3` had gone from 11 duplicated-knowledge sites to 16, the path-derivation preamble
from 2 copies to 5, and the consumer-install guard from 2 to 4 *with two divergent messages for the
same rule*. `scripts/lib/framework-paths.sh` now holds the guard, the git-repo check, the version
readers, the tag validator and the sanitiser — one message, one implementation. There was no
`source` statement anywhere in the corpus before this, so the obvious fix had been architecturally
unavailable rather than merely deferred.

`shellcheck` runs with `-x` so the sourced library is followed and linted too.

### Also fixed

- A missing library now produces a diagnosis and exit 2 rather than `unbound variable`.
- The marker read takes `head -1`, so a hand-edited file with two `version=` lines cannot yield a
  multi-line value that is then compared and echoed.
- A comment in `check-updates.sh` described a `sed` hazard while the code beneath it was `awk` — a
  comment that outlived its code, in the release that added it.

### On the shape of this release

Three consecutive releases fixed a defect and introduced another; this one fixes a defect introduced
by the last. The pattern was not bad luck: the guard could not work, because inferring which project
invoked a script from that script's resolved location is impossible when the location can be a
symlink. The lesson recorded here is the one the framework already states as principle 9 — when a
fix produces the next symptom, the design is the defect.

## [1.8.1] — 2026-09-03

A scoped re-audit of the four categories 1.8.0 touched. Three moved — Observability 7→8, Tooling
7→8, Testing 6→7 — and **Security did not**, because the previous release fixed the instance and
left the root: the same remote-controlled tag name still reached `git log` argv and the operator's
clipboard, eight lines below its own fix. That is principle 9 failing in the release that shipped
it, and this release fixes the root.

### Fixed — security, at the point of capture

- **Tag names are now allowlisted where they are read**, not sanitised where they are used.
  `check-updates.sh` filters both `CURRENT_TAG` and `LATEST_TAG` through `^v[0-9]+\.[0-9]+\.[0-9]+$`
  at capture, so a value that is not a well-formed release tag never enters the script. That closes
  all three sinks at once — the `sed` address 1.8.0 patched, the `git log` argv position it did not
  (a tag named `--output=<path>` is a valid refname and git parses it as an option, giving an
  attacker-chosen file write with attacker-influenced content), and the copy-pasteable commands the
  script prints, where `';id>…;'` closed the quoting. Case 28 creates both hostile tags upstream and
  asserts nothing is executed and nothing is echoed.
- **The hook's containment check was bypassable by symlinks.** It resolved the dirname without `-P`,
  so a symlinked directory inside the tree and a symlinked file both passed and reached the
  dispatch — inert only because every check ships commented out. Symlinks are now refused outright,
  and `pwd -P` handles symlinked directories.
- **`qa.sh` reintroduced two classes 1.8.0 had just fixed elsewhere**, in the script written to
  consolidate the gate: `cd "$(git rev-parse --show-toplevel)" || exit 2` is dead code because
  `cd ""` succeeds, so outside a git repo it ran the whole gate in the wrong directory and exited 1
  instead of 2; and it parsed no arguments, so `qa.sh --dry-run` ran everything and exited 0.

### Fixed — a portability defect the new tests exposed

- **All five scripts compared a logical path against a physical one.** `cd … && pwd` keeps the
  logical form while `git rev-parse` returns the resolved one, so on macOS any project reached
  through a symlink — `/tmp`, `/var/folders`, a symlinked home — failed the "is this a consumer
  install" guard and the scripts refused to work in a perfectly valid checkout. Now `cd -P` /
  `pwd -P` throughout, and the git side normalised too. Found by a sandbox test, not by reading.

### Fixed — legibility

- `check-install.sh` exited 1 under a banner reading `❌ Cannot verify` while its own header
  reserves 2 for "cannot tell". Now 2, and case 16 asserts it.
- The `missing:`/`differs:` detail lines printed before the finding they belong to, reading as
  continuation of the previous one. Collected and printed after it.
- `init-project.sh` and `uninstall.sh` document their exit codes, and a bad flag exits 2 everywhere
  rather than 1 in one script and 2 in the other three.
- The hook now reports when a parser exists but the payload is unreadable — previously it exited 0
  in silence, the same failure as having no parser, which 1.8.0 fixed only for the parser-absent half.

### Fixed — two tests of my own that could not fail

- **Case 22 asserted how many paths the gate counted, never that it caught a broken one** — a
  vacuous pass inside the case written to kill vacuous passes. It now injects three real defects (a
  dangling framework path, a retired command, a `VERSION`/`CHANGELOG` mismatch) and requires a
  failure for each. Its retired-command literal is assembled at runtime, because written out it
  would be caught by the very check it asserts.
- **Case 20 had a fallback arm that passed with a different message**, so it passed either way. The
  arm is gone.
- Case 28 was itself vacuous on first run: git refuses a refname containing `..` or a space, so
  neither hostile tag was created and every assertion passed against an attack that was not there.
  It now asserts the tags exist before asserting they are harmless.

### Added

- **A real submodule fixture.** `check-updates.sh` was covered for 2 branches of ~19 — measured by
  execution trace, not by reading — so everything from the fetch onwards was unreachable, including
  1.8.0's security fix, which shipped with no test. `new_submodule_project()` stands up a local
  upstream with tags and a consumer with a genuine git submodule, and case 28 exercises the upstream
  half through it.
- Cases 23–27 close the mutants the re-audit found surviving: a project's `.gitattributes` appended
  rather than replaced on install, a project-owned file in `.claude/hooks/` surviving uninstall, a
  legacy include not on its own line reported rather than announced as migrated, both mutating
  scripts refusing a non-git directory with a reason, and the hook speaking when it has no parser.
- **Check 9 — gate composition.** `qa.sh` fixed the CLAUDE.md-vs-CI drift and opened a qa.sh-vs-CI
  one: CI re-declares the same checks as jobs and nothing tied them, so a fifth job would silently
  falsify both the script and the documentation. The check compares the two and found its own first
  defect immediately — an anchored pattern counted two of four `run` calls. `qa.sh` no longer
  hardcodes "four" either; it counts.
- `.github/` is now inside the consistency corpus for path resolution.

### Still standing, and named

Category 8 will not reach 8/10 until the CI supply chain is hardened: `curl | tar` with no checksum,
actions on floating major tags rather than SHAs, and three registry fetches with version pins but no
integrity pins. Category 4 will not move much further without a formatter, a metric threshold, and
`check-consistency.sh` growing tests for the checks case 22 does not cover. Category 10 is untouched:
no ADRs, no `CONTRIBUTING.md`, `main` unprotected, no pull requests. None of these is a defect a
consumer hits.

## [1.8.0] — 2026-09-03

`/project-audit` was run on this repository — its first real execution — and the ten scoring agents
found what reading had not. Scores: Cat 2 7/10, Cat 4 6/10, Cat 6 8/10, Cat 7 7/10, Cat 8 6/10,
Cat 9 7/10, Cat 10 6/10; Cats 1, 3 and 5 N/A. This release fixes everything the audit surfaced that
a user could hit, and records what was deliberately deferred.

### Fixed — the upgrade path

Five of the six critical defects were in `init-project.sh` and `uninstall.sh`: the two commands
every consumer runs to update.

- **`init-project.sh` printed `❌ Install is not conformant` and exited 0.** The error message was
  followed by sixty lines of `echo`, and the last command set the status — so in the `&&` chain the
  README documents, the installer could not fail, and could not gate a CI job. It now propagates the
  conformance result.
- **It announced `✓ Migrated @-include` for a migration that had not happened.** The branch is
  chosen on a substring match while the rewrite was anchored, so a legacy include line with trailing
  whitespace took the path and matched nothing. The rewrite now tolerates surrounding whitespace and
  the result is verified before it is reported.
- **An uninitialised submodule produced a raw `cp: ... No such file or directory`.** The glob guard
  that `check-install.sh` and `uninstall.sh` both had was missing here — the same defect class 1.7.2
  fixed in the checker, in the installer.
- **Outside a git repository both mutating scripts died with `fatal: not a git repository`, exit
  128.** Both now detect it and explain what they needed it for.
- **`init-project.sh` located `check-install.sh` via `git rev-parse --show-toplevel`.** Run from
  another checkout it would have installed into that project and executed *its* copy of the checker.
  Both mutating scripts now derive their paths from `$0`, as the read-only scripts already did.
- **`uninstall.sh` ignored every argument it was given** — `--dry-run` performed a real uninstall in
  silence. It now refuses unknown options and says there is no dry run.
- `set -u` added to both mutating scripts. They were the only two without it: the scripts that
  delete and rewrite a consumer's files were the ones where an unset path variable expanded to empty.

### Fixed — security

- **A tag name from the remote reached a `sed` address.** `check-updates.sh` interpolated
  `$CURRENT_TAG` — from `git describe` over just-fetched refs — into `sed -n "/^$CURRENT_TAG$/,$p"`.
  Git permits `/ $ ( ) { } ; \ | #` in a ref name, which is enough to close the address and reach
  GNU sed's `e` command, which executes a shell; verified empirically (BSD sed refuses, GNU does
  not). Reaching it needs a hostile upstream tag, and that access already grants execution through
  the installer — so this was a broken pattern rather than a crossed boundary, but a network-derived
  string reached an interpreter. Replaced with an `awk` fixed-string comparison: no regex, no
  interpreter.
- **The hook stub silently did nothing when neither `jq` nor `python3` was present**, and looked
  healthy doing it — `--selftest` also printed nothing and exited 0, so the check whose stated job
  is to prove the reporting path works reported a false pass. Four of the ten agents found this
  independently. The no-parser case now emits the context envelope by hand (its message is a literal,
  so it needs no escaping) and says that no checks ran; `--selftest` exercises the extraction path,
  not only the reporting path.
- **The hook claimed a containment check it did not have.** Its comment said the guard rejected
  paths outside the project; it tested `-f` only, so a payload naming `~/.ssh/config` passed through
  to whatever the consumer had enabled. There is now a real containment check against the project
  root, and every example invocation passes `--` before the path so a file named `-x.php` cannot
  arrive as an option.

### Fixed — the framework's own claims

- **`CLAUDE.md` asserted "shellcheck clean, no exceptions" against five live `disable=SC2086`
  directives** — a false statement in the file loaded into every session of this repo. Corrected,
  and each directive now carries its reason.
- **`scripts/qa.sh`: the gate is one command.** It was three commands in `CLAUDE.md`, the same three
  in `README.md`, and four jobs in CI — and the documented three omitted markdownlint, so a
  developer running the gate exactly as written could still go red. The framework authored
  subcriteria 7.7 and did not satisfy it. `qa.sh` runs all four and reports which it could not run
  rather than passing silently; both documents now point at it instead of restating the list.
- **`.claudeignore` excluded `.github/`** — hiding the one file that declares every pinned tool
  version from the traversal protocol the framework mandates, while 6.9 asks about exactly those
  pins.
- **`/project-audit` hard-coded the N/A escape hatch for Categories 3 and 5 only**, while
  `INSTRUCTIONS.md` lists Cat 1 as "Always evaluated: Yes". An agent scoring OOP on a shell-only
  project had to infer the permission; this one did, another might have invented a score. Any
  category can now be N/A under the standard's own rule.
- **`/project-audit` said the audit report is "meant to be committed" without qualification.** A
  report names security weaknesses with file and line. In a private repository the history is the
  point; in a public one it is a disclosure. The command now requires asking whether the repository
  is public before recommending a commit, and offers the alternatives.
- `skill` was used for command files in user-facing output while the directory, `CLAUDE.md` and
  `check-install.sh` said *command* — and `skill` was overloaded in one file for both a command file
  and a developer competency. Two comments describing behaviour the code no longer had, corrected.

### Added — tests for the mutants that survived

The Testing agent ran mutation tests rather than reading, and three mutants survived a green suite,
all on data-loss paths. Cases 17–22 close them: the prepend-to-existing-`CLAUDE.md` branch (the most
common real install, previously untested), preservation of a developer-edited specialization file
across a second run, `.gitattributes` line-stripping versus deletion, the installer's exit code, the
uninstaller's argument handling, and a guard against `check-consistency.sh` passing vacuously — the
gate script that catches everyone else's drift had no test of its own.

### Deferred, deliberately

Recorded here because 2.7 asks for debt *carried*, not only debt prevented: no `scripts/lib/`
(reading `VERSION` is written in four places, the consumer-install guard in two), the longer scripts
are still comment-divided procedures rather than functions, CI runs Linux only while the `sed`
portability bug is a BSD one, and the version-control half of Category 10 is untouched — no ADRs, no
`CONTRIBUTING.md`, `main` verified unprotected, no pull requests. None is a regression; all are real.

### Note on the tooling

Two defects in `/project-audit` itself were found before the agents were launched and fixed first:
`common.md` carried the entire 2,100-line standard for all ten agents to read — 31k tokens each,
which is the duplication the 1.0.0 rewrite claimed to have removed, moved from the source to the
standard — and the manifest's `find` matched only application languages, returning zero files on a
shell-and-documents project. The framework is now sliced per category, and the manifest covers shell
and reports honestly when a project has no application source.

## [1.7.2] — 2026-09-03

A pre-release pass over the batch shipped today, looking for defects rather than scoring quality.
Four found, all of them things a user would have hit.

### Fixed

- **`/competency-review` could not write the profile it exists to update.** Its frontmatter declared
  `allowed-tools: [Read, Bash]` while step 4 of the command applies the confirmed changes to
  `~/.claude/context/user_profile.md`. The command has been unable to complete since it was written,
  in every release. Now `[Read, Write, Edit, Bash]`. `/project-audit` gained `Edit` for the same
  reason: it appends a row to `docs/audits/history.md`.
- **The breaking-change report was unreachable in the documented upgrade order.** The four-step
  sequence runs `init-project.sh` before `check-install.sh`, and the installer overwrites the version
  marker — so by the time the check ran there was nothing left to compare against, and the feature
  introduced in 1.7.0 could never fire. `check-install.sh` now accepts `--compare-from <version>`,
  and `init-project.sh` captures the marker before overwriting it and passes it through. The report
  now arrives at the moment of transition, and a later standalone check does not repeat it.
- **A missing `.claude/ export-ignore` was an error, which was wrong.** It made `check-install.sh`
  exit 1 with "the framework is not working as installed" over deploy hygiene that is irrelevant to
  a project which never packages with `git archive`. False alarms are how a checker gets ignored.
  Downgraded to a warning that says why it might not apply.
- **An uninitialised submodule read as conformant.** `git clone` without
  `--recurse-submodules` leaves `.claude/framework` an empty directory, and every check then passed
  vacuously — zero commands compared equal to zero commands, so `check-install.sh` reported
  "All 0 commands installed and identical" and exited 0 on an install that contained nothing. It now
  refuses early, names the likely cause, and gives `git submodule update --init --recursive`. This is
  probably the most common way to reach a broken install, and it was the one the checker was
  most confident about.
- **Seven independent "flag once at session start" instructions had accumulated.** No single release
  added more than one, so none of them looked like a problem: stale command copies, an upstream
  release, a missing profile, a review due, two absent specialization files, no `.claudeignore`, a
  stale audit. A freshly installed project would have opened every session with five warning blocks
  before answering anything. `INSTRUCTIONS.md` now governs them as inputs to a single notice: one
  block, three lines maximum, most consequential first, once per session — and the developer's
  question comes first, because a setup notice is never worth delaying an answer.

### Added

- A test case for the upgrade-order interaction, since it is the kind of defect that only appears
  when two correct components run in a particular sequence.

### On the end-to-end path

The upgrade was exercised for real before release: a consumer project with an actual git submodule,
installed at `v1.0.0`, upgraded through the documented four steps to the current version, verified
conformant. That run is what surfaced the marker-ordering defect — the earlier sandbox tests all
copy the framework rather than pin it, so none of them reproduced the sequence a user follows.

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
