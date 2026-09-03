# Working ON claude-audit-framework

Instructions for Claude Code when the task is **developing this framework**, not using it.

---

## ⚠ Stop — are you reading this from a consumer project?

This file is **not** the file consumer projects include. If you are reading it because a project's
`CLAUDE.md` contains `@.claude/framework/CLAUDE.md`, that project's installation predates the
`INSTRUCTIONS.md` split and is pointing at the wrong file.

**How to tell:** if `.claude/framework/` exists in the working tree, you are in a consumer project.
If `standards/` and `commands/` are at the root instead, you are in the framework repo itself and
the rest of this file applies.

**In a consumer project:** flag it once, then read `.claude/framework/INSTRUCTIONS.md` instead and
follow that for the rest of the session.

> ⚠ Outdated framework install — your `CLAUDE.md` includes `@.claude/framework/CLAUDE.md`, which is now the framework's own development file. Run `bash .claude/framework/scripts/init-project.sh` to migrate the include to `INSTRUCTIONS.md`.

---

## What this repo is

A portable quality framework distributed to other projects as a git submodule at
`.claude/framework/`. It ships documents and commands — no application code.

| Path | Audience | Role |
|---|---|---|
| `INSTRUCTIONS.md` | Consumer projects | The file `@`-included into a project's `CLAUDE.md`. Loaded into every session of every consuming project. |
| `CLAUDE.md` | This repo | This file. Never travels into a consumer session. |
| `standards/PROJECT_AUDIT_FRAMEWORK.md` | Consumer projects | The 10-category evaluation standard — *what good is measured against*. |
| `standards/CODING_STANDARDS.md` | Consumer projects | The 22 principles applied to every code proposal — *what good looks like*. |
| `commands/*.md` | Consumer projects | Slash commands, **copied** into `.claude/commands/` by `init-project.sh`. |
| `templates/*.md` | Consumer projects | Scaffolding for the project-level specialization files. |
| `scripts/init-project.sh` | Operators | Installs and migrates a consumer project. The only mutating script. |
| `scripts/check-install.sh` | Operators | Read-only conformance of an install against the version it has. Also used by `init-project.sh` for its verification step — the rules live here only. |
| `scripts/check-updates.sh` | Operators | Whether a newer release exists, at both drift levels. |
| `scripts/check-consistency.sh`, `scripts/test-install-cycle.sh` | This repo | The framework's own quality gate. |

---

## Rules for changing this framework

### 1. One fact, one place

The most frequent defect in this repo's history is the same statement living in two files and
drifting apart. Before adding a sentence, check whether it already exists elsewhere.

- A global rule belongs in `standards/` — never restated in `templates/` or `INSTRUCTIONS.md`
- A template is a *fill-in-the-blanks skeleton*, never a copy of the standard it extends
- `INSTRUCTIONS.md` **points at** the standards; it does not summarise their content
- A path written in prose is a fact like any other: if it appears in three files, it will be wrong
  in two of them after the next migration

### 2. Paths are load-bearing

Every `.claude/framework/...` path in a document is a live reference — a consumer project resolves
it at session start. When a file moves, `scripts/check-consistency.sh` is what catches the stragglers.
Run it before committing.

### 3. Version every change to a shipped document

A consumer project pins or pulls this repo by git ref. A change to anything under `standards/`,
`commands/`, `templates/`, or to `INSTRUCTIONS.md`, is a change to their sessions.

- Bump `VERSION` (semver) and add a `CHANGELOG.md` entry **in the same commit** as the change
- **Major** — a consumer must edit their own files to keep working (e.g. the `@`-include split)
- **Minor** — new category, new subcriteria, new command
- **Patch** — corrections, clarifications, path fixes
- Every breaking change needs a migration path in `scripts/init-project.sh`, not just a note in the
  changelog: the script is what consumers actually run

### 4. Scripts must be portable and non-destructive

`init-project.sh` and `uninstall.sh` run on developer machines and in CI, on macOS and Linux.

- POSIX-compatible text editing only — no `sed -i ''` (BSD) and no `sed -i` (GNU); use a temp file + `mv`
- Both scripts are **idempotent**: running twice changes nothing the second time
- `uninstall.sh` removes only what the framework installed. A file the project owns is never touched,
  and a directory is removed only when empty
- `shellcheck` clean. The only suppressions are per-line `disable=SC2086` on deliberate
  word-splitting in `check-consistency.sh`, each with its reason on the line above

### 5. Criteria need observable evidence

A subcriteria that cannot be scored from a file, a line, or a command's output is not a criteria —
it is an opinion. When adding one to `PROJECT_AUDIT_FRAMEWORK.md`, include what *good* and *bad*
look like as things a reader can point at, and keep the existing structure:
`what it measures → subcriteria → good → bad`.

---

## Quality gate

```bash
bash scripts/qa.sh
```

It runs all four checks CI runs — consistency, the install cycle, shellcheck, markdownlint — and
reports which it could **not** run rather than passing silently. This is the framework's own answer
to subcriteria 7.7, and the single place the gate is defined: do not restate the individual commands
elsewhere. They were previously listed here and in `README.md`, the list here omitted markdownlint,
and CI ran four jobs against a documented three.

`test-install-cycle.sh` works on throwaway `mktemp` projects and never touches this repo. It is the
only way to catch the in-place text editing bugs: a BSD-vs-GNU `sed` difference produces a silent
no-op, not an error.

---

## Conventions

- **Language:** all shipped documents are written in English, regardless of the conversation language
- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`), scoped to a
  category where relevant (`feat(cat9):`)
- **Dogfooding:** `/project-audit` should run cleanly on this repo. When it cannot, that is a finding
  about the framework, not about the repo
