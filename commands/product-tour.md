---
description: Derive what the software actually does from its entry points, and write it down for the people who use it — a task-organised manual for stakeholders and developers, a slide deck, and, where the project declares a target, a recorded walkthrough of the real application. Reports where the product's declared intent and its code disagree. --check rebuilds the inventory and reports drift without writing anything.
allowed-tools: [Read, Grep, Glob, Bash, Write]
---

Produce the user-facing documentation that subcriteria 0.9 scores, and the evidence that makes it
true rather than plausible.

## Arguments

```text
/product-tour [--check] [--no-video]
```

`--check` runs Phase 0 and Phase 1, compares the inventory with the committed manual, and reports the
drift. It writes nothing, and it is the procedure an audit follows to score 0.9.

`--no-video` stops after the slides, even where a recording target is declared.

## What this command is, and is not

It writes down **what the code does**, from the code — every route, command, screen and job a user
can reach. It does not write down what the product is for, and it never edits a document that says
so. 0.9 states why a manual derived from code is never evidence of intent; that rule bounds every
phase below.

The value of an AI here is coverage and speed: reading every entry point is cheap for an agent and
expensive for a person, so the manual can be regenerated in the change that makes it stale. The risk
is the same capability pointed the other way — a fluent paragraph about a feature that is not there.

> ⚠ **Every statement in the manual traces to an entry point in the inventory, or it is not
> written.** No task inferred from a name, a comment, a spec or a ticket. A capability the context
> document promises and the code does not deliver goes in the divergence report, never in the
> manual. A recording shows the running software at the stamped commit — no generated imagery, no
> avatar, no screen that was drawn rather than captured.

---

## Phase 0 — Read the declarations

- **The `Product tour` section** of `.claude/PROJECT_AUDIT_FRAMEWORK.md`. It names where the manual
  lives, its audiences, the vocabulary, and — if a recording is allowed at all — the target and the
  harness. **If it is absent**, the manual and slides go under the documentation home of 0.2 in
  `manual/`, after the user confirms the path, and Phase 4 does not run.
- **The product context of 0.1.** Its vocabulary is the manual's vocabulary: a task is named the way
  the context names it, not the way the code does. If there is no context document, say so once —
  the divergence report in Phase 5 then has nothing to compare against and is reported as such.
- **The stamp:** `git rev-parse HEAD`, whether the working tree is clean, and
  `.claude/framework/VERSION`. A manual generated from uncommitted code names a commit that does not
  contain what it describes; say so, and stamp it `dirty`.

## Phase 1 — The inventory

List every entry point a user can reach, with the file and line that defines it. Search by
mechanism, not by naming convention — the stack's router, CLI parser, screen registry, scheduler and
public API surface — and say which mechanisms were searched, so a reader can see what was not:

| Kind | Found by |
|---|---|
| HTTP routes and pages | the router's registration, not the controller directory |
| CLI commands and flags | the argument parser's definitions |
| Screens and navigation | the navigation graph or route table of the client |
| Scheduled and background jobs | the scheduler's configuration |
| Notifications the user receives | the email, push and SMS templates and what sends them |
| Public API of a library | the exported symbols, not every symbol |
| Files a user runs or edits | for a toolkit or framework, the scripts and documents it installs |

Each row gets a stable ID (`E1`, `E2`, …), the entry point, the `path:line` defining it, the role or
permission that guards it, and whether anything a user can see links to it. **An entry point
defined but unreachable** — no link, no navigation, no caller — is listed with that mark; it is a 2.6
finding, not a task.

Group the reachable entry points into **tasks**: what a user is trying to get done, named in the
context's vocabulary, each citing the IDs that carry it. Write the inventory to `inventory.md` in
the manual home. It is the evidence; the manual is its reading.

At `--check`, compare this inventory with the one committed beside the manual, report entry points
added, removed and changed since its stamp, and the tasks in the manual whose IDs no longer resolve.
Then stop.

## Phase 2 — The manual

Two documents, two audiences, one inventory:

- **`user-guide.md` — for whoever uses the product.** One section per task: what it achieves, who can
  do it, the steps, what the user sees when it worked and when it did not. Written in the context's
  vocabulary; no class names, no paths in the prose. Each section ends with the IDs it rests on.
  For a library or a framework the user is a developer, and the guide is its usage guide.
- **`developer-tour.md` — for whoever joins the team.** The same tasks, followed through the code:
  the entry point, the layers it crosses, the domain objects it touches, the side effects it leaves —
  each step a `path:line`. Where the path crosses a boundary 3.1 would score, say which.

Both carry frontmatter: `generated-by: /product-tour`, `commit`, `dirty`, `framework`, `date`. Neither
carries a status marker from 0.4 — a manual is a reading of a commit, not a plan.

What the command does not write, because the inventory cannot support it: *why* a task exists, a
tutorial that teaches the domain, a recommendation about what the user should do. Leave a heading
with a one-line note where a person is needed.

## Phase 3 — The slides

`slides.md` beside the manual, in Marp Markdown — plain text, versioned with the code, rendered by
any Marp tool. Derived from `user-guide.md`, never written independently: one title slide carrying the
stamp, one slide on who uses the product and for what, one slide per task with at most five lines,
and a last slide listing the divergences of Phase 5 that are still open. Speaker notes carry the IDs.

A deck that says more than the manual has an unsourced claim in it; cut it.

## Phase 4 — The recording

Runs only when the `Product tour` section declares a recording, and `--no-video` was not passed.

**Pre-flight**, each reported as a line:

- **The target is not production.** Compare it against every identifier in the **Production access**
  section. Any overlap stops the command; state what matched.
- **The data is synthetic.** A recording is a file that gets shared. Production personal data on a
  screen is a Category 8 finding caused by a Category 0 exercise — the declared seed, or stop.
- **Credentials resolve** from the environment variables the section names, and none is printed.
- **The harness exists.** The tour is written in the project's own end-to-end harness, in the
  directory the section names — never a second browser-automation stack installed for the occasion.

Then write one tour script per task, each step driven by the steps in `user-guide.md`, and captions
as WebVTT whose cues are the same sentences. **State in one block what is about to run** — the
target, the tasks, the expected duration — and **wait for the user to approve.**

Run it once. **Do not repair the run**: a step that fails is a task the manual describes and the
software does not perform, which is the most valuable thing a tour can find. Record it in Phase 5,
mark the task in the manual, and keep the recordings that succeeded.

Narration is the captions. A synthesised voice is used only if the section names the tool; the
script is the caption text, word for word.

## Phase 5 — The divergence report

`divergences.md` beside the manual, rewritten on every run, never appended to:

| Divergence | Read as |
|---|---|
| The context declares a capability no entry point delivers | 0.1 or 0.5 — promised or marked `implemented`, and not built |
| An entry point delivers a capability the context never mentions | 0.1 — an undeclared surface; also an input to 8's attack surface |
| An entry point is defined and unreachable | 2.6 — dead code, or a feature switched off and forgotten |
| A recorded step failed | the task does not work as described — a defect, or a manual that is wrong |

Each row names the IDs and the document line it compares. **The command decides none of them.**
Which side is right — the context or the code — is a product decision, and the manual describes the
code until somebody makes it.

## Report

End with: where each file was written, the stamp, the counts (entry points, tasks, unreachable,
divergences, recorded tasks passed and failed), and the three divergences most likely to matter,
in a line each. Do not commit; the files are the user's to review.
