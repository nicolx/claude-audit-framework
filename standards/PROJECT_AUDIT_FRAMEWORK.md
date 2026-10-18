# Enterprise Code Quality Standards

Reference framework for evaluating and improving the quality of any software project.
Designed for use in code reviews, onboarding, refactoring decisions, and project health checks.

---

## ⚠ Preconditions — verify before starting any evaluation

This document describes *what* to evaluate. How to operate safely and efficiently during an evaluation is defined in a separate file. **If the preconditions below are not met, stop and resolve them first — proceeding without them produces incomplete or wasteful results.**

### 1. Framework operating instructions must be loaded

The file `.claude/framework/INSTRUCTIONS.md` must be `@`-included from the project's `CLAUDE.md`, and must contain the "Large project analysis protocol" section. That section defines:

- The `.claudeignore` prerequisite
- How to work in blocks rather than on the whole project at once
- When to use the Explore subagent instead of reading files directly
- Which static analysis tools to run before asking Claude to read source

**To verify:** confirm `CLAUDE.md` contains `@.claude/framework/INSTRUCTIONS.md`, and that the section is present in the included file.

**If missing:** the evaluation may burn tokens on irrelevant files, saturate the context window, and produce degraded results on large projects. Run `bash .claude/framework/scripts/init-project.sh` to install or repair the include before continuing.

### 2. The project under evaluation must have a `.claudeignore`

Before reading any file in the project, verify that a `.claudeignore` exists at the project root and excludes at minimum: dependency directories (`vendor/`, `node_modules/`), build artefacts, caches, and log files.

**If missing:** create it now, or ask the user to confirm its absence is intentional. Do not proceed with file traversal on an unconstrained project tree.

### 3. Scope must be defined before starting

Do not begin a broad evaluation ("analyse everything") without first agreeing an explicit scope with the user:

- Which layer or directory is the focus?
- Which categories from this document apply?
- Is this a full evaluation or a targeted audit of one concern?

A scoped evaluation produces better results than a full sweep, costs fewer tokens, and is easier to act on.

### 4. Database access must be declared, or its absence acknowledged

Subcriteria 7.9 and 9.8 are about data-access cost, and configuration cannot answer them. A migration
declares an index; whether that index exists in the database, and whether the planner chooses it,
are two further questions. Without a database to ask, both criteria are scored from *intent*.

**What the audit needs is narrower than read access.** Query analysis reads **schema and statistics**,
not rows: `information_schema` / `pg_indexes`, `EXPLAIN` (never `EXPLAIN ANALYZE` on anything but a
plain `SELECT`, and never against production), row counts, and the statement statistics the engine
already aggregates (`pg_stat_statements`, `performance_schema`, the slow query log). Almost nothing
in 7.9 or 9.8 requires reading a single row of application data — which is exactly why the grant
should not permit it.

**What to declare** in `.claude/PROJECT_AUDIT_FRAMEWORK.md`: how to reach such a database, which
environment it is, and what the grant allows. The environment matters as much as the grant: a
development database with two hundred rows produces query plans that are worse than no evidence,
because they look like evidence. Representative volume — a restored dump, an anonymised replica, a
staging database — is what makes a plan mean anything.

**If it is not available:** say so, score 7.9 and 9.8 from configuration and migrations, state in the
evidence cell that the finding is unverified against a database, and **do not award 9–10**. An
unverified claim is not comprehensive evidence. Recording the limit is the point: a score that hides
it is worse than a lower score that explains itself.

### 5. The team must be declared, or read from the history

Category 10 measures practices that exist because of other people. A pull request is how a review
crosses between two of them; a protected branch is what stops a change arriving unseen; a tag is how
somebody downstream names the version they are running. Where the person the practice protects does
not exist, the practice is not a gap — and scoring it as one teaches a one-developer repository to
install ceremony that protects nobody, which is the fastest way to make a quality framework
something a project works around.

So establish four things before scoring Category 10: **who writes, who reviews, who releases, and
who consumes a version.** What they decide is the proportionality rule at the top of that category.

**What to declare** in `.claude/PROJECT_AUDIT_FRAMEWORK.md`: the **Team census** block — the
contributors active now and their roles, who may approve and who may release, and whether anything
downstream pins a version of this project. `/team-census` drafts it from the history and asks for
the rest.

**If it is not declared**, read the shape from the history rather than assuming a team or assuming a
solo developer:

```bash
# who has written code in the last year, and how much — the census's first draft
# (the revision argument is required: without it shortlog reads standard input and hangs)
git shortlog -sne --since='12 months ago' --no-merges HEAD

# who merges, which is rarely the same list, and is the review question
git log --merges --since='12 months ago' --format='%an' | sort | uniq -c | sort -rn
```

**An identity in the log is a credential, not a person**, and the mapping between the two breaks in
both directions. One person commits from a laptop, from CI, through the web interface and through an
agent acting for them — four identities, one writer. One identity covers a shared deploy account, a
team bot, or an agent run by whoever is on duty — one identity, several writers.

Those two errors are not symmetric, and only one of them is dangerous here. Overstating the team
costs the project some N/A it was entitled to. **Understating it removes subcriteria that should
apply** — a shared `deploy-bot` behind which four people work makes 10.12 look structurally absent,
and the framework would then certify a team that reviews nothing. So the rule is one-directional:

> **An unresolved identity is never resolved downward.** Where an identity cannot be tied to a
> person, record it in the census as unresolved and keep scoring the subcriteria it would otherwise
> have made N/A. Marking one N/A requires a positive finding that nobody else writes here — never an
> absence of evidence about who does.

Resolving one is a procedure, not a guess, and `/team-census` runs it: author against committer,
the commit's trailers, the account the noreply address encodes, the signature, and the pull request
the commit arrived in. What no repository holds is **who pushed** — that lives in the host's audit
log — so an identity that survives all five is a question for a person, not a shape to infer.

**An AI co-author is a tool, not a contributor.** A commit authored by a developer and trailed by
`Co-authored-by: Claude …` has one writer: the developer. Nor does a human approving an agent's diff
before it lands satisfy 10.12 — that subcriteria asks for a review by somebody who did not write the
change, and a developer directing an agent is its author. Where the authorship is the other way
round, an agent identity on the commit and a person in the trailer, the person in the trailer is the
writer.

A shape read from the log is evidence like any other and scores the same. Say that is where it came
from, because of the one thing the log cannot tell you: who is still on the project. Four names in
the last year is four contributors or one plus three leavers, and those are different projects.

**A declaration the history contradicts is a finding, not a shortcut.** Three active contributors in
the log against a census naming one is either a census nobody updated or a shape chosen to escape a
criterion; report it either way, exactly as a production path that no longer resolves is reported
under 9.9. The conditions in the proportionality rule are structural and observable — *we are small*
and *we move fast* are not among them.

---

## How to use this document

> **Note on examples:** Code snippets throughout this document are illustrative only. They use generic or multi-language notation. Language-specific equivalents are in the Appendix at the end of this document.

Each category contains:

- **What it measures** — the concern being evaluated
- **Subcriteria** — concrete, independently scorable dimensions
- **What good looks like** — observable signals of quality
- **What bad looks like** — observable anti-patterns
- **How to score** — 0–10 scale anchors

Scoring is always evidence-based: assign a score only when you can point to a specific file, line, or behaviour that justifies it. Avoid averaging across subcriteria mechanically — use judgement to weight the subcriteria that matter most for the specific project type.

### Score anchors (apply to every subcategory)

| Score | Meaning |
|---|---|
| 0–2 | Absent or actively harmful |
| 3–4 | Partial, inconsistent, or accidental |
| 5–6 | Present but incomplete, or correct in easy cases only |
| 7–8 | Solid, intentional, covers the main scenarios |
| 9–10 | Comprehensive, principled, no obvious gaps |

### When to mark N/A

Mark a category N/A only when the concern is structurally absent from the project (e.g., "Framework Adherence" for a project with no framework). Do not use N/A to avoid a difficult evaluation.

The same rule applies to a single subcriteria: some carry their own scope line saying when they are N/A, and that line states the structural condition, not a difficulty threshold. A subcriteria marked N/A is excluded from the category's score; it is never scored zero.

---

## Project-level specializations (optional)

For projects where global criteria need grounding in a specific technology stack, create a `PROJECT_AUDIT_FRAMEWORK.md` in the project's `.claude/` directory. Claude reads it alongside this global standard — it extends it, it does not replace it. `scripts/init-project.sh` scaffolds it automatically.

### When to create one

Create it when at least one of the following is true:

- The project uses a specific toolchain that maps concretely to a global category (e.g., a custom quality gate command for Cat. 7)
- The project enforces architectural rules that give observable meaning to abstract criteria (e.g., a strict layer structure for Cat. 3)
- The project has test kinds or tagging conventions that specialise how Cat. 4 applies

If the global standard applies without ambiguity, no project file is needed.

### What to put in it

- **Only categories that need grounding** — if a category applies without modification, omit it
- **Tool mappings** — e.g. "For Cat. 7, the quality gate is `make lint && make test`"
- **Architectural constraints** — layer rules, import restrictions, naming conventions that give evidence for scoring
- **Test taxonomy** — the test kinds in use and how they map to Cat. 4 subcriteria

### What not to put in it

- Global criteria restated in different words — if it is already in this document, do not repeat it
- Aspirational rules not yet enforced — document only what is actually in place
- A full copy of this global standard — the project file is a specialization, not a clone

### Format

The skeleton lives in `.claude/framework/templates/PROJECT_AUDIT_FRAMEWORK.md` — one `## Category N — <Name>` heading per category that needs grounding, each followed by the tool, rule, or constraint that gives it observable meaning in this stack.

A healthy project file is 30–80 lines. If it grows longer, it is likely duplicating rather than specializing.

### Ignore files

No changes to any ignore file are needed:

- **Version control** — commit the file; it documents quality conventions for the whole team.
- **`.claudeignore`** — do not add it; Claude needs to read it during quality evaluations. Excluding it would silently disable the specializations.

---

## Category 0 — Product Strategy & Delivery Documentation

**What it measures:** Whether the repository states what the product is for, what is planned, and
which of it already exists — so that every other category is scored against a declared intent rather
than against the code's own assumptions.

This category is the frame the other ten hang on. Categories 1–10 measure how well a thing is built.
None of them can tell you whether it is the thing the team meant to build, or whether the half that
is missing is missing on purpose. A codebase can score 9 across the board and still be an elegant
answer to a question nobody asked — and an auditor with no product documentation cannot see that,
because the code is then the only surviving account of intent, and code always agrees with itself.

Concretely, this is what its absence costs the rest of the audit:

- **Scope calls become guesses.** Category 3 asks whether the domain model matches the domain. With
  no written domain context, "the domain" is inferred from the entities, and the criterion collapses
  into "is the code self-consistent" — which it always is.
- **Incompleteness becomes indistinguishable from debt.** A missing authorisation check is a
  Category 8 finding if the feature shipped, and a non-finding if it belongs to a spec still marked
  `todo`. Only the delivery documentation separates the two, and the difference is the whole
  severity of the finding.
- **Priorities become the auditor's, not the team's.** "The top three improvements by impact" is a
  product judgement wearing an engineering hat. With nothing saying what the product is for, impact
  gets estimated from the severity of code smells, which is a different ranking and belongs to
  somebody else.

Score this category **first** and let its findings travel with the rest of the audit. A low score
here is not one finding among eleven — it is a caveat on every finding that follows.

**Proportionality.** The *form* scales with the project: a solo project's product context is
legitimately one page, and one page that is true scores 8. The *presence* does not scale. A
two-person project with nothing written down has the same problem as a fifty-person one; it just
meets it later, usually when the second person arrives.

**When this is N/A.** Rarely, and never for a project with work in flight. A frozen archive or a
single-purpose script has no 0.3, no 0.4 and no 0.8 to score — say which subcriteria are structurally
absent and score the rest. "We are too small to document" is not a structural absence; it is a low score.

### Subcriteria

#### 0.1 Product context is written down

What the product is for, who uses it, and what it deliberately does not do. Not a marketing
paragraph: the material a new team member — or an agent proposing a change — needs in order to judge
whether a proposal belongs in this product at all.

**Good:**

- A committed context document naming the users, the problem, the constraints that are not
  negotiable (regulatory, contractual, volume, latency), and what is explicitly out of scope
- The domain vocabulary defined once, where code can be read against it. This is also what makes
  2.8's language calls decidable rather than stylistic: a term is domain language because a document
  says so, not because a reviewer recognises it
- Dated or versioned, so a reader can tell whether it describes the current product

**Bad:**

- The only statement of purpose is the README's first sentence, written at `git init` and true of a
  different product since
- The "why" lives in a chat history, a slide deck outside the repository, or one person's head — all
  three fail the same way, by being unavailable to the person who needs them at 11pm
- A context document describing the product as it was pitched, never as it was built, with nothing
  marking the divergence

#### 0.2 The documentation has a home, and the home is discoverable

One predictable root, with a stated rule about what lives where. Discoverability is the criterion,
not tidiness: documentation a reader cannot find is worth exactly what documentation that does not
exist is worth, and an agent that cannot find it will reconstruct its content from the code — wrongly,
and confidently.

**Good:**

- A single root — `docs/` is the common choice — split by area in a way a newcomer can predict:
  product specs, decision records, design artifacts, context
- An index at that root saying what each area holds and what belongs in it
- The layout named where both people and agents will meet it — `CLAUDE.md`, `CONTRIBUTING.md`, or the
  README — in exactly one of them, with the others pointing at it rather than restating it
- External tools (tracker, design tool, wiki) are reachable *from* the repository; the repository is
  not a thing you find from the wiki

**Bad:**

- Documents scattered across the repository root, or a `docs/` whose structure is the sediment of
  whoever wrote last
- A wiki holding the real documentation that the repository never mentions — so the repository looks
  undocumented and the wiki looks abandoned, and both impressions are acted on
- Two homes with overlapping content and no rule about which one wins

#### 0.3 Work in flight has an implementation spec

A feature-level document — PRD, spec, RFC; the name matters less than the content — stating what is
to be built, for whom, and what *done* means, committed alongside the code that will satisfy it.

**Good:**

- One document per unit of delivery, identified by number or dated slug, so a commit, a branch or a
  test can cite it
- Acceptance criteria written as things that are observably true or false: a test could be written
  from them without asking the author a question
- Written before the work and reviewed like code. Changes to it are commits, so the negotiation is in
  the history rather than in a thread
- Small changes carry no spec, and the threshold is written down rather than left to taste

**Bad:**

- The work exists only as tickets: the repository cannot say what it was supposed to do, and the
  tracker cannot say what was actually built
- Specs written after delivery to satisfy a process. They describe the code, so they can never
  contradict it — which is the one thing a spec is for
- Acceptance criteria that are aspirations: "fast", "intuitive", "secure"
- A spec for every change, typo fixes included. A ceremony that expensive is abandoned within a
  quarter, and it takes the specs that were worth writing down with it

#### 0.4 Every implementation document declares its status

This is the field the team reads most often, and the one that turns a documentation directory into a
picture of what is left to do. A document describing work must state, in a fixed and machine-readable
place, whether that work exists yet.

**Good:**

- A status field in a fixed location — YAML frontmatter is the usual choice — drawn from a **closed**
  vocabulary: `todo`, `in-progress`, `implemented`, `superseded`, `abandoned`. The closed set is what
  makes the field aggregatable; free text is prose with extra steps
- Partially delivered specs mark status **per requirement**, not only per document, so `in-progress`
  says which half is which
- `superseded` and `abandoned` documents stay, marked, pointing at what replaced them. A deleted spec
  takes its rationale with it and the question comes back in a year
- The whole board is one command: `grep -rl 'status: todo' docs/product/` answers "what is left"
  without opening a file, and that is what makes the marker useful to a team rather than to a reader

**Bad:**

- Status conveyed in prose — "we'll add this later", three paragraphs in — which nobody can aggregate
  and nothing can verify
- Status conveyed only by directory (`docs/done/`, `docs/backlog/`): invisible inside the document,
  and updated only by moving a file, which is why it stops being updated
- No status at all. The reader cannot tell whether a document describes the system or a wish, and the
  only safe reading — treat every document as a wish — makes the whole corpus worthless
- An open vocabulary: `status: mostly done`, `status: waiting on the API team`, `status: ✅`

**Scoring thresholds:**

| Score | Situation |
|---|---|
| 9–10 | Every implementation document carries a status from a closed vocabulary in a fixed location; partial delivery is marked per requirement; outstanding work is listable with one command |
| 7–8 | Every document carries a status and the vocabulary is consistent; per-requirement granularity is missing where it would matter |
| 5–6 | Most documents carry a status; or status exists at document level only, in an inconsistent format |
| 3–4 | Status on some documents, in prose or by folder placement; not aggregatable |
| 1–2 | Nothing says whether a document describes the present or the future |

#### 0.5 The status marker is true

A marker that is not maintained is worse than no marker: it is a claim, and readers act on claims.
0.4 asks whether the field exists; this asks whether it is a fact.

This is the delivery-state half of the drift problem. 7.10 owns what documents assert about the
*system* — paths, commands, analyser levels; this subcriteria owns what they assert about their own
*delivery state*. Same failure, different claim, and they are scored separately because a project
often has one and not the other.

**Good:**

- Status changes in the same commit or pull request as the code that changes it — principle 22's rule
  for factual claims, applied to delivery state
- A spec marked `implemented` names what implements it: the module, the test, or the merge commit.
  That is what makes the claim checkable by somebody other than its author
- Something checks mechanically. A CI job that fails when a document is `implemented` and cites
  nothing, or when a `todo` spec's acceptance criteria are all already green in the suite, is worth
  more than a review step — because the review step is what gets skipped when the release is late
- Documents that cannot be checked mechanically carry a visible date, so an `in-progress` from eleven
  months ago reads as what it is

**Bad:**

- Everything is `todo`, including the four features that are in production. The field was filled in
  at creation and never again
- Everything is `implemented`, including the ones that are not, because status was swept clean before
  a review
- `in-progress` with no owner and no date, indistinguishable from abandoned
- Status updated in a separate documentation commit, days later, by somebody who was not there. That
  is how it becomes a chore, and a chore is what it is right before it stops

#### 0.6 Design and interaction artifacts are versioned with the code

Mockups, wireframes, flows and content design are specifications: they say what to build as precisely
as prose does, and they change as often. When they live only on a design tool's mutable canvas, the
artifact the code was built against has ceased to exist by the time anyone reviews the code.

**Good:**

- The agreed state is committed — an export, a PDF, a frame capture — beside the spec that references
  it, so a review can compare the code against what was actually approved
- Links into the design tool are pinned to a file *and* a frame or version, never to the current canvas
- Each artifact is named by the spec that depends on it, so "which mock does this screen implement"
  has an answer
- Superseded designs are kept and marked, on the same rule as superseded specs

**Bad:**

- A bare link to a design tool's home canvas. The approved design has been edited since, and nobody
  can say how
- Mockups delivered in chat and never landed anywhere, leaving the implementation as the only
  surviving record of the agreement
- A `mockups/` directory of undated exports that no document references
- Committed exports that were never regenerated after the design moved and are not marked historical
  — worse than a stale link, because they look current

#### 0.7 Architecture Decision Records (ADRs)

Significant architectural decisions belong in short, committed records capturing context, rationale
and the alternatives rejected. Code alone cannot explain why a decision was made, and the reasons are
the first thing lost — usually to a reorganisation, sometimes to a holiday.

An ADR is not an implementation spec. 0.3 records what will be built; an ADR records a decision that
constrains how, and it outlives the feature that prompted it.

**Good:**

- A `docs/adr/` directory (under the home from 0.2) with numbered records
- Each states the decision plainly, its context, its consequences, and the alternatives rejected
- Superseded ADRs are marked, not deleted — the same `superseded` status 0.4 defines, from the same
  closed vocabulary, so one convention covers every document in the tree
- The index answers "why is this structured this way?" for every non-obvious structural choice

**Bad:**

- Architecture explicable only through tribal knowledge or a long conversation
- No record of decisions that were reversed — only the current state, never the history that would
  stop it being reversed back next year
- ADRs written retrospectively as busywork rather than prospectively as decision aids

**How to score:**

- 0–2: No ADRs; structural decisions are implicit and undocumented
- 3–5: Some decisions documented informally (README, comments), but no systematic practice
- 6–7: ADR practice present; coverage incomplete or format inconsistent
- 8–10: All significant structural decisions have ADRs; history is traceable; new decisions trigger
  new ADRs as a matter of course

#### 0.8 The plan decomposes into steps that each ship

0.3 scores whether the work is written down. This scores whether it is **sequenced**. A spec that
states an end state and nothing about the order it arrives in has left the most consequential
decision in the change to whoever opens the editor next — and that is now routinely an agent, which
will attempt the whole of it in one pass because nothing in the document said not to.

The unit is the step, and a step is three things at once: **one change to the implementation, the one
test that proves it, and a state the system can be released and observed in.** A line item missing
any of the three is not a step, whatever the list calls it.

The first step carries more weight than the rest of the list, and is where the A3 habit earns its
place: one page stating the problem, where the system is now, where it has to get to, the single
countermeasure being tried first, and how its effect will be checked. A plan that opens on the
riskiest assumption learns in a day what a plan that opens on the easiest file learns in the third
week — by which point the cost of being wrong is the whole branch.

**Scored on the units of work that carry a spec under 0.3's threshold.** A change below it has a
plan with one step in it, and that is a pass rather than a gap.

**Good:**

- The spec carries an ordered list of steps, each naming what it changes, the test that will prove
  it, and what is observably true in a running system once it lands
- Every step leaves the system working: it can be merged, released, and then left alone for a week.
  Nothing is in a state that only the next step repairs
- The order is a dependency order and says so. Where a step genuinely cannot ship alone, the spec
  names what it is waiting on — a stated exception, not the shape of the whole plan
- The first step is the smallest change that produces evidence about the assumption most likely to
  be wrong
- Each step can be reverted without reverting its neighbours, which is also what makes it an honest
  unit for the commits of 10.11 and the pull requests of 10.12
- Where the end state replaces something that exists, the plan names the intermediate states it
  passes through; how to obtain them is 10.9's subject, not this one's

**Bad:**

- A plan whose only unit is the finished feature: one branch, one merge, one test run at the end,
  and no point along the way at which anyone could have said *stop, this is wrong*
- *"Then migrate everything to X"* as a line item — a cutover written as though it were a step, with
  no releasable state anywhere between the old world and the new one
- Steps cut by layer rather than by behaviour — all the entities, then all the repositories, then
  all the controllers — where nothing is observable until the last one lands. That is one step
  wearing three numbers
- Verification deferred to a phase of its own at the end. A step whose test arrives later is a step
  whose failure arrives later too, attached to the wrong cause
- A step whose done condition is *"it works"*, *"refactored"*, or *"cleaned up"* — nothing a release
  can be checked against, so nothing that can be called finished or unfinished
- A plan written at the altitude of the request — *"rebuild the billing module"* — and handed
  straight to an implementer. A person will ask what to do first; an agent will start

**How to score:**

- 0–2: Work arrives as one undivided change. The plan, where there is one, states a destination and
  no route
- 3–5: Steps exist but are not independently releasable — split by file or by layer, with everything
  observable concentrated in the last one
- 6–7: Units of work are sequenced into shippable steps; the test per step is implied rather than
  named, or large replacements still contain a single cutover
- 8–10: Every unit of work in flight carries an ordered plan whose steps each name their change,
  their test and their released state; the first step tests the riskiest assumption; replacements
  run through named intermediate states, and no step depends on its successor to be correct

##### How the plan is measured against the history

Read on its own, a plan scores the writing. What makes 0.8 falsifiable is the **join** between the
document and the record of how the work actually arrived — and that record is already in the
repository. Everything below is read-only `git`, plus the CI's own run history.

**The join** is the identifier 0.3 already requires. Steps are counted in the document; deliveries
are found with the identifier. The examples use `SPEC-042`; substitute the project's convention,
which may be a scope, a branch name or a trailer.

```bash
git log --first-parent main --grep='SPEC-042' --format='%h %cI %s' --shortstat
```

**Where the project squashes on merge**, that commit is the pull request, not the step, and the
granularity this measurement needs was discarded before the change reached `main`. Measure at the
pull request instead — `gh pr list --search 'SPEC-042' --state merged` — and take the step record
from there. A project that squashes *and* ships one pull request per unit of work has no step record
anywhere, which is not a measurement problem: it is the finding.

**1. Realisation — were the declared steps the steps that landed?** Count what the plan declares,
count what cites it, compare. Five steps declared and one change merged is a plan that was collapsed
into the cutover it was written to avoid, and the score belongs to the history rather than to the
document. One step declared and forty commits merged at once is a plan that was never made.

**2. Shape — is one of them the cutover wearing a step's number?** Compare each step's changed lines
to the median of its siblings. No absolute size is wrong, and the test is not size but **uniformity**:
a step that does one thing many times — a mechanical rename across nine hundred sites — is ordered at
any size, and *The mass rename is the most ordered change of all* says how it is cut. A step that
does many things once is the cutover, and it is usually the one an order of magnitude past the rest
of a unit whose steps were meant to be alike.

**3. Verification — did each step bring its own test?** Two numbers, and the second is the one that
catches what the first misses:

```bash
for s in $(git log --first-parent main --grep='SPEC-042' --format=%h); do
  printf '%s  tests=%s\n' "$s" \
    "$(git show --name-only --format= "$s" | grep -cE '(^|/)(tests?|spec|__tests__)/')"
done
```

The share of steps carrying a test file, and the share of the unit's *total* test churn that landed
in its final step. A testing phase at the end is visible in the second even when the first looks
healthy, because the tests exist — they just all arrived together, after the last thing they could
have contradicted was already written.

**4. Independence — was the system releasable at each step?** This is the indicator that cannot be
staged after the fact, and the closest thing the criterion has to a fitness function (10.9). Join the
step commits against CI:

```bash
gh run list --branch main --limit 200 --json headSha,conclusion,createdAt
```

A step whose pipeline failed, or never ran, is a step nobody could have released — whatever the plan
called it. Where no CI history survives, the local equivalent is exact and nearly as cheap: check the
step out in a detached worktree and run the project's one-command quality gate (7.7) against it.

```bash
probe=$(mktemp -d)/step && git worktree add -d "$probe" <step-sha>
# run the gate inside "$probe", then:
git worktree remove --force "$probe"
```

**5. Cadence — did anything reach users between the first step and the last?** Count the releases
inside the unit's window — tags, deployment records, or first-parent merges to `main` where the
project deploys continuously.

```bash
first=$(git log --first-parent main --grep='SPEC-042' --format=%cI --reverse | head -1)
last=$(git log  --first-parent main --grep='SPEC-042' --format=%cI | head -1)
git tag --sort=creatordate --format='%(creatordate:short) %(refname:short)' |
  awk -v a="${first%%T*}" -v b="${last%%T*}" '$1 >= a && $1 <= b'
```

Zero releases across a unit that ran for six weeks means no step was releasable in fact, however the
document described them. This is also where the cosmetic split shows: steps authored within minutes
of each other and merged together were one change cut up for the log, and they satisfy indicator 1
while failing this one and 4.

**6. Learning — did the plan change as the work taught it something?**

```bash
git log --follow --format='%cI %h %s' -- docs/specs/042-billing.md
```

A plan with one commit, written before the work and never touched again, either guessed perfectly or
was never opened after the kickoff; the second is far more common. Revisions dated *between* step
deliveries are the check half of the A3, visible in the record. This is the one indicator where more
is not better without limit — a plan rewritten after every step was not a plan.

**Ceilings.** Applied after the bands above, over the window defined below:

| What the history supports | Ceiling |
|---|---|
| The plan declares no steps — there is nothing to join | 3 |
| Steps declared; nothing in the history cites the unit, so the plan cannot be checked against what was delivered | 5 |
| Citations exist and the unit arrived as one change — the declared steps were not the steps that landed | 5 |
| Steps landed separately, but they carry no tests of their own, or the gate was not green between them | 6 |
| Each step landed separately and green, carrying the test that proves it | 8 |
| …and the unit released more than once along the way, with the plan revised as the steps reported back | 10 |

**The window — how many units, and when the number moves.** A score computed over everything since
the adoption date is a score the team cannot move: the collapsed unit from twenty deliveries ago is
still in the denominator, and the arithmetic answers *wait a year*. Nobody waits a year. They stop
reading the number, which is the failure the adoption provision already names — a denominator nobody
can move is not a measurement, it is a sentence. So 0.8 is scored on a **rolling window**:

- the **last five units of delivery**, in the sense 0.3 gives the word — not the last five commits;
- **bounded at six months**, or at the audit before last, whichever is nearer. Older work was done by
  a different team under a different practice, and averaging it in measures neither;
- **fewer than three units inside those bounds** and the sample is too short to carry the criterion:
  score the plans as documents, say the sample is short, and cap at 6. A practice that has not been
  observed cannot be certified by reading about it.

The report **names the window it used** — which units, which dates. Two audits that read different
windows are two different measurements, and the difference between them is not progress.

Inside that window the response is arithmetic, and a team can plan against it:

| Units in the window delivered the new way | What happens to the score |
|---|---|
| 1 | Nothing. One unit is an anecdote, and the ceilings read the sample rather than its best member |
| 3 of 5 | The collapsed-delivery ceiling lifts: the new practice is now most of what the window holds. 6, or 8 where those three carried their tests and stayed green |
| 5 of 5 | The window holds nothing else. The ceilings stop binding and the score is whatever the plans themselves earn |

Downward, the thresholds are deliberately not the mirror image: **three units raise the score, two
lower it.** One collapsed unit in five is a lapse and does not move a settled score; two in five is
the mode wearing the clothes of an exception, and the score returns to the ceiling those deliveries
carry. A practice is harder to demonstrate than to abandon, and a measure that pretends otherwise
reads high for exactly as long as it takes somebody to notice.

**So the answer to "when does it improve" is five units** — three to move the number, five to settle
it — and no document written today shortens that by a day. Indicators 4 and 5 read the history of
units already delivered, and that history is written. 0.8 is the criterion in this framework that
**cannot be repaired retroactively**, which is the same property that makes it worth measuring: a
backfilled plan for a unit that shipped as one change scores the change, exactly as a spec
reconstructed from code scores below the gap it was written to fill.

It is also among the cheapest criteria to raise going forward. Sequencing the next five units needs
no infrastructure, no refactoring and no budget — unlike coverage, which needs a quarter, or a
framework upgrade, which needs a release window. On a floor-raising programme that usually puts it
early rather than late.

**What the numbers cannot say.** Indicators 1, 2 and 6 are counts, and counts are the cheapest thing
in this criterion to satisfy without changing anything — which is why they are here to find the
collapsed plan, not to certify a good one. What cannot be staged is 4 and 5: a green gate at each
step and a release between them require the system to have actually been in that state.

And no command answers the question the criterion opens with — whether the first step was the one
worth taking first. The riskiest assumption is a judgement about the problem, not a property of the
repository, and an audit reports it as a judgement with its reasoning attached.

**What the history is evidence of.** It records what the process emitted, not what anyone intended —
which is precisely why it is worth joining to the plan. A plan read on its own agrees with itself,
for the same reason a spec reconstructed from code agrees with the code: there is only one hand in
the record. The history is the second hand, and consistency between two independent records is the
whole mechanism, here as in 9.10.

Two consequences follow, and both belong in the finding rather than in a footnote. A team whose
process discards the record — squash-on-merge with one pull request per unit — is unmeasurable here,
and that is scored as the gap it is: the next person to ask what was delivered in which order has no
answer either. And what is scored is the **delivery inside the window, never the people in it**. A
finding that names a developer has stopped measuring a practice and started doing something else.

### Adopting this category on an existing project

A project that installs this framework in its third year has no history of specs and no way to
acquire one. That is the normal case, not the exception, and the category has to be recoverable from
it — a criterion that scores a past nobody can change is a criterion teams correctly learn to ignore.

**Reconstructing the missing documents from the code is not the way, and it scores below the gap it
was meant to fill.** Documentation reverse-engineered from an implementation cannot contradict that
implementation: it is a description wearing a specification's clothes. The whole evidential value of
a spec is that it was written by somebody who could still turn out to be wrong about what the code
would do — retrofit it and that property is gone permanently, while the corpus now *looks* complete.
A sweep like that produces documents that are 100% `implemented`, 100% accurate and 0% useful, and it
destroys the one honest signal the project had: *we started documenting in March*.

So the remediation runs forward, with a small bounded backfill. In this order:

1. **Write the product context (0.1). One page, this week.** The highest score per unit of effort in
   the category, and the only part that gets *easier* the longer the project has run: it comes out of
   the team's heads rather than out of the code, and three years of arguing about what the product is
   for have already produced the answer. It is also what the other ten categories most need.
2. **Create the home and its index (0.2), and put the context in it.** An empty tree scores nothing.
   A tree with one true document in it scores.
3. **Start specs at the next unit of work (0.3), never at the last one.** The practice begins with the
   next feature. Nothing shipped before that date gets a spec — demanding otherwise is what makes
   teams abandon the practice inside a quarter. The first one to write is the step list (0.8): it is
   the half of the spec that changes what happens this week rather than what is on record about it.
4. **Backfill ADRs (0.7) only where all three hold:** the decision still constrains the code today; a
   new reader would not deduce it from the code; and somebody still on the team remembers the
   reasoning. Where the first two hold and the third does not, the honest record says so —
   `**Rationale:** not recovered, the decision predates the current team` is a real ADR and a more
   useful one than an invented rationale, because it tells the next reader the constraint is
   inherited rather than defended. Never backfill to raise a count.
5. **Pin the design artifacts that are live (0.6)** — the mockups for the screens that exist now,
   pinned to a frame or committed as an export. The history is gone. It is not recoverable and does
   not need to be.

Steps 4 and 5 are the entire backfill. Everything else runs forward.

**How this is scored.** 0.3, 0.4, 0.5 and 0.8 are scored against the **units of delivery since the
practice started**, not against the project's whole history — and for 0.8 that date is the lower
bound rather than the denominator, which is the rolling window of *The window* above — the same way coverage on a legacy codebase is
measured on changed lines rather than on the whole tree, and for the same reason: a denominator
nobody can move is not a measurement, it is a sentence.

Two things make that provision available, and refusing either is itself the finding:

- **The adoption date is a fact in the repository** — the commit that created the documentation home
  — not a claim made during the audit. Read it from the log.
- **What gets scored is the distance between shipping and specifying.** A project that adopted in
  March, shipped eleven features and wrote one spec has not adopted a practice; it has a directory.
  Count the units of delivery since that date against the documents that describe them.

A project three months into the practice, with a spec for every feature since and markers that match
the code, scores 8. A project holding five years of documents nobody has updated scores 4. This
category measures a practice that is running, not an archive that has accumulated.

**The first audit is the adoption moment.** Where the framework has just been installed, Category 0
scores what is actually there — usually low — and that number is a baseline rather than a verdict.
What the next audit measures is the distance travelled from it, which is what the score history is
for.

---

## Category 1 — OOP & Design Patterns

**What it measures:** How well the codebase applies object-oriented principles and established structural patterns to produce code that is modular, extensible, and resistant to accidental coupling.

### Subcriteria

#### 1.1 Encapsulation

All internal state is hidden behind a well-defined interface. Classes expose only what callers need; implementation details cannot be modified from outside.

**Good:** `private readonly` properties with typed getters. No public mutable fields except in explicit DTO/value types. Invariants enforced in the constructor.

**Bad:** `public $field` on domain objects. Setters that allow external code to put an object into an invalid state. Protected properties used as a shortcut to avoid proper API design.

#### 1.2 Single Responsibility Principle (SRP)

Each class has exactly one reason to change. A class that orchestrates network calls, parses JSON, applies business rules, and formats output for the view is four classes in disguise.

**Good:** `OrderRepository` fetches data. `OrderMapper` translates raw data to domain objects. `PlaceOrderUseCase` executes the business rule. `OrderPresenter` formats for the response.

**Bad:** A controller that validates input, calls external APIs, applies business logic, and builds the HTML response.

**Test:** Ask "what would make me change this class?" If there are two distinct answers, split it.

#### 1.3 Open/Closed Principle (OCP)

The system can be extended with new behaviour without modifying existing, tested code. The mechanism is typically abstraction: interfaces, abstract classes, or composition.

**Good:** Adding a new payment provider means creating a new class that implements `PaymentGatewayInterface` — zero changes to the checkout flow.

**Bad:** Adding a new case to a `switch` statement or `if/elseif` chain inside a core class every time the system is extended.

#### 1.4 Dependency Inversion (DI)

High-level modules (use cases, controllers) depend on abstractions, not on concrete infrastructure classes. Dependencies are injected, not instantiated.

**Good:** `GetOrderUseCase` depends on `OrderRepositoryInterface`. Whether the implementation hits a database, a cache, or a test stub is irrelevant to the use case.

**Bad:** `new HttpClient()` inside a use case. `new DatabaseConnection()` inside a repository without injection. Any `new` on a non-value object inside a class that is not a factory or container.

#### 1.5 Design Patterns applied

Intentional use of established patterns where they solve a real problem. Patterns should earn their place — do not add them speculatively.

| Pattern | When it earns its place |
|---|---|
| Repository | Decouples domain from persistence technology |
| Mapper / Transformer | Translates between layers without polluting domain or infrastructure |
| Use Case / Application Service | Encapsulates one business operation end-to-end |
| Factory Method | Constructs domain objects from raw data without leaking construction logic into consumers |
| Value Object | Encapsulates a concept with identity defined by its value, not its instance |
| Observer / Event | Decouples side effects (emails, audits, webhooks) from business operations |
| Decorator | Adds cross-cutting behaviour (caching, logging, retries) without modifying the target |

**Bad:** Patterns used for their own sake. A Repository wrapping a single `find()` call with no interface. A Factory that does `new Foo($a, $b)` and nothing more.

#### 1.6 Liskov Substitution

A subtype can stand in for its parent everywhere the parent is used, without the caller noticing.
The rule is behavioural, not syntactic: a subclass that compiles against the interface but throws
where the parent returned, accepts less than the parent accepted, or promises less than the parent
promised breaks every caller written against the parent.

**Good:**

- Overrides that accept at least what the parent accepted and guarantee at least what it guaranteed
- Callers that work through the parent type and never ask which subtype they were given
- Contract tests written once against an interface and run against every implementation — the
  in-memory fake of 4.6 included — so a substitution failure is a red test, not a production surprise

**Bad:**

- An override that throws `NotImplementedException`, `UnsupportedOperationException` or the
  language's equivalent
- Type checks (`instanceof`, `isinstance`, `is`) on a subtype of something the caller received as its
  parent — the caller compensating for a subtype that does not substitute
- `ReadOnlyRepository extends Repository` with a `save()` that throws: inheritance used for reuse
  where the subtype cannot honour the contract
- A test fake that behaves differently from the real implementation on a case the tests rely on

#### 1.7 Interface Segregation

Clients depend only on the methods they use. An interface that grows to serve every caller makes each
implementer provide what some caller needs, and each caller depend on what the others need — so a
change for one consumer reaches all of them.

**Good:**

- Interfaces shaped by what a caller needs: `OrderReader` for the query side, `OrderWriter` for the
  use case that saves
- Every implementation implements every method meaningfully
- Test doubles that stay small, because the interface they stand in for is small

**Bad:**

- A twenty-method `UserServiceInterface` whose callers each touch two
- A test that has to stub ten methods to exercise one
- Implementations with empty methods, or methods that only throw, to satisfy an interface

**Scored once.** An empty or throwing implementation is evidence for both 1.6 and 1.7. Score it under
the one that names the cause: 1.7 when the interface asks for more than its implementers can do, 1.6
when inheritance was the wrong tool for a type that could not honour its parent.

#### 1.8 Modules hide design decisions

The unit of decomposition is a decision likely to change, not a step of processing. A file format, a
protocol, the shape of a third party's API, a caching policy, the way an identifier is generated:
each belongs to one module, which hides it behind an interface simpler than what it hides. Parnas
named the principle; Ousterhout gave it a measure — **depth**, the functionality a module provides
against the complexity of its interface. A deep module hides a great deal behind a little. A shallow
one has an interface nearly as complicated as its body: it adds a name to learn without removing
anything to understand.

1.1 asks whether a class keeps its fields private. This asks something larger: whether a decision is
known in one place. A class with every field private can still leak its decision through its
interface — `getRowsAsArray()` tells every caller that there are rows, and that they are arrays.

Where 2.6 finds Shotgun Surgery or Middle Man, this is usually the cause. 2.6 scores the shape of the
code where it is read; 1.8 scores whether the decision behind it has one owner.

**Good:**

- Each volatile decision has an owner: the JSON shape of a partner's API is known to its adapter and
  nowhere else, the retry policy to one client
- Interfaces named in the caller's terms, not the implementation's: `findOverdueInvoices()`, not
  `queryInvoicesWhereDueDateLessThanNow()`
- Modules whose interface is markedly smaller than their implementation
- A change to a format or a protocol that touched one module, visible as such in the history

**Bad:**

- Information leakage: one decision encoded in two places — a parser and a serialiser that must
  change together, a date format repeated in three adapters, a status code interpreted by every caller
- Pass-through methods: a layer whose methods call the next layer's methods with the same signature
  and add nothing
- Classes split so finely that using any one of them requires knowing the others
- Interfaces that expose the implementation: return types tied to the storage, method names that
  describe the algorithm

**How to check.** Reading finds a leak only where the reader already suspects one. The history finds
the rest: files that keep changing together share a decision, whatever the directory tree says.

```bash
# pairs of files changed together in five or more commits over the last year
git log --since='12 months ago' --no-merges --format='%x40' --name-only |
awk '/^@/ { for (i in f) for (j in f) if (i < j) n[i " " j]++; delete f; next }
     NF   { f[$0] = 1 }
     END  { for (i in f) for (j in f) if (i < j) n[i " " j]++
            for (p in n) if (n[p] >= 5) print n[p], p }' | sort -rn | head -20
```

A test moving with its subject is expected, and so are the release files — version, changelog,
install instructions — moving with every release, which is principle 25 working. Two production files
in different modules moving together, release after release, are one decision with two owners — name
the decision in the finding.

---

## Category 2 — Clean Code

**What it measures:** How well the code communicates its intent to a human reader without requiring external context or comments to decode — and, in 2.9 and 2.10, whether the text it writes for its users can be read in their own language.

2.1–2.8 are always evaluated, and 2.11 wherever the history contains changes to existing code. 2.9 and 2.10 are evaluated wherever the system produces text for someone using it: they are N/A only for a codebase that produces none — a pure library, a machine-only pipeline, or a tool whose only readers are its own developers and operators.

### Subcriteria

#### 2.1 Naming

Names reveal intent. The name of a variable, function, or class should answer: what is this, what does it do, and why does it exist?

**Good:** `calculateMonthlyInterest()`, `hasExpired()`, `isEligibleForDiscount()`, `pendingOrders`.

**Bad:** `calc()`, `doStuff()`, `flag`, `tmp`, `data`, `Manager` (what does it manage?), `Helper` (help with what?).

**Rules of thumb:**

- Boolean variables and functions: `is`, `has`, `can`, `should` prefix
- Functions: verb phrase describing what they do, not what they return
- Classes: noun phrase describing what they represent, not what they do
- Avoid abbreviations unless they are universally understood in the domain (e.g., `id`, `url`, `html`)

#### 2.2 Function size and focus

Functions should do one thing. If a function needs a comment to explain each "section", it is
multiple functions in disguise.

**Size is a signal, not the criterion.** The opposite failure is real and scores the same way: a
function cut into pieces so small that each hides nothing, so the reader follows six calls to learn
what one body would have told them. Ousterhout calls these *shallow* — an interface nearly as complex
as the implementation behind it. An extraction is worth making when the extracted function hides a
decision its caller does not need to know. It is noise when the caller has to read it anyway.

**Good:** Functions that do exactly what their name says — usually short, with 5–20 lines as the
common shape rather than the requirement. A longer function that does one thing in a straight line,
with no sections, is fine. A test function per behaviour.

**Bad:** Functions over 50 lines that set up state, execute logic, clean up, format output, and
handle errors — all in one body. Equally: chains of one-line functions that pass their arguments
straight through, and helpers called once whose name says no more than their body.

**Test:** Would extracting a named sub-function let a reader understand the parent *without reading
the sub-function*? If yes, extract it. If they would have to read it anyway, the extraction adds a
jump and hides nothing.

#### 2.3 DRY (Don't Repeat Yourself)

Every piece of knowledge has a single, authoritative representation in the codebase — Hunt and Thomas's formulation of the principle they named. Duplication is not just copy-pasted code — it is also duplicated concepts expressed in different ways.

**Good:** A single `sanitizeSymbol()` function called from every place that needs it. A shared validation rule used by both the API endpoint and the CLI command.

**Bad:** The same regex in three files. The same business rule expressed in the controller, the service, and the template. Two `decodeJson()` methods with slightly different signatures doing the same thing.

**Nuance:** Not all duplication is bad. Two functions that happen to look similar but evolve independently for different reasons should not be merged. Only merge code that represents the same knowledge.

#### 2.4 Error handling

Errors are first-class citizens, not an afterthought. The error-handling strategy should be consistent, visible, and recoverable.

**Good:** Domain exceptions with descriptive names (`CoinNotFoundException`, `PaymentDeclinedException`). A single top-level handler that logs the full context and returns a structured error response. No silent failures.

**Bad:**

- `catch (\Exception $e) {}` — swallows all errors silently
- `@file_get_contents(...)` — suppresses PHP errors with the `@` operator
- Returning `null` or `false` to signal failure, forcing every caller to check
- Catching a specific exception only to re-throw `new \Exception("Something went wrong")`

#### 2.5 Self-documenting code

Code that can be read and understood without comments, because the names, structure, and types carry the meaning.

**Good:** A method named `isEligibleForEarlyAccess()` that reads like a sentence: `return $user->isVerified() && $campaign->hasStarted() && !$user->hasAlreadyRedeemed($campaign)`.

**Bad:** A 40-line calculation with a comment at the top explaining what it does, instead of being extracted into a named function. Comments that describe *what* the code does (the code already shows that) instead of *why* a non-obvious decision was made.

**When comments are appropriate:** Non-obvious business rules ("// per regulation X, we must retain this for 7 years"), known trade-offs ("// unsafe-inline required because the template inlines JSON"), and API contract notes.

The interface comment is the one most often missing: what a function or class promises its caller
that the signature cannot say — units, ownership, what an empty input does, which errors it raises
and when. If a caller would have to read the implementation to use it correctly, the interface is
undocumented however clean the body is. A comment that restates the code is still drift; one that
states the contract is part of the interface.

#### 2.6 Refactorability and code smells

A codebase is not only evaluated on what it does now, but on how safely it can be changed. Refactorability is a structural property: the presence of seams (Feathers: points where behaviour can be changed without modifying surrounding code), the testability of individual units as a precondition to safe refactoring, and the absence of the known patterns that signal structural degradation.

The code smell catalogue of Fowler and Beck (*Refactoring*, 2nd edition — the names below are that edition's) provides a shared vocabulary for naming structural problems without ambiguity. The most impactful smells to watch for:

| Smell | Signal | Typical fix |
|---|---|---|
| **Long Function** | Function over 20–30 lines; needs comments to divide "sections" | Extract Function |
| **Large Class** | Class over 200 lines; does too many things | Extract Class |
| **Feature Envy** | A method uses another class's data more than its own | Move Function |
| **Data Clumps** | The same group of 3+ fields passed together repeatedly | Extract Class — often into a Value Object (3.3) — or Introduce Parameter Object |
| **Primitive Obsession** | `string` or `int` used where a domain concept (`Money`, `EmailAddress`, `OrderStatus`) should exist | Replace Primitive with Object |
| **Shotgun Surgery** | A single change requires edits in many unrelated classes | Move Function / Move Field to consolidate |
| **Divergent Change** | A single class changes for multiple different reasons | Split Phase or Extract Class (split by reason to change) |
| **Repeated Switches** | A `switch` on a type field that recurs throughout the codebase | Replace Conditional with Polymorphism |
| **Middle Man** | A class that does nothing but delegate every call to another class | Remove Middle Man or Inline Function |
| **Temporary Field** | Instance variables that are only set in certain paths | Extract Class or Introduce Special Case |

**Test for refactorability:** Can a Long Function be extracted into smaller named functions without changing the public contract? Can a dependency be swapped without touching call sites? If the answer is "no" because of global state, hardcoded instantiation, or missing interfaces — the code is not safely refactorable, regardless of how clean it looks.

**Good:** Methods short enough to be extracted cleanly. Dependencies injected so they can be replaced in tests. No `static` methods with side effects that cannot be overridden.

**Bad:** A 150-line method where every line is entangled with the others. A class where adding a new behaviour requires understanding — and modifying — unrelated methods. No seams: `new ConcreteClass()` inline, impossible to substitute in a test.

#### 2.7 Technical debt management

Technical debt is the accumulated cost of deliberate shortcuts taken to ship faster. It is not inherently bad — incurring debt knowingly and repaying it intentionally is good engineering. The problem is invisible, untracked, or denied debt.

**Good:**

- Shortcuts are annotated inline with the reason and the future intent: `// TODO [tech-debt]: using direct DB query here — refactor to use OrderRepository once migration is complete`
- A maintained backlog of known debt items, each with: description, business reason it was incurred, estimated cost to repay, priority
- Debt repayment is budgeted in sprint planning as a first-class activity, not "whenever there's time"
- New deliberate debt requires a decision record (ADR or ticket) — not a silent shortcut

**Bad:**

- `// TODO: fix this` with no explanation, no author, no date, no ticket reference
- Technical debt discovered only during incidents — it was never tracked
- "Cleanup sprints" that never happen because product priorities always win
- A codebase where developers hesitate to change anything because they cannot predict what will break

**Relationship to refactoring:** Technical debt management without refactoring discipline is a wishlist. Refactoring discipline without technical debt tracking is unsustainable urgency. Together they form the practice of intentional code evolution.

#### 2.8 Language of identifiers

Code is written in English. A domain term is kept in its original language when the English word
would not name the same thing — and every such term is declared together with **the context it
belongs to**.

Both halves are load-bearing. English is the language of the platform, the standard library, the
framework, and of whoever joins the project later; a codebase where `getUtenti()` sits beside
`findOrders()` makes every reader guess which convention applies where. But translating a domain
term for the sake of uniformity destroys precision: a *Codice Fiscale* is not a tax code and a
*Fattura Elettronica* is not an invoice — these are artefacts defined by law, and the English word
names something broader. Category 3 calls this the ubiquitous language; this criterion is where it
is measured.

**The test, and why it is scoped to a context:**

> In this bounded context, does the English word name the same thing?
>
> Yes → use English. It names something broader, narrower, or different → keep the original term.

The test is context-local, which means **the same concept legitimately carries different names in
different contexts**. In a generic payments core, `Invoice` is correct: there the concept genuinely
is a generic accounting record. Inside a module implementing Italian e-invoicing law,
`FatturaElettronica` is correct: there the concept is the legally defined document, and `Invoice`
would name a superset of it.

Those two names are not an inconsistency to be unified. They are a context map doing its job, and a
reviewer who "harmonises" them deletes the distinction the code was built to hold.

**The declaration:**

The project's `.claude/CODING_STANDARDS.md` carries a **Domain language** section: one row per term,
naming the term, the context it belongs to, its meaning, and why it is not translated. A term used
**inside** its declared context is correct. The same term appearing **outside** it is not an
exception — it is a boundary leak, and a worse finding than a naming slip, because it means a
context has learned a concept that should have reached it through a translation.

Single-context projects declare the context as the whole codebase and the column costs nothing.

**Seams are where this actually breaks:**

Between two contexts something must translate, and half-translated identifiers appear almost
exclusively there: `getFatturaList()`, `ElectronicInvoiceFattura`, `IsPagato`. The translation has to
be an explicit, named thing — a mapper or adapter that takes an `Invoice` and produces a
`FatturaElettronica` — not an implication spread across renamed fields.

**Not translating means keeping the domain's grammar:**

The precision being protected is the domain's own. *FatturaElettronica* is the document;
*FatturazioneElettronica* is the process — so a module or service may carry the second name, an
entity may not. Inventing a compound the domain does not use loses exactly what translating would
have lost.

**Scope.** Identifiers (classes, methods, variables, files, database columns), comments,
developer-facing messages, test names, technical documentation. **Not** user-facing text: labels,
emails and messages shown to end users are measured by 2.9 and 2.10, which ask a different question —
not what language the code is written in, but whether the product can be read in a language it was
not written in.

**Good:**

- `final class Fattura` next to `final class OrderRepository`, with `Fattura` declared and scoped to
  the billing context
- The same concept named `Invoice` in the payments core and `FatturaElettronica` in the Italian
  compliance module, with an explicit `FatturaElettronicaMapper` at the seam
- A declared row that reads like a decision: "*Cedolino* — payroll context — Italian statutory
  payslip; the English `Payslip` names a broader document with no legally defined format"
- Domain terms kept whole and grammatically as the domain uses them: `FatturaElettronica` the
  document, `FatturazioneElettronica` the process
- Comments and test names in English even about domain terms:
  `it_rejects_a_fattura_without_a_partita_iva()`

**Bad:**

- General vocabulary in the local language where English names the same thing: `getUtenti()`,
  `$elencoProdotti`, `salvaOrdine()`
- Half-translated identifiers, especially at a context boundary: `UserFattura`, `getFatturaList()`
- A declared term used outside its context — `FatturaElettronica` reaching the generic payments
  core, which should only know `Invoice`
- A glossary with no context column, in a codebase that has more than one context: it cannot
  distinguish a correct use from a leak, so it authorises both
- Rows with a meaning but no reason. "*Fattura*: invoice" declares nothing — if that is the whole
  entry, the term should have been translated
- A glossary that has grown to cover every local word in the codebase. That is not a glossary, it is
  an amnesty: exceptions granted retroactively to avoid renaming
- Comments in the local language inside otherwise English code — above all the ones explaining
  *why*, whose reader is the one least likely to read that language
- Non-ASCII characters in identifiers (`città`, `prezzoUnitàrio`): they break greps, tooling and
  other people's keyboards
- One declared term spelled three ways across the codebase (`Fattura`, `fattura_elettronica`,
  `FattElettr`): declaring a term is also committing to one spelling of it

**How to score.** Read the Domain language section before judging any identifier, then sample across
the layers *and across the context boundaries*. Full marks require three things: English as the
default, the exceptions declared with contexts and reasons, and the declared terms staying inside
their contexts. A uniformly English codebase with nothing to declare scores full marks with no
section — the criterion measures consistency and intent, not the existence of a glossary. Weight a
boundary leak above a local naming slip: the first says the architecture is eroding, the second says
someone was in a hurry.

#### 2.9 Translatability of user-facing text

*Applies wherever the system produces text for someone **using** it. Mark N/A only for a codebase
with no such output — a pure library, a machine-only pipeline, or a tool whose only readers are the
developers and operators of the system itself. A product CLI, an API with displayable error
messages, or a batch job that emails a report is not N/A.*

Every string a person reads goes through a translation mechanism, and the mechanism reaches every
surface the system writes to. English is the source text and the last link of the fallback chain.

This is not the question 2.8 asks. That one asks what language the *code* is written in; this one
asks whether the *product* can speak a language it was not written in. A codebase scores full marks
on 2.8 and is still untranslatable if every label was typed straight into a template.

**Where it applies:** UI labels and templates, PDFs and generated reports, emails and notifications,
product CLI output, and validation and error messages that reach a screen. A surface that writes text
for a person is in scope whether or not the project thinks of it as "the UI".

**The line is the reader, not the surface.** 2.8 already claims developer-facing messages — logs,
stack traces, assertion text, the output of a build script or an operator command — and keeps them
in English, untranslated. This subcriteria claims the text written for someone using the product. A
developer tool whose only readers are its own operators has no user-facing text at all, and both 2.9
and 2.10 are N/A for it. When the same message reaches both, it is user-facing: the operator can read
English, and the user may not.

**English is the source, and the fallback that never fails.** Text is authored in English. A locale
with no entry for a key renders the English text — never a blank, a raw key, or an exception. Terms
declared under 2.8 are not translated in any locale: the English catalog says `FatturaElettronica`,
because that is the name of the thing.

**The pocket is the failure mode.** Translation is rarely absent outright; it is almost always
partial, and the part left behind is the one nobody demos — the PDF, the cron job's email, the CLI's
error text. One uncovered surface makes the product monolingual for everyone who reaches it.

**Where the catalog must not reach:** the domain. 3.2 keeps display concerns out of domain objects,
and a translation key inside an entity is that same leak — the domain names the *fact*
(`OrderRejected`, an error type), and the layer that speaks to a person chooses the sentence.

**Good:**

- Every surface resolving text through one mechanism: web templates, the PDF builder, the mailer and
  the console command all read from the same catalog
- The framework's own translation component rather than a hand-rolled `t()` (see 6.2)
- A missing Italian key rendering the English text, with the miss logged rather than swallowed
- Declared domain terms left whole in every catalog:
  `en.billing.fattura_elettronica = "FatturaElettronica"`
- Text held as data with named placeholders — `orders.shipped_on` taking a date argument — so a
  language with different word order can reorder it

**Bad:**

- Literal human-readable text inside a template, a PDF builder or a mail body: `<h1>Invoice</h1>`,
  `$pdf->text('Total due')`
- A translated web UI whose emails, PDFs and CLI output are hardcoded — the pocket
- Exception and validation messages written for developers and then shown to users unchanged
- A missing key rendering `orders.shipped_on` or an empty string on the page
- Sentences assembled from translated fragments: `t('the order') . ' ' . t('was shipped')`
- A translation key stored on a domain entity, so the domain now knows how it will be displayed
- A second language added by duplicating the templates rather than by adding a catalog

**How to score.** Do not sample the surface the project is proud of. List every place the system
writes text for a person — templates, PDF, mail, CLI, API error payloads that reach a screen — and
check each one for literal text. Weight one entirely uncovered surface far above a scatter of stray
strings: the first says the mechanism has a boundary, the second says someone was in a hurry. A
project with no mechanism at all scores in the 0–2 band however clean its templates are, because
this subcriteria measures whether a second language is possible, not whether the first one is tidy.

#### 2.10 Locale coverage

*Applies wherever the system produces text for someone using it — same scope as 2.9, and N/A on the
same grounds.*

The project declares which languages it serves, and the catalogs are complete for every one of them.
2.9 asks whether the product *can* be translated; this asks whether it *has been*, for the people who
actually need it.

**The declaration.** The project's `.claude/CODING_STANDARDS.md` carries a **User-facing text**
section naming the translation mechanism and listing the required locale set: one row per locale with
the reason it is required. English is always in the set. A project whose domain is defined in another
language is serving people who work in that language — a codebase built on `FatturaElettronica` has
Italian users, and English-only is a coverage gap, not a decision.

**Good:**

- A declared locale set with a reason on every row, and a catalog for each that a key-set diff shows
  is complete
- `en` and `it` in a project implementing Italian e-invoicing, because the people who file a
  `FatturaElettronica` work in Italian
- A CI step that fails when a key exists in one catalog and not in another
- A feature landing with its keys in every declared locale in the same change, rather than in a
  "translations" ticket that never comes up

**Bad:**

- One catalog with 900 keys and another with 300, and nobody able to say which 600 are missing
- Keys present but empty, so the page renders blank instead of falling back to English
- A declared locale nobody has updated in a year, drifting behind the English text it mirrors
- A locale set that exists only in someone's head: with no declaration there is nothing to be
  complete against, so coverage cannot be distinguished from ambition
- A project whose domain is defined by another country's law shipping English only, with no row
  explaining why

**How to score.** Read the **User-facing text** section first. Without a declared set there is
nothing to measure completeness against, and that absence is the finding — 3–4 at best, however many
catalogs exist. Then diff the key sets across locales and check when each was last touched: a catalog
that stopped being updated is worse than one never started, because it renders stale text with no
warning.

**What is scored is the project's declaration, not the evaluator's machine.** The required locale set
is the one written in the project's file. Two people auditing the same commit must reach the same
score: a number that moved because a different laptop ran the audit is worse than a low one, because
it enters `docs/audits/history.md` as a trend. Nothing outside the repository enters this score. A
language in real use but missing from the declared set enters one step earlier — it is a finding
about the *declaration*, reported as a gap in that section and never as a deduction against the
catalogs. Name the locale, not the person.

#### 2.11 Refactoring proceeds in behaviour-preserving steps

*Applies wherever the history contains changes to existing code. N/A only for a repository too young
to have restructured anything.*

2.6 scores whether the code *can* be changed safely, and 2.7 whether its debt is known. Neither looks
at how the code is actually changed — and that is where a refactoring goes wrong. Not in the decision
to make it, but in a diff that moved thirty things at once and changed one behaviour on the way,
which nobody can now find.

A refactoring, in Fowler's sense, is a change to structure that leaves observable behaviour exactly
as it was. That definition is what makes it checkable. Done as a sequence of small named steps —
Extract Function, Move Function, Rename Variable — each followed by a green suite, every step is easy
to review because it is one known transformation, and easy to revert because nothing else rides on
it. Done as one large restructuring, it is a rewrite with a reassuring commit subject.

Beck adds the order. When a behaviour change is hard to make, first change the structure so that it
becomes easy, in its own commit, then make the change that is now easy. The structural commit is
reviewed as *nothing changed*; the behavioural one as a small diff.

**The evidence is the log**, read the way 4.7 reads it. Conventional Commits make the first query
exact; without them, pick the restructuring commits by hand — an unlabelled history is harder to
query, not exempt from the question.

```bash
# refactoring commits that changed what the tests assert. A rename shows up as a removed and an
# added assertion differing only in the renamed identifier: read those, do not count them.
git log --since='6 months ago' --format='%h %s' --grep='^refactor' | while read -r sha subject; do
  n=$(git show "$sha" --format= -U0 -- '*test*' '*Test*' '*spec*' |
      grep -cE '^[-+][^-+].*(assert|expect|should)')
  [ "$n" -gt 0 ] && printf '%s  assertion lines changed: %s  %s\n' "$sha" "$n" "$subject"
done
```

Then two readings the query cannot do. **Step size and state:** the refactoring commits' sizes
against each other, and whether CI was green on each — indicators 2 and 4 of 0.8 apply unchanged.
**Order:** inside a unit of work, whether the structural commits came before the behavioural change
they made room for, or arrived tangled in it.

**Not 10.11, and not 4.7.** 10.11 scores whether the commit message is a good message; this scores
whether a commit labelled as a refactoring was one. 4.7 reads fixes for the test they leave behind;
this reads restructurings for the tests they leave *unchanged*.

**Good:**

- Refactoring commits that change no assertion, or change only the identifiers the refactoring
  renamed
- Steps named for the transformation they apply: `refactor(billing): extract function computeVat
  from Invoice::total`
- Each step green in CI on its own — the gate ran between the steps, not only after the last one
- A behaviour change preceded by the structural commit that made it small: the `refactor:` that makes
  room, then the `feat:` or `fix:` that uses it
- A large mechanical refactoring cut as *The mass rename is the most ordered change of all*
  describes: one transformation per step, however many sites

**Bad:**

- `refactor:` commits that change assertions or add tests for new behaviour — a behaviour change
  under the one label that tells the reviewer not to look for one
- A single commit that restructures a module and fixes the bug that prompted it: the fix cannot be
  reverted without the restructuring, nor reviewed apart from it
- *"Refactor billing module"*, one commit, two thousand lines, red in CI until the follow-up
- Steps that leave the build red in between, repaired by the next one
- A refactoring of code no test covers, so *behaviour-preserving* is a belief rather than a check —
  *Remediation order* is the gate this skipped

**How to score:**

- 0–2: Restructuring arrives inside feature and fix commits, or as large single commits. Nothing in
  the history distinguishes a refactoring from a rewrite
- 3–5: Refactoring commits exist and are labelled, but they are large, carry behaviour changes, or
  routinely change what the tests assert
- 6–7: Refactorings are separate from behaviour changes and leave the assertions alone; the steps are
  coarse — one commit per module rather than per transformation — or the gate is not green between
  them
- 8–10: Refactorings arrive as small named steps, each green, none changing what the tests assert;
  a behaviour change that needed room is preceded by the structural commit that made it

---

## Category 3 — Domain-Driven Design (DDD)

**What it measures:** How faithfully the architecture separates business logic from technical infrastructure, and how well the domain model communicates the language of the business.

### Subcriteria

#### 3.1 Layer separation

The codebase is organized into layers with a strict dependency direction:

```text
Domain  ←  Application  ←  Infrastructure
                         ←  Presentation (HTTP, CLI)
```

- **Domain:** Entities, Value Objects, Repository interfaces, Domain Exceptions, Domain Events. Zero dependencies on infrastructure or frameworks.
- **Application:** Use Cases, Application Services, DTOs. Depends only on the Domain layer.
- **Infrastructure:** Repository implementations, external API clients, mappers, email senders. Implements Domain interfaces.
- **Presentation:** Controllers, CLI commands, views. Depends on Application layer only.

**Bad:** A domain entity that imports a database class. A use case that calls `json_encode`. A controller that contains business logic. A repository implementation that is referenced by name in a use case.

**Adaptation for native mobile apps (iOS, Android, Flutter):** The four-layer model applies but the layers map differently. There is no HTTP Presentation layer — the entry point is a screen or a ViewModel. Infrastructure covers local persistence (CoreData, Room, SQLite) and remote API clients rather than a web server. The dependency rule is identical: the Domain layer must not know about UIKit, SwiftUI, Jetpack Compose, or any persistence framework. Application layer Use Cases remain the boundary between UI and domain. A SwiftUI View that directly queries CoreData, or an Android Activity that contains business logic, is the same violation as a PHP controller that queries the database directly.

#### 3.2 Purity of the domain

The domain layer must not know about:

- How data is stored or fetched (SQL, Redis, file system, HTTP)
- How data is serialized (JSON, XML, CSV)
- How data is displayed (HTML templates, CSS classes, localized strings)
- Framework internals (request objects, ORM annotations, DI container)

**Bad:**

- `toCssClass()` on a domain value object — CSS is a presentation concern
- `fromJsonArray()` on a domain entity — JSON parsing is an infrastructure concern
- `toArray()` with HTML attributes in the returned keys
- A domain exception that extends a framework exception

**Good:** Mapper classes in the Infrastructure layer translate raw API/database data into domain objects. Presenter classes in the Presentation layer translate domain objects into view-ready structures.

#### 3.3 Value Objects

A Value Object models a domain concept whose identity is defined by its value, not its instance. They are immutable and always valid.

**Good:**

- `Price` that validates non-negative amounts and rounds to the correct precision
- `EmailAddress` that validates format on construction
- `CoinId` that enforces allowed character set
- `Money` that prevents adding EUR to USD
- All properties `readonly`, no setters, equality by value

**Bad:** Using primitives (`string`, `float`, `int`) where a domain concept exists. A `Price` class with a `setAmount()` method. A `UserId` that accepts empty strings.

#### 3.4 Entities and Aggregates

Entities have identity that persists across state changes. Aggregates are clusters of entities and value objects that are treated as a single unit for data changes, protected by an Aggregate Root.

**Good:** `Order` as aggregate root controls access to `OrderLine` items. Business invariants (e.g., "an order must have at least one line") are enforced inside the aggregate, not in the service layer.

**Bad:** Business invariants enforced only in controllers or services, leaving the domain object susceptible to being put in an invalid state by other paths. Direct access to child entities bypassing the aggregate root.

#### 3.5 Repository interfaces

Repository interfaces live in the Domain layer and express domain language: `findById`, `findAllActive`, `save`. Implementations live in Infrastructure.

**Good:**

```php
// Domain layer
interface OrderRepositoryInterface {
    public function findById(OrderId $id): ?Order;
    public function findByCustomer(CustomerId $id): list<Order>;
    public function save(Order $order): void;
}
```

**Bad:** A repository interface with methods like `executeQuery()`, `fetchRows()`, or any reference to a specific storage technology.

#### 3.6 Use Cases / Application Services

Each use case encapsulates one business operation: one entry point, one responsibility, one reason to change.

**Good:** `PlaceOrderUseCase`, `CancelOrderUseCase`, `GetOrderHistoryUseCase` — one verb, one noun, one file.

**Bad:** A `OrderService` with 20 methods that is a dumping ground for every order-related operation. Use cases that contain SQL queries. Use cases that format HTML or JSON.

#### 3.7 Domain Events

A Domain Event is a named, immutable record that something significant happened in the domain. It is a first-class domain artefact, not a technical mechanism.

The distinction matters: `OrderPlaced`, `PaymentDeclined`, `EmployeeBenefitActivated` are domain events — they express something the business cares about, in language the business uses. `onAfterSave`, `EntityPersistedEvent`, `PostCommitHook` are technical hooks — they express an implementation detail of the persistence layer.

**Good:**

- Domain events named in past tense with domain language: `OrderShipped`, `AccountSuspended`, `BenefitRedeemed`
- Domain events defined in the Domain layer as immutable value objects containing only domain data
- Published by the Aggregate Root after a state transition, not by infrastructure code
- Consumers (side effects: emails, audit logs, webhooks, projections) registered in the Application or Infrastructure layer — never in the Domain

**Bad:**

- Events named after technical operations: `UserSaved`, `DatabaseUpdated`
- Events that carry references to infrastructure objects (entity managers, HTTP clients)
- Domain events published from within a repository implementation
- Side effects (sending emails, triggering webhooks) triggered inline inside the domain method that raises the event — this makes the domain method non-deterministic and untestable

**Why it matters:** Domain events make the system's behaviour explicit and auditable. They also decouple side effects from the triggering operation, enabling independent scaling, replay for debugging, and event sourcing as a future option.

#### 3.8 Bounded Contexts and context integration

*Apply this subcategory when the system contains — or communicates with — multiple distinct domains or subdomains. Mark N/A for single-context applications.*

A Bounded Context is the explicit boundary within which a domain model applies. The same word ("User", "Account", "Product") can mean radically different things in different bounded contexts — and conflating them is one of the most common sources of accidental complexity in large systems.

**Context integration patterns (Evans's strategic design, elaborated by Vernon):**

| Pattern | When to use | Risk |
|---|---|---|
| **Shared Kernel** | Two teams share a small, stable subset of the model | Changes to the kernel require coordination between teams |
| **Customer/Supplier** | Upstream context defines the contract; downstream adapts | Downstream depends on upstream's release schedule |
| **Anti-Corruption Layer (ACL)** | Downstream context translates the upstream model into its own model | Extra indirection, but protects domain purity |
| **Open Host Service** | Upstream publishes a formal, versioned API for all consumers | Requires API discipline; breaking changes are costly |
| **Published Language** | A shared, documented interchange format (JSON schema, Protobuf, event schema registry) | Governance overhead, but enables decoupling |
| **Conformist** | Downstream simply adopts the upstream model as-is | Pollutes the downstream domain with upstream concepts |

**Good:**

- An explicit Context Map documenting which bounded contexts exist and how they communicate
- An Anti-Corruption Layer wherever one context must consume another's model without polluting its own
- Domain Events (3.7) as the primary mechanism for cross-context communication — avoids direct coupling between contexts
- Each context has its own ubiquitous language; translation happens at the boundary

**Bad:**

- A single "User" object shared directly across billing, authentication, and profile management — any change to it breaks all three
- Direct database access from one context into another context's tables
- Shared DTOs between contexts that evolve at different rates, causing cascading changes
- No awareness of where one context ends and another begins

**Concrete signal to look for:** If you find yourself writing code like `$employee->getMerchant()->getEmployer()->getContract()` across what should be context boundaries — that is a Conformist integration that has accumulated accidental coupling. Each `->` crossing a context boundary is a seam that should be an explicit integration point.

#### 3.9 The core domain is named, and gets the investment

*Apply when 3.8 applies — a system with more than one subdomain. Mark N/A for single-context
applications.*

Not every part of a system deserves the same care. Evans's distillation separates the **core
domain** — the part that makes the product worth building, where it competes — from **supporting**
subdomains, specific to the business but not distinctive, and **generic** ones every business has:
identity, billing, notifications, search. The machinery of this category earns its cost in the core.
Spent evenly, it is overhead in the generic parts and usually thin in the core, because the core is
where the deadlines are.

Principle 7 says architecture follows the problem. This asks whether the project knows which part of
its problem is the one that matters.

**Good:**

- The product context (0.1) names the core domain in a sentence, and the code has a place where it
  lives
- The richest model, the strictest invariants (3.3, 3.4) and the densest tests are in the core
- Generic subdomains bought or delegated (6.8) — an identity provider, a payment service — rather
  than modelled
- Supporting subdomains built simply, without the full tactical toolkit

**Bad:**

- Aggregates and domain events around user preferences, while the pricing engine the product
  competes on is a 900-line service passing arrays
- A hand-built invoicing engine with its own domain model, in a product whose distinctive work is
  elsewhere
- Nobody can say which part is the core, so investment follows whoever is most interested
- Tests concentrated in the generic code because it was the easiest to test

**How to check.** Ask the context document — or, failing it, the team — which subdomain is core. Then
compare where the richness sits: coverage per directory, value objects per directory, ADRs per area,
recent design effort in the log. The finding is the mismatch between the answer and the evidence.

---

## Category 4 — Testing

**What it measures:** How thoroughly and reliably the test suite verifies the system's behaviour, how maintainable the tests are as the codebase evolves, and whether the suite grows by one test for every defect the project has already paid for.

### Subcriteria

#### 4.1 Unit test coverage

**What to cover:** Domain logic — Value Objects (validation, calculations, comparisons), Entities (business rules, invariants), Mappers (field mapping, edge cases), utility functions.

**What not to force:** Thin wrapper classes, trivial getters/setters, framework glue code.

**Good:** Every constructor invariant has a test that verifies it throws on invalid input. Every business rule method (e.g., `isBullish()`, `isEligibleForDiscount()`) has at least a positive and a negative test case. Edge cases (zero, boundary values, null) are covered.

**Bad:** Tests that only verify the "happy path". Tests that test the framework instead of the code. 100% line coverage with zero assertion coverage (lines executed but no `assert` validating the outcome).

#### 4.2 Unit test quality and testing style

Tests should be deterministic, fast, independent, and readable.

**Good:**

- Test method names describe the behaviour: `testPriceRejectsNegativeAmount`, `testHighIsAlwaysAboveOrEqualToLow`
- Each test has a single logical assertion (may be multiple physical `assert*` calls for the same concept)
- No shared mutable state between tests
- No network calls, no file system, no database
- Helper methods to reduce construction boilerplate (`makeOrder()`, `makePricePoint()`)

**Bad:**

- Tests named `test1`, `testFoo`, `testHappy`
- A single test that validates ten different behaviours
- Tests that depend on execution order
- Tests that use `sleep()` to wait for async operations

**Testing styles — from most to least robust (Khorikov):**

Tests can verify behaviour in three fundamentally different ways. The style matters because it determines how much the test will resist future change.

| Style | What it verifies | Fragility | When to prefer |
|---|---|---|---|
| **Output-based** | Given inputs X, the return value is Y | Low — only breaks when the contract changes | Pure functions, calculations, transformations |
| **State-based** | After calling method X, the object's state is Y | Medium — breaks when internal state structure changes | Domain objects, aggregates, collections |
| **Communication-based** (often called interaction-based) | Method X called method Y N times with argument Z | High — breaks whenever the implementation changes, even if the observable behaviour is unchanged | Cross-boundary calls (e.g., verify an email was sent) |

**Rule:** Prefer output-based tests wherever possible. Use state-based tests for domain objects. Use interaction-based tests (mocks with `verify`) only at system boundaries — to verify that an external side effect was triggered (email sent, event published, log written). Never use `verify(mock, times(1)).someInternalMethod()` to test an implementation detail.

**TDD signal (Freeman & Pryce):** Code written test-first tends to have: injected dependencies (because you need to substitute them in tests before writing the implementation), small focused interfaces (because you define what you need, not what exists), and simple constructors (because complex setup in tests is a design warning). If a test requires 30 lines of setup to construct the subject under test, the design needs simplification — the test is telling you something about the production code.

#### 4.3 Functional / integration tests (within process)

Tests that exercise the system end-to-end without real external dependencies, using stubs or in-memory implementations.

**Good:**

- HTTP contract tests: dispatch a real request through the full stack (Router → Controller → UseCase → StubRepository), verify status code and response body shape
- Cover the most important paths: success, not found (404), service unavailable (503), malformed input
- Use stub implementations, not mocks — stubs are simpler and don't tie tests to implementation details

**Bad:**

- No functional tests at all — unit tests alone cannot catch routing bugs, controller wiring issues, or serialization problems
- Functional tests that mock every dependency — they end up testing the mock, not the code

#### 4.4 Integration tests (external dependencies)

Tests that make real calls to external services to verify the API contract is still honoured.

**Purpose:** Detect breaking changes in third-party APIs — shifted field positions, removed keys, changed response shapes — that unit tests cannot catch because they use stubs.

**Good:**

- Run in a separate test suite, excluded from the default CI run (to avoid rate-limiting and flakiness)
- Annotated with `#[Group('integration')]` and run explicitly with `vendor/bin/phpunit --group integration`
- Test the raw response contract (field names, types, structure) as well as domain-level invariants (high >= low, chronological order)
- Use `markTestSkipped()` gracefully when the external service is unavailable, instead of failing
- Minimize API calls: `setUpBeforeClass()` fetches data once, individual tests assert against the cached result

**Bad:**

- Integration tests mixed into the default test run — causes CI failures due to network issues
- No integration tests at all — you find out about API contract changes in production

#### 4.5 Test naming and organization

**Good:**

- One test class per production class
- Tests grouped into mirrored directory structure (`tests/Unit/Domain/ValueObject/PriceTest.php` mirrors `src/Domain/ValueObject/Price.php`)
- Test method names follow the pattern: `test[Subject][Condition][ExpectedOutcome]` or `test[WhatItDoes][WhenThisCondition]`

**Bad:**

- All tests in a single file or directory
- Tests that require reading the implementation to understand what they're testing

**A skip is a deadline, not a state.** A suite's organisation includes which of its groups CI
actually runs, and that is where tests go to disappear. A test skipped *for now* — a flaky one parked
until someone has time, a group excluded while an environment was broken, an annotation added during
a release crunch — is removed from the suite without being removed from the repository. It still
appears in the test count, it still looks like coverage from the outside, and it protects nothing.
4.4's `markTestSkipped()` for an unavailable external service is the opposite case and stays correct:
it skips on a *condition evaluated at runtime*, so the test returns on its own the moment the
condition clears.

The distinction to score is whether a skip can end: a condition that lifts it by itself, or a
recorded reason and an owner. Not an annotation whose only exit is somebody noticing.

**Good:** `vendor/bin/phpunit --list-groups` (or the suite's equivalent) and the CI invocation agree
on which groups run; every unconditional skip names a reason and an issue; the count of skipped
tests is visible in CI output, so it has to go up in public.

**Bad:** a skip annotation whose comment is `// flaky` and whose git blame is two years old. A group
excluded in CI that no longer exists in anyone's mental model of the suite. A suite whose green run
is green because forty of its tests do not execute, and whose summary line nobody reads to the end.

#### 4.6 Test doubles used correctly

Meszaros (*xUnit Test Patterns*) distinguishes five types of test double, each with a specific role. Using them interchangeably produces tests that are either too brittle or too permissive.

| Type | What it does | When to use |
|---|---|---|
| **Dummy** | Passed but never used | Satisfying a required parameter that has no effect on the test |
| **Stub** | Returns pre-configured answers to calls | Providing indirect inputs to the subject under test (query results, config values) |
| **Fake** | A working but simplified implementation | In-memory repository, in-process event bus — faster and simpler than the real thing |
| **Spy** | Records calls for later assertion | When you need to verify an indirect output happened, but don't want to pre-program the expectation |
| **Mock** | Pre-programmed with expectations; fails if not met | Verifying that a specific interaction with a collaborator occurred |

**The critical rule — mock only what you own (Freeman & Pryce):**
Never create a mock of a class you do not control (a third-party library, a framework class, an external SDK). If the library changes its interface, the mock will still pass while the real integration breaks. Instead:

1. Wrap the third-party class in an interface you own (`HttpClientInterface`, `PaymentGatewayInterface`)
2. Mock *your* interface in tests
3. Test the adapter that wraps the third-party class with a real (or recorded) integration test

**Good:**

```php
// PHP (PHPUnit) — own the interface; mock it freely
interface HttpClientInterface {
    public function get(string $url): string;
}
$http = $this->createMock(HttpClientInterface::class);
$http->method('get')->willReturn('{"price": 42000}');
```

```typescript
// TypeScript (Jest) — same principle
const http: HttpClientInterface = { get: jest.fn().mockResolvedValue('{"price":42000}') };
```

```python
# Python (unittest.mock)
with patch.object(HttpClientInterface, 'get', return_value='{"price": 42000}'):
    ...
```

```swift
// Swift (XCTest) — protocol-based fake
class FakeHttpClient: HttpClientProtocol {
    func get(url: String) -> String { return "{\"price\": 42000}" }
}
```

**Bad:**

```php
// Mocking a third-party concrete class — brittle, couples the test to the implementation
$guzzle = $this->createMock(GuzzleHttp\Client::class);
$guzzle->method('request')->willReturn(new Response(200, [], '{"price": 42000}'));
```

The bad pattern is identical across all languages: mocking `OkHttpClient` in Kotlin, `aiohttp.ClientSession` in Python, or `URLSession` in Swift produces the same fragility.

**Prefer stubs and fakes over mocks for dependencies you query:** If you only need a repository to return data, use a `StubOrderRepository` with pre-loaded data. Reserve mocks for verifying side effects (emails sent, events published) — interactions, not queries.

#### 4.7 Bug fixes leave regression tests behind

The six subcriteria above measure the suite against the code as it is today: what is covered, how
well, with which doubles. This one measures it against the project's own history — whether each
defect the project has already paid for is pinned by a test, and whether those tests survive the
years between the fix and the next person to touch that code.

It is the most mechanically observable criterion in this category, because the evidence is the log.
Every bug-fix commit either changed a test file or did not:

```bash
# Conventional Commits. Without them, read the subjects and pick the fixes by hand —
# an unlabelled history is harder to query, not exempt from the question.
git log --format='%H%x09%s' --grep='^fix' | while IFS=$'\t' read -r sha subject; do
  git show --name-only --format= "$sha" \
    | grep -qiE '(^|/)(tests?|spec|__tests__)/|(_test|Test|\.test|\.spec)\.' \
    && printf 'test  %s\n' "$subject" || printf 'NONE  %s\n' "$subject"
done
```

That ratio is the first number. The second is whether the tests were real: for three to five recent
fixes, check out the fix's parent, bring in only the new test, and run it. A regression test that
passes against the unfixed code was written from the fix rather than from the bug, and asserts that
the new code does what the new code does.

The third is whether they stay. `git log --diff-filter=D --name-only -- tests/` lists every deleted
test; each deletion should sit in a commit that changed the behaviour the test pinned, not in a
refactor, a suite reorganisation, or a sweep for slow or flaky tests.

**Scope:** N/A only where the history is structurally too short to contain bug fixes — a repository
in its first weeks. Unlabelled commits do not make it N/A, and neither does a small number of fixes:
four fix commits are a sample, and four fix commits with no tests are an answer.

**Good:**

- The test arrives in the fix commit and fails on that commit's parent
- The test names the defect it pins — issue id in the method name, or one line of docblock. The next
  reader can see why a test exists for an input nobody would think to try
- Regression tests run in the default suite, at the lowest level that reproduces the defect
- A defect that recurs is treated as a finding about the suite, not as bad luck
- Retiring a regression test happens in the commit that changes the behaviour it pinned, and says so

**Bad:**

- Fix commits that touch only production code. *"Test to follow"* is a commitment with no deadline
  and no artifact, and the follow-up competes with the next bug
- A regression test that passes when the fix is reverted — written from the diff, not from the report
- Regression tests parked in a skipped group, a `@flaky` tag, or a suite CI does not run. A test
  nobody runs is documentation with a build cost
- A regression test deleted in a refactor, or folded into a broader test that no longer exercises the
  specific input. The coverage number does not move; the defect becomes reachable again
- The same defect twice in the log, months apart, two commits touching the same lines for the same
  reported reason. This is the finding that scores the subcriteria on its own

**How to score:**

- 0–2: No relationship between fix commits and test changes. Defects are closed by changing code and
  confirming manually that the symptom is gone
- 3–5: Some fixes carry a test, usually where the code already had a suite and the test was cheap.
  No expectation stated anywhere, so it holds exactly as long as the schedule does
- 6–7: Most fixes carry a test, and the tests are genuine. The lifetime of a regression test is not
  governed: deletions are not examined, and a test removed in a refactor removes the guarantee with it
- 8–10: Every fix carries a test that failed first, at the level the defect lives on and naming the
  defect; a recurrence is treated as a defect of the suite; and retiring a regression test requires
  the behaviour change that justifies it. The log for the last year shows no defect fixed twice

---

## Category 5 — JavaScript / Frontend Quality *(Web/Browser)*

**Scope:** This category applies to browser-based frontends — JavaScript, TypeScript, and any framework running in a browser (React, Vue, Svelte, Angular). For native mobile clients (iOS/Swift, Android/Kotlin, Flutter/Dart) mark this category **N/A** and apply the principles of Categories 1, 2, and 3 directly to the native layer instead: function purity, explicit state, separation of concerns, and async discipline translate to any language without a browser runtime.

**What it measures:** How well the frontend code manages complexity, side effects, and state, using the same rigour applied to backend code.

### Subcriteria

#### 5.1 Function purity

A pure function's output depends only on its inputs and has no side effects. Pure functions are trivially testable, composable, and predictable.

**Good:** Format helpers (`formatPrice`, `formatDate`), calculation functions (`computePercentageChange`, `normalizeToRange`), and rendering helpers that accept data and return a string or DOM structure — all pure.

**Bad:** A function named `updatePrice()` that reads from a global variable, modifies the DOM, and schedules a timeout — three side effects in one function.

**Approach:** Identify the pure core (calculations, transformations) and separate it from the impure shell (DOM, fetch, timers). Pure functions form the inner layer; side effects are pushed to the edges.

#### 5.2 State management

State should have a single, explicit owner. Mutation should happen in one place, not scattered across functions.

**Good (small apps, no framework):** State variables collected in a single module with explicit read (`getState()`) and write (`setState()`) functions. Other modules receive state as function arguments.

**Good (larger apps):** A state store (Redux, Zustand, or similar) with immutable updates, centralized mutation, and clear data flow.

**Bad:** The same logical value mutated from multiple functions. Global `let` variables modified by any function that imports the module. State changes that happen as a side effect of rendering.

#### 5.3 Explicit dependencies

Every function should declare its dependencies explicitly (through parameters or module imports) rather than reaching into global scope.

**Good:**

```javascript
function updateCoinHeader(coinId, name, price, getPrice) {
    const livePrice = getPrice(coinId);
    // ...
}
```

**Bad:**

```javascript
function updateCoinHeader() {
    const livePrice = priceCache[currentCoinId]; // implicit access to two globals
    // ...
}
```

#### 5.4 Single Responsibility

JavaScript functions should have the same SRP discipline as PHP classes. A function that updates state, modifies the DOM, fetches data, and logs — is four functions.

**Good:** `updateActiveStates(id)`, `updateCoinHeader(...)`, `loadCoin(id, symbol)` as separate, composable functions.

**Bad:** A `selectCoin()` function that does all of the above in one body.

#### 5.5 Async error handling

Every `fetch()`, `WebSocket`, and `setTimeout` must handle failures explicitly. Silent failures are unacceptable in production.

**Good:**

- `.catch(err => console.error('[App] OHLCV fetch failed:', err))` — at minimum, visible in devtools
- User-facing notification for failures the user must know about
- WebSocket reconnection logic with exponential backoff
- `try/catch` on `JSON.parse` wherever WebSocket or fetch messages are parsed

**Bad:**

- `.catch(() => {})` — silent black hole
- No `.catch()` at all on a `fetch()` call
- `JSON.parse(event.data)` without a `try/catch` — crashes on malformed messages

#### 5.6 Layer separation

Even in a non-framework frontend, separate concerns into logical groups:

| Layer | Responsibility |
|---|---|
| Rendering | Pure DOM manipulation from data — no fetch, no state writes |
| Data loading | Fetch calls, error handling, parsing — no DOM except loader indicators |
| Live feed / WebSocket | Connection, reconnection, message parsing — no DOM except status indicators |
| UI coordination | User interactions, routing between views, state ownership |

**Good:** An IIFE or module pattern that defines each layer as a self-contained unit with explicit public API (`return { init, getPrice }`).

**Bad:** All logic flat in one file: event listeners, WebSocket handlers, DOM updates, fetch calls interleaved with no structure.

#### 5.7 Naming (JS-specific)

- Event handlers: `onCoinSelected`, `onPriceUpdated` (prefix with `on`)
- Boolean-returning functions: `isConnected()`, `hasLoaded()`
- Avoid single-letter variables outside of loop indices and math contexts
- Acronyms: `formatUrl` not `formatURL`, `coinId` not `coinID`

---

## Category 6 — Framework, Library & Dependency Fitness

**What it measures:** Three related but distinct things. Subcriteria 6.1–6.6 measure *how well* the codebase uses the frameworks it already has. Subcriteria 6.7 measures *whether* the current framework choices (including the absence of one) are proportionate to current complexity. Subcriteria 6.8 measures *whether* each significant capability is handled at the right level of abstraction — built in-house where appropriate, delegated to a third-party library where appropriate. 6.1–6.6 may be marked N/A when no relevant framework is in use; **6.7 and 6.8 are always evaluated.**

### Subcriteria

#### 6.1 Structural conventions

Every framework has an expected project structure. Deviating from it makes onboarding harder and may prevent tooling (IDE plugins, generators, deployment scripts) from working correctly.

**Good:** Controllers in the expected directory, named per the framework's convention. Configuration files in the expected location. Service definitions using the framework's DI system.

**Bad:** Business logic placed directly in framework entry points (e.g., route closures in a routes file). Framework config spread across arbitrary files. A Symfony project that uses a custom autoloader instead of the framework's.

#### 6.2 Native abstractions

Using the framework's built-in mechanisms instead of reinventing them.

**Good:** Using Symfony's `EventDispatcher` for domain events, Laravel's `Collection` for array manipulation, React's `useEffect` for side effects.

**Bad:** A hand-rolled event bus when the framework already provides one. A custom query builder when the ORM covers the use case. A custom middleware system in a framework that already has middleware.

#### 6.3 Declarative over imperative

Most modern frameworks favour declaring intent over writing step-by-step procedures.

**Good (React):** Derive view from state. Use `useMemo` for computed values. Let React manage the DOM.

**Bad (React):** Manually calling `document.getElementById` inside a component. Imperative DOM mutations that bypass React's reconciler.

**Good (Symfony):** Route defined with `#[Route('/orders/{id}')]` attribute. Security rules declared in `security.yaml`.

**Bad (Symfony):** Route registered imperatively in a service. Security checks in controller methods instead of using the security layer.

#### 6.4 No bypass of core mechanisms

**Bad patterns across frameworks:**

- Disabling CSRF protection globally to avoid dealing with it
- Calling `exit()` or `die()` inside a controller, bypassing the framework's response lifecycle
- Using `eval()` or dynamic requires to load code
- Setting `strictMode: false` to suppress framework warnings without fixing the underlying issue
- Using `dangerouslySetInnerHTML` in React without sanitization

#### 6.5 Configuration in the right place

Framework-specific configuration belongs in framework-specific places, not hardcoded in production code.

**Good:** Database credentials in `.env` files. Feature flags in config files. Route definitions in route files.

**Bad:** `define('DB_HOST', '10.0.0.1')` in application code. Magic strings that should be environment variables. Infrastructure addresses hardcoded in classes.

#### 6.6 Testing with framework tools

When the framework provides testing utilities, use them.

**Good:** Symfony's `WebTestCase` for functional tests. Laravel's `artisan test` with `RefreshDatabase`. React Testing Library for component tests.

**Bad:** Testing a Symfony controller by instantiating it directly and bypassing the kernel, when `WebTestCase` exists specifically to avoid that.

#### 6.7 Framework fitness for current complexity

*This is the only subcriteria in Cat. 6 that is always scored — even when no framework is in use.*

The question this criterion answers: **is the current tooling choice proportionate to what the project actually is?** The score is not a measure of "how much framework is present" — it is a measure of **fit**. Both extremes are penalised equally: a project that has outgrown its structure scores low, and a project that has imported heavy structure it does not need scores just as low. The ideal sits in the middle.

**Scoring is a bell curve, not a ramp:**

```text
Score
 10 |              ████
  8 |           ██      ██
  6 |         ██          ██
  4 |       ██              ██
  2 |     ██                  ██
    |________________________________
      heavy     proportionate   missing
      overkill  fit             structure
```

A 9–10 is not "has a framework" — it is "has exactly the right amount of structure for current complexity." Moving in either direction from that point reduces the score by the same logic: introducing React into a 200-line static page is as much a mistake as running a 3,000-line SPA in vanilla JS.

**Why over-engineering scores as low as under-engineering:**

Premature framework adoption is not free. It introduces real, measurable costs:

- Every simple operation now carries framework boilerplate that the problem does not require
- Onboarding requires learning the framework *before* contributing — for a complexity that does not justify it
- The framework's opinions drive architecture decisions that should be driven by the domain
- Build tooling, bundle size, and runtime overhead increase without proportional benefit
- Future evaluators see a framework and assume the project needed it — masking the actual complexity level

These costs compound over time exactly as technical debt does. A junior developer forced to understand React's component lifecycle, hook rules, and state management to fix a static marketing page is paying a tax imposed by a premature decision.

**Scoring thresholds — JavaScript layer:**

| Score | Situation | Direction of misfit |
|---|---|---|
| 9–10 | Framework choice matches current structural complexity: vanilla JS ≤ ~500 lines with explicit module separation; OR a lightweight lib (Alpine, Svelte) for moderate interactivity; OR React/Vue for a genuine component-driven SPA | Fit |
| 7–8 | *Under:* Vanilla JS 500–1,000 lines, module pattern strained. *Over:* Full SPA framework (React + Redux) for a project with 2–3 interactive elements and no shared state | Mild misfit in either direction |
| 5–6 | *Under:* Vanilla JS 1,000–2,000 lines, state scattered, DOM logic entangled with business logic. *Over:* Next.js or Angular for a project that renders 3 pages with no routing requirements | Meaningful misfit; should be addressed in the next development cycle |
| 3–4 | *Under:* Vanilla JS > 2,000 lines, adding features breaks other features. *Over:* Full enterprise framework (Angular + NgRx + RxJS) for a single-form tool that could be 150 lines of vanilla JS | Framework choice is actively impeding development |
| 1–2 | *Under:* No structure at any non-trivial scale (global variables, inline scripts). *Over:* Architectural stack chosen to match a CV or a trend, with no relationship to the problem being solved | Requires a reset of the structural decision |

**Scoring thresholds — PHP/backend layer:**

| Score | Situation | Direction of misfit |
|---|---|---|
| 9–10 | Custom micro-framework for a genuinely simple project (< 5 controllers, < 10 routes, no complex auth or DI); OR Symfony/Laravel at a scale that justifies them | Fit |
| 7–8 | *Under:* Custom framework beginning to reinvent wheels (custom router, hand-rolled DI). *Over:* Symfony full-stack for a 3-endpoint JSON API with no auth, no forms, no ORM usage | Mild misfit |
| 5–6 | *Under:* Custom framework at 10+ routes with hand-built auth and event dispatch. *Over:* Full DDD + CQRS + Event Sourcing stack for a project whose domain has 2 entities and 4 use cases | Meaningful misfit |
| 3–4 | *Under:* Teams maintaining infrastructure instead of building features. *Over:* Microservices with message queues and distributed tracing for a project that one developer deploys once a week | Framework choice is actively impeding development |
| 1–2 | *Under:* Monolithic spaghetti, no routing layer. *Over:* Architecture chosen to explore patterns rather than solve the problem — the codebase is a laboratory, not a product | Requires a reset |

**Wrong framework / framework decay:**

A framework that is present and correctly sized can still be a mismatch for other reasons. Score down for:

- Framework is end-of-life (AngularJS 1.x, CakePHP 2.x, CodeIgniter 3.x) — security risk and recruiting disadvantage
- Framework fights the problem domain (Rails for a stateless API; a full SPA framework for a mostly-static site)
- Framework version is > 2 major versions behind current stable — upgrade cost compounds every month

**Important: score measures structural complexity, not line count.**

Line count is a proxy, not the signal. A 900-line file with 6 well-bounded modules and no cross-cutting state may be healthier than a 400-line file with implicit globals and side-effect-driven flow. Before scoring, identify:

- How many distinct concerns share state across module boundaries
- Whether adding a new feature requires understanding the entire file or only one section
- Whether the framework's abstractions are being used, fought, or ignored

**Scoring guidance for evaluators:**

Read the largest layer first. Then ask:

1. Could a new team member add a feature without reading all existing code in this layer? (If no: −2)
2. Is state management explicit — can you trace every mutation to its owner? (If no: −2)
3. Would the next 5 features require touching the same 2–3 files repeatedly because there is no better place? (If yes: −2)
4. Is the framework choice driven by the problem, or by habit, trend, or premature anticipation of scale? (If the latter: −1 to −3 depending on severity)
5. Is the project on a growth trajectory that will invalidate the current choice within 6 months, and has no plan been made? (If yes: −1)

#### 6.8 Build vs. buy — capability abstraction level

*Always evaluated. Applies independently of any framework choice.*

For every significant capability in the codebase — data access, authentication, logging, HTTP communication, email, queuing, search, validation — the question is: **is this capability handled at the right level of abstraction given current scale?** Building in-house what a well-maintained library would cover is a cost. Importing a heavy library for a problem that 20 lines of code would solve cleanly is an equal and opposite cost.

This is the **NIH (Not Invented Here) principle applied proportionally.** The failure mode runs in both directions.

**The bell curve applies here as for 6.7:**

- 9–10: each capability is handled at the level of abstraction its complexity warrants
- Scores decrease symmetrically toward both extremes — excessive hand-rolling and excessive external dependency are penalised identically

**Capability reference — appropriate abstraction by scale:**

| Capability | Small project | Medium project | Large/complex project |
|---|---|---|---|
| **Data access** | Plain SQL or PDO, a simple query class | Lightweight ORM (Eloquent standalone, Cycle ORM) | Doctrine with Unit of Work, migrations, complex relations |
| **HTTP client** | `file_get_contents()` with context, or a 30-line curl wrapper | Symfony HttpClient or Guzzle | Guzzle with middleware pipeline, retry, circuit breaker |
| **Logging** | `error_log()` or a 50-line FileLogger writing NDJSON | Monolog with handlers and formatters | Centralised log aggregation (ELK, Datadog) fed by Monolog |
| **Validation** | Manual `if` guards at boundaries | Symfony Validator component or Respect\Validation | Full validation pipeline with i18n error messages |
| **Authentication** | Session-based with `password_hash/verify` | JWT library (firebase/php-jwt) or OAuth2 client | Full auth server (League OAuth2, Keycloak integration) |
| **Email** | `mail()` for a single notification | Symfony Mailer or PHPMailer | Transactional email service (Postmark, SES) via adapter |
| **Queue / async** | Cron + DB flag column | Simple DB-backed queue (Doctrine-based) | Dedicated broker (RabbitMQ, Redis Queue, SQS) |
| **Search** | SQL `LIKE` or `ILIKE` | Trigram index (pg_trgm), fulltext index | Meilisearch, Elasticsearch, Typesense |
| **Caching** | In-memory array cache within request | PSR-16 simple cache (Symfony Cache) | Distributed cache (Redis, Memcached) with TTL strategy |

**Scoring thresholds:**

| Score | Situation |
|---|---|
| 9–10 | Every capability is handled at the abstraction level appropriate for its current complexity and usage frequency. No wheels are reinvented at scale. No libraries are imported for trivial tasks. |
| 7–8 | One or two minor mismatches: a slightly over-engineered solution for a simple need, or a hand-rolled helper that a small library would handle more robustly. Neither causes maintenance pain yet. |
| 5–6 | A systematic pattern in one direction: either several capabilities are home-grown at a scale where a library would reduce code and risk; OR several heavy dependencies are present for needs that could be met with a fraction of the code. |
| 3–4 | Significant maintenance burden visible: home-rolled auth/ORM/HTTP client that is missing edge cases, has no tests, and is being bug-fixed repeatedly; OR a dependency graph so heavy that upgrades are feared and build times have doubled. |
| 1–2 | Total NIH syndrome at scale — core infrastructure (session management, cryptography, HTTP parsing) built from scratch with no external libraries; OR dependency chaos — hundreds of transitive dependencies for a project that renders 4 pages. |

**Why reinventing at scale scores as low as over-importing:**

A hand-rolled ORM at 50 entities is not just inefficient — it is a security and correctness risk. SQL injection, N+1 query bugs, and transaction isolation issues are problems that Doctrine, Eloquent, and every mature ORM have already solved, tested, and documented. Every hour spent fixing those in a home-grown layer is an hour not spent on the actual domain. The opportunity cost is real and compounds.

Conversely, adding Doctrine to a project with 3 tables and 5 queries imports ~120 files, a complex configuration layer, and a steep learning curve — for a problem that a 40-line PDO wrapper would solve in full. The dependency now needs to be upgraded, monitored for CVEs, and understood by every new developer. That cost is also real.

**The signal to watch for in both directions:**

*Reinventing at scale:* the home-grown solution has a bug backlog, its test coverage is lower than the rest of the codebase, and team members hesitate to modify it.

*Over-importing:* `composer.json` / `package.json` grows by one dependency per feature; `composer why` reveals packages no developer recognises; a trivial feature change requires upgrading 4 transitive dependencies.

**Dependency health check — score down additionally for:**

- Any dependency with no commits in > 24 months and no stated maintenance policy
- Any dependency flagged by `composer audit` / `npm audit` with a known CVE that has not been addressed
- Any dependency that is a fork of an abandoned project with no clear ownership

#### 6.9 Dependency currency and upgrade path

7.4 asks whether dependencies are *vulnerable*. This asks whether they are *current*, and — the
question that matters more — whether they still **can** be upgraded.

Currency is not a virtue in itself. Chasing every release is churn, and a stable dependency two minor
versions behind is nobody's problem. What is a problem is distance that compounds: an upgrade
deferred is an upgrade that gets more expensive every month, until the day a CVE makes it urgent and
it is a three-week project instead of an afternoon. The measure is not "how new" but **"how far, and
is the road still open"**.

**One dependency can close the road for all of them.** A single package pinning `php <8.2` or
`react ^17` blocks the runtime, and through it every other upgrade. That is not a ranking of
staleness, it is a structural constraint, and finding it is the most valuable thing this criterion
does. Ask the resolver: `composer why-not php 8.3`, `npm ls <pkg>`, `pip install --dry-run`.

**The runtime counts as a dependency.** 6.7 covers whether the *framework* is end-of-life; the
interpreter, the JDK, the database engine and the base image have support windows too, and a
codebase on an unsupported PHP or Node receives no security patches regardless of how current its
libraries are.

**Submodules are dependencies that no tool watches.** A package manager reports an outdated package;
nothing reports a submodule pinned three years ago. If the project uses submodules, a pin is
acceptable — pinning is the point — but only if someone knows what it is pinned to and why, and
something tells them when upstream moves.

**Good:**

- Direct dependencies within one major of current, or a recorded reason for staying behind
- Runtime, base image and database engine inside their support windows, with the EOL date known
  before it arrives rather than discovered by a scanner
- An answerable upgrade path: the project can say which dependency is the current blocker, or that
  there is none
- Automated update PRs (Renovate, Dependabot) with grouping and a schedule, so upgrades arrive as a
  routine trickle rather than a quarterly cliff
- Submodules pinned to a tag rather than a loose commit, and a way to learn that upstream has
  released since
- `composer outdated --direct` / `npm outdated` / `pip list --outdated` visible in the quality gate
  or a scheduled job — reported, not necessarily failing the build

**Bad:**

- No idea how far behind anything is: the first measurement happens when an audit asks
- A dependency whose last release predates the project's current major version, still a direct
  dependency
- An upgrade blocker nobody has identified — "we cannot move to PHP 8.3" with no name attached to
  the reason
- A runtime past EOL, or within months of it with no plan
- Automated update PRs opened and left to accumulate: the bot is configured, and the queue is the
  finding
- Submodules pinned to a commit with no tag, no note, and no upstream tracking — a dependency
  frozen by accident rather than by decision
- Upgrades taken only in response to a CVE, each one a large and risky change, which is the
  predictable consequence of deferring all the small ones

**How to score.** Read the manifests and the lockfile, then ask the resolver about the upgrade path
rather than eyeballing version numbers — a list of outdated packages is far less informative than
the one constraint that pins them. Weight the blocker and the runtime EOL above ordinary staleness:
being behind is a cost, being unable to move is a risk. A project deliberately behind, with the
reason recorded, scores well; a project behind without knowing it does not, at the same version
numbers.

---

## Category 7 — Tooling & Quality Standards

**What it measures:** The degree to which code quality is enforced automatically, not just aspired to.

The key insight: a quality standard that exists only in a document or a developer's head is not a standard — it is a wish. Quality must be enforced by machines, in the development loop, before code is merged.

### Subcriteria

#### 7.1 Static analysis (types)

**PHP:** PHPStan or Psalm at level 6 or higher. All `array` types annotated with their element type (`array<string, int>`, `list<Order>`, `array{id: int, name: string}`). No `mixed` without justification.

**TypeScript:** `strict: true` in `tsconfig.json`. No `any` except in adapter/mapping layers with explicit justification.

**Python:** `mypy` with `strict = true`. `pyright` in strict mode.

**JavaScript (no TypeScript):** JSDoc types for public APIs. ESLint with `no-undef`, type-checking rules enabled.

**Why this matters:** Type errors caught at analysis time cost nothing. Type errors caught in production can cost data, users, and sleep.

#### 7.2 Code style and formatting

A consistent, automatically-enforced style removes an entire class of review comments ("wrong indentation", "missing semicolon", "import order") and ensures the diff in every PR reflects intent, not formatting noise.

**PHP:** PHP-CS-Fixer or PHP_CodeSniffer with a defined ruleset (PSR-12 as baseline, with team additions).

**JavaScript/TypeScript:** ESLint + Prettier. Separate linting (logic errors) from formatting (style). Both enforced in CI.

**Python:** `black` for formatting, `ruff` or `flake8` for linting.

**Go:** `gofmt` is the standard; non-negotiable.

**Recommended PHP rules beyond PSR-12:** `ordered_imports`, `no_unused_imports`, `trailing_comma_in_multiline`, `binary_operator_spaces`, `blank_line_before_statement` (before `return`, `throw`, `try`).

#### 7.3 Complexity and metrics

Complex code has higher defect rates and is harder to test.

**Cyclomatic complexity:** Flag functions with complexity > 10. Refactor functions with complexity > 15.

**Function length:** Flag functions over 30 lines (PHP/Python/JS). Prefer under 20.

**Class length:** Flag classes over 200 lines. Large classes usually violate SRP.

**Nesting depth:** Flag nesting beyond 3–4 levels. Deep nesting usually means missing early returns or extracted helper functions.

**Tools:** PHPStan (some rules), PHP Mess Detector (phpmd), ESLint `complexity`/`max-depth`/`max-lines-per-function` rules.

#### 7.4 Dependency security scanning

All third-party dependencies are potential attack vectors.

**PHP:** `composer audit` — checks installed packages against the PHP Security Advisories database. Run in CI on every push.

**JavaScript:** `npm audit` or `yarn audit`. For zero-tolerance environments: `npm audit --audit-level=high` fails the build on high-severity CVEs.

**Python:** `pip-audit` or `safety check`.

**Java/Kotlin:** OWASP Dependency-Check, Snyk, or Dependabot.

**Best practice:** Automated PRs for dependency updates (Dependabot, Renovate). Security audit integrated into CI, not run manually.

#### 7.5 Dead code detection

Unused imports, unreachable code paths, never-called private methods, and obsolete feature flags accumulate quietly and increase cognitive load.

**Tools:** PHPStan (detects unused variables, unreachable code), ESLint `no-unused-vars`, Python's `vulture`.

**Good:** `no_unused_imports` enforced by CS-Fixer. PHPStan `deadCode` ruleset enabled.

**Bad:** Commented-out blocks of old code committed to the repository. Unused `use` statements. Private methods that are never called.

#### 7.6 Architectural constraints

Enforce layer boundaries automatically, not by convention.

**PHP:** `deptrac` defines which namespaces may import from which other namespaces and fails CI when a violation is introduced. This prevents the slow entropy of a DDD project's layers collapsing into each other over months.

**TypeScript:** ESLint `import/no-restricted-paths` rules.

**Java/Kotlin:** ArchUnit.

**Why this matters:** Without tooling enforcement, architectural boundaries drift. The first time a developer imports a repository implementation directly into a use case "just this once", the barrier is gone for everyone.

#### 7.7 One-command quality gate

The entire quality suite should be runnable with a single command in development and CI.

**PHP example:**

```bash
composer qa  # runs: phpstan + php-cs-fixer check + phpunit
```

**Node example:**

```bash
npm run qa  # runs: eslint + tsc --noEmit + jest
```

**Make/Just example:**

```makefile
qa: analyse cs-check test
```

A developer should be able to verify their changes pass all quality checks before pushing, in under 60 seconds for most projects.

#### 7.8 Deprecation discipline

Deprecation warnings are signals with a deadline, not noise to be filtered. A deprecation notice means: *"this will break in a future version — you have until then to fix it."* Suppressing the notice does not extend the deadline; it removes the reminder.

This criterion covers two distinct failure modes that are often found together:

**Failure mode 1 — Signal suppression:** The tooling configuration has been modified to hide deprecation warnings rather than address them.

Observable signals of suppression:

| Language / Tool | Suppression anti-pattern |
|---|---|
| PHP (`php.ini` / `error_reporting`) | `E_DEPRECATED` and `E_USER_DEPRECATED` excluded from reporting |
| PHPStan (`phpstan.neon`) | `ignoreErrors` entries matching `deprecated` patterns that have accumulated over time |
| PHPUnit (`phpunit.xml`) | `convertDeprecationsToExceptions="false"` or a `<source>` exclusion list covering deprecated call sites |
| JavaScript / TypeScript | `@ts-ignore` or `// eslint-disable` comments on lines flagged for using deprecated APIs |
| Python | `warnings.filterwarnings("ignore", category=DeprecationWarning)` in production code or test setup |
| Go | No built-in deprecation system; signal is in `godoc` comments — suppression manifests as ignoring `staticcheck` SA1019 warnings |
| Kotlin / Java | `@SuppressWarnings("deprecation")` used broadly rather than per-call-site with a tracked reason |

**Good:** Suppression is absent, or limited to a single explicitly documented exception with a ticket reference. Deprecation warnings cause CI to emit a visible warning or, for mature projects, fail the build.

**Bad:** A growing `ignoreErrors` block in PHPStan. A `phpunit.xml` that converts zero deprecations to exceptions. A codebase where `@ts-ignore` is the standard response to type warnings.

---

**Failure mode 2 — Accumulation without a plan:** Deprecation warnings are visible but treated as background noise. No one owns the backlog; warnings accumulate across versions.

The risk compounds in a specific pattern:

1. Dependency releases a minor version with deprecation notices → warnings appear
2. Team suppresses or ignores → no action taken
3. Dependency releases a major version removing the deprecated API → **breaking change with no prior work**
4. Upgrade is now a large, risky migration instead of a series of small, incremental fixes

**Scoring thresholds:**

| Score | Situation |
|---|---|
| 9–10 | No deprecation warnings in CI output; or all warnings are tracked in the backlog with a scheduled fix; own-code `@deprecated` annotations have a documented removal plan |
| 7–8 | A small number of deprecation warnings (< 5) present but tracked; no suppression configuration in place |
| 5–6 | Deprecation warnings visible but untracked; OR a partial suppression config that hides some but not all warnings |
| 3–4 | Systematic suppression via tooling configuration; or > 20 untracked deprecation warnings across dependencies and own code |
| 1–2 | Deprecation warnings entirely disabled at the runtime or CI level; the team has no visibility into what will break on the next major upgrade |

**Own-code deprecations (`@deprecated` annotations):**

When you deprecate your own methods or classes, the annotation is a commitment, not decoration. A `@deprecated` without a removal plan is technical debt with no due date.

**Good:** `@deprecated since v2.3 — use OrderService::submit() instead; to be removed in v3.0`

**Bad:** `@deprecated` with no replacement reference, no version, and the method has been there for two years with active call sites remaining.

**Feature flags are deprecations with a different word.** A flag introduced to ship a change
incrementally is a temporary fork in the system's behaviour, and the moment the rollout finishes one
side of that fork is deprecated code with no annotation on it. What makes a flag worse than an
ordinary deprecation is that the dead side stays *reachable in production*: a configuration value, an
environment variable or a stale row can still select it, while nobody has exercised that path or
written a test against it for a year.

So a flag is scored by the same rule as a `@deprecated` annotation — **a removal condition, decided
when the flag is created**, and audited against the same question: how many flags exist, and how many
of them have outlived the rollout they were created for?

**Good:** each flag carries its purpose and its retirement condition where it is declared (*remove
once 100% of traffic has been on the new path for one release*); the flag inventory is short enough
to read; retiring the flag and deleting the path it guarded is one commit, and that commit is what
closes the rollout.

**Bad:** a flag at 100% for two years, with both branches still compiled in and only one of them
ever executed. A flag nobody can name the owner of. A flag whose "off" path is the one that would be
taken if the configuration store were ever empty — which makes an abandoned flag an availability
risk rather than a cleanliness one. A kill switch kept deliberately: legitimate, and it belongs in
the inventory *as* a kill switch, with a stated reason, rather than sitting among the rollout flags
that should have been removed.

**Inclusion in the quality gate:** For projects above "early production" maturity, deprecation warnings should be surfaced in CI output even if they do not fail the build. For "established" and above, treating own-code deprecations as build failures (via PHPUnit's `convertDeprecationsToExceptions`, TypeScript's `noImplicitAny`, or equivalent) is a signal of mature deprecation discipline.

**How to collect evidence for this criterion (tool-first):**

Run static analysis tools before reading source files. Pass their output to the evaluating agent for interpretation — do not ask the agent to discover deprecations by reading source manually.

| Language | Command |
|---|---|
| PHP | `vendor/bin/rector process src --dry-run` (Rector) or `vendor/bin/phpstan analyse src --level=max 2>&1 \| grep -i deprecated` |
| PHP (own-code) | `vendor/bin/phpunit 2>&1 \| grep -i deprecated` (with `convertDeprecationsToExceptions="false"` temporarily) |
| JavaScript / TypeScript | `npx tsc --noEmit 2>&1 \| grep -i deprecated` or `npx eslint src --rule 'deprecation/deprecation: warn' --format json` |
| Python | `python -W error::DeprecationWarning -m pytest --tb=no -q 2>&1 \| grep -i deprecated` |
| Go | `staticcheck ./... 2>&1 \| grep SA1019` |
| Kotlin / Java | `./gradlew compileKotlin 2>&1 \| grep -i deprecated` |

#### 7.9 Query analysis in the quality gate

Data-access defects are the one class of quality problem that reading code does not reliably find,
because the defect is not in any single line. An N+1 is a loop in one file and a lazily loaded
association declared in another; both are correct on their own. What finds it is **counting queries**,
and that is a mechanical check the gate can own.

This criterion asks whether the project detects data-access defects before production, not whether
it is fast. Speed is an outcome; this is about the instrument.

**Good:**

- Integration tests assert a query count on the endpoints and jobs that matter — a route that should
  issue 3 queries fails the build at 40, whatever the wall-clock time on a laptop with 20 test rows
- Lazy loading raises in development and test, so an N+1 is a failure at the moment it is written
  (`Model::preventLazyLoading()` in Laravel, `fetch: EAGER` audits or a `SQLLogger` assertion in
  Doctrine, `nplusone` in Django, `bullet` in Rails)
- A migration that adds a query path also adds the index it needs, and the review says so
- `EXPLAIN` run against production-like volume for new queries on tables that grow — a plan checked
  at 200 rows tells you nothing
- The static analyser's ORM extension is enabled where one exists (`phpstan-doctrine`,
  `mypy` plugins), so wrong field and relation names fail before runtime

**Bad:**

- No query counting anywhere: the first measurement of a query's cost happens in production
- `preventLazyLoading` / `nplusone` / `bullet` available for the stack and not enabled — the tooling
  exists, the project declined it
- Performance tests that assert *duration* on a developer machine, which measures the laptop, not the
  query plan. Assert query counts and row counts; those are stable
- Indexes added in a separate "performance" ticket weeks after the query shipped
- An N+1 fixed reactively, with no test added — so the next refactor reintroduces it silently

**Scoring without a database:** the test suite and the migrations are readable evidence, so a project
with no query-count assertions and no lazy-load guard scores low on config alone — that finding is
solid. The reverse is not: a migration that adds an index proves the intent to have one, not that it
exists or that the planner uses it. Without the declared database access of precondition 4, mark such
evidence unverified and cap the subcriteria at 8.

**Language equivalents:**

| Stack | Query counting | Lazy-load guard |
|---|---|---|
| PHP / Doctrine | `DebugStack` / `SQLLogger` assertion in a functional test | `phpstan-doctrine`, explicit `fetch` review |
| PHP / Laravel | `DB::listen` counter, `assertDatabaseQueryCount` | `Model::preventLazyLoading()` in a non-prod service provider |
| Python / Django | `assertNumQueries` | `django-nplusone` |
| Ruby / Rails | `assert_queries` | `bullet` gem |
| TypeScript / Prisma | `$on('query')` counter | `include` / `select` review, no implicit relation loads |

#### 7.10 Documentation currency and drift detection

Stale documentation is worse than none. Absent documentation is at least honest — a reader knows to
go and look. A document that describes a system which no longer exists spends someone's afternoon
before they work out it is lying.

This criterion is not about how much is written. It asks whether anything **keeps the written
description true**, and notices when it stops being.

Its scope is what a document asserts about the **system**: paths, commands, analyser levels, layer
rules. What a document asserts about its own **delivery state** — implemented, or still planned — is
0.5. Both are drift; they are scored apart because projects routinely have one without the other.

**Two audiences, and the quieter one fails worse:**

*Human-facing* — README, onboarding, `CONTRIBUTING.md`, API contracts, the ADR index. Drift here
surfaces eventually: someone runs the command, it fails, they complain or fix it. Expensive, but
self-revealing.

*AI-facing* — `CLAUDE.md` and whatever sits in `.claude/`. Drift here is silent and repeats. These
files are loaded into every session and applied as fact, and nobody reads them end to end, so nobody
notices. A `.claude/CODING_STANDARDS.md` naming PHPStan level 6 after the project moved to level 8,
or a layer rule that `deptrac.yaml` no longer enforces, will shape every future proposal without a
single reader disagreeing.

**A mechanism, not a discipline.** "We review the docs each quarter" does not survive two sprints
under pressure — it is the same gap 7.7 identifies for quality checks that rely on remembering. What
survives is making the documentation's factual claims **executable**:

- Paths and file references cited in documents resolve — checked in CI, not by eye
- The README's setup path runs in CI on a clean checkout: onboarding becomes a test rather than prose
- The API contract is generated from the routes, or a contract test fails when spec and code diverge
- Generated documentation is regenerated in CI, and a non-empty diff fails the build
- What the AI instruction files assert about tooling matches the tooling: the quality gate command
  exists, the analyser level matches its config, the layer rules match the file that enforces them

**Good:**

- A CI job that fails when a document names a path, file or command that no longer resolves
- Onboarding verified by execution, not by belief — the quickstart runs somewhere automated
- OpenAPI generated from annotations or validated by a contract test; never hand-maintained beside
  the code it describes
- `.claude/*` claims that are checkable and checked, so the instructions cannot quietly diverge from
  the config they name
- Documents fixed in the same commit as the change that invalidated them, visible in the history
- A dated freshness marker on the documents that genuinely cannot be machine-checked, so at least
  their age is visible

**Bad:**

- A README whose setup instructions have not been executed since they were written
- Documentation reviewed "when someone notices" — a discipline with no trigger is not a mechanism
- A hand-maintained OpenAPI spec sitting next to the routes, diverging from the day it was written
- An AI instruction file naming an analyser level, lint command, or architectural rule the project no
  longer uses — misdirecting every session, reviewed by nobody
- Generated documentation committed once and regenerated by hand, so the committed copy describes an
  older system
- A `docs/` directory whose last meaningful change predates the current architecture
- Onboarding that lives in one person's head, with the README as decoration

**How to score.** Look first for any automated tie between documentation and reality: a single path
checker in CI is worth more than a thick unverified handbook. Then spot-check the highest-traffic
claims — the setup command, the quality gate command, and whatever the AI instruction files assert
about tooling — against the files that would prove them. Weight the AI-facing half at least as
heavily as the human one: it is applied far more often and reviewed far less. **Thin but true
documentation with a check that keeps it true scores above extensive documentation with no
mechanism.**

---

## Category 8 — Application Security

**What it measures:** How well the application protects itself and its users from common attack vectors.

Security is not binary. The goal is defence in depth: multiple independent layers, each of which would stop an attack even if the others failed.

### Subcriteria

#### 8.1 Input validation

Every value that enters the system from outside (HTTP query strings, headers, request body, environment variables, file uploads) must be validated and sanitized before use.

**Good:**

- Parse and type-cast inputs at the entry point before any other use — PHP: `(int) $request->get('limit')` / Go: `strconv.Atoi(r.URL.Query().Get("limit"))` / Python: `int(request.args.get("limit"))` / Kotlin: `params["limit"]?.toIntOrNull()` / Swift: `Int(request.queryParameters["limit"] ?? "")`
- Validate against a domain Value Object that rejects invalid values: `new CoinId($input)` throws if invalid — the language is irrelevant, the pattern is universal
- Use allowlists, not blocklists, for string validation: `/^[a-z0-9\-]+$/` not `strpos($input, '<')`
- Validate file uploads: MIME type from file headers (not extension), size limits, path traversal prevention

**Bad:**

- Using `$_GET['id']` directly in an SQL query (SQL injection)
- Using user input directly in a shell command
- Trusting `Content-Type` header for file validation (trivially spoofed)
- Validating only in the controller but not in the domain

#### 8.2 Output encoding

Every value that leaves the system to a consumer must be encoded for the target context.

**HTML output:** Use the language's standard escaping function — PHP: `htmlspecialchars($v, ENT_QUOTES, 'UTF-8')` / Python: `html.escape(v)` / Go: `html.EscapeString(v)` / Kotlin/Java: `HtmlUtils.htmlEscape(v)` / Swift: no stdlib function; use a template engine or `replacingOccurrences` for the five unsafe characters. Never write your own escaper.

**JSON output:** Use the language's serialiser — PHP: `json_encode()` / Python: `json.dumps()` / Go: `encoding/json` / Kotlin: `Json.encodeToString()`. Do not manually concatenate JSON strings in any language.

**SQL:** Prepared statements / parameterised queries in every language. No string concatenation into SQL, ever.

**Shell commands:** Escape or avoid — PHP: `escapeshellarg()` / Python: `subprocess.run([...], shell=False)` (pass a list, never a string) / Go: `exec.Command(name, args...)` (variadic, never `sh -c`). Prefer avoiding shell invocation entirely.

**Why "Context" matters:** A value that is safe in JSON (because `json_encode` handles it) may be unsafe if that JSON is then interpolated into a `<script>` tag in HTML. Each transition between contexts requires its own encoding.

#### 8.3 Authentication and authorisation

**Authentication** (who are you?): Use established libraries, never roll your own. Hash passwords with a slow, salted algorithm — PHP: `password_hash($p, PASSWORD_ARGON2ID)` / Python: `argon2-cffi` or `bcrypt` / Go: `golang.org/x/crypto/bcrypt` / Kotlin: Spring Security's `BCryptPasswordEncoder` / Swift: `CryptoKit` (for client-side; server-side auth belongs on the backend). Never store plaintext passwords or reversible hashes (MD5, SHA1, SHA256 without a salt and work factor).

**Authorisation** (are you allowed?): Check permissions at the use case / service layer, not only in the controller. A controller that returns a 403 does not prevent direct service-layer calls from bypassing the check.

**Good:** Role and permission checks in a dedicated policy or middleware layer. Attribute-based access control for fine-grained rules.

**Bad:** `if ($user->role === 'admin')` scattered across multiple controllers and services.

#### 8.4 CSRF protection

Cross-Site Request Forgery attacks trick authenticated users into making unintended state-changing requests.

**Applies to:** Any state-changing endpoint (POST, PUT, PATCH, DELETE) that is accessible from a browser session.

**Good:** CSRF token validated on all non-idempotent requests. SameSite cookie attribute set to `Strict` or `Lax`.

**Does not apply:** Pure API endpoints authenticated via Bearer tokens (not cookies).

#### 8.5 Security headers

HTTP response headers instruct browsers on how to handle page content. They are a low-cost, high-impact defence layer.

| Header | Value | Purpose |
|---|---|---|
| `X-Frame-Options` | `DENY` | Prevents clickjacking by disallowing the page in iframes |
| `X-Content-Type-Options` | `nosniff` | Prevents MIME type sniffing |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Controls how much referrer info is sent cross-origin |
| `Content-Security-Policy` | (see below) | Defines allowed sources for scripts, styles, images, connections |
| `Strict-Transport-Security` | `max-age=31536000` | Forces HTTPS for one year (production only) |

**CSP guidance:**

- Start with `default-src 'self'` and add exceptions as required
- Prefer `nonce`-based script allowlisting over `'unsafe-inline'`
- `connect-src` must include every WebSocket/API domain the frontend connects to
- `img-src` must include every CDN from which images are loaded
- Document every exception with a comment explaining why it is necessary

#### 8.6 Secrets management

**Good:**

- All secrets (API keys, database passwords, private keys) in environment variables or a secrets manager (AWS Secrets Manager, HashiCorp Vault)
- `.env` files in `.gitignore`; `.env.example` committed with placeholder values
- Secret scanning (GitHub Secret Scanning, `git-secrets`, `truffleHog`) in CI

**Bad:**

- API keys committed to the repository, even in "private" repos
- Hardcoded credentials in configuration files
- Secrets in log output

#### 8.7 Verified against a declared ASVS level

8.1–8.6 score six defences in depth. This subcriteria scores the rest of the surface, and it needs a
standard to score against. The OWASP Top 10 is not one: it ranks what goes wrong most often, which
explains why a finding matters but gives an auditor nothing to point at. The OWASP Application
Security Verification Standard (ASVS) is its counterpart written for verification — around 350
requirements, each phrased as something that passes or fails, in seventeen chapters and three
levels:

| Level | What it covers | Requirements in v5.0.0 |
|---|---|---|
| L1 | The first layer of defence against common attacks that need no other weakness to succeed. The minimum for anything with users | 70 |
| L2 | What most applications should reach: less common attacks, and stronger defences against common ones. Anything holding personal, financial or account data | 253, L1 included |
| L3 | Defence in depth for applications that must demonstrate the highest assurance — banking, health, critical infrastructure | all 345 |

**The level is the project's to declare, from its risk.** The **Security verification** block of
`.claude/PROJECT_AUDIT_FRAMEWORK.md` names the ASVS version, the target level and the reason for it,
and every chapter out of scope with the reason — a machine-to-machine API has no *Web Frontend
Security*, a product without delegated login has no *OAuth and OIDC*. The ASVS asks for exactly this:
choose the level by the sensitivity of the data and what the users expect, and drop the chapters the
application does not expose. The framework ships the requirement list for the version it supports in
`standards/asvs/`, so two audits of the same commit read the same requirements.

**How it is proportionate to the project.** Two things set what the score expects, and neither is
the auditor's taste. The declared level sets the *destination*, from the data. The maturity minimums
set how far along the road the project must already be, through the bands below: a prototype is
scored on its progress towards L1, a project in early production is expected to have L1 complete, an
established one to have its declared level mostly met, an enterprise one to have it met and verified.
A four-person startup holding payment data declares L2 just as a bank's smaller product would. What
differs is how far the score expects it to have got this year, not where it is going.

**One gap jumps the queue.** An unmet L1 requirement in a chapter the project exposes, where the
consequence is exploitable without any other weakness, is Phase 0 of *Remediation order* — whatever
the band, whatever the maturity. L1 is defined as exactly those requirements, and leaving one open on
a system with real users is the bleeding Phase 0 exists to stop. Every other gap — the rest of L1,
all of L2 and L3 — is ordinary work, sequenced by band and phase like any other.

**Scored once.** A requirement whose failure is already a finding under 8.1–8.6 — an injection under
8.2, a missing authorisation check under 8.3 — is cited there by its ASVS identifier and not deducted
again here. 8.7 carries the rest of the declared level. Cite every requirement the way the ASVS asks,
with its version — `v5.0.0-8.2.1`, never a bare number — because identifiers change between major
versions.

**Documentation requirements count.** Many chapters open with a requirement that a security decision
be documented: which file types may be uploaded, which data is sensitive, how sessions expire. An ADR
(0.7) or a section of the product context (0.1) satisfies them, and the matching implementation
requirement then checks the code against what was written.

**Some requirements cannot be read from the repository** — TLS as negotiated, headers as served,
session behaviour at runtime. Where the **Production access** block declares a read-only path, check
them through it. Where it does not, score them from configuration, mark them unverified, and cap the
subcriteria at 8, the same rule as 7.9.

**Good:**

- A declared version, level and reason, with every out-of-scope chapter named and justified
- The level chosen from the data the product holds, consistent with the product context (0.1)
- Gaps listed by versioned identifier, each with an owner or an accepted-risk decision in an ADR
- Technical requirements pinned by tests — the ASVS describes itself as a guide for automated unit
  and integration tests: the login controller tested for enumeration and brute force, the upload
  endpoint for type and size
- A new ASVS version adopted deliberately, with the re-evaluation the standard says it requires

**Bad:**

- No declaration — so no target, and no way to tell a gap from a choice
- A level chosen below what the data warrants: L1 declared by a product whose context document
  describes stored card data
- Chapters marked out of scope that the application plainly exposes: no *OAuth and OIDC* in a product
  with a *Sign in with Google* button
- *"OWASP compliant"* claimed with no level, no version and no list — a phrase, not a verification
- Requirements ticked from the framework's documentation rather than from the application's own
  configuration

**How to score:**

| Score | Situation |
|---|---|
| 0–2 | An L1 requirement unmet in an exposed chapter with an exploitable consequence, or nobody has ever checked |
| 3–4 | L1 partially met; the gaps could be found, and nobody has listed them |
| 5–6 | L1 met in every exposed chapter — 6 when complete, 5 with residue that is not exploitable |
| 7–8 | Above L1, the declared level mostly met (7), or met with every exception recorded by identifier and reason (8). Where the declared level is L1 itself, these bands are reached by verification rather than breadth: its technical requirements pinned by tests, its documentation requirements met |
| 9–10 | The declared level met in every exposed chapter, its technical requirements pinned by tests, nothing open without an accepted-risk decision |

Read against the maturity minimums, these bands *are* the proportionality: 4 for a prototype is L1 in
progress, 6 for early production is L1 complete, 7 and 8 for established and enterprise are the
declared level mostly and then fully met.

**Without a declaration**, score against L1 in every chapter the application visibly exposes, say
so, and **cap at 6** — L1 complete is the most an undeclared target can show. **A declared level the
product context contradicts** is reported first among the category's findings, as a finding about the
declaration: the audit names the level the data suggests and does not substitute it for the
project's. The score is read against the declaration, so two auditors reach the same number; the
contradiction is what tells the reader the number deserves a question.

**The Top 10 keeps its place** as the explanation, not the ruler. When a finding needs a reason a
reader will recognise, name the Top 10 category beside the ASVS identifier.

---

## Category 9 — Observability & Operability

**What it measures:** How well the system allows operators to understand what it is doing, diagnose what went wrong, and verify that it is healthy — both in development and in production.

The core question: *if this system misbehaves at 3am, can the on-call engineer understand what happened and fix it without reading the source code?*

And its companion, which is about operability rather than diagnosis: *will the system still be running at 3am, or will it have quietly filled its own disk?* Observability that costs unbounded storage eventually becomes the outage it was meant to diagnose. And one step further out, where operability ends: *if the machine or the data is not there tomorrow morning, what comes back, and how long does that take?*

And the one nobody asks until the invoice or the breach asks it for them: *what is still
running, and who still holds a valid key, for a reason that ended months ago?*

And the question that decides whether the first two matter: *can whoever is on call — the engineer, or the agent they hand the problem to — reach those signals at 3am, without waking a second person to get in?* A dashboard one person can log into is a dashboard that is down whenever that person is.

### Subcriteria

#### 9.1 Structured logging

Logs should be machine-parseable (NDJSON or similar) and contain consistent fields.

**Minimum fields:** `timestamp` (ISO 8601 with timezone), `level`, `message`, `context` (structured key-value pairs).

**Levels used correctly:**

| Level | Use for |
|---|---|
| `debug` | Developer-only detail, disabled in production |
| `info` | Normal operations: request received, job completed, user authenticated |
| `warning` | Unexpected but recoverable: external API unavailable, retry triggered, deprecated usage |
| `error` | Failures that need attention: exception caught, data integrity issue, integration failure |
| `critical` | System is unusable: database unreachable, disk full, fatal configuration error |

**Good:**

```json
{"ts":"2026-05-27T10:14:22.000+00:00","level":"error","message":"External service unavailable","context":{"service":"price-api","error":"Connection timed out after 12s"}}
```

**Bad:**

- `echo "Error: " . $e->getMessage();` — unstructured, goes to stdout not logs
- Logging only in catch blocks — half the picture
- No correlation ID — cannot trace a request across multiple log lines
- Passwords or tokens in log context

#### 9.2 Error tracking

Unhandled exceptions and application errors should be captured, aggregated, and alerted on.

**Tools:** Sentry, Bugsnag, Datadog Error Tracking, Rollbar.

**Good:** A single top-level exception handler sends all unhandled `Throwable`s to the error tracker with full stack trace, request context, and environment. Errors grouped by type, not by instance.

**Bad:** Errors only visible in log files that no one monitors. Every error generating an email notification (alert fatigue). No distinction between errors that affect one user and errors that affect all users.

#### 9.3 Health check endpoint *(Backend/Server-side only)*

**Scope:** Applies to HTTP servers, APIs, and background workers. For native mobile clients (iOS, Android, Flutter) this subcriteria is N/A — the equivalent concern is addressed through crash reporting (Crashlytics, Sentry), remote config availability checks, and in-app diagnostic screens accessible to support teams.

A `/health` (or `/healthz`, `/ping`) endpoint allows load balancers, container orchestrators, and monitoring systems to verify the application is alive and its dependencies are reachable.

**Minimum response:**

```json
{
  "status": "ok",
  "checks": {
    "database": {"status": "ok", "latency_ms": 3},
    "cache":    {"status": "ok"},
    "disk":     {"status": "ok", "free_mb": 1240}
  }
}
```

**Good:** Returns `200 OK` when healthy, `503 Service Unavailable` when any critical dependency fails. Kubernetes `livenessProbe` and `readinessProbe` point to it. Health checks have a timeout to avoid blocking indefinitely.

**Bad:** A `/health` that just returns `{"status":"ok"}` without checking dependencies — load balancers mark the instance healthy while the database is unreachable.

#### 9.4 Metrics

Application metrics — request rate, error rate, response time percentiles (p50, p95, p99), queue depth, cache hit rate — are the foundation of SLA monitoring and capacity planning.

**Tools:** Prometheus + Grafana, Datadog, New Relic, CloudWatch.

**Minimum for a web service:**

- Request count by route and status code
- Response time by route (histogram)
- Error rate
- Saturation of the resource that runs out first

**Good:** An `oncall` dashboard exists. Alerts fire before users notice problems (proactive alerting on error rate or latency, not reactive alerting on user complaints).

**The fourth signal is saturation.** Rate, errors and duration say how the system is behaving;
saturation says how close it is to stopping — connection pool usage, queue depth, memory or CPU
against its limit. It is the one of the four that moves *before* users notice.

**Objectives, not only measurements.** A dashboard with no target says what the system did, not
whether that was acceptable. Where people wait on the service in real time, state a service level
objective for the paths they use — *99.5% of checkout requests succeed in under 800 ms, over 28
days* — computed from the metrics above, and alert on how fast the error budget is being spent
rather than on every spike. The objective is a product decision, so it is written down with the
product context, and it is what decides whether a slow week is an incident. A system nobody waits
on in real time — a nightly batch — states its objective as completion and lateness instead.

**Good:** objectives written down and measured; alerts on budget burn rather than on raw
thresholds.

**Bad:** alerts on raw thresholds that page for every spike and stay silent through a slow
degradation. An SLA in a contract with no internal objective behind it.

#### 9.5 Graceful degradation

When a dependency fails, the system should continue serving users as best it can, not crash entirely.

**Good:**

- CoinGecko API down → return a cached page with a "data may be outdated" notice, not a 500 error
- Redis cache unavailable → fall through to database, log a warning, continue serving
- Non-critical feature (A/B test, recommendation engine) fails → hide the feature, continue serving the main content
- Every call across the process boundary — HTTP, database, queue, cache — has an explicit timeout,
  shorter than the timeout of whoever is waiting on it
- Retries bounded, with backoff and jitter, and only on idempotent operations or behind an
  idempotency key
- A circuit breaker on a dependency that fails slowly, so a sick dependency stops being called
  instead of being waited on
- Bulkheads: a separate pool per dependency, so one slow service exhausts its own pool and not the
  one every request needs

**Bad:**

- One failed external API call causes a full page crash
- No fallback for a missing non-critical dependency
- Cascading failures: one slow service causes threads to pile up, crashing unrelated services
- An outbound client with no timeout configured, relying on the library's default — which for
  several common HTTP clients is no timeout at all
- Retries with no cap, or retries at every layer, multiplying the load on a dependency that is
  already failing

**How to check:** list the outbound clients — HTTP, database, queue, cache — from the manifest and
the configuration, and find where each one's timeout is set. A client with none is the finding, and
*the library has a default* stays a finding until somebody names the value.

#### 9.6 Log retention and disk hygiene *(Backend/Server-side and long-running processes)*

**Scope:** Applies wherever the system writes logs to durable storage it owns — servers, containers with persistent volumes, background workers. For managed platforms that enforce retention for you (hosted log drains, ephemeral container stdout), the criterion is met by that platform, but the *bound* must still be known.

Every log sink has a bound. The question is whether you chose it or inherited it.

- **Every sink has a known, enforced bound** — by size, by age, or both. "Known" means verified, not assumed: platform defaults *are* bounds, but often far larger than intended. `systemd-journald`, for example, defaults to 10% of the filesystem with **no time limit at all**, so retention silently becomes "as long as the disk allows".
- **The volume of each sink is measured at least once**, along with its composition — which channel, level, or event produces most of the lines. A sink whose daily volume you cannot state is a sink you cannot capacity-plan.
- **Writing a log record is never fatal to the operation it describes.** A sink that becomes unwritable — permission change, rotation race, full disk — must degrade: fall back to another sink, or drop the record. It must never abort the business operation.
- **Rotation ownership matches the writing process.** If rotation recreates the file as a different user than the one writing it, the sink breaks precisely at rotation time, on a schedule, in the middle of the night.
- **Debug-level output does not reach durable storage in production** (see 9.1).

**Good:**

- Retention bounds declared in configuration that is version-controlled or documented in a runbook — not left to distribution defaults
- Free space exposed as a health signal (see 9.3), so exhaustion is noticed while it is still cheap to fix
- A fallback chain on the primary sink (e.g. file → stderr) so an unwritable log cannot kill a request or a job

**Bad:**

- "It rotates by default" — without knowing which default, or whether that default bounds time as well as size
- One channel producing the overwhelming majority of log volume, unnoticed for months, because volume was never measured
- The logger raising an exception that propagates into application code
- Log growth discovered by the disk filling up

#### 9.7 Data lifecycle and retention

Logs are not the only thing that grows without limit. Append-only *data* — audit trails, event stores, notification history, metrics rows, diagnostic trackers — accumulates on the same trajectory, with none of the tooling that exists for log files.

- **Every append-only dataset has a retention policy that is scheduled**, not merely available. A purge command that exists in the codebase but is wired into no scheduler is not a retention policy; it is an intention.
- **Each dataset carries the temporal column its retention needs.** A policy that can only be expressed as "delete rows below id N" is a manual operation performed under pressure, not a policy.
- **Growth is measured** — rows and bytes per day — and compared against available storage, so time-to-exhaustion is a known number instead of a surprise.
- **Diagnostic and instrumentation data has an expiry decided when it is added.** Data added to investigate one incident should not still be accumulating a year later.
- **Retention is verified, not assumed.** A scheduled purge that has been failing silently for months is indistinguishable from no purge at all unless something reports its last successful run.

**How to check:** list the persisted datasets ordered by size, then for each of the largest ask *which scheduled job bounds this, and when did it last succeed?* Reconcile the list of append-only datasets against the list of scheduled retention jobs — the gap is the finding.

**Good:**

- Every append-only dataset maps to exactly one retention job, and the mapping is explicit enough to be reviewed (a documented list, a configuration table, or a test that fails when a new table has no policy)
- Retention windows chosen from a stated requirement — legal, forensic, or operational — rather than left implicit
- Datasets whose growth rate is measured and recorded, so a change of regime is visible

**Bad:**

- A purge command in the codebase that was never added to the scheduler, and therefore has never run
- A high-volume log table with no timestamp column, purgeable only by id
- A temporary diagnostic tracker, added during an incident, still growing indefinitely
- Retention "handled" by a job nobody has verified since it was written

#### 9.8 Slow query visibility

A query that was fast at ten thousand rows and takes four seconds at two million did not break
suddenly — it degraded, in public, while nobody was measuring. This criterion asks whether the
project would know.

Visibility has three parts, and a project usually has one of them: the threshold log exists, the
attribution is missing, and nobody reads it.

**Good:**

- Slow query logging on with a threshold chosen for this application — a value tuned to what "slow"
  means here, not the engine's 10-second default, which catches only queries that were already
  disasters
- Each slow query attributable to what caused it: the request path, job name, or correlation id
  travels with it, so the entry names a code path rather than only SQL text
- Queries aggregated by shape, not logged as unique strings: one fingerprint at 4,000 executions is
  the finding, and per-execution log lines hide it (`pt-query-digest`, `pg_stat_statements`,
  APM statement aggregation)
- **p95 and p99** tracked, not the mean. The mean of a fast path and a pathological tail is a
  reassuring number describing nobody's experience
- Row counts recorded alongside duration, so an unbounded fetch is visible before it becomes an
  out-of-memory incident
- Someone actually looks: the data reaches a dashboard or an alert threshold, not a file on a server

**Bad:**

- `slow_query_log` off, or on at the default threshold so nothing has ever been written to it
- A slow query log that exists and has never been opened — which is the same as not having one, at
  the cost of the disk it fills (see 9.6)
- Only average latency on the dashboard
- Slow queries visible in the database but not attributable to a request, so the investigation starts
  by guessing which endpoint issued them
- Query duration logged per execution into the application log, drowning the entries that need reading
- A degradation discovered because a user reported that a page "feels slow"

**Scoring without a database:** configuration tells you whether the threshold log is *enabled* and at
what value — half of this criterion, and the readable half. It cannot tell you whether anything is in
it, whether the entries are attributable, or whether the slow paths are known. Without the declared
access of precondition 4, score the configuration, say the rest is unverified, and cap the
subcriteria at 8.

#### 9.9 Operational access to the running system *(Operated services)*

**Scope:** Applies wherever the team operates the thing it ships — servers, containers, an
orchestrator, a managed platform. For a library, or an application that runs only on the user's
device, this is N/A: the equivalent concern is crash reporting and release telemetry, scored in 9.2.

Subcriteria 9.1 to 9.8 ask whether the system *produces* signals. This one asks who can reach them,
how quickly, and with what. A Grafana nobody can log into, a log file one developer knows how to
tail over SSH from one laptop, an uptime monitor on a trial account that stopped ingesting in March
— each of those is a signal that exists and cannot be read at the moment it is needed.

Three questions, scored as the weakest of them:

1. **Do the mechanisms exist in production?** Logs readable away from the machine (hosted search, a
   log drain, `journalctl` over a documented access path), a metrics dashboard (9.4), an uptime check
   that alerts a person, the error tracker's own UI (9.2), and a documented way to see process,
   container and deploy state.
2. **Can more than one person reach each of them today, without asking anybody?** Named accounts,
   and a runbook that gives the URL, the host, or the command for every signal above — not a
   credential in a chat thread and a key on one laptop.
3. **Can the agent working on the code reach the read-only half of it directly?** Through a declared
   path: an SSH account restricted to reading, an MCP server for the observability platform, a
   read-only API token, or a project command (`make prod-logs`) allow-listed in
   `.claude/settings.json`. The declaration lives in the **Production access** section of
   `.claude/PROJECT_AUDIT_FRAMEWORK.md`.

The third question is scored rather than merely noted because diagnosis conducted through a human
relay is diagnosis through a keyhole: the agent sees the excerpt it was pasted, not the surrounding
lines, not the metric that moved first, and not the second occurrence last Tuesday. Every narrowing
is invisible to it, so every conclusion it draws is conditioned on what someone already suspected.

**The ceiling has a condition.** Reach is not control, and the top of this scale is access that is
scoped, attributable and read-first — never root. An unrestricted `root` key, a shared `admin`
login, or a production token committed to `.mcp.json` scores **below** a project with no agent access
at all: it is reach the project cannot bound, attribute or revoke, and 8.x and 10.7 say the same
thing about it from their own side.

**What each band looks like here** (the anchors are the global ones; this is their shape for this
criterion):

| Score | Shape |
|---|---|
| 0–2 | No production signal is reachable without sitting at the machine, or the answer to "how do I see the logs?" is the name of a person |
| 3–4 | Access exists but is precarious: one holder, nothing written down, credentials passed by hand, a dashboard on an account nobody owns, a log readable only on the box |
| 5–6 | Documented and multi-person, but human-only: a runbook names the dashboards, hosts and commands, and every look is a manual one |
| 7–8 | Reachable from the development loop: read-only credentials in the operator's environment, wrapped in project commands or an MCP server, so the agent reads logs, metrics and health itself. Anything that mutates production stays a human's action |
| 9–10 | The agent can also carry out *named* operational procedures end to end — restart a service, tail and rotate a sink, trigger a rollback — each one an explicitly listed and individually approved action with a documented blast radius, leaving an attributable trail, and with the recovery path (10.6) not depending on that access |

**Good:**

- A runbook that, for each signal in question 1, names where it is, who can reach it, and how to get in
- Read-only by default: the credential the agent holds reads logs, metrics and health and can do
  nothing else; any mutating path is separate, explicitly granted, and separately approved
- Access expressed as project commands (`make prod-logs SINCE=1h`, `make prod-health`) that are
  allow-listed, so what the agent may do is a reviewable list in the repository rather than a shell
- One named account per consumer — revocable individually, and its use attributable afterwards
- Credentials read from the operator's environment or a secrets manager, never from the repository (10.7)
- The observable test: in a session, the agent can answer *"what did production do in the last hour?"*
  from the system itself

**Bad:**

- The only way to read a production log is `ssh root@server` with a key one developer holds
- Grafana exists; its URL is in somebody's bookmarks and its password in a 2023 chat thread
- Monitoring on a free tier that stopped ingesting months ago and was never noticed — a precarious
  tool is worse than no tool, because it is believed
- An MCP server configured with a production admin token committed alongside the code
- Production incidents diagnosed by pasting a log excerpt into a chat window
- Shared `admin` or `root` credentials: every action attributable to nobody, so an audit of what the
  agent did is impossible even in principle

**How to check:** ask for the list of production signals and, for each, the path that reaches it and
who holds it. Then verify the declaration *resolves* — the host and dashboard exist, the credential
source is named, the command is in the allow-list — rather than trusting it; a runbook entry pointing
at a decommissioned host is the finding. Verification during an audit is read-only: never issue a
mutating command to prove that access exists.

**Access cannot outrun the signals behind it.** If 9.1, 9.2 and 9.4 are low, the reach is onto a
system with nothing to say: score what is actually reachable and cap the subcriteria at 6. A shell on
a box whose application logs are unstructured `echo` statements gives the operator a terminal, not an
answer.

#### 9.10 Disaster recovery *(Operated services)*

**Scope:** Applies wherever the project owns production state or infrastructure — a database, an
uploads directory, an object store, a configured host, a domain. For a library, or an application
whose only artefact is a release someone else installs, this is N/A; the equivalent concern is build
reproducibility (10.1).

Start from the only question that matters: **what, if it disappeared tonight, could not be rebuilt
from the repository?** The database, the files users uploaded, the secrets, the DNS zone, the TLS
certificates, the hand-configured parts of a host, the provider account itself. That list is the
scope of this criterion, and in most projects nobody has ever written it down — which is the first
finding, because a backup plan can only cover the items somebody enumerated.

**This is not 10.6.** Rollback undoes a *deployment*: the code was wrong, the previous version is
still there, and the data is intact. Disaster recovery is for when the data or the machine is not
there at all — a dropped table, a corrupted volume, a ransomware event, an expired card that
terminated the account, an engineer who ran the right command against the wrong environment. The two
are scored separately because the project that has one almost never has the other.

**And it is the other half of 9.7.** Retention bounds what is kept; recovery guarantees that what is
kept can come back. A purge job with no backup and a backup that has never restored are the same
data loss at different speeds.

What is scored:

- **Coverage** — every item on the irreproducible list maps to a backup job, or is explicitly listed
  as accepted loss. "The hosting provider takes snapshots" counts only if someone can say what they
  contain, how far back they go, and how to get one back.
- **Separation** — a copy sharing the fate of its original is not a backup. A snapshot on the same
  host, in the same account, reachable with the same credential, dies with the thing it protects:
  one compromised key, one `terraform destroy`, one closed account. At least one copy is somewhere
  else, with its own credential, and is immutable or versioned so that corruption cannot propagate
  into it.
- **Proof** — a restore has actually been performed, end to end, into a clean environment, and the
  date and duration are recorded. Until that has happened the backup is a hypothesis; the clean
  environment is what makes it a proof, because a restore onto the original machine silently reuses
  every undocumented thing that machine already had.
- **RPO and RTO as stated numbers** — how much data the project accepts losing, and how long it
  accepts being down — chosen from a requirement and actually implemented by the backup frequency
  and the measured restore duration. Hourly backups with a twelve-hour restore do not meet a
  four-hour RTO, and only the drill reveals that.
- **Monitoring** — a backup job that fails is a backup job that fails *silently*. Last successful
  run is a health signal (9.3) with an alert behind it, and the same applies to the drill.
- **A runbook a second person can execute**, under pressure, without the author — including where
  the restore credentials come from. A backup encrypted with a key that exists only inside the lost
  system is not recoverable, and this is discovered exactly once.
- **Who can reach it** — the restore path needs the access of 9.9. If one person holds the only
  credential to the backup store, the recovery time is however long it takes to find that person.

**Good:**

- A written list of what cannot be rebuilt from the repository, each item mapped to the job that
  backs it up, the destination, and the retention
- At least one copy in another account or another provider, write-once or versioned, with its own
  credential
- A restore drill on a schedule, into a disposable environment, with the duration recorded and
  compared against the stated RTO — and the drill result alerting when it fails, like any other job
- Infrastructure reproducible from code (10.2), so recovery is restore-data-into-rebuilt-environment
  rather than remembering how the server was configured in 2021
- Non-production restores anonymised, so a drill does not spread production personal data into a
  staging environment that is less protected than the system it came from (Cat 8)
- What is deliberately *not* recovered written down, with the accepted loss — a decision, not a gap

**Bad:**

- No backup of the uploads directory, because the conversation only ever covered the database
- A nightly dump written to the same volume as the database it dumps
- A backup job whose last success was in March, in a project where nothing reports last-success
- A documented restore procedure that nobody has executed, written by the one person who could
  execute it
- A "daily backup, 7 days retention" chosen from a tutorial rather than from how much data the
  business can lose, and never reconciled with it
- Backups the agent or the on-call engineer cannot reach without waking the person who holds the key
- Recovery that depends on a single hand-configured machine nobody can rebuild — the backup restores
  the data onto nothing

**How to check:** ask for the irreproducible list and the backup jobs, and reconcile them — the gap
is the finding. Then, for each job: where does it write, is that somewhere that survives the loss of
the source, when did it last succeed, and **when was it last restored**. Where a production path is
declared (9.9), the last-success timestamps can be read through it; where none is, score from the
job configuration, the IaC and the runbook.

##### How the restore is proven

The difficult half of this criterion is not what the project does, it is what anyone can *know*. A
drill that happened and left nothing behind is indistinguishable from a drill that did not happen —
and not only to an auditor. The team that ran it has no duration to compare the next one against, no
record of which assertions passed, and nothing to alert on when the result changes. The artifact is
part of the practice, not a courtesy extended to the audit.

So the evidence is scored by **what produced it**. These are ceilings on 9.10, applied after the
properties above:

| Evidence that a restore works | Ceiling |
|---|---|
| The procedure has never been exercised | 5 |
| Somebody remembers doing it; nothing was recorded | 6 |
| A receipt written by hand after the fact | 6 — a claim in the shape of evidence is still a claim |
| A receipt emitted by a committed drill script: artifact restored and its age, target, duration, assertion results, outcome | 8 |
| That same script run by a scheduler or CI, its result recorded automatically, its failure alerting like any other job | 10 |

The step from 8 to 10 is not ceremony. A drill that runs because somebody remembered answers "did it
work in June"; a scheduled one answers "does it work now", which is the only tense an RTO is written
in. And its evidence is produced by a system whose output nobody types.

**`exit 0` is not a restored system.** An empty backup restores perfectly and reports success. A
drill proves something only where it asserts: row counts within an expected range of the source, a
known canary record present, a checksum or manifest over the restored files, the application booting
against the restored data with its health endpoint green (9.3), and the smoke tests of 10.8 run
against the restored environment. Without assertions, what was measured is the restore *command*.

**What an audit can and cannot verify.** A receipt can be typed by hand, and no amount of reading
will reveal it. What an audit *can* do is check it against records written by a different hand: does
the backup artifact it names exist in the store, does its duration appear in a CI run log, does the
commit that added it date from when it claims, did the drill script exist in the repository on that
date, does the receipt's shape match what that script emits. Consistency across independent records
is the entire mechanism — it raises the cost of a fiction rather than removing the possibility — and
a report says which of the two it is looking at instead of presenting a claim as an observation.

Where the project drills with `/dr-drill`, the receipt is written by the run and never by hand,
including when the run fails. A failed drill recorded is worth more than a successful one
remembered: it names a defect while the system is still standing.

#### 9.11 Orphaned infrastructure and unused access *(Operated services)*

**Scope:** applies wherever the project owns infrastructure or identities — a cloud account, a
cluster, a DNS zone, CI integrations, keys issued to it or by it. For a library, or an application
whose only artefact is a release someone else installs, this is N/A.

Every other subcriteria in this category is about what the running system tells you. This one is
about what stopped telling you anything: the resources and the credentials that are still
provisioned, still billed, still valid, and attached to nothing.

Two accumulations, and only one of them is about money.

**Resources.** A volume detached from the instance it was made for. Snapshots and machine images
from a migration that finished. An environment stood up for a demo in March. A DNS record pointing
at an address that now answers to somebody else. A bucket, a queue, a load balancer with no targets.
The bill is the small part. The real cost is that nobody can say which of the forty resources matter,
so nobody touches any of them — an orphan nobody recognises is indistinguishable from a resource
somebody depends on, and that ambiguity is what makes the list permanent. The dangling DNS record is
not even a cost: it is a subdomain takeover waiting to be found by somebody who is looking.

**Access.** The larger risk, and the one almost never swept. A deploy key for an archived
repository. A CI token for a provider the team left. An identity created for a migration two years
ago. A service account whose last use nobody remembers. A personal access token belonging to someone
who no longer works here. 8.6 scores how a secret is stored; this scores whether it should still
exist. An unused credential carries the full blast radius of a used one and none of the attention:
nothing breaks when it is compromised, so nothing reveals that it was.

*9.7 bounds data that grows; this bounds resources and identities that persist. 10.2's
infrastructure-as-code is what makes the reconciliation below possible at all — with no declared
state, there is nothing to compare the account against.*

**The evidence, and the access it needs.** Where the **Production access** block of
`.claude/PROJECT_AUDIT_FRAMEWORK.md` declares a read-only path, the provider answers most of it
directly. AWS below; every provider has the equivalent call:

```bash
# resources attached to nothing
aws ec2 describe-volumes --filters Name=status,Values=available
aws ec2 describe-images --owners self --query 'Images[].[ImageId,CreationDate]'
aws elbv2 describe-target-groups --query 'TargetGroups[?length(LoadBalancerArns)==`0`]'

# credentials that are valid and unused — the column that decides this is the last-used date
aws iam list-access-keys --user-name <user>
aws iam get-access-key-last-used --access-key-id <id>
gh api /repos/<owner>/<repo>/keys
```

Two more need no provider access at all, and they are the ones to run first: `terraform plan` (or
the stack's equivalent) against a clean checkout — whatever it proposes to create or destroy *is*
the drift between the declared account and the real one — and the monthly cost report read by
resource rather than by total, where an orphan appears as a flat line nobody can attribute.

**Reading is the whole audit.** Enumerating, planning and cost reporting are read-only; deleting a
resource or disabling a key is not, and is never part of scoring this. Where no production path is
declared, score from what the repository shows — the IaC state, the integrations listed in the CI
configuration, the documented key inventory — and **cap at 7**: the repository can only show the
declared half, and this subcriteria is precisely about the half nobody declared.

**Good:**

- The account is declared as code, and the reconciliation between declaration and reality runs as a
  job rather than as an afternoon. Anything present but undeclared is either an orphan or an
  undeclared dependency, and both are findings
- Temporary things are created with a death date: a TTL tag on the demo environment, an expiry on
  the migration key, a retention rule set when the first snapshot was taken rather than when the
  bucket became expensive
- Every long-lived credential has a named owner and a last-used date somebody looks at. Keys unused
  past a stated threshold are **disabled first and deleted later**, so a wrong call is reversible
- Cost is reviewed per resource by someone who can say what each line is for — the only review that
  finds an orphan, because the total is stable while the composition rots
- DNS records have owners, and a record whose target no longer resolves raises an alert

**Bad:**

- Nobody can produce a list of what the account contains. The question *which of these is
  load-bearing?* has no answer, and that is the finding before any single resource is examined
- Credentials that predate the current team, kept because nobody can prove what would break
- Resources named `test`, `test2`, `new-prod` — 10.10's branch failure, one layer down, with a
  monthly invoice
- A demo environment from a sales call eighteen months ago, still running, still holding a copy of
  production data: a 9.7 finding and an 8.6 finding arriving together
- *"We will clean it up when the bill becomes a problem."* The bill is the cheapest of the three
  costs and the only one that arrives on a schedule
- A sweep done by hand by whoever feels confident, with no dry run and no record. An orphan sweep
  that removes something load-bearing is worse than the orphans it removed

**How to score:**

- 0–2: no inventory. Resources and identities predating the current team, no owner, no expiry, and
  the first enumeration of what the account holds would be the one this audit performs
- 3–5: somebody knows most of it. Cleanup happens when a bill or an incident forces it; keys are
  revoked when a person leaves, when that is remembered
- 6–7: declaration and reality are reconciled periodically, by hand. Credentials are inventoried
  with owners, temporary resources are still created without a death date
- 8–10: the reconciliation is a job that reports, temporary things carry an expiry from the moment
  they are created, unused credentials are disabled on a last-used threshold before deletion, and
  the sweep's safety rules are written where the sweep is defined — dry run first, nothing deleted
  that the declaration does not know about until its owner has been found

---

## Category 10 — CI/CD & Version Control Discipline

**What it measures:** How well the delivery pipeline automates quality validation, environment management, and deployment — and how well version control practices make that pipeline trustworthy, auditable, and team-scale. Pipeline without discipline is a car with no steering wheel; discipline without pipeline is a steering wheel with no car.

*Decision records are scored in 0.7, with the rest of the planning documentation. What this
category measures is the pipeline and the repository, not the reasoning behind them.*

### Proportionality — which practices are load-bearing here

Every practice below exists to solve a problem, and not every project has every problem. Score the
practice against the problem rather than against the ceremony: **a project that does not have the
problem scores full marks without the practice**, and one that adopts the practice anyway has bought
friction and called it quality. This is the only place in the framework where the project's own shape
changes which subcriteria are in play, and it is confined to this category because this is where the
practices are about people rather than about code.

Two questions decide. Precondition 5 is where their answers come from — the **Team census** block,
or the git history where there is none.

**Who writes?** One person, or more than one.

**Who consumes a version?** Somebody who pins one, rolls back to one, or deploys one by name — a
library consumer, a release artifact, a changelog with readers. Or nobody, because the service is
deployed continuously from the mainline and a rollback names a commit.

| Subcriteria | Load-bearing when | Otherwise |
|---|---|---|
| 10.10 Branching strategy | always — every project has a mainline | Never N/A. *"Trunk, straight to `main`, merged the day it is started"* is a complete strategy and scores as one **once it is written down**. What this subcriteria fails is silence, not simplicity |
| 10.12 Pull requests | more than one person writes | **N/A.** A review that crosses nobody is a form filled in for the file. What the subcriteria asks of the change itself — one coherent concern, the *why* recorded, small enough to read in one sitting — survives without it and is scored in 10.11 |
| 10.13 Branch protection | always, in two halves | The **approval** half — require a review, dismiss stale approvals, no self-merge — is **N/A** with a single writer. The **gate** half is not: required status checks, no force-push to the mainline, linear history, signed commits. Those protect a lone developer from their own worst afternoon, and nothing about being alone makes them unavailable |
| 10.14 Tagging and semantic versioning | something consumes a version | **N/A.** A service deployed from `main` whose rollback names a commit already answers *what was running on 15 March* — `git log` does — and a tag nothing reads is a ritual. The day anything pins a version, this returns and is scored in full, including the changelog that comes with it |

The subcriteria not in the table are scored for every project. 10.11 and 10.15 always apply, and 10.17 to anything that ships; 10.16
carries its own partial-scoring clause for a repository with no branch residue to remove.

**The same question again, per area.** *More than one person writes* puts 10.12 in play for the
repository; it does not make a review available everywhere inside it. A directory one person has
ever touched has no reviewer — the pull request opens, somebody approves what they are not equipped
to evaluate, and the gate records a review that did not happen. Raising the required approval count
does not reach that, because the missing thing is not a rule. **The finding is the concentration**,
and it lands on the criteria that would have made the knowledge available to a second person: the
*why* written down rather than held (0.1), and onboarding that is a document rather than a
conversation (7.10). Score 10.12 on the changes that could be reviewed, and report the areas where
no approval is available as what they are.

```bash
# distinct authors per directory, lowest first — the 1s are the finding
# raise depth on a deep tree; 2 suits src/Domain-shaped layouts
git log --no-merges --format='@%an' --name-only HEAD |
awk -v depth=2 '
  /^@/ { a = substr($0, 2); next }
  NF { n = split($0, p, "/")
       if (n == 1) { d = "(root)" }
       else { k = (n - 1 < depth ? n - 1 : depth); d = p[1]; for (i = 2; i <= k; i++) d = d "/" p[i] }
       if (!((d SUBSEP a) in seen)) { seen[d SUBSEP a] = 1; authors[d]++ } }
  END { for (d in authors) printf "%d\t%s\n", authors[d], d }' | sort -n

# for an area that comes back 1: who, and whether the area is still alive
git log --no-merges --format='%an' HEAD -- <path> | sort -u
git log -1 --format='%ad' --date=short HEAD -- <path>
```

Read the two together before calling anything a finding. An area with one author and no commit in
two years is dormant code, and the question it raises is whether it should still be there (7.5). An
area with one author and a commit last week is the live half of the same observation, and the one
worth acting on. A `CODEOWNERS` entry naming somebody who has not committed in a year is the third
shape: review routed to nobody, with the routing still displayed as if it worked.

**This is a property of the repository, never of a person.** It names the area nobody else has been
in; it does not rank the people in it. Commit history measures territory — which parts of the tree
somebody was assigned — and territory is not ability: the developer who only ever appears in the
oldest module may be the strongest engineer on the team, placed where the work was hardest. Nothing
in this document scores an individual's competence from a log, and a reading of the history that
produces one is outside the framework.

Three things this rule is not:

- **Not a discount for small teams.** 10.1–10.9 are untouched by who writes the code: build
  reproducibility, environment separation, the CI gate, migrations, rollback, secrets, smoke tests. A
  one-person service in production is scored against every one of them exactly as a team's is, and
  the N/A column above never reaches them
- **Not permanent.** The shape belongs to a census, and a census has a date. A project that was one
  developer last year and is three now has 10.12 and 10.13's approval half back, and the first
  release somebody pins brings 10.14 with it. Discovering any of that during an audit is a finding
  about the census, reported as one
- **Not an argument a project makes for itself.** The conditions are structural and observable — a
  second contributor in the log, a consumer that pins — and the N/A rule earlier in this document
  already refuses the rest: N/A is for a concern that is absent, never for one that is inconvenient

### Subcriteria

#### 10.1 Build reproducibility

Every build from the same source revision must produce the same artefact.

**Good:**

- Lock files committed: `composer.lock`, `package-lock.json`, `Pipfile.lock`, `Cargo.lock`
- Docker images pinned by digest, not floating tags (`image: php:8.3.7-fpm`, not `php:latest`)
- Build dependencies explicitly declared, not installed ad-hoc

**Bad:** `npm install` without a lockfile in CI. `FROM ubuntu:latest` in a Dockerfile. A build that calls out to external URLs for assets.

#### 10.2 Environment separation

Code must run identically in all environments; only configuration changes.

**Good:**

- Dev, staging, production environments identical except for configuration values
- Configuration via environment variables (12-Factor principle)
- No `if ($env === 'production')` branches in business logic
- Infrastructure as Code (Terraform, CDK, Pulumi) for environment definitions

**Bad:**

- Hotfixes applied directly to production that are never back-ported
- Code that behaves differently based on detected hostname or IP
- Manual configuration steps not tracked in version control

#### 10.3 Automated quality gate in CI

Every push to a shared branch triggers the full quality suite: static analysis, style checks, tests.

**Minimum pipeline:**

```yaml
- static-analysis   # phpstan / tsc --noEmit
- style-check       # php-cs-fixer / eslint / prettier --check
- unit-tests        # fast, no external dependencies
- functional-tests  # in-process, stubs
- security-audit    # composer audit / npm audit
```

**Good:** PRs cannot be merged if any step fails. Pipeline runs in under 5 minutes for most projects. Integration tests run on a schedule (nightly), not on every push.

**Bad:** Tests only run locally before push. CI that only builds but does not test. A flaky test suite that is routinely bypassed.

#### 10.4 Database migrations

**Good:**

- All schema changes versioned as migration files
- Migrations run automatically on deploy
- Migrations are backward-compatible: add columns as nullable before removing old code, then remove old code before making them required ("expand-contract" pattern)
- Migrations are reversible (down migrations) where feasible

**Bad:**

- Manual SQL applied directly to production databases
- Schema changes deployed simultaneously with code changes (downtime risk)
- Migrations that cannot be rolled back

**The contract phase is the half that does not happen.** Expand-contract is two deployments and
scoring only the first one rewards half a pattern. The expand is forced — the feature does not work
without it — while the contract is a deployment whose entire visible effect is that something stops
existing. Nobody is waiting for it, so it is never urgent, and the schema ends up carrying both
shapes permanently: the column left nullable "for now" three years ago, read by nothing and
defensively handled everywhere; the table the old code wrote to; the index created for a query that
was rewritten the following week.

This is not tidiness. Every abandoned column is a field a developer must decide about when they
touch that table, a column an ORM hydrates, a shape a migration has to carry forward, and — where it
held personal data the application no longer uses — a retention obligation nobody is tracking (9.7).

What to look for, and none of it needs an opinion:

```sql
-- indexes the planner has never used since statistics were last reset (PostgreSQL)
SELECT relname, indexrelname, idx_scan FROM pg_stat_user_indexes WHERE idx_scan = 0;

-- tables that are written and never read, or neither (PostgreSQL)
SELECT relname, seq_scan, idx_scan, n_tup_ins FROM pg_stat_user_tables ORDER BY seq_scan + idx_scan;
```

Then read the migration directory as a sequence rather than a set: a project whose migrations only
ever add is a project that has run the expand half of every change it ever made. **Good** is the
contract migration arriving as a scheduled follow-up, written when the expand is written, with the
condition for running it stated — *when no code path has read this column for one release* — and a
query confirming the condition before it runs. **Bad** is a column whose comment says
`-- TODO: drop after migration`, dated, and still there.

#### 10.5 Zero-downtime deployment

**Strategies:** Blue-green deployment, canary releases, rolling updates.

**Good:**

- New version deployed alongside old version; traffic shifted gradually
- Automated health checks gate the rollout — if error rate spikes, rollout stops automatically
- Load balancer drains connections from the old version before terminating it

**Bad:**

- Deploy by stopping all instances, deploying, restarting (100% downtime per deploy)
- Relying on "it's 3am, nobody is using it" as a deployment strategy

#### 10.6 Rollback capability

**Good:**

- Any deployment can be rolled back in under 5 minutes
- Rollback is a one-command operation (`kubectl rollout undo`, `git revert` + redeploy)
- Rollback tested regularly (not just theoretically available)

**Bad:**

- Rollback requires manually undoing database migrations with no documented procedure
- Last known good artefact is not retained

*Rollback is for a deployment that went wrong while the data and the machine are still there.
Recovering from losing either of those is 9.10.*

#### 10.7 Secrets in CI/CD

**Good:**

- Secrets injected as environment variables from the CI platform's secrets store (GitHub Secrets, GitLab CI Variables, AWS SSM)
- Secrets never echoed in build logs
- Separate secrets per environment; no production credentials accessible from development jobs

**Bad:**

- Secrets hardcoded in `.gitlab-ci.yml` or `Makefile`
- The same API key used in all environments
- Build logs that print environment variables on failure

#### 10.8 Smoke tests post-deploy

**Good:** After every deployment, an automated smoke test suite verifies the most critical user paths are working in the live environment (not just in the test environment).

**Bad:** First signal of a broken deployment is a user complaint.

#### 10.9 Evolutionary architecture and incremental change

*This subcategory is most relevant for systems that must evolve over time — multi-tenant platforms, systems serving multiple markets, or codebases that will be extended by different teams.*

*The plan that sequences a migration is scored in 0.8. What this subcategory measures is whether the
architecture admits such a sequence at all — a system with no seams leaves no plan available but the
cutover.*

An evolutionary architecture is one that supports incremental, guided change across multiple dimensions simultaneously. The central idea (Ford, Parsons, Kua) is that architecture fitness functions — automated checks that verify architectural properties — should be treated as first-class citizens alongside functional tests.

**Strangler Fig pattern (Fowler):** When replacing a legacy subsystem, do not attempt a big-bang rewrite. Instead:

1. Place a facade in front of the legacy system that intercepts calls
2. Incrementally redirect calls from the facade to the new implementation, path by path
3. When all calls are redirected, remove the legacy system
4. The system continues operating throughout the migration

This pattern applies to any large-scale refactoring: replacing a monolith with services, migrating from one data store to another, re-platforming a legacy API — all are Strangler Fig scenarios.

**Signals of evolutionary readiness:**

- New features can be added without modifying existing, tested code (OCP in practice at the system level)
- Bounded contexts can be extracted into separate deployable units without rewriting their internal logic
- Data schema changes are additive and backward-compatible (new columns nullable; old columns deprecated before removal)
- A new integration partner can be onboarded by implementing an existing interface, not by modifying core flows

**Signals of evolutionary brittleness:**

- Adding a new market or customer type requires changes in 20+ files
- A "simple" feature request triggers a rewrite discussion
- No seams between major subsystems — everything is entangled in a shared database schema or a shared object graph
- Every schema migration is a deployment freeze risk

**Fitness functions (architecture tests):** Automated checks that verify architectural properties remain intact over time. Examples:

- `deptrac` fails if any domain class imports an infrastructure class (architectural boundary)
- A test that verifies all public API endpoints return within 200ms (performance fitness function)
- A mutation test threshold that fails CI if mutation score drops below 60% (test quality fitness function)
- A check that no aggregate root exposes more than N public methods (complexity fitness function)

#### 10.10 Branching strategy

A branching strategy is a team contract, not a technical setting. Any well-known flow (Git Flow, trunk-based development, GitHub Flow) is acceptable; the failure mode is the absence of any explicit agreement, which produces organic chaos: long-lived branches that diverge for weeks, silent merge conflicts, and no shared understanding of "what is in production right now."

**Signals of a healthy strategy:**

- The strategy is written down (in `CONTRIBUTING.md`, a wiki, or a team agreement) — not just assumed
- Every branch has a clear purpose and a clear owner (whether the deletion after merge actually
  happens, and what makes it happen, is 10.16)
- The main branch reflects production at all times (trunk-based) or a well-defined integration branch does (Git Flow `develop`)
- Feature branches are short-lived: merged within days, not weeks

**Signals of no strategy:**

- Branches named `fix`, `test2`, `nicolaTempBranch`, `mario-lavori` accumulate and are never merged or deleted
- The same logical change exists on multiple branches without a merge plan
- Nobody can answer "what is currently deployed to production?" without checking with a person
- Merge conflicts are discovered only at the moment of release, not continuously

**Common strategies:**

| Strategy | Best for | Key rule |
|---|---|---|
| Trunk-based | High-deployment-frequency teams (≥1/day) | All work merges to `main` within 1–2 days; feature flags gate incomplete work |
| GitHub Flow | Small teams, continuous deployment | One `main`, feature branches, PR → merge → deploy |
| Git Flow | Scheduled releases, versioned artefacts | `main` + `develop` + `feature/*`, `release/*`, `hotfix/*` |

Whatever strategy is chosen, the rule is the same: **name it, document it, enforce it via branch protection.**

#### 10.11 Commit discipline

A commit message is the only piece of documentation that travels with the code forever. It is the primary input to `git log`, `git bisect`, automated changelogs, and future developers trying to understand why a change was made.

**Conventional Commits format (de facto standard):**

```text
<type>(<scope>): <short summary in imperative mood>

[optional body — explains WHY, not WHAT]

[optional footer — breaking changes, issue references]
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`, `build`

**Good examples:**

```text
feat(pricing): add support for OHLCV interval selection

fix(health): return 503 when disk usage exceeds 90%

refactor(http-client): extract decodeJson to eliminate duplication
# Why: BinanceRepository and CoinGeckoRepository had identical private methods
```

**Bad examples:**

```text
fix stuff
WIP
update
asdfasdf
changed things, now works
```

**Why it matters beyond aesthetics:**

- `feat:` and `fix:` commits enable automated semantic versioning (Conventional Commits + `semantic-release`)
- `git bisect` becomes effective only when commits are atomic and their messages describe their intent
- A one-year-old commit message is the only context available when debugging a regression at 2am

**Tooling:** `commitlint` in CI enforces the format. A `.commitlintrc.json` with `@commitlint/config-conventional` catches violations at PR time.

#### 10.12 Pull requests as the unit of review

A pull request is not just a merge mechanism — it is the primary asynchronous communication channel between the author and the rest of the team. Its quality directly determines the quality of the review it receives.

**A reviewable PR:**

- Is focused on one coherent change (a feature, a bug fix, a refactor — not all three at once)
- Has a description that explains the **why** (what problem does this solve? why this approach and not another?)
- Is ≤400 lines of meaningful code change (excluding generated files, lock files, migrations)
- Links to the issue or ticket it addresses
- Notes any non-obvious decisions or trade-offs so reviewers know where to focus attention
- Is submitted in a state the author considers mergeable — not "I'll clean it up after review"

**A non-reviewable PR:**

- 3,000-line diff touching 40 files across unrelated concerns
- Description: "fixes bug" or left blank
- No context about what was broken or why this is the right fix
- Code that the author knows is incomplete but "wanted feedback early"

**The size trap:** Large PRs are not reviewed — they are rubber-stamped. The SmartBear study of code review at Cisco (Cohen, 2006) found reviewers' ability to find defects falls off beyond roughly 200–400 lines in one review. If a change genuinely requires more, split it into a stacked PR series: infrastructure first, then feature on top.

**Good signals:**

- Average PR size is tracked (GitHub Insights, LinearB, etc.)
- There is a team norm on PR size and it is enforced socially or tooling
- Reviewers leave substantive comments, not just approvals
- All review discussions are resolved before merge

#### 10.13 Branch protection

Branch protection rules are the enforcement layer that makes all other practices non-optional. Without them, every quality gate in Cat. 10 can be bypassed with a direct push to `main`.

**Minimum protection on `main` (and `develop` in Git Flow):**

| Rule | Why |
|---|---|
| Require pull request before merging | Enforces review as a gate, not a courtesy |
| Require at least 1 approving review | No single-person merges of their own code |
| Dismiss stale approvals on new push | Re-review required if code changes after approval |
| Require CI status checks to pass | Pipeline cannot be bypassed |
| Require branches to be up to date | Prevents "it passed on my branch" merges that break main |
| Restrict who can push directly | Only break-glass for emergency hotfixes, with a documented procedure |

**Additional protections for enterprise:**

- Require signed commits (`git commit -S`) — non-repudiation for regulated environments
- Require linear history (no merge commits on `main`) — cleaner `git log` and `git bisect`
- Require conversation resolution before merge — no open review threads at merge time

**The emergency hotfix exception:** Every team will have a genuine emergency that requires bypassing the normal flow. Define the exception procedure in advance: who can bypass, what documentation is required, and what follow-up is mandatory (post-merge PR review, incident record).

#### 10.14 Tagging and semantic versioning

A version tag is a pointer from a human-readable name to a specific commit. It answers the question: "what code was running in production on 15 March?" without requiring a conversation.

**Semantic versioning (semver): `MAJOR.MINOR.PATCH`**

| Increment | When | Example |
|---|---|---|
| `PATCH` | Backward-compatible bug fix | `1.4.2` → `1.4.3` |
| `MINOR` | Backward-compatible new feature | `1.4.3` → `1.5.0` |
| `MAJOR` | Breaking change | `1.5.0` → `2.0.0` |

**Good practices:**

- Every production release has a git tag: `git tag -a v1.5.0 -m "feat: OHLCV interval selection"`
- Tags are pushed explicitly: `git push origin v1.5.0` (tags are not pushed by default)
- `CHANGELOG.md` is generated automatically from Conventional Commits (tools: `conventional-changelog`, `semantic-release`, `release-please`)
- Pre-release versions use the semver pre-release syntax: `v2.0.0-rc.1`, `v2.0.0-beta.3`

**Bad practices:**

- No tags at all — "you can check the deploy log in Slack" is not a substitute
- Tags named `final`, `final2`, `final-REAL`, `production-dec`
- Version bumps are manual and inconsistent — the CHANGELOG is written by hand and frequently out of date
- Internal libraries have no versioning — consumers cannot pin to a known-good version

**Automation with `semantic-release`:** Given Conventional Commits are enforced (10.11), the version bump and CHANGELOG generation can be fully automated: `feat:` → MINOR, `fix:` → PATCH, `BREAKING CHANGE:` footer → MAJOR. The CI pipeline tags the release, publishes the artefact, and updates the CHANGELOG without human intervention.

#### 10.15 The definition of done is declared, and its mechanical half is automated

Every other subcriteria in this category measures the quality of an artifact: the message (10.11),
the pull request (10.12), the protection rule (10.13), the tag and its version (10.14). This one
measures whether the artifact **reliably exists when a change is finished**, and what makes sure of
it. Work that runs on a laptop has not been delivered; it has been written.

**The shape is the project's, and more ceremony is not a higher score.** A solo repository where done
means *committed to `main`, pushed, CI green* is a complete and legitimate answer that scores 9 when
it is declared and checked. A twelve-person team where done means *branch, pull request, one
approval, green, squash, changelog entry, release tag* is another. The framework does not pick
between them and does not reward the longer list.

What does not scale with the team is whether it is **written down**. An undeclared convention is one
the newest member learns by having a pull request rejected, and one an agent cannot follow at all:
it will ask at every step or guess, and the asking is what a team mistakes for caution until it has
paid for it a hundred times.

Three questions, in order.

**1. Is it declared?** The *Delivery convention* block of `.claude/PROJECT_AUDIT_FRAMEWORK.md`: the
branch policy, what *done* means, what rides along with a user-visible change, what triggers a
release, and — separately — which of commit, push, branch, pull request and tag a session may do
unattended, onto which refs. That last part is the project's standing authorization, and the reason
an agent can stop asking.

**2. Is the mechanical half mechanical?** Everything in the declaration a machine could check is
checked by one. The version and the changelog's newest entry agree; every released version has a tag
and the tag sits on the commit that declared it; the install and upgrade instructions pin the current
version; the changelog has an entry for the release being cut. Each of those is a job that fails with
the command that fixes it. Where the only thing making it happen is somebody remembering, what the
project has is a norm, not a definition of done — and norms are observed in proportion to how recently
someone was burned.

**3. Does the history conform?** The artifacts arrive *with* the change, not after it. This is the
question the first two cannot answer, and the log answers it without being asked.

**And it is read against the convention *including its declared exception*.** Every convention is
departed from eventually — the production incident at 2am, the one-character fix on a Friday — and a
reading that counts each departure as a breach scores the team that wrote down when it is allowed
below the team that has never had an emergency, and level with the team that departs whenever it
feels like it. That is the measurement backwards.

So the *Fast-lane gate* block of `.claude/PROJECT_AUDIT_FRAMEWORK.md` is part of what question 3
reads. It declares what qualifies as small enough to shorten the ceremony, what never qualifies
however small it looks, and what the change carries anyway. Then:

- **A departure inside a declared gate, carrying what the gate says it carries, is conformance.**
  It is the convention working, not an exception to it. Score it as such.
- **A departure with no gate declared is a breach**, whatever reason the commit message gives. The
  reason is always good at the time; that is precisely why the bound is written in advance.
- **A gate whose bounds are not observed is worse than no gate**, because the declaration is now
  evidence the team knew and went anyway. Read the *Never qualifies* list against the diffs that
  actually took the lane.
- **Declaring no gate at all is a complete answer** and costs nothing here. It means every change
  goes the ordinary route, and the history should show exactly that. What is scored is the agreement
  between the two, never the presence of a fast lane.

**Good:**

- The convention is declared, at the size the team actually is, and the declaration names what a
  session may do rather than leaving it to be inferred
- The release-time documents ride with the change that invalidated them: the version bump, the
  changelog entry, and the install or upgrade steps that name a version, in the same commit.
  Principle 22's rule applied to the artifacts of a release; 7.10 scores the rest of the corpus
- One check per mechanical claim, each failing with the command that fixes it
- The release is reproducible from the repository — a script or a workflow, not a sequence in
  somebody's notes, and not a sequence only one person has run
- An agent's permissions are enumerated action by action and ref by ref, and the enumeration is
  narrower than what the humans may do
- Where the ceremony can be shortened, the bound is written before it is needed: what qualifies in
  terms somebody can check against a diff, what never qualifies however small it looks, and the
  floor the change still carries. Used a handful of times a year, each time inside those bounds, each
  time with the test that proves the fix — a convention with a declared exception that is observed is
  a stronger result than one with no exception that is quietly broken twice a quarter

**Bad:**

- No declaration. *"We all know how we work here"* is true of everyone who was in the room when it
  was decided, and of nobody who arrived afterwards
- Finished work left uncommitted or unpushed at the end of a session, because delivering it was
  nobody's step. The most common failure in this subcriteria and the only one that leaves no
  artifact at all to find later
- A changelog written in a sweep before the release, from the log, by whoever is cutting it: it
  records what the commits said, which is the one thing a reader could already get from the commits
- The version bumped in one commit, tagged from another, the changelog updated in a third, and the
  install instructions still pinning the version before last
- A convention enforced by review comments — *"please add a changelog entry"* on every pull request
  is a check being run by a person, at the price of a person, with a person's recall
- A declaration that grants an agent everything, force-push and tagging included, because enumerating
  was more work than allowing. The block is a boundary; one that excludes nothing is decoration
- No declared exception path, and a history that departs from the convention every few weeks anyway.
  Each departure had a reason, nobody wrote the reasons down, and the convention now describes how
  the team works on calm days only
- A fast lane with no floor — *small* taken to mean the test, the log line and the document can wait
  as well as the review. Less ceremony is the point; less change never was, and the fix that came
  back is the one that shipped without the regression test
- A *Never qualifies* list the diffs contradict. A one-line change to an authorization check is not a
  small change; it is a one-line change, and a lane that accepted it was not a gate

**How to score:**

- 0–2: Done is whatever the developer felt was enough. Nothing declared, nothing checked; work and
  its documents arrive in unrelated commits, or do not arrive
- 3–5: A convention exists in people's heads or in a contributing guide, and is enforced by review or
  by memory. Release artifacts are a sweep before a tag
- 6–7: Declared and largely followed, with the checks partial — the changelog is validated but the
  install instructions are not, or the tag is manual and sometimes lands on the wrong commit
- 8–10: Declared at the size the project is, every mechanical claim carried by a check that fails,
  the history showing artifacts arriving with their change, and a session's authority enumerated.
  A three-line convention fully automated scores above a fifteen-step one enforced by review

**On the exception path, at every band:** a project that declares none and departs from its
convention anyway is scored on the departures, which is where it already was. A project that declares
one is scored on whether the history stays inside it — never on having one. The band is not raised by
writing a *Fast-lane gate* and not lowered by leaving it out; what moves is the reading of the
departures the log already contains.

#### 10.16 The repository cleans up after itself

10.10 scores whether a branching strategy exists and is named. This scores whether the repository
still looks like that strategy after six months of a team following it — and the difference between
the two is not discipline, it is whether anything runs on its own. Every practice in this category
leaves residue: a branch per merge, a dead remote-tracking ref per deleted branch, an artifact per
build, a draft release per tag. Residue is nobody's task right up until the list it lives in has
stopped being readable, and by then the cleanup is an afternoon rather than a setting.

*Dead code inside the source is 7.5 and a deprecated API past its deadline is 7.8. What this
subcriteria measures is the repository and its host — refs, artifacts, ignore rules, size — not the
code stored in them.*

**The evidence is four commands, and none of them needs an opinion:**

```bash
# merged branches still on the remote, excluding the mainline itself
git branch -r --merged origin/main | grep -vE 'origin/(main|HEAD)' | wc -l

# every remote branch by last commit, oldest first — the age distribution is the finding
git for-each-ref --sort=committerdate --format='%(committerdate:short) %(refname:short)' refs/remotes | head -20

# refs this clone still carries for branches that no longer exist upstream
git remote prune --dry-run origin

# what the repository weighs, which is what every new clone downloads
git count-objects -vH
```

Then one more, which is the cheapest check in this category and the one most often never run: a
clean checkout, a full build and test run, and `git status`. Anything it lists is something the
project's ignore rules do not cover and somebody will eventually commit.

**Good:**

- The host deletes the branch at merge — GitHub *Automatically delete head branches*, GitLab's
  *delete source branch* default, the Bitbucket equivalent. One setting, on the repository, so no
  author is ever the reason a branch survives
- `fetch.prune` reaches every clone through a documented setup step or a bootstrap script, rather
  than through each developer discovering it after a year of noisy fetches
- The project ships the local-side command — a `make tidy` target, a checked-in script, a
  documented alias — and it is safe by construction: merged branches only, never the checked-out
  one, dry run by default
- A scheduled job handles what no single change can reach, with its retention rule written where the
  job is defined and a report naming what it removed
- Artifact and cache retention is configured, not left at whatever the CI platform defaults to
- The ignore rules arrived with the tool that made them necessary, and a fresh checkout is clean
  after a full build

**Bad:**

- Sixty remote branches, fifty-five of them merged — the five that are not are invisible, which is
  the actual cost; the storage never mattered
- Every developer pruning refs by hand on the day the noise finally annoys them, forever, because
  the configuration that would do it was never written down anywhere
- `dist/`, `node_modules/`, a database dump or a `.env` in the history. Every clone pays for them
  permanently, and the fix is a coordinated history rewrite rather than a cleanup
- The sweep lives in one person's shell aliases and leaves with them
- A scheduled job that deletes branches by age alone, merged or not. Automation that destroys
  unfinished work scores **below** having none: the mess was recoverable, the branch was not
- A *clean up branches* card moved forward every sprint. The card is the admission that nothing runs

**N/A and partial scoring:** a repository worked straight on `main` by one person has no branch
residue to remove; score the ignore rules, artifact retention and clone size, and mark the branch
half N/A rather than scoring it zero. A project whose host offers no auto-delete setting is scored on
what it put in place instead, not on the absence.

**How to score:**

- 0–2: nothing runs. Merged branches, dead refs and build output have accumulated since the first
  commit, and every ignore rule arrived one commit after something was committed by mistake
- 3–5: cleanup happens when somebody is annoyed enough to do it, by hand, alone. The repository was
  last tidied the day a developer could not find their own branch
- 6–7: the merge-time half is automatic — the host deletes the branch, build output is ignored —
  and everything outliving a single change is still manual
- 8–10: both triggers run. The change's residue leaves with the change, the rest leaves by a
  scheduled job with a written retention rule and a readable report, the safety line is stated and
  the job honours it, and a fresh clone of an old repository is small and clean after a build

#### 10.17 Delivery outcomes are measured

Every other subcriteria in this category scores a practice. This one scores whether the project
knows what its practices produce. Forsgren, Humble and Kim identified four measures that, across
thousands of organisations, separate the teams that deliver well from the rest — and found that
speed and stability move together rather than trading against each other:

| Measure | The question | Read from |
|---|---|---|
| Deployment frequency | How often does a change reach production? | Tags, deployment records, merges to a continuously deployed mainline |
| Lead time for changes | How long from commit to running in production? | Each commit's time against the first deployment that contained it |
| Change failure rate | What share of deployments needed a fix, a rollback or a hotfix? | Reverts and `fix:` releases against the deployment they repair; incident records |
| Time to restore | How long from a failure in production to its repair? | Incident records; the gap between the failing deployment and the one that fixed it |

**What is scored is that they are measured, visible and read — never their values.** A team that
deploys monthly, knows it, and watches the trend scores above a team that deploys daily and has never
looked. The values belong to the product's context; the measurement belongs to every project that
ships.

**Read as a set.** Any one of the four alone is the easiest number in this document to improve by
making another worse — deploy more often by shipping small fixes to the failures you just caused. A
measure turned into a target stops measuring, which is Goodhart's law and the reason this
subcriteria scores the instrument and not the reading.

**Scope.** Applies to anything that is deployed or released. A library reads its releases as
deployments: frequency of release, lead time to release, and the patch releases that repair the one
before as its failure rate. N/A only for a repository that never ships.

**No tooling is needed to start.** For a project that deploys from tags, the history already holds
the first two:

```bash
# deployment frequency: releases per month
git tag --sort=creatordate --format='%(creatordate:format:%Y-%m)' | uniq -c

# lead time: for each release, the age of the oldest commit it shipped for the first time
prev=""
for t in $(git tag --sort=creatordate); do
  if [ -n "$prev" ]; then
    oldest=$(git log --format=%ct "$prev..$t" | sort -n | head -1)
    shipped=$(git log -1 --format=%ct "$t")
    [ -n "$oldest" ] && printf '%s  %s days\n' "$t" "$(( (shipped - oldest) / 86400 ))"
  fi
  prev=$t
done
```

The other two need the project to record what a failure is — a revert, a hotfix tag, an incident
entry — and the first finding is often that nothing does.

**Good:**

- The four computed by a job or a dashboard, not by hand at audit time
- Each visible to the team, with a trend over at least a quarter
- A change in one of them noticed and discussed — a lead time that doubled is a finding the team
  made before the audit did
- Failures counted honestly: a hotfix is a failure of the deployment it repaired, not a separate
  delivery

**Bad:**

- Nobody can say how often production changes, or how long a commit waits to reach it
- Deployment frequency reported alone and celebrated while the change failure rate climbs
- Targets set on the measures and rewarded, so the numbers improve and the delivery does not
- Measures computed and never read

**How to score:**

- 0–2: None of the four is known
- 3–5: One or two could be computed from the history and nobody has, or they were measured once
- 6–7: All four computed, by hand or at irregular intervals; the trend not watched
- 8–10: All four computed automatically, visible, read as a set, and discussed when they move

---

## How to conduct a quality evaluation

### Step 1 — Read before scoring

Read at least these files before assigning any score:

1. The product documentation — the context of 0.1, the specs of 0.3 and their status markers. Read
   it *first*, and before the code: it is the only account of intent that the code cannot supply,
   and every later judgement about whether something is missing or merely unbuilt depends on it
2. The core domain models (Entities, Value Objects)
3. The main use case or service entry points
4. A representative controller or API handler
5. The test suite structure (directories, a few test files)
6. The CI configuration (`.github/workflows`, `Makefile`, `composer.json` scripts)
7. The dependency manifests (`composer.json`, `package.json`)
8. The git log (`git log --oneline -20`) — commit message quality is observable immediately
9. The branch list (`git branch -a`) — stale or unnamed branches signal absent strategy
10. `CONTRIBUTING.md` or equivalent — is the branching strategy documented?
11. The translation catalogs and the surfaces that write text for a person (templates, PDF and mail builders, CLI output) — 2.9 and 2.10 cannot be scored from source alone

### Step 2 — Score each subcategory with evidence

For each subcategory, write: "Score X/10 because [specific file, line, or observable behaviour]." Reject vague scores like "7/10 — looks pretty good."

### Step 3 — Identify the top 3 improvement opportunities

Across all categories, identify the three improvements that would have the highest impact per unit of effort. Prioritise:

- Gaps with severity: a missing CSRF token is higher priority than an imperfect naming convention
- Automation gaps: any quality that currently relies only on developer discipline
- Test coverage gaps: untested critical paths

Rank against the product context of 0.1 where one exists — impact is a claim about the product, and
a document that says what the product is for is better evidence for it than the auditor's reading of
the code. Where it does not exist, say so in the ranking: the order is then an engineering judgement
presented as a product one, and the reader deserves to know which they are getting.

**Rank inside the band and inside the phase, never across either.** Which improvements are
available to a project at all is decided by *Remediation order* below, and that section is applied
before this ranking rather than after it: the band selects the categories that are still short of
target, the phase orders them, and impact per unit of effort chooses among what is left. A top three
that leads with work the project cannot yet do safely is a worse artefact than one that leads with
the prerequisite holding it — the first reads as a plan and fails as one. A top three that leads
with a category already at the band target is worse still: it reads as a plan, works as one, and
leaves the project exactly as fragile as it was.

### Step 4 — Produce a category summary

| # | Category | Score | Top gap | Recommended action |
|---|---|---|---|---|
| 0 | Product Strategy & Delivery Documentation | 4.0 | PRDs carry no status marker | Add `status:` frontmatter from the closed set; update it in the implementing PR |
| 1 | OOP & Design Patterns | 8.0 | PageController has 4 responsibilities | Split into PageController + BootstrapBuilder |
| 10 | CI/CD & Version Control Discipline | 6.5 | No branch protection; commit messages undisciplined | Enable branch protection on main; add commitlint to CI |
| ... | | | | |

### Step 5 — Reassess after changes

Score only after changes are implemented and verified. An improvement that is "planned" or "in progress" does not change the score.

---

## Remediation order — what has to be true before a gap can be closed

An audit produces a list of gaps. A list is not a plan, and ranking it by impact per unit of effort
does not make it one: that ranking answers *which gap is worth the most*, which is a different
question from *which gap can be closed safely this month*. The second question has a stricter
answer, and it does not depend on how much any one gap is worth.

**The rule in one sentence: a change to existing code is only as safe as the project's ability to
notice that it broke something.** Categories 0, 4, 7 and 10 are what produce that ability —
recorded intent, tests, analysers, and a pipeline that runs them on every change. Categories 1, 2,
3, 5 and 6 spend it. Spending before earning is how a quality programme turns into an outage, and
it is the single most common way a team that did everything the audit asked ends up worse off than
when it started.

The failure is not hypothetical and it has a recognisable shape. A team reads a 4/10 in Clean Code,
spends six weeks renaming and decomposing, ships a regression nobody can localise because thirty
files moved in the same diff, and concludes that the framework costs more than it returns. The
audit was right about the score. The sequence was wrong, and the sequence was the team's to choose
because nothing in the report told them one existed.

### The phases

Work in phase order. Within a phase, rank by impact per unit of effort — that is where the ranking
of Step 3 belongs, and the only place it is safe.

| Phase | The work | Categories | What it produces |
|---|---|---|---|
| 0 | Stop the bleeding | 8, parts of 9 and 10 | Nothing is actively being lost |
| 1 | Record the intent | 0 | A statement of what the code is supposed to do |
| 2 | Build the net | 4, 7, 10, parts of 9 | The ability to detect a regression |
| 3 | Change the code | 1, 2, 3, 5 | Structure, naming, boundaries |
| 4 | Change the platform | 6 | A supported framework and dependency set |

**Phase 0 — Stop the bleeding.** An exploitable vulnerability (Category 8), data that is
accumulating with no backup or no retention bound (9.7, 9.10), a deploy that cannot be rolled back
(10.6). These bypass every gate below, because the cost of waiting on them is unbounded while the
cost of waiting on everything else is linear. The bypass is narrow: it licenses the smallest change
that closes the hole, not the refactoring the same file also deserves.

**Phase 1 — Record the intent.** Category 0, and specifically 0.1. A refactoring is a claim that
two pieces of code mean the same thing, and nothing in the code can adjudicate it — the odd special
case in the pricing function is either an accident worth deleting or a contract signed in 2021, and
only a document distinguishes them. Without 0.1, every Phase 3 decision is a guess dressed as a
cleanup. The backfill is bounded and the order inside this category is its own:
see *Adopting this category on an existing project* in Category 0 — do not reconstruct
documentation from the code to clear this gate, which produces a corpus that cannot contradict the
implementation and therefore cannot sign off on changing it.

**Phase 2 — Build the net.** Category 4 on the paths the planned work will touch, Category 7's
analyser and formatter, and Category 10 running both on every change. All three, not the first two:
a suite nobody runs is not a net, and a formatter that is a local habit becomes a diff full of
whitespace the moment two people touch the same file. Where the planned change alters runtime
behaviour rather than structure — a framework upgrade, a swapped library, a changed query — the
Category 9 subcriteria that would reveal the regression in production (9.1, 9.2, 9.3) belong in
this phase too, because some breakage is not observable from a test suite at all.

**Phase 3 — Change the code.** Categories 1, 2, 3 and 5: decomposition, naming, layering, the
domain model, the frontend's structure. This is the work most audits make look most urgent, and it
is the work with the least standing to go first.

**Phase 4 — Change the platform.** Category 6: a major framework version, a replaced library, a
build system swapped out. Last, because it invalidates more of the net than any other change and is
the hardest to reverse once a sprint of application code has been written against it. A platform
change made on top of a project that has already reached Phase 3 is a contained migration; the same
change made first is a rewrite that nobody called a rewrite.

### How far to take a category before starting the next

The phases say which category gets attention first. They do not say when it has had enough, and a
programme that follows them perfectly can still fail in a shape most engineering organisations will
recognise: the team that owns the pipeline takes Category 10 from 1 to 9 in a quarter — that being
the work it already knows how to do — and Category 1 is still at 2. The average moved. Nothing a
user touches got better and no future refactoring got safer, because what made it unsafe was never
the pipeline.

**The rule: a project raises its floor, not its best number.** Every scored category reaches the
target of the band the project is on before any category is taken past it. The bands are the
maturity minimums in *Quick reference* below, read as rungs rather than as labels — **4, 6, 7, 8** —
and a project climbs them one at a time: at 4 across the board it targets 6 everywhere before
anything targets 7. It stops at the rung its own maturity requires. Past that the ladder has nothing
further to say and effort goes wherever the product needs it.

So the programme is steered by two numbers, and they answer different questions:

| | The question it answers | Where it comes from |
|---|---|---|
| **Band target** | How far every category has to get | The next rung above the project's lowest score, capped at the maturity minimum |
| **Phase** | Which category gets there first | *The phases*, above |

They compose in one direction only: **the band decides which categories are in scope, the phase
orders the ones that are.** A phase is therefore complete *for a band* when its categories reach
that band's target — not when they reach 10 — and every phase reopens at the next rung. A project
that finished Phase 2 at band 6 is in Phase 2 again the moment its target becomes 7 and Category 4
is sitting at 6.

Categories marked N/A are excluded from the floor and the spread, as they already are from the
average.

### What the band rule governs, and what it does not

It does not forbid a category being above the band. Scores are not a budget, and nothing is ever
lowered to level a profile: a project whose Category 8 is at 9/10 because it was built by someone
who knew what they were doing keeps that 9 while the floor climbs toward it.

What the rule governs is **where the next unit of effort goes**, and the test is a single question:
*does this change raise the lowest score?* If it does not, it needs one of the exemptions to be
worth starting. A sprint spent on a category already at the band target while another sits beneath
it is the move this rule exists to prevent — and it is an attractive move precisely because that
category is the one the team is already good at.

The exemptions are the four in *What the order does not gate* below, unchanged and for the same
reasons: Phase 0, new code, scoring, and a fix that is one line of configuration. The last one
matters most here. Enabling a setting that happens to take Category 10 from 6 to 8 costs an
afternoon; declining it to keep the profile flat is the rule worn as a costume. Free overshoot is
free — it is *paid* overshoot that waits.

One category resists the ladder on principle. A framework two majors behind is upgraded or it is
not; there is no way to spend 60% of that work and bank 60% of the score. Where a gap has no small
version, the band rule and the phase order agree rather than conflict: Category 6 is Phase 4, it is
last regardless, and a project short of its band target elsewhere was never going to start it.

### Why the floor and the spread, and not the average

Because the average rewards the behaviour the band rule exists to stop, and rewards it identically.
Across eleven categories, taking one of them from 6 to 10 and taking four of them from 5 to 6 are
the same **+0.36**, and only the second is progress. Anything that can be bought four points at a
time in the category a team already likes will be, and the trend line will applaud.

So report the average — it is the cheapest summary of total work done — and **steer by the floor and
the spread**: the lowest-scoring category, and the distance between the lowest and the highest. A
project whose spread is widening is getting less maintainable while its average improves, and the
floor is the one number that cannot move without someone doing the work nobody volunteers for.

Both are read off the scores already in `history.md` rather than stored beside them. A number
derived from the same row twice is a number that will eventually disagree with itself, and the `C0`
column is the standing reminder of what it costs to repair a history file after the fact.

### Which phase a project is in

The phase is read off the scores, not negotiated: **a project is in the earliest phase that still
has a category below its current band target.** A project assessed as Established with Category 4
at 5/10 and nothing lower is at band target 6, and it is in Phase 2 regardless of how bad Category 2
looks; it leaves Phase 2 when 4, 7 and 10 reach 6 — which is a date the score history can be asked
for rather than a judgement anybody has to defend in a meeting. It re-enters Phase 2 at band 7, and
the second pass is shorter than the first every time.

Band and phase together are the headline for the programme. They are not the gate for an individual
change, and the two are allowed to disagree: the gate in the table below is scoped to the module
being changed, so a team whose project sits in Phase 2 may still refactor the one module it has just
covered. The band and the phase say where the work as a whole has got to; the gate says whether this
change may start today. Report the band and the phase, apply the gate.

### What the gate actually requires

The gate is scoped to the change, never to the project. "We cannot refactor until Category 4 is
7/10" is a misreading that makes the order an excuse for doing nothing, and a project that reads it
that way has swapped one failure for a slower one.

| The work planned | What must be true first | How to check it |
|---|---|---|
| Refactoring a module | Tests cover that module's behaviour at some seam, and CI runs them | Run the suite; make a deliberate breaking edit in the module; confirm something red appears without being asked |
| Renaming to the declared domain language (2.8–2.10) | The term's meaning is recorded, and the rename is observable to the suite | A document or glossary states what the term means; the suite exercises every mechanism that resolves the name as a string |
| Introducing or replacing a framework (6.x) | Phases 1–3 reached the **maturity** minimum — not merely the current band — plus the Phase 2 signals for runtime behaviour | The audit's previous entry in `history.md` shows Categories 0, 4, 7 and 10 at the maturity target. This is the one piece of work the band ladder does not let a project take early: it is too expensive to do twice and too hard to reverse once |
| Splitting a layer or extracting a bounded context (1.x, 3.x) | The use cases crossing that boundary are covered end to end | Name the tests that would fail if the boundary were drawn wrongly |
| Raising the analyser level (7.1) | Nothing — it is Phase 2 work | Raising it is Phase 2; fixing what it then reports is Phase 3, site by site. A baseline file is what keeps the two separable |

Three of those rows ask for coverage of *the thing being changed*. None asks for a project-wide
number. A team that writes characterisation tests for one module on Monday has cleared the gate for
that module on Tuesday, and has cleared nothing for the module next door — which is correct, and is
why the order does not stall a project that moves module by module.

### When the code cannot be tested until it has been refactored

This is the standing objection to the order, and on a bad enough codebase it is a real one: the
class has a constructor that opens a database connection, so there is no way to instantiate it in a
test, so there is no net, so by this section's rule it may never be touched. Read that way the order
is a sentence rather than a plan, and a team that accepts it has found a principled reason to change
nothing.

The way out is that **a test does not have to be a good test to be a net.** What Phase 2 requires is
the ability to detect a regression, not a well-factored suite — those are different goals and only
the first one gates. So the net is built at the coarsest seam the code already has, which is almost
never the class:

- The HTTP endpoint, driven with a recorded request and asserted on the whole response body
- The CLI command, run end to end, asserted on exit code and output
- The database state before and after a job, compared row by row
- A golden file: capture today's output for a hundred real inputs, assert the refactoring reproduces
  it byte for byte

None of these require the code to be well designed. They require it to be *callable*, which it is —
something calls it in production. They are allowed to be slow, to need a database, and to assert on
things a unit test never would, because their entire job is to be deleted later, once the structure
they protected has emerged and real tests can be written against it.

What they must not be is written *after* the refactoring. A characterisation test (Feathers) records what the
system does now, including the behaviour nobody intended — that is the point of it, and it is
worthless if captured from the code you are about to claim is equivalent.

### The mass rename is the most ordered change of all

Translating identifiers into the project's declared language looks like the safest item on any
remediation list: mechanical, reviewable, no logic touched. It is close to the opposite, and the
reason it is worth stating explicitly is that its danger is invisible in exactly the way its cost
is.

The diff is large, uniform, and resistant to review — a reader checks the first forty renames
carefully and scrolls the remaining nine hundred. The blast radius is the whole tree. And the
compiler, which is what makes the change feel safe, does not see most of the ways a name is
resolved: string-keyed container lookups, serialized payloads already sitting in a queue or a
column, ORM mappings inferred from a property name, translation catalog keys, reflection, route
names in a configuration file, a column name a migration will not rename with the property. Each of
those fails at runtime, in production, on the path the rename did not touch.

So the rename is Phase 3 work with a Phase 1 prerequisite that nothing else in that phase has: you
cannot rename a domain term correctly without knowing what it means, and the term that most needs
translating is usually the one whose meaning is least recoverable from the code — otherwise someone
would have translated it already. `Fattura` becomes `Invoice` and both are wrong if the entity is
actually a credit note.

**How it is cut: one term per step, never the glossary in one change.** The step is mechanical and
carries nothing else — no behaviour change rides along with a rename, because the moment one does,
the property that made the diff reviewable at all, that every hunk is the same edit, is gone, and
with it the only cheap verification the change had. The resolution sites the compiler cannot see
become the step's checklist rather than its surprise: the container keys, the payloads already
serialized, the ORM mapping, the catalog keys, the route names, the column a migration has to rename
alongside the property. Per term that list is finite and can be walked to the end. Across forty terms
at once it is the blast radius described above.

This is also what makes the rename *ordered* rather than merely large: it does one thing many times.
A change that does many things once is not a rename, however many identifiers it happens to touch.

### What the order does not gate

- **New code.** Written to the full standard from the first line, in every phase. The order governs
  changes to code that already exists and already works; it has nothing to say about code being
  written now, and reading it as "we cannot write clean code until we have tests" inverts it.
  Where the new code has to live inside a class with no seam, it does not wait for one. It is
  written as a new, tested function or class, called from a single line in the legacy code —
  Feathers's *sprout* — or the legacy method is renamed and wrapped by a new one that adds the
  behaviour around it — *wrap*. The legacy code gains one untested line instead of a feature's worth.
- **Scores.** Every category is scored at its real value at every phase. The order decides what to
  *do* about a 3/10, never whether to report one — an audit that hid the Category 2 score until
  Category 4 was fixed would be withholding the reason the work matters.
- **Phase 0.** Named above, and the only exception.
- **A gap whose fix is a line of configuration.** Enabling branch protection, adding a `.editorconfig`,
  pinning a dependency: no net is required to change something that cannot regress silently. Where
  the fix is genuinely that small and genuinely that contained, take it out of order and say so.

### How remediation work is delivered

The order decides which gap is closed and when. It says nothing about the shape of the change that
closes it, and that is where a correctly ordered programme still fails — invisibly to the people
inside it, because every decision they can name was the right one. The team picks the right gap, in
the right phase, with the net in place, and ships it as one change across ninety files. Nothing in
that quarter can be reverted without reverting all of it, and the first regression costs the whole
sequence rather than the step that caused it.

So: **remediation work is scored by 0.8 like any other work, and it is the work that needs 0.8
most.** It touches code that already runs, where the only evidence of a mistake is a regression that
may not arrive for a week. Three things follow.

**A phase is a direction, not a change.** *Build the net* is a phase. It is not a commit, a branch,
or a pull request. The unit of delivery inside a phase is the step of 0.8 — one change, the test
that proves it, a state the system can be released in — and a phase ends when its categories reach
the band target, which is a score and never a merge.

**The audit's own recommendation names a first step.** A gap written at the altitude of its end
state — *split the controller*, *rename the domain layer*, *extract the billing context* — is the
artefact 0.8's bad list ends on, and an audit report is the likeliest document in a project to be
handed to an agent verbatim. Where closing a gap takes more than one change, what the report owes
its reader is the smallest change that settles the riskiest part of it, not the destination restated
with an effort estimate beside it.

**Size is not the test; uniformity is.** One large step is legitimate, and it is not a licence: a
mechanical change that does one thing many times — see *The mass rename is the most ordered change
of all*, which says how to cut it. Many things done once, in one change, is the cutover under
another name, whatever the audit called it and however well ordered the phase it sits in.

### Recording the order in the audit

Step 3's ranking runs inside a band and inside a phase, not across either. The report opens the
programme with one line carrying both, plus the two numbers the band rule is steered by:

> **Band target 6** (Established, minimum 7) · **Phase 2** · floor Cat 9 at 5.0 · spread 4.0 (Cat 1
> at 9.0). Below target: Cat 9, Cat 4. Category 10 is at 8.0 and its backlog is not this quarter's
> work unless an item is the afternoon kind.

When the highest-impact gap in the project sits in a later phase than the project has reached, the
report names it *and* names the prerequisite that holds it, in that order — the reader needs to know
both that the gap is the biggest one and why it is not this quarter's work:

> **Cat 2 — 3/10. Highest-impact gap in the project; blocked.** The domain layer is in mixed
> Italian and English (`src/Domain/Fattura.php:14`). Renaming is Phase 3 work and this project is in
> Phase 2: `src/Domain` has no test covering it, so no rename is observable. **Prerequisite:**
> characterisation tests over the invoicing use cases (Cat 4, ~2 weeks). The rename is a week of
> work behind it.

Two audits apart, that paragraph is also how a reader tells progress from drift: the prerequisite
either moved or it did not. The headline above it answers the same question for the programme — a
band target that has not changed in three audits is the finding, whatever the average did.

---

## Quick reference — score targets by project maturity

| Maturity | Description | Min target per category |
|---|---|---|
| Prototype | Proof of concept, not production | 4/10 |
| Early production | Live, <6 months, small team | 6/10 |
| Established | Live, growing team, SLAs | 7/10 |
| Enterprise | Regulated, multiple teams, high availability | 8/10 |

A project that consistently scores 7/10 across all measured categories is well-engineered, maintainable, and defensible in a professional context.

The four minimums are also the rungs a project climbs on its way to its own: see *How far to take a
category before starting the next* in *Remediation order* above. The column is a floor for every
category, never an average across them — a project with one category at 4 has not reached 6, whatever
the other ten say.

---

---

## Appendix — Language equivalents quick reference

The criteria in this document are language-agnostic. This table maps each quality concern to its canonical tool or pattern across the languages most commonly encountered in web, backend, and mobile projects.

### Static analysis

| Concern | PHP | TypeScript | Python | Go | Kotlin/Android | Swift/iOS |
|---|---|---|---|---|---|---|
| Type checking | PHPStan / Psalm | `tsc --noEmit` (`strict: true`) | mypy / pyright | `go vet` + staticcheck | Kotlin compiler (null-safe by default) | Swift compiler (strict optional handling) |
| Code smells / complexity | phpmd, phpcs | ESLint | ruff, pylint | golangci-lint | detekt | SwiftLint |
| Style enforcement | php-cs-fixer | ESLint + Prettier | black + ruff | gofmt (non-negotiable) | ktlint | SwiftFormat |
| Architectural constraints | deptrac | ESLint `import/no-restricted-paths` | pydeps (analysis) | manual package structure | ArchUnit (JVM) | SwiftLint custom rules |

### Testing

| Concern | PHP | TypeScript/JS | Python | Go | Kotlin/Android | Swift/iOS |
|---|---|---|---|---|---|---|
| Test runner | PHPUnit | Jest / Vitest | pytest | `go test` | JUnit 5 / Kotest | XCTest |
| Mocking | PHPUnit `createMock()` | `jest.fn()` / `vi.fn()` | `unittest.mock` / `pytest-mock` | Interface substitution (no mock library needed in idiomatic Go) | MockK / Mockito-Kotlin | Protocol fakes (idiomatic) / Cuckoo |
| In-memory fakes | Custom class implementing interface | Same | Same | Same | Same | Same |
| Integration test group | `#[Group('integration')]` | `describe.skip` / custom config | `@pytest.mark.integration` | `//go:build integration` | `@Tag("integration")` | `XCTSkipIf` / custom scheme |

### Translation of user-facing text (2.9, 2.10)

| Language / platform | Mechanism | Completeness check |
|---|---|---|
| PHP (Symfony) | `symfony/translation`, `translations/messages.<locale>.xlf` | `bin/console lint:xliff` + `debug:translation --only-missing <locale>` |
| PHP (Laravel) | `lang/<locale>/*.php`, `__()` / `@lang` | `php artisan lang:missing` (community package) or a key-set diff in CI |
| TypeScript / JS | `i18next` / `react-intl`, JSON catalogs per locale | `i18next-parser` extraction, then diff the generated catalogs |
| Python | `gettext` + Babel, `locale/<locale>/LC_MESSAGES/*.po` | `pybabel extract` + `pybabel update`; `msgfmt --statistics` reports untranslated |
| Go | `go-i18n` or `golang.org/x/text/message`, `active.<locale>.toml` | `goi18n merge` writes `translate.*.toml` — a non-empty one is the gap |
| Kotlin / Android | `res/values/strings.xml`, `res/values-<locale>/strings.xml` | Lint `MissingTranslation` (make it an error, not a warning) |
| Swift / iOS | String Catalogs (`.xcstrings`) or `Localizable.strings` | Xcode reports per-locale completion; `xcodebuild -exportLocalizations` for the diff |

The completeness column is what 2.10 is scored from: a mechanism with no way to list the missing keys cannot be shown to be complete, and the project is credited for coverage it has not demonstrated.

### Dependency security

| Language | Tool |
|---|---|
| PHP | `composer audit` |
| JavaScript / TypeScript | `npm audit` / `yarn audit` |
| Python | `pip-audit` / `safety` |
| Go | `govulncheck` |
| Kotlin / Java | `./gradlew dependencyCheckAnalyze` (OWASP) |
| Swift / iOS | `swift package audit` (SPM) / Dependabot on GitHub |
| All | Dependabot / Renovate for automated PRs on version bumps |

### Output encoding (HTML context)

| Language | Function / approach |
|---|---|
| PHP | `htmlspecialchars($v, ENT_QUOTES, 'UTF-8')` |
| Python | `html.escape(v)` |
| Go | `html.EscapeString(v)` or `html/template` (auto-escapes) |
| TypeScript (React) | JSX auto-escapes; avoid `dangerouslySetInnerHTML` |
| Kotlin / Java | `HtmlUtils.htmlEscape(v)` (Spring) or template engine |
| Swift | Use `AttributedString` or a template engine; never string-interpolate into HTML |

### Password hashing

| Language | Recommended |
|---|---|
| PHP | `password_hash($p, PASSWORD_ARGON2ID)` |
| Python | `argon2-cffi` or `bcrypt` |
| Go | `golang.org/x/crypto/bcrypt` |
| Kotlin / Java | Spring Security `BCryptPasswordEncoder` or `argon2` via Bouncy Castle |
| Swift (server-side, e.g. Vapor) | `Bcrypt` package |
| All | Never MD5, SHA1, SHA256 without a purpose-built password hashing wrapper |

### Mobile-specific quality notes

These concerns apply to native mobile projects (iOS/Swift, Android/Kotlin, Flutter/Dart) where Categories 5 and parts of 9–10 do not directly apply.

| Concern | iOS / Swift | Android / Kotlin | Flutter / Dart |
|---|---|---|---|
| Observability (replaces 9.3) | Crashlytics / Sentry iOS SDK | Crashlytics / Sentry Android SDK | Sentry Flutter SDK |
| CI/CD (replaces 10.3–10.8) | Xcode Cloud / Fastlane → TestFlight → App Store | GitHub Actions + Gradle → Firebase App Distribution → Play Store | Codemagic / Fastlane → both stores |
| Dependency security | `swift package audit`, Dependabot | OWASP Dependency-Check Gradle plugin | `dart pub audit` |
| Architecture fitness | SwiftLint custom rules for layer imports | ArchUnit or detekt rules | `dart analyze` + custom lints |
| Input validation (deep links, push payloads) | Validate every `URL`, `UNNotificationContent`, and `Decodable` at the boundary | Validate every `Intent`, `Bundle`, and `Parcelable` at the boundary | Validate every route parameter and platform channel message |
| Translatability (2.9, 2.10 — apply in full) | String Catalogs; a literal in SwiftUI `Text()` is already localizable, one in a formatted string is not | `strings.xml` only; a literal in a layout or Compose call is the finding | `flutter_localizations` + ARB files; `flutter gen-l10n` |

---

## Appendix — Sources

Every criterion in this document and every principle in `CODING_STANDARDS.md` stands on its own
evidence — a file, a line, a command's output. Nothing here is scored because a book says so. This
appendix exists for two other reasons: to give credit where an idea was taken, and to show whoever
applies the framework where the idea came from, so the reasoning behind a criterion can be read at
its full length rather than in the few lines the criterion has room for.

It is the only place the framework's sources are listed. A criterion may name its source inline; the
full reference, and every place that uses it, live here.

**Where the framework departs from a source, the row says so.** A departure is a decision, and a
source cited without it would be read as an endorsement of the part the framework set aside.

**For a developer early in their career:** the last column is a reading list. None of these works is
needed to apply the framework. Each of them explains, at length, why it asks what it asks.

### Code and design

| Source | Where the framework uses it | Why read it |
|---|---|---|
| Robert C. Martin, *Clean Code* (2008) | Category 2; principles 1 and 3. **Departs:** function length as a target in itself — 2.2 judges an extraction by what it hides, following Ousterhout | The vocabulary of readable code — naming, function focus, error handling — that most review comments are written in |
| Robert C. Martin, *Agile Software Development: Principles, Patterns, and Practices* (2002) | 1.2–1.4 and 1.7 — interface segregation; principles 3 and 4 | Where SOLID was assembled as a set, with the reasoning behind each letter |
| John Ousterhout, *A Philosophy of Software Design* (2018; 2nd edition 2021) | 1.8 — deep and shallow modules, information leakage, pass-through methods; 2.2 — an extraction is judged by what it hides; 2.5 and principle 1 — interface comments | Complexity as the thing design exists to reduce, with a precise vocabulary for where it hides — the counterweight to *Clean Code*, from another school |
| David Parnas, *On the Criteria To Be Used in Decomposing Systems into Modules* (1972) | 1.8; principle 4 | The paper that introduced information hiding: decompose by the decisions likely to change, not by the steps of processing. Twelve pages, still current |
| Barbara Liskov, *Data Abstraction and Hierarchy* (1987); Barbara Liskov, Jeannette Wing, *A Behavioral Notion of Subtyping* (1994) | 1.6; principle 4 | Substitutability defined as behaviour rather than signature — the L in SOLID, from its source |
| Bertrand Meyer, *Object-Oriented Software Construction* (1988) | 1.3 — the open/closed principle, in the form Martin later restated through abstraction | The original statement of the principle, and of design by contract |
| Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides, *Design Patterns* (1994) | 1.5 — Factory Method, Observer, Decorator; principle 2's distrust of deep hierarchies, *favour composition over inheritance* | The catalogue every later pattern book assumes. Read the introduction before the patterns |
| Martin Fowler, *Patterns of Enterprise Application Architecture* (2002) | 1.5 — Repository, Data Mapper, Value Object; 3.5 | The patterns of the layer between a domain and its storage, which is where most business code lives |
| Joshua Kerievsky, *Refactoring to Patterns* (2004) | Principle 2; 1.5 — a pattern earns its place | How to arrive at a pattern by refactoring towards it when the code asks, instead of designing it in up front |
| Andrew Hunt, David Thomas, *The Pragmatic Programmer* (1999; 20th anniversary edition 2019) | 2.3 — the DRY principle, and its definition as *knowledge* rather than text | A career's worth of working habits in short chapters — the first book on this list to read |
| Sandi Metz, *The Wrong Abstraction* (2016) | Principle 2; 2.3 — similar code is not always the same knowledge | Why duplication is cheaper than the wrong abstraction, and how to back out of one |
| Kent Beck, *Extreme Programming Explained* (1999; 2nd edition 2004) | Principle 12 — the four rules of simple design, and *you aren't gonna need it* | The origin of practices most teams now take for granted: small releases, continuous integration, refactoring as daily work |

### Refactoring and legacy code

| Source | Where the framework uses it | Why read it |
|---|---|---|
| Martin Fowler, with Kent Beck, *Refactoring* (2nd edition 2018) | 2.6 — the smell catalogue and its fixes, by that edition's names; 2.11 and principle 11 — refactoring as small, named, behaviour-preserving steps. **Departs:** the *Rule of Three* the book reports from Don Roberts — refactor at the third duplication — is not adopted; principle 2 decides by the complexity of the problem, not by counting occurrences | Refactoring as a sequence of small, named, behaviour-preserving steps, each with its own mechanics |
| Kent Beck, *Tidy First?* (2023) | Principle 19 — a change to structure and a change to behaviour are two commits; principle 24 and 2.11 — make the change easy, then make the easy change | When to tidy before a change, after it, later or never — argued as economics rather than as a rule |
| Michael Feathers, *Working Effectively with Legacy Code* (2004) | 2.6 — the seam; principle 11's first pass; *Remediation order* — characterisation tests, code that cannot be tested until it has been refactored, and the sprout and wrap of *What the order does not gate* | Dozens of concrete techniques for bringing untested code under test, which describes most code anyone inherits |
| Martin Fowler, *Strangler Fig Application* (2004) | 10.9 | Replacing a system while it keeps running, one path at a time |
| Danilo Sato, *Parallel Change* (2014) | Principles 11 and 27; 10.4 — expand, migrate, contract | The three-phase shape of every backward-compatible change, and why the third phase is the one that goes missing |

### Domain modelling

| Source | Where the framework uses it | Why read it |
|---|---|---|
| Eric Evans, *Domain-Driven Design* (2003) | Category 3 — ubiquitous language, entities, value objects, aggregates, repositories, bounded contexts, and the integration patterns of 3.8; 2.8's language test; 3.9 and principle 7 — distillation and the core domain | The book the category is named after. Its strategic half — contexts and their relationships — matters more than the tactical half and is read less |
| Vaughn Vernon, *Implementing Domain-Driven Design* (2013) | 3.7 — domain events; 3.8 — the integration patterns, as elaborated | Evans's ideas carried into running code, with domain events treated as part of the model |
| Fred Brooks, *No Silver Bullet* (1986) | Principle 7; 3.8 — essential against accidental complexity. **Departs:** *plan to throw one away*, from *The Mythical Man-Month* (1975), is not adopted — principle 12 makes each step a refactoring, never a rewrite, and Brooks himself called that advice too simplistic in the 1995 edition, in favour of building incrementally | The clearest argument for why no tool removes the hard part of software, and which part that is |
| Melvin Conway, *How Do Committees Invent?* (1968) | 3.8 — boundaries between contexts follow boundaries between teams; Category 10's reading of knowledge concentration by area | Why a system's structure mirrors the organisation that builds it, and what follows from changing either |

### Testing

| Source | Where the framework uses it | Why read it |
|---|---|---|
| Vladimir Khorikov, *Unit Testing Principles, Practices, and Patterns* (2020) | 4.2 — output-, state- and communication-based styles | What makes a test valuable rather than merely present — resistance to refactoring above all |
| Steve Freeman, Nat Pryce, *Growing Object-Oriented Software, Guided by Tests* (2009) | 4.2 — the TDD signal; 4.6 — mock only the types you own; principle 17 | Tests as a design tool: a test that is hard to write is the production code telling you something |
| Gerard Meszaros, *xUnit Test Patterns* (2007) | 4.6 — the five kinds of test double | The reference vocabulary for test doubles and test smells |
| Kent Beck, *Test-Driven Development: By Example* (2002) | Principle 10. **Departs:** the framework requires the expected behaviour to be agreed before the code — a test being its most precise form — not test-first as a mandatory cycle | The red, green, refactor rhythm, on worked examples small enough to follow by hand |
| Titus Winters, Tom Manshreck, Hyrum Wright, *Software Engineering at Google* (2020) | Principle 26 and 4.7 — the *Beyoncé rule*, if you liked it you should have put a test on it; 10.12 — small changes as the unit of review | Practices at the scale where every shortcut is paid for a thousand times — including Hyrum's Law, on why every observable behaviour ends up a contract |

### Architecture and evolution

| Source | Where the framework uses it | Why read it |
|---|---|---|
| Robert C. Martin, *Clean Architecture* (2017) | 3.1 — the dependency rule | Why dependencies point inwards, towards policy and away from detail |
| Alistair Cockburn, *Hexagonal Architecture* (2005), and the walking skeleton of *Crystal Clear* (2004) | 3.1 and 4.6 — the domain reached through ports, infrastructure behind adapters; principle 24 — a thin slice through every layer, never one layer at a time | The shortest route to a core that can be tested without its infrastructure |
| Neal Ford, Rebecca Parsons, Patrick Kua, *Building Evolutionary Architectures* (2017) | 10.9 — fitness functions; 7.6 | Architecture as a property checked continuously by automation, rather than decided once |
| Michael Nygard, *Documenting Architecture Decisions* (2011) | Principle 13 and 0.7 — the ADR, extended here with *Alternatives considered* | The one-page format that made decision records practical |
| Martin Kleppmann, *Designing Data-Intensive Applications* (2017) | Principle 21, 7.9 and 9.8 — what data access costs; 10.4 — evolving schemas and encodings compatibly | How databases, replication and streams actually behave, at the depth where performance and correctness are decided |

### Delivery and operations

| Source | Where the framework uses it | Why read it |
|---|---|---|
| Jez Humble, David Farley, *Continuous Delivery* (2010) | 10.3, 10.5, 10.6 and 10.8 — the deployment pipeline, deployment strategies, rollback, smoke tests | Why every commit should be releasable, and the pipeline that makes it so |
| Adam Wiggins, *The Twelve-Factor App* (2011) | 10.2 | Twelve short rules for a service that behaves the same in every environment |
| Michael Nygard, *Release It!* (2nd edition 2018) | 9.5 and principle 8 — cascading failures, graceful degradation, timeouts, circuit breakers and bulkheads; 9.6 and 9.7 — the *steady state* pattern, in which everything that accumulates needs something that removes it | What production does to software that has only ever run in tests |
| Charity Majors, Liz Fong-Jones, George Miranda, *Observability Engineering* (2022) | 9.1 — context as structured fields; 9.9 — *what did production do in the last hour?* **Departs:** the book prefers wide, high-cardinality events to levelled logs; 9.1 keeps the levels | Debugging systems that cannot be reproduced locally, by asking new questions of the data rather than reading prepared dashboards |
| Nicole Forsgren, Jez Humble, Gene Kim, *Accelerate* (2018) | 10.17 | The research behind the four delivery measures, and the finding that speed and stability improve together |
| Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy (eds.), *Site Reliability Engineering* (2016) | 9.4 — the four golden signals, service level objectives, error budgets | How to decide how reliable a service needs to be, and how to know whether it is |
| Charles Goodhart (1975) | 10.17 — a measure that becomes a target | Why a number people are rewarded on stops describing what it measured |
| Jason Cohen, *Best Kept Secrets of Peer Code Review* (2006) | 10.12 — review size | The data behind the advice that a review should be small enough to read in one sitting |

### Planning

| Source | Where the framework uses it | Why read it |
|---|---|---|
| John Shook, *Managing to Learn* (2008) | Principle 24 and 0.8 — the A3: problem, current state, target, countermeasure, check | Problem solving on one page, as Toyota teaches it |

### Security

| Source | Where the framework uses it | Why read it |
|---|---|---|
| OWASP Top 10 | 8.7 — the explanation named beside an ASVS identifier, not the ruler | The current ranking of the most common web application risks |
| OWASP Application Security Verification Standard (ASVS), 5.0.0 (2025) | 8.7 — the declared level, version and requirement list, shipped in `standards/asvs/` | Security requirements written as things that can be checked, level by level: the Top 10 names what goes wrong, the ASVS what to verify |

---

*This document is a living standard. Update it when you discover recurring patterns, anti-patterns, or new tooling that changes the cost/benefit of a quality practice.*
