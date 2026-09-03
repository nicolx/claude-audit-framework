# claude-audit-framework

A portable quality framework for Claude Code — travels with any project as a git submodule.

## What it includes

- **10-category quality framework** for code review and architecture evaluation (`/project-audit`)
- **20 coding principles** applied automatically to every code proposal, traced to the audit criteria that measure them
- **Developer profile system** — calibrates Claude's recommendations to each developer's skill level
- **Skill commands**: `/project-audit`, `/competency-review`, `/init-profile`

## Add to a project

```bash
# Add the submodule — pin a released version rather than tracking main
git submodule add git@github.com:nicolx/claude-audit-framework.git .claude/framework
git -C .claude/framework checkout v1.2.1

# Bootstrap: installs the commands, scaffolds the project files, records the version
bash .claude/framework/scripts/init-project.sh

# Optional: also install the per-file check hook (see "Enforcement" below)
bash .claude/framework/scripts/init-project.sh --with-hooks
```

Then edit the generated `CLAUDE.md`, `.claude/PROJECT_AUDIT_FRAMEWORK.md`, and
`.claude/CODING_STANDARDS.md` to add your project-specific context.

## Set up your developer profile

The first time you open Claude Code in a project with this framework, run:

```text
/init-profile
```

This creates a personal profile at `~/.claude/context/user_profile.md`. It stays on your machine — it is never tracked in the project repo. Every developer on the team creates their own.

## Available commands

| Command | What it does |
|---|---|
| `/init-profile` | First-time developer profile setup (~5 min) |
| `/project-audit` | Full 10-category quality evaluation with 10 parallel agents; writes a dated report and score history to `docs/audits/` |
| `/competency-review` | Quarterly review and update of your developer profile |

## Keeping the framework up to date

```bash
cd .claude/framework && git fetch --tags && git checkout v1.2.1 && cd ../..
bash .claude/framework/scripts/init-project.sh     # required — refreshes the command copies
git add .claude/ && git commit -m "chore: update claude-audit-framework to v1.2.1"
```

**Re-running `init-project.sh` is not optional.** The commands are *copied* into
`.claude/commands/`, not symlinked — Claude Code does not follow symlinks — so updating the
submodule alone leaves the old copies in place. The installed version is recorded in
`.claude/.framework-version`, and Claude flags the mismatch at the start of a session when the
copies fall behind.

## Two halves: writing and measuring

An audit that only produces a score changes nothing about the code written after it. The framework
works on both sides of that line.

| | Write-time | Audit-time |
|---|---|---|
| **What** | 20 coding principles | 10 scored categories |
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
criterion. Code written for someone whose profile says `Observability | Base *` still gets
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

Each developer has their own profile at `~/.claude/context/user_profile.md`. When the profile is
missing, Claude suggests running `/init-profile` at the start of the session and then proceeds
normally.

## Project-level specializations

After `init-project.sh`, customize:

- `CLAUDE.md` — project name, stack, architecture, quality gate command
- `.claude/PROJECT_AUDIT_FRAMEWORK.md` — stack-specific quality criteria (tool mappings, test taxonomy, layer rules)
- `.claude/CODING_STANDARDS.md` — language-specific naming conventions, patterns, style rules

These files extend the global framework — they do not replace it.

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
bash scripts/check-consistency.sh
bash scripts/test-install-cycle.sh
shellcheck scripts/*.sh templates/hooks/*.sh
```
