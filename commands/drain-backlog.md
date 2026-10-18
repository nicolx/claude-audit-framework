---
description: Use when asked to implement the pending specs, work through the backlog, build what is in the inbox, or turn the PRDs and ARDs that have been dropped into the repository into code. Ingests new documents from the declared inbox, then takes every `todo` spec in order — readiness check, plan by `architect`, build by `implementer`, review by `pr-critic` — and delivers each within the project's Delivery convention. --dry-run reports the queue and its readiness without writing anything.
allowed-tools: [Read, Grep, Glob, Bash, Write, Edit, Task, Agent]
---

Implement the specified work that is waiting in this project, one spec at a time, to the standards
every other change here is held to.

## Arguments

```text
/drain-backlog [--dry-run] [--ingest-only] [<spec id> ...]
```

`--dry-run` runs Phases 0–2 without writing: what would be ingested, the queue in order, and the
readiness verdict for each spec. Nothing is moved, marked or committed.

`--ingest-only` stops after Phase 1.

Spec ids limit the run to those specs, in queue order, with the dependencies they name.

**Invoked from a conversation rather than by name** — *implement the backlog*, *build the pending
specs*, *process the PRDs in the inbox* — run it as written and say so in one line. A request to
build **one** named spec is ordinary work for the session, under principle 23, unless the developer
asks for it to go through the drain.

## What this command is, and is not

It builds work that **was specified elsewhere**. It does not write a spec, complete one, or repair
one: a document that cannot be built as written is reported, never improved into something that can.
The value of running unattended rests entirely on the spec having been reviewed by a person before it
arrived, and a spec the drain finished itself has had no such review.

It is one route among two. Work asked for in a conversation goes the ordinary way and needs no
document — 0.3 already says small changes carry none.

**Execution model:** Phases 0–2 in this conversation. Phase 3 dispatches three agents per spec,
sequentially and never in parallel — `architect`, `implementer`, `pr-critic` — so each spec is built
in a clean context and this conversation holds only their results. Specs are drained one at a time:
the next one starts on the tree the last one left.

---

## Phase 0 — Read the declarations

```bash
git status --porcelain
test -f .claude/PROJECT_AUDIT_FRAMEWORK.md && sed -n '/^## Backlog drain/,/^## /p' .claude/PROJECT_AUDIT_FRAMEWORK.md
test -f .claude/PROJECT_AUDIT_FRAMEWORK.md && sed -n '/^## Delivery convention/,/^## /p' .claude/PROJECT_AUDIT_FRAMEWORK.md
```

**A dirty tree stops the run.** It is somebody's work in progress, and a drain committed on top of it
would carry it into a spec's history.

**The Backlog drain block** gives the inbox, the spec home, the naming rule, whether plans are
approved by the declaration or by a person, what always comes back to a person, and the per-run limit.

**If it is absent**, the drain still runs, with no inbox — Phase 1 is skipped — and every plan
approved by a person. It reads the spec area the documentation home's index (0.2) names; if the index
names none, stop:

> This project declares no **Backlog drain** block and its documentation home names no spec area, so
> there is nowhere to read the backlog from. The block is in
> `.claude/framework/templates/PROJECT_AUDIT_FRAMEWORK.md`.

Never create the inbox or the spec home. The layout is the team's decision, and an empty tree
scaffolded by an agent is a worse signal than none.

**If the Delivery convention is absent**, the drain commits nothing: ingestion and `blocked:` fields
are written and left uncommitted, every spec stops at an approved plan, and the report says so. A drain is a long run of commits, and an absent convention
is never read as permission for one.

---

## Phase 1 — Ingest the inbox

The inbox is a point of arrival, not a status. A document in it is not yet in the backlog; ingesting
it is what puts it there, with its status in the document where 0.4 requires it — never in the folder
it sits in.

For each file in the inbox:

- **Not Markdown or plain text** — leave it and report it. A converted document loses its tables and
  its emphasis without saying so, and nobody reviewed the conversion
- **Frontmatter with a `status` outside 0.4's closed vocabulary** — leave it and report it
- **Otherwise**, move it to the spec home under the declared naming rule, with `git mv` so its history
  follows, and give it the frontmatter below. Existing fields are kept; missing ones are added. **The
  body is not touched** — not a heading, not a typo

```yaml
---
id: 042                       # next free number in the spec home
title: Export invoices as CSV # the document's own first heading
kind: prd                     # prd, or ard for an architecture requirements document
status: todo
received: 2026-10-18
source: docs/inbox/invoice-export.md
depends_on: [038]             # only when the document itself names the dependency
---
```

All ingested documents land in one commit — `docs(specs): ingest 042, 043` — within the Delivery
convention. An ARD is built like a PRD; one that records a decision rather than a requirement is an
ADR, and is reported rather than ingested.

---

## Phase 2 — Build the queue, and check readiness

```bash
grep -rlE '^status: (todo|in-progress)$' <spec home>
```

Order by `id`, then move each spec after the specs it `depends_on`. A dependency cycle is reported and
every spec in it skipped. Specs carrying a `blocked:` field are skipped: a person removes the field
once the cause is fixed, and that is how a spec returns to the queue. Apply the per-run limit after
ordering.

`in-progress` specs come first: work already half in the system is worth finishing before new work
starts, and only their unmarked requirements are built.

**Readiness**, for each spec in the queue, in this order:

1. **Every acceptance criterion is observable**, by the test in 0.3: a test could be written from it
   without asking the author a question. Name each criterion that fails it
2. **Nothing contradicts it** — no accepted ADR, no `implemented` spec, and no part of the code it
   does not say it changes. Principle 23: the contradiction is the finding, and it has two fixes the
   developer picks between
3. **Its dependencies are implemented**, or ahead of it in this run and not blocked

A spec that fails readiness is **blocked**: write the field and move on.

```yaml
blocked: "2026-10-18 — criterion 3 is not observable: 'the export is fast'"
```

The field goes in its own commit, `docs(specs): 042 blocked`, so the history says when and why. Its
dependents are skipped for this run without being marked — the cause is not theirs.

`--dry-run` stops here and prints the queue with each verdict.

---

## Phase 3 — Each spec, in order

### 3.1 Plan

Dispatch `architect` with the spec's path. It returns the five questions answered, the routes, the
step list, and an ADR draft when the decision is expensive to reverse.

### 3.2 Approval

The plan is approved **by the declaration** only when all of these hold:

- the block declares `Plan approval: unattended`
- `architect` drafted no ADR — a decision expensive to reverse is outside any standing agreement
- nothing in the plan matches the block's **Always asks** list

Then print the plan in one block and carry on. Otherwise show it and wait: approval, a change to the
plan, or *skip* — which marks the spec `blocked` with the developer's reason. Principle 24 states what
a standing agreement may and may not cover.

### 3.3 Build

On the ref the Delivery convention names for this spec — the mainline, or a branch cut for it —
dispatch `implementer` with the spec, the approved plan, the ADR draft if any, and the ref. It commits
step by step and never pushes.

If it stopped, the spec is already marked per requirement by its last commit. Add the `blocked:`
field with the condition it reported, commit, and go to 3.5 with what was built.

### 3.4 Review

Dispatch `pr-critic` on the spec's commits — the range from before 3.3 to `HEAD` — and, when those
commits touch the attack surface as the routing table in `INSTRUCTIONS.md` describes it,
`security-reviewer` on the same range. Their findings are handled alike.

- **CONFIRMED findings** go back to `implementer` once. Review again. A CONFIRMED finding that
  survives the second round blocks the spec: its status goes back to `in-progress` and the `blocked:`
  field names the finding, in a new commit. Published history is never rewritten
- **PLAUSIBLE findings** do not block. They go in the report, each with what could not be verified

### 3.5 Deliver

Within the Delivery convention, exactly as a session would: push where it permits, open the pull
request where it permits, and stop at the last permitted action. A spec on an unmerged branch is not
`implemented` on the mainline yet, so a spec that depends on it waits for the next run.

Report the spec in one line, return to the mainline, and take the next one.

---

## Phase 4 — Report

```markdown
## Backlog drain — 2026-10-18

| Spec | Outcome | Commits | Notes |
|---|---|---|---|
| 042 Export invoices as CSV | implemented | a1b2c3d..e4f5a6b, pushed `main` | 2 PLAUSIBLE findings |
| 043 Bulk refunds | blocked | — | criterion 2 is not observable |
| 044 Refund audit log | skipped | — | depends on 043 |

Ingested: 042, 043, 044. Left in the inbox: `roadmap.pdf` (not Markdown).
Plans approved by declaration: 042. By the developer: none.
```

Then the PLAUSIBLE findings, and what each `implementer` noticed and did not touch — the follow-ups
nobody asked for, written down so they are not lost and not done in passing.

---

## What this command never does

- **Write or fix a spec.** It adds frontmatter and the `blocked:` field. The body is the author's
- **Decide a contradiction.** Spec against ADR, spec against spec, spec against code: reported, never
  resolved by picking one
- **Run two specs at once.** The second would be planned against a tree the first is still changing
- **Widen a grant.** Every agent it dispatches is bounded by the same declarations as this session
- **Report a spec `implemented` that `pr-critic` has not reviewed**
