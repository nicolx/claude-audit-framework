# claude-audit-framework

A portable quality framework for Claude Code — travels with any project as a git submodule.

## What it includes

- **11-category quality framework** for code review and architecture evaluation (`/project-audit`), from product intent (Cat 0) to delivery pipeline (Cat 10)
- **24 coding principles** applied automatically to every code proposal, traced to the audit criteria that measure them
- **Developer profile system** — calibrates Claude's recommendations to each developer's skill level, and records the natural language they work in
- **A remediation order** — the phases a project closes gaps in, so that recorded intent and a working
  safety net come before refactoring, renaming or replacing a framework, and the band rule that keeps
  every category climbing together instead of one running ahead
- **Plans scored against the history** — whether a unit of work arrived as a sequence of releasable
  steps or as one flip, read from the git log and the CI runs rather than from the document that
  described it. The one criterion a project cannot repair retroactively, and the framework holds its
  own remediation output to it
- **Skill commands**: `/project-audit`, `/dr-drill`, `/competency-review`, `/init-profile`

## Add to a project

```bash
# Add the submodule — pin a released version rather than tracking main
git submodule add git@github.com:nicolx/claude-audit-framework.git .claude/framework
git -C .claude/framework checkout v1.16.1

# Bootstrap: installs the commands, scaffolds the project files, records the version
bash .claude/framework/scripts/init-project.sh

# Optional: also install the per-file check hook (see "Enforcement" below)
bash .claude/framework/scripts/init-project.sh --with-hooks
```

Then edit the generated `CLAUDE.md`, `.claude/PROJECT_AUDIT_FRAMEWORK.md`, and
`.claude/CODING_STANDARDS.md` to add your project-specific context.

## Set up your developer profile

**Once per machine, not once per project.** The profile lives at `~/.claude/context/user_profile.md`
— outside every repository — so each project on the same machine reads the same one. If it is
already there, adding the framework to a new project needs no profile step at all: `init-project.sh`
reports it as found and Claude never asks again.

The first time, from any project with the framework installed:

```text
/init-profile
```

It stays on your machine — never tracked in a project repo. Every developer on the team creates their own, once.

Most of it is competency levels. One block is not: the natural language you work in, which lets Claude tell you when a project's declared locale set leaves your language out (subcriteria 2.10). It never changes the language anything is written in — code, comments and documents stay English.

## Available commands

| Command | What it does |
|---|---|
| `/init-profile` | One-time developer profile setup for this machine (~5 min) |
| `/project-audit` | Full 11-category quality evaluation with 11 parallel agents; writes a dated report and score history to `docs/audits/`. `--summary` / `--deep` change how much of the result is printed — never what is measured |
| `/competency-review` | Quarterly review and update of your developer profile |
| `/dr-drill` | Runs the project's committed disaster-recovery drill against the disposable target declared in `.claude/PROJECT_AUDIT_FRAMEWORK.md`, verifies the restore actually restored something, and writes a receipt for 9.10. Refuses to start without that declaration; read-only against production and the backup store; `--dry-run` checks the setup without restoring |

## Upgrading an existing install

Updating the submodule is **not** enough on its own. Two things live outside it: the `@`-include in
your `CLAUDE.md`, and the command copies in `.claude/commands/`. A submodule bumped without them is
a framework that is present and doing nothing.

```bash
# 1. Is there anything newer?
bash .claude/framework/scripts/check-updates.sh

# 2. Move to it
cd .claude/framework && git fetch --tags && git checkout v1.16.1 && cd ../..

# 3. Make the install conformant with the new version — migrations included
bash .claude/framework/scripts/init-project.sh

# 4. Verify, and read what it says
bash .claude/framework/scripts/check-install.sh

git add .claude/ CLAUDE.md && git commit -m "chore: update claude-audit-framework to v1.16.1"
```

Three scripts, three questions, no overlap:

| Script | Answers | Touches anything? |
|---|---|---|
| `check-updates.sh` | Is a **newer version** available? | No — contacts the remote |
| `check-install.sh` | Is my install **conformant** with the version I have? | No — read-only |
| `init-project.sh` | Make it conformant. | Yes |

**`check-install.sh` is the one to trust after an upgrade.** It is read-only, safe in CI, and checks
what actually breaks: the `@`-include present and not the pre-1.0 one, the command copies
*byte-identical* to the version checked out (a marker can be right while a file was hand-edited), the
version marker, the specialization files, a wired hook whose script still exists, `.claudeignore`,
and the `git archive` exclusion. Every failure prints the command that fixes it. Exit 0 conformant,
1 errors, 2 cannot tell.

It also reports **which releases since your last install had breaking changes**, so the changelog
entries you need are named rather than hunted for. `init-project.sh` migrates everything it can
automatically and is idempotent, so there is no version-by-version upgrade path to follow: you can
go from any older version straight to the newest one.

The conformance rules ship *inside* each version, so checking out `v1.16.1` gets you `v1.16.1`'s
checks with no lookup table to keep in sync.

## Two halves: writing and measuring

An audit that only produces a score changes nothing about the code written after it. The framework
works on both sides of that line.

| | Write-time | Audit-time |
|---|---|---|
| **What** | 24 coding principles | 11 scored categories |
| **When** | Every code proposal, automatically | `/project-audit`, on demand |
| **Where** | `standards/CODING_STANDARDS.md` | `standards/PROJECT_AUDIT_FRAMEWORK.md` |

The traceability table at the end of `CODING_STANDARDS.md` maps each principle to the criteria that
measure it, and states which criteria are audit-only by nature (CI setup, security headers, health
endpoints — things configured once, not written per feature). That table is the only cross-reference
between the two documents, and CI fails if it drifts from either.

**The loop closes both ways.** `/project-audit` writes `.claude/audit-focus.md`: the 3–5 criteria
this project scores worst on, each with a concrete rule to apply when touching related code. Claude
reads it before writing, so the next feature is written against this codebase's real weaknesses
rather than generic ones. It is regenerated at every audit.

## Skill level changes the delivery, never the target

A developer profile calibrates *how* work is delivered — how much is explained, whether a gap is
addressed jointly, which of several compliant options is chosen. It never lowers a quality
criterion, and the one non-competency field in it — the developer's natural language — changes
nothing about what gets written either. Code written for someone whose profile says `Observability | Base *` still gets
structured logging; the difference is that Claude says so and walks through it instead of handing
over a finished Monolog config.

## Enforcement

Instructions are the framework's main mechanism, and instructions can be overlooked. `--with-hooks`
adds the one mechanical check: a `PostToolUse` hook that runs the formatter and type checker on
**the file that just changed** — never the whole suite — and feeds any failure straight back into
the same turn, so Claude fixes it immediately instead of leaving it for CI.

The script arrives as a stub at `.claude/hooks/on-file-edit.sh` with no checks enabled: fill in the
commands for your stack, after confirming the plumbing with
`bash .claude/hooks/on-file-edit.sh --selftest`. It is opt-in because it changes how the harness
behaves, and `init-project.sh` never modifies an existing `.claude/settings.json` — it prints the
snippet to merge instead.

## Versioning

The framework follows semantic versioning; `CHANGELOG.md` records every release.

| Bump | Meaning for a consumer project |
|---|---|
| **Major** | You must change something in your own project to keep working — the changelog says what |
| **Minor** | New category, subcriteria, or command; existing behaviour unchanged |
| **Patch** | Corrections and clarifications |

Pinning a tag means a framework update never changes your sessions until you choose it. Tracking
`main` works, but you inherit changes as they land.

> **Upgrading from a pre-1.0 install:** the `@`-include target moved from
> `@.claude/framework/CLAUDE.md` to `@.claude/framework/INSTRUCTIONS.md`. Running
> `init-project.sh` rewrites the line for you — no manual edit needed.

## How it works

The project's `CLAUDE.md` includes `@.claude/framework/INSTRUCTIONS.md`, which loads the quality
framework into every Claude Code session. The commands are installed as copies in
`.claude/commands/` by `init-project.sh`.

Each developer has their own profile at `~/.claude/context/user_profile.md` — see *Set up your
developer profile* above for its scope. When it is missing, Claude suggests running `/init-profile`
once at the start of the session and then proceeds normally; when it is present, nothing is asked,
in a newly installed project as in an old one.

## Project-level specializations

After `init-project.sh`, customize:

- `CLAUDE.md` — project name, stack, architecture, quality gate command
- `.claude/PROJECT_AUDIT_FRAMEWORK.md` — stack-specific quality criteria (tool mappings, test taxonomy, layer rules)
- `.claude/CODING_STANDARDS.md` — language-specific naming conventions, patterns, style rules

These files extend the global framework — they do not replace it.

**Three blocks of `.claude/PROJECT_AUDIT_FRAMEWORK.md` are declarations rather than
specializations**, and each one decides what an audit is able to verify rather than how it reads the
code. Leaving one out is a legitimate answer; it just sets a ceiling:

| Block | Without it |
|---|---|
| `Database access for query analysis` | 7.9 and 9.8 are scored from configuration, capped at 8 |
| `Production access` | No production path is open to a session; 9.9 is scored on what a person can reach |
| `Disaster recovery drill` | `/dr-drill` has nothing to run, and 9.10 is scored from the runbook |

The skeletons, with a worked example each, are in
`.claude/framework/templates/PROJECT_AUDIT_FRAMEWORK.md`. Declare only what you mean to grant: each
block *is* the boundary of what a session may do, and read-only is the default in all three.

## Removing the framework

```bash
bash .claude/framework/scripts/uninstall.sh
```

It removes only what it installed: framework commands (project-owned commands in
`.claude/commands/` are left alone), the scaffolded specialization files, `.claude/audit-focus.md`,
the hook script, the `@`-include, and the `.gitattributes` entry. It keeps your developer profile
and `docs/audits/` — the quality history belongs to the project, not to the framework. The script
prints the three `git submodule` commands needed to finish.

## Developing the framework itself

See `CLAUDE.md` in this repo. Its quality gate:

```bash
bash scripts/qa.sh
```
