# Changelog

All notable changes to this framework are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Because consumer projects load this framework into every Claude Code session, a version bump is
about *their* sessions: **major** means they must change something in their own project,
**minor** adds criteria or commands, **patch** corrects and clarifies.

## [1.1.1] — 2026-09-03

### Fixed

- The hook stub's `report()` helper tripped an unreachable-code warning, because every call site
  ships commented out. Rather than suppress it, the stub now exposes
  `bash .claude/hooks/on-file-edit.sh --selftest`, which exercises the reporting path and prints the
  envelope Claude Code reads context back from — so a developer can confirm the plumbing before
  wiring any real check, and the helper is genuinely reachable.
- CI installed shellcheck from apt, whose version drifts. Different versions report *different codes
  for the same finding* (0.11.0 says SC2329, older ones SC2317), so a run went red on findings that
  were green locally. The version is now pinned to 0.11.0, matching what the quality gate documents.
- `shellcheck` now also covers `templates/hooks/*.sh`; the shipped hook is shell code like any other.
- `check-consistency.sh` fails when the version the README tells people to pin is not the current
  one — the staleness this release had to fix by hand.

## [1.1.0] — 2026-09-03

Closes the gap between measuring quality and writing it. Before this release the framework had a
write-time layer covering 6 of its 10 audited categories, and an audit whose findings reached no
later session. Security and observability — the two categories where a rule while writing matters
most, because a vulnerability and a missing log are written rather than discovered — had no
write-time counterpart at all.

### Added

- **Six coding principles** covering the categories that had none: check what already exists (14),
  validate at the boundary (15), observability is part of the feature (16), test doubles at the
  boundary (17), a deprecation is a deadline (18), history is part of the deliverable (19).
- **A traceability table** in `CODING_STANDARDS.md` mapping every principle to the subcriteria that
  measure it, plus an explicit list of criteria that are audit-only by nature and why. It is the
  single cross-reference between the two halves of the framework, and `check-consistency.sh` now
  fails if it drifts from either document — a new principle without a mapping, or a cited
  subcriteria that does not exist.
- **`.claude/audit-focus.md`**, written by `/project-audit`: the 3–5 weakest criteria *that have a
  write-time principle behind them*, each with a concrete rule for code that touches them.
  `INSTRUCTIONS.md` has Claude read it before writing. Infrastructure gaps stay in the report as
  project work, since no rule can honour them mid-feature. Regenerated at each audit; removed on
  uninstall.
- **Audit freshness check** — Claude flags once when the newest report in `docs/audits/` is more
  than three months old.
- **`init-project.sh --with-hooks`** — an opt-in `PostToolUse` hook running fast per-file checks
  after each edit. Beyond formatting, a failing check reports back through
  `hookSpecificOutput.additionalContext`, so the error reaches Claude in the same turn instead of
  surfacing in CI. Ships as a stub with nothing enabled; never modifies an existing
  `.claude/settings.json`, printing the snippet to merge instead. Four new cases in
  `test-install-cycle.sh` cover opt-in, wiring, non-clobbering and cleanup.

### Changed

- **The precedence rule between the quality standard and the developer profile is now explicit:**
  the standard fixes the target, the profile fixes the delivery. A competency level decides how much
  is explained, whether the work is done jointly, and which of several compliant options is chosen —
  it never lowers a criterion. Previously the two documents could be read as contradicting each
  other: a profile entry of `Base` said "avoid as a primary technology" while the audit demanded
  7/10 in that category, and nothing said which won.
- `Base` in the profile template no longer reads "avoid as a primary technology"; it reads "prefer
  the simplest approach that still meets the standard, and explain as you go". `Base *` now
  forbids silently handing over correct work as well as working around the gap — silent correctness
  teaches nothing.
- `INSTRUCTIONS.md` no longer exempts `/project-audit` from the block-reading protocol; since 1.0.0
  the command reaches coverage by fanning out, not by reading the whole tree.
- `uninstall.sh` keeps `docs/audits/` and says so — the quality history belongs to the project, not
  to the framework.

## [1.0.0] — 2026-09-03

First versioned release. Consolidates the framework after two migrations — global install →
git submodule, and symlinked commands → copied commands — each of which left inconsistencies
behind.

### Breaking

- **The `@`-include target moved.** Consumer projects must include
  `@.claude/framework/INSTRUCTIONS.md` instead of `@.claude/framework/CLAUDE.md`.
  `CLAUDE.md` in this repo is now the framework's own development file and must not be loaded
  into a consumer session.
  **Migration:** run `bash .claude/framework/scripts/init-project.sh` — it rewrites the line in
  place. No manual edit needed. An un-migrated project still works: the new `CLAUDE.md` opens with
  a guard that detects the situation and redirects Claude to `INSTRUCTIONS.md`.

### Added

- `VERSION` and this changelog; releases are now tagged, so a project can pin a version instead of
  tracking `main`.
- `.claude/.framework-version`, written by `init-project.sh`. Because commands are *copied* into
  `.claude/commands/`, they go stale when the submodule moves ahead; Claude now compares the marker
  against `VERSION` and flags the drift once per session.
- `scripts/check-consistency.sh` — the framework's own quality gate. Fails on retired names, false
  symlink claims, non-portable `sed -i`, broken path references, an `@`-include target that
  disagrees with what `init-project.sh` installs, and a `VERSION`/`CHANGELOG` mismatch.
- `scripts/test-install-cycle.sh` — exercises install, re-install, pre-1.0 migration and uninstall
  against throwaway projects. It is what caught the `sed` alternation bug below, which no amount of
  reading would have: BSD sed silently does nothing rather than reporting an error.
- CI (`.github/workflows/ci.yml`): shellcheck, markdownlint, the consistency check, and the
  install/uninstall cycle on every push — the last one runs on Linux, where the `sed` differences bite.
- `.claudeignore` — the framework now satisfies the precondition it imposes on the projects it audits.
- `/project-audit` writes a dated report to `docs/audits/` and maintains `docs/audits/history.md`,
  so score movement between audits is visible instead of being lost with the chat.

### Changed

- **`/project-audit` execution model.** The 10 scoring agents are now native subagents launched in a
  single message, and the evidence is sliced: a small shared `common.md` plus a *manifest* of source
  files, which each agent reads from selectively. Previously the entire project source was inlined
  into 10 separate `claude -p` invocations, so a project's code was paid for ten times over.
- `/project-audit` gained the frontmatter (`description`, `allowed-tools`) the other two commands
  already had, and writes intermediates to the session scratchpad rather than `/tmp`.
- Project-level specialization files are documented where they actually live — `.claude/` — instead
  of the project root, in both `standards/` documents.
- The specialization format is no longer inlined in `standards/PROJECT_AUDIT_FRAMEWORK.md`; it
  points at `templates/PROJECT_AUDIT_FRAMEWORK.md`, so the two cannot drift apart again.
- `README.md` describes copied commands (not symlinks), states that re-running `init-project.sh`
  after an update is required, and documents versioning and removal.

### Fixed

- Dead references to `~/.claude/CLAUDE.md` and `~/.claude/standards/CODE_QUALITY_STANDARDS.md` in
  the evaluation preconditions — paths from the pre-submodule layout that no longer existed.
- `uninstall.sh` used `sed -i ''`, which fails on GNU sed (Linux, CI). Replaced with a portable
  temp-file helper using `sed -E` — BSD sed does not support `\|` alternation in basic regexes, so
  the first replacement silently failed to remove the `@`-include on macOS.
- `uninstall.sh` deleted `.claude/commands/` wholesale, taking project-owned commands with it. It
  now removes only the files it installed and keeps the directory unless it is empty.
