---
description: Run the project's committed disaster-recovery drill against its declared disposable target, verify the restore actually restored something, and write a receipt. Read-only against production and the backup store. --dry-run checks the setup without restoring.
allowed-tools: [Read, Grep, Glob, Bash, Write]
---

Rehearse the recovery that subcriteria 9.10 scores, and leave behind the evidence that makes the
rehearsal count.

## Arguments

```text
/dr-drill [--dry-run]
```

`--dry-run` validates everything up to the restore — the declaration, the script, the target, the
credentials — and stops before touching anything. Use it to check the drill is still runnable
without paying for a full exercise.

## What this command is, and is not

It runs **the project's own drill script**, and transcribes what that script reports. It does not
compose a restore out of whatever it can infer from the repository.

That distinction is the whole value. A restore improvised afresh each time is not comparable with
the last one, cannot be handed to a person at 3am, and cannot be moved into CI — and CI running the
*same script* is what takes 9.10 from 8 to 10. An agent makes the drill cheap enough to actually
perform; it does not make the drill.

> ⚠ **The receipt records what the run reported, never what you concluded.** Do not write a receipt
> for a drill that did not run. Do not edit a result, fill a field by inference, or smooth over a
> step that failed. A field you cannot fill stays empty, with the reason. A hand-written receipt is
> a claim in the shape of evidence, and 9.10 scores it as a claim — so writing one does not raise
> the score, it only removes the chance of ever measuring the real one.

---

## Phase 0 — The declaration, or stop

Read the **Disaster recovery drill** section of `.claude/PROJECT_AUDIT_FRAMEWORK.md`.

**If it is absent, stop.** Do not look for backups, do not infer a restore command from the
migrations, do not provision anything. Say what the section needs — the drill script, the backup
source, the disposable target, the assertions, where receipts go, the RPO and RTO — and offer to
scaffold it together with a first version of the script. A restore improvised against an undeclared
target is the accident the drill exists to rehearse for.

**If it is present**, everything below is bounded by it. It is the list of what may happen, not an
illustration of it.

## Phase 1 — Pre-flight

Check, and report each as a line the user can see:

- **The drill script exists** at the declared path, is executable, and is **committed**. If the
  working tree has uncommitted changes to it, say so — the receipt names a commit, and a receipt
  naming a commit that does not contain what ran is worse than no receipt.
- **The target is not production.** Compare the declared target against every production identifier
  in the **Production access** section — host, database name, bucket, account, cluster. Any overlap
  stops the command. State what matched; do not ask whether to proceed anyway.
- **The target is disposable**: created by the drill and destroyed by it. If the declaration names a
  long-lived environment, stop — a drill that restores into staging-as-it-is proves nothing about
  recovering from nothing, and quietly destroys staging.
- **Credentials resolve** from the environment variables the declaration names, and none of them is
  printed. Absent variable, absent drill — say which.
- **Backup access is read-only.** The drill reads an artefact. It never rotates, deletes, overwrites
  or re-tags anything in the backup store, and if the script does any of those, that is a finding to
  report rather than a step to run.

At `--dry-run`, report the result of these checks and stop here.

## Phase 2 — Confirm, then run

State in one block what is about to happen: the script, the artefact it will restore and that
artefact's age, the target it will create and destroy, the expected duration if a previous receipt
records one, and the cost if the target is cloud infrastructure. **Wait for the user to approve.**
An allow-listed command is permission to ask, not approval.

Then run the script once, from the project root, capturing:

- wall-clock start and end, in ISO 8601 with timezone — the duration is the number RTO is measured
  against, so it is observed, not estimated
- the exit code
- the assertion results, as the script reports them
- the tail of stdout and stderr, enough to make a failure diagnosable

**Do not repair the run.** If a step fails — a missing dependency, an expired credential, a path
that moved — stop, and record the failure. The temptation is to patch around it and re-run so the
drill "passes"; that converts the one output worth having into a formality. A drill that fails in a
rehearsal has done its job: the same gap, discovered during a real recovery, is discovered with the
production system already gone. Fix the cause in the script, commit it, and run the drill again as a
new drill.

## Phase 3 — Verify that something was actually restored

`exit 0` is not a restored system: an empty backup restores perfectly and reports success. Check
what the script asserted, and record each assertion with its result.

If the script asserts nothing beyond the exit code, say so plainly, mark the receipt's outcome
**`unverified`** rather than `pass`, and name the assertions it needs: row counts against the
recorded source counts, a canary record, a checksum over restored files, the application booting
with its health endpoint green, the smoke tests of 10.8 against the restored environment. An
unverified drill measures the restore command, not the restore.

## Phase 4 — Tear down

Destroy the target, confirm it is gone, and record that it was. A drill that leaves its restored
copy running has created a second production system holding production data with none of the
production controls — which is a Category 8 finding caused by a Category 9 exercise.

## Phase 5 — The receipt

Write it to the declared receipts directory, one file per drill, and never overwrite an earlier one.
Fixed shape, so a later audit can compare two drills and a CI job can emit the same thing:

```markdown
---
drill: <script path>
commit: <sha the script was run from>
date: <ISO 8601 start, with timezone>
operator: <who invoked it — a person, or the CI job name>
outcome: pass | fail | unverified
---

| Field | Value |
|---|---|
| Backup artefact | <id or path> |
| Artefact age at restore | <duration> — RPO is <declared>, so <met / missed by X> |
| Target | <what was created, and that it was destroyed> |
| Restore duration | <wall clock> |
| Time to service | <until health returned green, where the app was booted> — RTO is <declared>, so <met / missed by X> |

**Assertions**

| Assertion | Result |
|---|---|
| <as the script reports them> | pass / fail |

**Deviations** — every step that did not go as the runbook says, including ones worked around by
hand. Empty only if there were none.

**Not covered** — what this drill did not exercise: the data it did not restore, the failure mode it
did not simulate, the dependency it stubbed.
```

The **Not covered** section is the one people skip and the one that matters most. A drill that
restores a database and calls itself disaster recovery has not tested the uploads, the secrets, the
DNS, or whether anyone but its author can run it.

## Phase 6 — Report

Say, in a few lines: outcome, duration against RTO, artefact age against RPO, which assertions
failed, and what the drill did not cover. Where a previous receipt exists, compare the durations —
a restore that has been getting slower for three drills is a finding before it becomes an incident.

Then, if the drill passed and is not yet scheduled: **say that the next step is CI, not another
manual run.** This command exists to get a drill working and to re-run it by hand when something
changes. A drill that runs because somebody remembered answers "did it work in June"; 9.10 reserves
its top band for one that answers "does it work now".
