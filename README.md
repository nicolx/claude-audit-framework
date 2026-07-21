# claude-audit-framework

A portable quality framework for Claude Code — travels with any project as a git submodule.

## What it includes

- **10-category quality framework** for code review and architecture evaluation (`/project-audit`)
- **13 coding principles** applied automatically to every code proposal
- **Developer profile system** — calibrates Claude's recommendations to each developer's skill level
- **Skill commands**: `/project-audit`, `/competency-review`, `/init-profile`

## Add to a project

```bash
# Add the submodule
git submodule add git@github.com:nicola/claude-audit-framework.git .claude/framework

# Bootstrap: creates symlinks in .claude/commands/ and scaffolds project files
bash .claude/framework/scripts/init-project.sh
```

Then edit the generated `CLAUDE.md`, `PROJECT_AUDIT_FRAMEWORK.md`, and `CODING_STANDARDS.md` to add your project-specific context.

## Set up your developer profile

The first time you open Claude Code in a project with this framework, run:

```
/init-profile
```

This creates a personal profile at `~/.claude/context/user_profile.md`. It stays on your machine — it is never tracked in the project repo. Every developer on the team creates their own.

## Available commands

| Command | What it does |
|---|---|
| `/init-profile` | First-time developer profile setup (~5 min) |
| `/project-audit` | Full 10-category quality evaluation with 10 parallel agents |
| `/competency-review` | Quarterly review and update of your developer profile |

## Keeping the framework up to date

```bash
cd .claude/framework && git pull origin main && cd ../..
git add .claude/framework
git commit -m "chore: update claude-audit-framework"
```

## How it works

The project's `CLAUDE.md` includes `@.claude/framework/CLAUDE.md`, which loads quality framework instructions into every Claude Code session. Skills are available via symlinks in `.claude/commands/` created by `init-project.sh`.

Each developer has their own profile at `~/.claude/context/user_profile.md`. When the profile is missing, Claude prompts you to run `/init-profile` before answering technical questions.

## Project-level specializations

After `init-project.sh`, customize:

- `CLAUDE.md` — project name, stack, architecture, quality gate command
- `PROJECT_AUDIT_FRAMEWORK.md` — stack-specific quality criteria (tool mappings, test taxonomy, layer rules)
- `CODING_STANDARDS.md` — language-specific naming conventions, patterns, style rules

These files extend the global framework — they do not replace it.
