# claude-audit-framework

A portable quality framework for Claude Code — travels with any project as a git submodule.

## What it includes

- **10-category quality framework** for code review and architecture evaluation (`/project-audit`)
- **13 coding principles** applied automatically to every code proposal
- **Developer profile system** — calibrates Claude's recommendations to each developer's skill level
- **Skill commands**: `/project-audit`, `/competency-review`, `/init-profile`

## Add to a project

```bash
# Add the submodule — pin a released version rather than tracking main
git submodule add git@github.com:nicolx/claude-audit-framework.git .claude/framework
git -C .claude/framework checkout v1.0.0

# Bootstrap: installs the commands, scaffolds the project files, records the version
bash .claude/framework/scripts/init-project.sh
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
cd .claude/framework && git fetch --tags && git checkout v1.1.0 && cd ../..
bash .claude/framework/scripts/init-project.sh     # required — refreshes the command copies
git add .claude/ && git commit -m "chore: update claude-audit-framework to v1.1.0"
```

**Re-running `init-project.sh` is not optional.** The commands are *copied* into
`.claude/commands/`, not symlinked — Claude Code does not follow symlinks — so updating the
submodule alone leaves the old copies in place. The installed version is recorded in
`.claude/.framework-version`, and Claude flags the mismatch at the start of a session when the
copies fall behind.

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
`.claude/commands/` are left alone), the scaffolded specialization files, the `@`-include, and the
`.gitattributes` entry. Your developer profile is untouched. The script prints the three
`git submodule` commands needed to finish.

## Developing the framework itself

See `CLAUDE.md` in this repo. Its quality gate:

```bash
bash scripts/check-consistency.sh
bash scripts/test-install-cycle.sh
shellcheck scripts/*.sh
```
