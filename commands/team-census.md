---
description: Record who writes, reviews, releases and consumes a version of this project, into the Team census block — the input Category 10 is scored proportionally against.
allowed-tools: [Read, Write, Edit, Bash]
---

> **Execution constraints:** Run entirely in this conversation. Do NOT spawn subagents.

## Purpose

Fill in — or refresh — the **Team census** block of `.claude/PROJECT_AUDIT_FRAMEWORK.md`.

Four of Category 10's subcriteria exist because of other people: a pull request carries a review
between two of them, a protected branch stops a change arriving unseen, a tag names a version
somebody downstream runs. Precondition 5 of the standard establishes who those people are, and the
proportionality rule at the top of Category 10 turns that into which subcriteria are in play. Without
the census the shape is inferred from the git log, which knows who committed and not who is still
here.

**Most of this command is reading, not asking.** The history answers the questions it can; the
developer answers the four it cannot.

This is not the developer profile. `~/.claude/context/user_profile.md` is per machine, personal and
never committed — it calibrates how a proposal is delivered. The census belongs to the project, is
committed, and calibrates what an audit measures.

---

## Step 1 — Find the file, and whether this is a first census or a refresh

```bash
test -f .claude/PROJECT_AUDIT_FRAMEWORK.md && echo "---SPEC_EXISTS---" || echo "---SPEC_MISSING---"
grep -n '^## Team census' .claude/PROJECT_AUDIT_FRAMEWORK.md 2>/dev/null && echo "---BLOCK_EXISTS---" || echo "---BLOCK_MISSING---"
```

**`SPEC_MISSING`:** stop. The specialization file is scaffolded by the installer, and writing one by
hand produces a file the next `init-project.sh` will not recognise:

> The project has no `.claude/PROJECT_AUDIT_FRAMEWORK.md`. Run
> `bash .claude/framework/scripts/init-project.sh` first — it scaffolds the file from the template,
> with this block and the other declarations in it.

**`BLOCK_EXISTS`:** this is a refresh. Read the block in full and say what it currently claims,
including its `next_review_date`. Then run Steps 2 and 3 and present the evidence *against* the existing
block — the useful output of a refresh is the difference, not a fresh interview. If nothing has
changed, say so and move the review date; do not re-ask the four questions to write the same table back.

**`BLOCK_MISSING`:** a first census. If the file predates the block entirely, note it once — the
template now carries it, and `bash .claude/framework/scripts/check-install.sh` is what lists any
other declaration the project is missing.

---

## Step 2 — Read the evidence

Do not ask any of this. Run it.

```bash
# who has written code in the last year, and how much
git shortlog -sne --since='12 months ago' --no-merges HEAD

# the same over the whole history, to see who has left
git shortlog -sne --no-merges HEAD | head -20

# who merges — rarely the same list, and it is the review question
git log --merges --since='12 months ago' --format='%an' | sort | uniq -c | sort -rn

# the last commit of each author, which is what separates active from departed
git log --since='24 months ago' --no-merges --format='%aI %aE' \
  | sort -t' ' -k2 | awk '{ last[$2] = $1 } END { for (a in last) print last[a], a }' | sort -r

# who the host thinks reviews what — the file is valid in any of three locations
find . -maxdepth 2 -name CODEOWNERS -not -path './.git/*' -exec cat {} +

# whether anything downstream could pin a version of this project
git tag -l | tail -5
```

Two readings that change a number before it reaches the table:

- **One person can be several email addresses.** A developer who has committed from a laptop, a
  server and a CI job appears three times in `shortlog`. If the list looks inflated that way, say so
  and propose a `.mailmap` — it fixes every future reading of the history, not just this one.
- **The last-commit date is the only departure signal in the repository.** An author whose most
  recent commit is fourteen months old is not an active contributor, whatever the yearly total says.
  Bring it to the developer as a question, never as a conclusion: people take sabbaticals.

---

## Step 3 — Resolve every identity to a person

`shortlog` counts identities. The census counts people, and the two differ whenever a bot, an agent,
a shared account or a web interface sits between the two. Do not drop a bot from the list — **find
who is behind it**: its commits are somebody's work, and that somebody is a writer.

Walk the ladder in order and stop at the first rung that answers.

**1. Author against committer.** Every commit carries two identities and `shortlog` shows only the
first:

```bash
git log --since='12 months ago' --format='%an <%ae>  ||  %cn <%ce>' | sort | uniq -c | sort -rn
```

The author is whose work it is; the committer is what put it there. A merge made through a web
interface commits as the host with the human as author; a bot that rebases or amends is the
committer over somebody else's authorship. `git shortlog -sce HEAD` gives the committer view of the
same history.

**2. The trailers**, which is where the second party is recorded:

```bash
git log --since='12 months ago' \
  --format='%h | A=%an | CO=[%(trailers:key=Co-authored-by,valueonly,separator=%x3B)]'
```

A developer as author with `Co-authored-by: Claude …` is **one writer** — the developer. The reverse
shape, an agent identity as author with a person in the trailer, makes the person in the trailer the
writer. `Signed-off-by` names whoever vouched for the change.

**3. The address encodes an account.** `12345+alice@users.noreply.github.com` carries both the
numeric account id and the login, and `49699333+dependabot[bot]@…` does the same for an app. A
`[bot]` suffix means an application acting for an installation: the human who triggered it is in the
host's audit log and never in the commit. Where the project is on GitHub and `gh` is available,
`gh api /user/<id>` turns the id into an account.

**4. The signature**, which is stronger than any name field:

```bash
git log --since='12 months ago' --format='%h %G? %GS' | sort -k2 | uniq -c -f1 | head
```

A commit authored under a bot identity but signed with a person's key was made with that person's
key. The host's own web-flow key is the exception — it signs everything committed through the web
interface, so it proves the route and not the author.

**5. The pull request it arrived in.** A squash commit ends in `(#123)`; a merge commit names the
branch. `gh pr view 123 --json author,mergedBy,reviews` turns that into accounts, and it is the most
reliable bridge from a bot commit to the people on either side of it.

**What no repository holds is who pushed.** That is in the host's audit log, not in the object graph,
and a clone cannot reach it. An identity that survives all five rungs is a question for a person —
ask it in Step 4 rather than inferring a shape around it.

One hint worth running when a single identity carries a suspiciously large share of the history,
because a shared account is the error that matters:

```bash
# several timezone offsets under one address is travel, or it is several people
git log --since='12 months ago' --format='%ae %ai' | awk '{print $1, $NF}' | sort -u
```

Then apply the rule from precondition 5, which runs one way only: **an unresolved identity is never
resolved downward.** Record it in the census as unresolved and keep scoring the subcriteria it would
otherwise have made N/A. Marking 10.12 N/A needs a positive finding that nobody else writes here —
not an absence of evidence about who does.

---

## Step 4 — Ask only what the history cannot know

Four questions, one at a time, waiting for each answer. Lead each with what the history already
suggested, so the developer is correcting a draft rather than filling in a form.

1. **Who is still on this project, and who is behind the identities Step 3 could not resolve?** "The
   log shows *N* identities in the last year — *names* — which resolve to *M* people. Which of them
   are still contributing, is anybody writing code here who has not committed yet, and who is behind
   *the unresolved identity*?"
2. **Who reviews, and what enforces it?** "Does a change reach the mainline through someone else's
   approval, and is that enforced by branch protection or by agreement?" A team that agrees on review
   and does not enforce it is a legitimate answer — it is scored in 10.13, not here.
3. **Who releases?** "Who cuts a release, and is it a person, a command, or something that runs on
   merge?" If nothing is released — the mainline deploys — say so in the row; that is an answer.
4. **Does anything consume a version?** This is the question that decides 10.14, so do not accept a
   yes or a no on its own. Ask what would consume one: another service pinning this package, a
   deployed artifact identified by version, a changelog with readers outside the team, a customer
   with a support contract on a version. If a rollback names a commit and nothing pins, the answer is
   nobody.

---

## Step 5 — Propose the block, with what it changes

Present the filled table in the shape the template defines, followed by what this shape means for
scoring — derived from the proportionality rule, never invented here:

> With this shape, Category 10 is scored as: 10.12 *(reason)*, 10.13 *(reason)*, 10.14 *(reason)*.
> Everything else in the category is scored as written.

Then two checks, both of which are findings rather than edits:

- **Against the Delivery convention block**, if the project has one. A census of one writer beside a
  convention requiring a pull request and an approval is a contradiction with two readings — the
  census is wrong, or the convention describes a team the project no longer has. Name both readings
  and ask which; never silently reconcile them.
- **Against the last audit**, if `docs/audits/` has one. A census that moves a subcriteria from
  scored to N/A, or back, changes what the next audit measures. Say which, so the movement in
  `history.md` is read as a change of shape rather than as progress or regression.

Ask for confirmation before writing anything.

---

## Step 6 — Write it

Replace the existing `## Team census` block, or insert one immediately before `## Delivery
convention` if there is none. Set:

| Field | Value |
|---|---|
| Census date | today |
| next_review_date | today + 6 months |

Six months, not a year: team shape changes faster than competency does, and a census nobody has
revisited is the input an audit will trust anyway.

Leave the commit to the project's **Delivery convention** — this command writes the file and reports
it, exactly like any other change.

---

## Step 7 — Report

Three lines at most:

- What the census now says, in one sentence
- Which subcriteria that puts in or out of play, if this run changed any
- Any contradiction found in Step 4, named and unresolved
