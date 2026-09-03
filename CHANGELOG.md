# Changelog

All notable changes to this framework are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Because consumer projects load this framework into every Claude Code session, a version bump is
about *their* sessions: **major** means they must change something in their own project,
**minor** adds criteria or commands, **patch** corrects and clarifies.

## [1.9.1] — 2026-09-03

The adversarial pass was re-run against the 1.9.0 redesign. It broke two of the three targets again.
Both findings were mine: one was the same class one level up, the other a construction bug in the
helper 1.9.0 introduced.

### Fixed — the guard validated the route, not the target

1.9.0 secured a symlinked `.claude/framework` and never dereferenced **`.claude` itself**. Every
write and delete is issued as the string `"$PROJECT_ROOT/.claude/…"`, and the filesystem follows a
symlink in the middle of it, so

```text
ln -s ../victim/.claude .claude
```

let the guard pass, `PROJECT_ROOT` point at the operator's own project, and `uninstall.sh` delete
the victim's commands and marker — while `announce_target` printed the *reassuring, wrong* answer.
The safety net added in 1.9.0 misreported in precisely the scenario it existed for.

Now the target is checked rather than the route: `.claude` must be a real directory whose physical
parent is the physical project root, and both mutating scripts refuse otherwise with exit 2.
`announce_target` gained a **`Writing:`** row naming the directory actually being written to, with
its resolved form when they differ — the line an operator can verify by eye.

### Fixed — sanitize_display was a deny-list, and an incomplete one

The 1.9.0 filter removed a curated set of control bytes. Two holes, both demonstrated end to end:

- The range `\000-\010\013\014\016-\037` **skips 0x0D**, so CR survived and could return the
  cursor to column 0 and overwrite the start of its own line.
- Every byte ≥ 0x80 survived, which carries C1 controls encoded as UTF-8 — U+009B is the CSI
  introducer — and the bidirectional overrides, where U+202E reverses the text an operator reads.

Enumerating what is dangerous is a game lost one codepoint at a time, so it is now an **allow-list**:
tab and printable ASCII, everything else dropped. The cost is stated rather than hidden — a commit
subject in Italian or Japanese prints with those characters missing, which is a far smaller problem
than a forged line, and `CHANGELOG.md` remains the authoritative text because it is read as a file
rather than echoed into a terminal.

- **`read_marker_version` was not sanitised**, sitting directly beside `read_framework_version`,
  which was. A committed `.framework-version` carrying ESC injected a forged green
  "✓ Install verified by vendor" line into the operator's terminal. The marker is repository
  content, so it is exactly as remote as a commit subject.

### Fixed — one more hook re-rooting

A symlinked `.claude/hooks` moved the project boundary two levels above the link target, widening
confinement for every later edit — the same root-relocation risk closed for `GIT_WORK_TREE` in
1.9.0, through a different door. Refused, and added to the enumerated list rather than left implicit.

### Held under attack

The tag allowlist held at its core: the `case` form rejects the multi-line value that defeated
`grep -qE`. Hook confinement held against every payload-driven attack — absolute paths, `..`
traversal, mid-path and final-component symlinks, disagreeing payload fields, a directory or a
trailing slash as the path. `CDPATH`, `PWD`/`OLDPWD` spoofing, crafted `$0` and `..` in the
invocation path were all tried against the new guard and all failed. The hardlink and
check-then-use cases behave exactly as documented — the adversarial pass confirmed the comment does
not overclaim.

### A note on where the defects live

Every serious finding across four adversarial rounds has been in the same place: a shell script
computing a filesystem path and then mutating it. `uninstall.sh` is the only destructive component
in the framework, and it has produced the two data-loss findings. That is an observation about the
design, not about any one bug, and it is recorded here rather than acted on.

## [1.9.0] — 2026-09-03

An adversarial pass — one agent told to break three fixes rather than score them — broke all three,
with reproductions. One was destructive, and the cause was a fix from the previous release.

### Fixed — the guard was designed wrong, not implemented wrong

`pwd -P` was added in 1.8.1 to reconcile a macOS logical/physical path mismatch. It answers *where
does this script live*, and the guard silently used it for *which project asked*. With
`.claude/framework` as a symlink the guard therefore passed **for the wrong project**:

- **Two projects sharing one framework checkout.** `uninstall.sh` run from project B deleted project
  A's commands, both specialization files, the marker, the `@`-include, and `.gitattributes`
  outright. Project B was untouched, and the operator saw ten green checkmarks in project B's
  terminal.
- **A supply-chain vector.** Git stores symlinks, and a relative one may escape the repository. A
  repository containing a single committed `.claude/framework -> ../../victim/.claude/framework`
  plus a README carrying the framework's own documented install line was enough: clone it as a
  sibling, follow the README, and the neighbouring project is stripped. No attacker code runs — the
  scripts are the victim's own, only the path is redirected.
- **And the mirror image:** the legitimate "one shared clone symlinked into each project" layout was
  *refused*, with a message contradicting what the operator had typed.

The fix is a redesign, in the new `scripts/lib/framework-paths.sh`. The project is derived from the
**logical** invocation path — `cd` without `-P` keeps the path as typed, symlink and all, which is
precisely "who asked" — and the physical form is kept separately for the one comparison that needs
it, against `git rev-parse`, which resolves. Both mutating scripts now **print the project and
framework directories before touching anything**, with the symlink target shown when there is one:
that is what turns a redirection from silent into obvious. All three cases are regression-tested,
including the layout that must be *accepted*.

### Fixed — the paste vector the allowlist did not cover

The 1.8.1 tag allowlist held under attack, but its stated purpose — nothing remote reaches the
operator's terminal unfiltered — was still open through two other channels, neither bounded by
git's refname rules:

- **Commit subjects.** A subject carrying `\033[1A\033[2K` moves the cursor up and erases the line
  the script just printed, forging a line directly above the block of four commands the operator is
  told to paste.
- **The `VERSION` file**, which is submodule content and therefore equally remote. `tr -d
  '[:space:]'` does not remove `ESC`, and the value was then written verbatim into
  `.claude/.framework-version`, a file Claude reads.

Every remote-derived display string now passes through `sanitize_display`. Verified: zero `ESC`
bytes reach the terminal from either channel.

- **The allowlist was also not self-sufficient.** `grep -qE` matches if *any line* matches, so a
  value containing a newline followed by `v1.0.0` passed. Git's refname rules forbid newlines, which
  meant the check was safe by git's construction rather than its own — and would have become an
  injection primitive the moment the same helper met a value git does not bound. Replaced by a
  `case` test that rejects the multi-line form.

### Fixed — the hook

- **`GIT_WORK_TREE` widened the confinement.** `git rev-parse --show-toplevel` obeys the
  environment, so a variable reachable through a repository's own settings, direnv, or the user's
  shell could move the project root up to `$HOME`. The hook now derives its project root from its
  own installed location and does not consult git at all.
- **The jq and python3 branches disagreed.** The python branch guarded each container with
  `isinstance`; the jq filter did not, so a payload whose `tool_response` was a string aborted the
  whole filter before the fallback and **silently suppressed every check on a jq machine** while
  running normally on a python one. Same hook, two behaviours, and `--selftest` could not surface it.
- The `php-cs-fixer` example contradicted its own instruction, passing `--quiet` after `--` so the
  formatter read it as a second path.
- **Two residual bypasses are now documented rather than implied away**: a hardlink to a file
  outside the project, and a swap between the check and the tool's use of the path — measured at 11%
  and 28% hit rates by a plain local racer. Neither is closable with path-string checks in bash. The
  comment said `pwd -P` "handles the other half"; it does not, and now says so.
- `report()` is documented as what it is: a channel into the model's context. A linter quotes the
  source it read, so passing tool output through sends file content into the conversation.

### Changed — the duplication the last re-audit measured

Category 2's `2.3` had gone from 11 duplicated-knowledge sites to 16, the path-derivation preamble
from 2 copies to 5, and the consumer-install guard from 2 to 4 *with two divergent messages for the
same rule*. `scripts/lib/framework-paths.sh` now holds the guard, the git-repo check, the version
readers, the tag validator and the sanitiser — one message, one implementation. There was no
`source` statement anywhere in the corpus before this, so the obvious fix had been architecturally
unavailable rather than merely deferred.

`shellcheck` runs with `-x` so the sourced library is followed and linted too.

### Also fixed

- A missing library now produces a diagnosis and exit 2 rather than `unbound variable`.
- The marker read takes `head -1`, so a hand-edited file with two `version=` lines cannot yield a
  multi-line value that is then compared and echoed.
- A comment in `check-updates.sh` described a `sed` hazard while the code beneath it was `awk` — a
  comment that outlived its code, in the release that added it.

### On the shape of this release

Three consecutive releases fixed a defect and introduced another; this one fixes a defect introduced
by the last. The pattern was not bad luck: the guard could not work, because inferring which project
invoked a script from that script's resolved location is impossible when the location can be a
symlink. The lesson recorded here is the one the framework already states as principle 9 — when a
fix produces the next symptom, the design is the defect.

## [1.8.1] — 2026-09-03

A scoped re-audit of the four categories 1.8.0 touched. Three moved — Observability 7→8, Tooling
7→8, Testing 6→7 — and **Security did not**, because the previous release fixed the instance and
left the root: the same remote-controlled tag name still reached `git log` argv and the operator's
clipboard, eight lines below its own fix. That is principle 9 failing in the release that shipped
it, and this release fixes the root.

### Fixed — security, at the point of capture

- **Tag names are now allowlisted where they are read**, not sanitised where they are used.
  `check-updates.sh` filters both `CURRENT_TAG` and `LATEST_TAG` through `^v[0-9]+\.[0-9]+\.[0-9]+$`
  at capture, so a value that is not a well-formed release tag never enters the script. That closes
  all three sinks at once — the `sed` address 1.8.0 patched, the `git log` argv position it did not
  (a tag named `--output=<path>` is a valid refname and git parses it as an option, giving an
  attacker-chosen file write with attacker-influenced content), and the copy-pasteable commands the
  script prints, where `';id>…;'` closed the quoting. Case 28 creates both hostile tags upstream and
  asserts nothing is executed and nothing is echoed.
- **The hook's containment check was bypassable by symlinks.** It resolved the dirname without `-P`,
  so a symlinked directory inside the tree and a symlinked file both passed and reached the
  dispatch — inert only because every check ships commented out. Symlinks are now refused outright,
  and `pwd -P` handles symlinked directories.
- **`qa.sh` reintroduced two classes 1.8.0 had just fixed elsewhere**, in the script written to
  consolidate the gate: `cd "$(git rev-parse --show-toplevel)" || exit 2` is dead code because
  `cd ""` succeeds, so outside a git repo it ran the whole gate in the wrong directory and exited 1
  instead of 2; and it parsed no arguments, so `qa.sh --dry-run` ran everything and exited 0.

### Fixed — a portability defect the new tests exposed

- **All five scripts compared a logical path against a physical one.** `cd … && pwd` keeps the
  logical form while `git rev-parse` returns the resolved one, so on macOS any project reached
  through a symlink — `/tmp`, `/var/folders`, a symlinked home — failed the "is this a consumer
  install" guard and the scripts refused to work in a perfectly valid checkout. Now `cd -P` /
  `pwd -P` throughout, and the git side normalised too. Found by a sandbox test, not by reading.

### Fixed — legibility

- `check-install.sh` exited 1 under a banner reading `❌ Cannot verify` while its own header
  reserves 2 for "cannot tell". Now 2, and case 16 asserts it.
- The `missing:`/`differs:` detail lines printed before the finding they belong to, reading as
  continuation of the previous one. Collected and printed after it.
- `init-project.sh` and `uninstall.sh` document their exit codes, and a bad flag exits 2 everywhere
  rather than 1 in one script and 2 in the other three.
- The hook now reports when a parser exists but the payload is unreadable — previously it exited 0
  in silence, the same failure as having no parser, which 1.8.0 fixed only for the parser-absent half.

### Fixed — two tests of my own that could not fail

- **Case 22 asserted how many paths the gate counted, never that it caught a broken one** — a
  vacuous pass inside the case written to kill vacuous passes. It now injects three real defects (a
  dangling framework path, a retired command, a `VERSION`/`CHANGELOG` mismatch) and requires a
  failure for each. Its retired-command literal is assembled at runtime, because written out it
  would be caught by the very check it asserts.
- **Case 20 had a fallback arm that passed with a different message**, so it passed either way. The
  arm is gone.
- Case 28 was itself vacuous on first run: git refuses a refname containing `..` or a space, so
  neither hostile tag was created and every assertion passed against an attack that was not there.
  It now asserts the tags exist before asserting they are harmless.

### Added

- **A real submodule fixture.** `check-updates.sh` was covered for 2 branches of ~19 — measured by
  execution trace, not by reading — so everything from the fetch onwards was unreachable, including
  1.8.0's security fix, which shipped with no test. `new_submodule_project()` stands up a local
  upstream with tags and a consumer with a genuine git submodule, and case 28 exercises the upstream
  half through it.
- Cases 23–27 close the mutants the re-audit found surviving: a project's `.gitattributes` appended
  rather than replaced on install, a project-owned file in `.claude/hooks/` surviving uninstall, a
  legacy include not on its own line reported rather than announced as migrated, both mutating
  scripts refusing a non-git directory with a reason, and the hook speaking when it has no parser.
- **Check 9 — gate composition.** `qa.sh` fixed the CLAUDE.md-vs-CI drift and opened a qa.sh-vs-CI
  one: CI re-declares the same checks as jobs and nothing tied them, so a fifth job would silently
  falsify both the script and the documentation. The check compares the two and found its own first
  defect immediately — an anchored pattern counted two of four `run` calls. `qa.sh` no longer
  hardcodes "four" either; it counts.
- `.github/` is now inside the consistency corpus for path resolution.

### Still standing, and named

Category 8 will not reach 8/10 until the CI supply chain is hardened: `curl | tar` with no checksum,
actions on floating major tags rather than SHAs, and three registry fetches with version pins but no
integrity pins. Category 4 will not move much further without a formatter, a metric threshold, and
`check-consistency.sh` growing tests for the checks case 22 does not cover. Category 10 is untouched:
no ADRs, no `CONTRIBUTING.md`, `main` unprotected, no pull requests. None of these is a defect a
consumer hits.

## [1.8.0] — 2026-09-03

`/project-audit` was run on this repository — its first real execution — and the ten scoring agents
found what reading had not. Scores: Cat 2 7/10, Cat 4 6/10, Cat 6 8/10, Cat 7 7/10, Cat 8 6/10,
Cat 9 7/10, Cat 10 6/10; Cats 1, 3 and 5 N/A. This release fixes everything the audit surfaced that
a user could hit, and records what was deliberately deferred.

### Fixed — the upgrade path

Five of the six critical defects were in `init-project.sh` and `uninstall.sh`: the two commands
every consumer runs to update.

- **`init-project.sh` printed `❌ Install is not conformant` and exited 0.** The error message was
  followed by sixty lines of `echo`, and the last command set the status — so in the `&&` chain the
  README documents, the installer could not fail, and could not gate a CI job. It now propagates the
  conformance result.
- **It announced `✓ Migrated @-include` for a migration that had not happened.** The branch is
  chosen on a substring match while the rewrite was anchored, so a legacy include line with trailing
  whitespace took the path and matched nothing. The rewrite now tolerates surrounding whitespace and
  the result is verified before it is reported.
- **An uninitialised submodule produced a raw `cp: ... No such file or directory`.** The glob guard
  that `check-install.sh` and `uninstall.sh` both had was missing here — the same defect class 1.7.2
  fixed in the checker, in the installer.
- **Outside a git repository both mutating scripts died with `fatal: not a git repository`, exit
  128.** Both now detect it and explain what they needed it for.
- **`init-project.sh` located `check-install.sh` via `git rev-parse --show-toplevel`.** Run from
  another checkout it would have installed into that project and executed *its* copy of the checker.
  Both mutating scripts now derive their paths from `$0`, as the read-only scripts already did.
- **`uninstall.sh` ignored every argument it was given** — `--dry-run` performed a real uninstall in
  silence. It now refuses unknown options and says there is no dry run.
- `set -u` added to both mutating scripts. They were the only two without it: the scripts that
  delete and rewrite a consumer's files were the ones where an unset path variable expanded to empty.

### Fixed — security

- **A tag name from the remote reached a `sed` address.** `check-updates.sh` interpolated
  `$CURRENT_TAG` — from `git describe` over just-fetched refs — into `sed -n "/^$CURRENT_TAG$/,$p"`.
  Git permits `/ $ ( ) { } ; \ | #` in a ref name, which is enough to close the address and reach
  GNU sed's `e` command, which executes a shell; verified empirically (BSD sed refuses, GNU does
  not). Reaching it needs a hostile upstream tag, and that access already grants execution through
  the installer — so this was a broken pattern rather than a crossed boundary, but a network-derived
  string reached an interpreter. Replaced with an `awk` fixed-string comparison: no regex, no
  interpreter.
- **The hook stub silently did nothing when neither `jq` nor `python3` was present**, and looked
  healthy doing it — `--selftest` also printed nothing and exited 0, so the check whose stated job
  is to prove the reporting path works reported a false pass. Four of the ten agents found this
  independently. The no-parser case now emits the context envelope by hand (its message is a literal,
  so it needs no escaping) and says that no checks ran; `--selftest` exercises the extraction path,
  not only the reporting path.
- **The hook claimed a containment check it did not have.** Its comment said the guard rejected
  paths outside the project; it tested `-f` only, so a payload naming `~/.ssh/config` passed through
  to whatever the consumer had enabled. There is now a real containment check against the project
  root, and every example invocation passes `--` before the path so a file named `-x.php` cannot
  arrive as an option.

### Fixed — the framework's own claims

- **`CLAUDE.md` asserted "shellcheck clean, no exceptions" against five live `disable=SC2086`
  directives** — a false statement in the file loaded into every session of this repo. Corrected,
  and each directive now carries its reason.
- **`scripts/qa.sh`: the gate is one command.** It was three commands in `CLAUDE.md`, the same three
  in `README.md`, and four jobs in CI — and the documented three omitted markdownlint, so a
  developer running the gate exactly as written could still go red. The framework authored
  subcriteria 7.7 and did not satisfy it. `qa.sh` runs all four and reports which it could not run
  rather than passing silently; both documents now point at it instead of restating the list.
- **`.claudeignore` excluded `.github/`** — hiding the one file that declares every pinned tool
  version from the traversal protocol the framework mandates, while 6.9 asks about exactly those
  pins.
- **`/project-audit` hard-coded the N/A escape hatch for Categories 3 and 5 only**, while
  `INSTRUCTIONS.md` lists Cat 1 as "Always evaluated: Yes". An agent scoring OOP on a shell-only
  project had to infer the permission; this one did, another might have invented a score. Any
  category can now be N/A under the standard's own rule.
- **`/project-audit` said the audit report is "meant to be committed" without qualification.** A
  report names security weaknesses with file and line. In a private repository the history is the
  point; in a public one it is a disclosure. The command now requires asking whether the repository
  is public before recommending a commit, and offers the alternatives.
- `skill` was used for command files in user-facing output while the directory, `CLAUDE.md` and
  `check-install.sh` said *command* — and `skill` was overloaded in one file for both a command file
  and a developer competency. Two comments describing behaviour the code no longer had, corrected.

### Added — tests for the mutants that survived

The Testing agent ran mutation tests rather than reading, and three mutants survived a green suite,
all on data-loss paths. Cases 17–22 close them: the prepend-to-existing-`CLAUDE.md` branch (the most
common real install, previously untested), preservation of a developer-edited specialization file
across a second run, `.gitattributes` line-stripping versus deletion, the installer's exit code, the
uninstaller's argument handling, and a guard against `check-consistency.sh` passing vacuously — the
gate script that catches everyone else's drift had no test of its own.

### Deferred, deliberately

Recorded here because 2.7 asks for debt *carried*, not only debt prevented: no `scripts/lib/`
(reading `VERSION` is written in four places, the consumer-install guard in two), the longer scripts
are still comment-divided procedures rather than functions, CI runs Linux only while the `sed`
portability bug is a BSD one, and the version-control half of Category 10 is untouched — no ADRs, no
`CONTRIBUTING.md`, `main` verified unprotected, no pull requests. None is a regression; all are real.

### Note on the tooling

Two defects in `/project-audit` itself were found before the agents were launched and fixed first:
`common.md` carried the entire 2,100-line standard for all ten agents to read — 31k tokens each,
which is the duplication the 1.0.0 rewrite claimed to have removed, moved from the source to the
standard — and the manifest's `find` matched only application languages, returning zero files on a
shell-and-documents project. The framework is now sliced per category, and the manifest covers shell
and reports honestly when a project has no application source.

## [1.7.2] — 2026-09-03

A pre-release pass over the batch shipped today, looking for defects rather than scoring quality.
Four found, all of them things a user would have hit.

### Fixed

- **`/competency-review` could not write the profile it exists to update.** Its frontmatter declared
  `allowed-tools: [Read, Bash]` while step 4 of the command applies the confirmed changes to
  `~/.claude/context/user_profile.md`. The command has been unable to complete since it was written,
  in every release. Now `[Read, Write, Edit, Bash]`. `/project-audit` gained `Edit` for the same
  reason: it appends a row to `docs/audits/history.md`.
- **The breaking-change report was unreachable in the documented upgrade order.** The four-step
  sequence runs `init-project.sh` before `check-install.sh`, and the installer overwrites the version
  marker — so by the time the check ran there was nothing left to compare against, and the feature
  introduced in 1.7.0 could never fire. `check-install.sh` now accepts `--compare-from <version>`,
  and `init-project.sh` captures the marker before overwriting it and passes it through. The report
  now arrives at the moment of transition, and a later standalone check does not repeat it.
- **A missing `.claude/ export-ignore` was an error, which was wrong.** It made `check-install.sh`
  exit 1 with "the framework is not working as installed" over deploy hygiene that is irrelevant to
  a project which never packages with `git archive`. False alarms are how a checker gets ignored.
  Downgraded to a warning that says why it might not apply.
- **An uninitialised submodule read as conformant.** `git clone` without
  `--recurse-submodules` leaves `.claude/framework` an empty directory, and every check then passed
  vacuously — zero commands compared equal to zero commands, so `check-install.sh` reported
  "All 0 commands installed and identical" and exited 0 on an install that contained nothing. It now
  refuses early, names the likely cause, and gives `git submodule update --init --recursive`. This is
  probably the most common way to reach a broken install, and it was the one the checker was
  most confident about.
- **Seven independent "flag once at session start" instructions had accumulated.** No single release
  added more than one, so none of them looked like a problem: stale command copies, an upstream
  release, a missing profile, a review due, two absent specialization files, no `.claudeignore`, a
  stale audit. A freshly installed project would have opened every session with five warning blocks
  before answering anything. `INSTRUCTIONS.md` now governs them as inputs to a single notice: one
  block, three lines maximum, most consequential first, once per session — and the developer's
  question comes first, because a setup notice is never worth delaying an answer.

### Added

- A test case for the upgrade-order interaction, since it is the kind of defect that only appears
  when two correct components run in a particular sequence.

### On the end-to-end path

The upgrade was exercised for real before release: a consumer project with an actual git submodule,
installed at `v1.0.0`, upgraded through the documented four steps to the current version, verified
conformant. That run is what surfaced the marker-ordering defect — the earlier sandbox tests all
copy the framework rather than pin it, so none of them reproduced the sequence a user follows.

## [1.7.1] — 2026-09-03

### Fixed

- **`init-project.sh` still told people to upgrade with `git pull origin main`** — the pre-1.0 path,
  replaced by pinned tags in 1.0.0, and omitting `check-install.sh` entirely. It survived seven
  releases in the installer's own closing output: the one place every new install reads. This is
  principle 22 failing inside the release that introduced 7.10 — the model changed and the text
  describing it did not.
- `git pull origin main` is now in `check-consistency.sh`'s retired-pattern list, so the
  contradiction cannot reappear. Its failure message no longer assumes the only retired things are
  the two old filenames.

### Added

- **The upgrade procedure now reaches Claude, not only human readers.** The README carried the four
  steps from 1.7.0, but the framework's README is never `@`-included — a consumer session loads only
  `INSTRUCTIONS.md`, where the three scripts were mentioned in three separate places with no ordered
  sequence. Asked to upgrade, Claude would have had to reconstruct the order and could plausibly
  have skipped the verification step. `INSTRUCTIONS.md` now carries the four commands in order, the
  invariant that makes them matter, and the instruction to report what the check said rather than
  declare success.

The split between the two documents is deliberate: `INSTRUCTIONS.md` gets the commands and the
order, the README keeps the rationale and the comparison table. Duplicating the reasoning in both
would be a second copy to drift — which is the defect this release exists to fix.

## [1.7.0] — 2026-09-03

Updating the submodule was never sufficient, and nothing said so. Two things live outside it — the
`@`-include in the project's `CLAUDE.md` and the command copies in `.claude/commands/` — so a
project could pull v1.6.0, commit the bump, and run a framework that loads nothing at all. The
1.0.0 `@`-include split made that failure mode concrete, and it was recoverable only by re-running
the installer, which mutates and therefore cannot be used to *check*.

### Added

- **`scripts/check-install.sh`** — read-only conformance of an install against the version it has
  checked out. Safe in CI, safe to run any time. It verifies the `@`-include is present and is not
  the pre-1.0 one, that the command copies are **byte-identical** to the version (a marker can be
  accurate while a file was hand-edited), the version marker, the specialization files, that a wired
  hook still has its script, `.claudeignore`, and the `git archive` exclusion. Every failure prints
  the command that fixes it. Exit 0 conformant, 1 errors, 2 cannot tell.
- **Breaking-change reporting.** When the recorded install version differs from the current one,
  `check-install.sh` names the releases in between whose changelog entry has a `### Breaking`
  section — so the entries that need reading are identified rather than hunted for.
- An "Upgrading an existing install" section in the README with the four-step sequence and a table
  of which script answers which question.

### Changed

- `init-project.sh` no longer carries its own verification block: it calls `check-install.sh` and
  reports its exit code. The conformance rules now exist in exactly one place, which is also the
  place a developer can run without changing anything.
- `check-updates.sh` recommends `check-install.sh` after an upgrade, closing the loop between
  "a newer version exists" and "the upgrade actually took".

### Why not a version-by-version upgrade path

`init-project.sh` is idempotent and migrates from any earlier state, so a stepped path would be
machinery for a problem that does not exist — you can go from any older version straight to the
newest. And the conformance rules ship *inside* each version rather than in a separate migration
matrix: checking out `v1.7.0` gets you `v1.7.0`'s checks, with no lookup table that could itself go
stale. Release notes were never the missing piece either; the CHANGELOG already had them. What was
missing was a way to verify, and a way to be told which entries apply to you.

### Why this is a script and not a slash command

The commands are copies in `.claude/commands/`. A `/framework-doctor` command would be one of the
stale copies it is meant to diagnose — it cannot be relied on to report that it is itself out of
date. Invoked by path from the submodule, the checker is always the version the submodule holds.

## [1.6.0] — 2026-09-03

Documentation currency was almost entirely uncovered: 10.15 scored ADRs, 2.5 scored self-documenting
*code*, and two incidental lines mentioned `CONTRIBUTING.md` and a hand-written CHANGELOG. Nothing
asked whether the README still works, whether an API contract matches the routes, or whether
*anything* notices when a document stops being true. `OpenAPI` did not appear in the document at all.

### Added

- **7.10 Documentation currency and drift detection.** Not how much is written — whether anything
  keeps it true. It sits in Category 7 because the criterion is about a mechanism, and a quality that
  relies only on remembering is the gap 7.7 already names. What counts is making the documentation's
  factual claims executable: paths that resolve, a README setup path that runs in CI, an API contract
  generated from the routes or held by a contract test, generated docs whose stale diff fails the
  build. Scoring anchor: **thin but true documentation with a check that keeps it true scores above
  extensive documentation with no mechanism.**
- **Principle 22 — Documentation is part of the change that invalidated it.** Narrower than "write
  documentation": you renamed the make target, so rename it in the README, in that commit. The only
  moment anyone reliably knows which documents a change has falsified is the moment they make it. It
  also asks for claims a machine can check — name the command rather than describing it.
- **Session behaviour for the AI-facing half** (`INSTRUCTIONS.md`): update an instruction file in the
  same change that invalidates it and say so; and when a file contradicts the code, stop rather than
  guess.

### Why the AI-facing half is called out separately

The two audiences fail differently, and the quieter one fails worse. A stale README is read by a
person who runs the wrong command, notices, and goes to look at the code — expensive, but
self-revealing. `CLAUDE.md` and `.claude/*` are loaded into every session and applied as fact by a
reader who never questions them and never reads them end to end. A `.claude/CODING_STANDARDS.md`
naming an analyser level the project has left, or a layer rule its config no longer enforces, shapes
every future proposal with nobody disagreeing. 7.10 therefore weights that half at least as heavily
as the human one.

### The ambiguity that must not be resolved silently

An instruction file contradicting the config has two readings with opposite fixes: the document is
**stale** (the code moved, fix the document) or **aspirational** (the project decided to reach this,
fix the config). `.claude/CODING_STANDARDS.md` naming PHPStan level 8 while `phpstan.neon` says 6 is
exactly that. Claude is now told to name the contradiction and both readings and ask — because
picking one would quietly undo a decision — while following the code for what is currently true.

## [1.5.0] — 2026-09-03

Dependency updates were covered unevenly: 7.4 scored whether dependencies are *vulnerable*, 6.7
flagged an end-of-life *framework*, 6.8 mentioned abandoned forks. Nothing asked whether the
dependencies are current, whether the runtime is supported, or whether an upgrade is still possible
at all. Submodules appeared nowhere in the document.

### Added

- **6.9 Dependency currency and upgrade path.** The measure is not "how new" but "how far, and is
  the road still open". Its most valuable question is which single dependency closes the road for
  all the others — a package pinning `php <8.2` blocks the runtime and through it every other
  upgrade, and that is a structural constraint rather than a ranking of staleness. Also covers the
  runtime, base image and database engine as dependencies with support windows, and submodules as
  dependencies no package manager watches: a pin is fine, a pin nobody can name is a dependency
  frozen by accident. Scoring weights the blocker and the EOL above ordinary staleness — being
  behind is a cost, being unable to move is a risk.
- **Principle 14 extended** to the write-time half: check that a dependency is still alive before
  adding it, not only that it fits. Release history, archived status, and what it constrains — a
  package that pins an old runtime does not just age, it freezes everything else.
- **`scripts/check-updates.sh`** — the real check, closing the framework's own instance of 6.9. The
  existing session-start check compared the copied commands against the *pinned* submodule, so a
  project sitting on `v1.0.0` looked perfectly consistent while four releases had shipped. The new
  script answers both levels, lists the releases in between with their commit subjects, prints the
  upgrade commands, and warns when the submodule follows a branch, is pinned to an untagged commit,
  or has uncommitted local edits that an upgrade would discard. Exit codes: 0 nothing to do, 1
  action recommended, 2 cannot tell.
- **A local-only session check** in `INSTRUCTIONS.md`: Claude compares the pin against tags already
  fetched and points at the script. It never runs `git fetch` on its own — a session start is not
  the place for a network call the developer did not ask for.

### Fixed

- `check-updates.sh` trusted `git -C <framework> rev-parse`, which walks up to a parent repository.
  With the framework copied rather than added as a submodule, every git query answered from the
  *project's* repo — so it would have compared the project's tags against the framework's version
  and produced confident nonsense. It now requires the repository found to be the framework's own.
  Caught by a new case in `test-install-cycle.sh`, whose sandbox reproduces exactly that layout.

## [1.4.0] — 2026-09-03

7.9 and 9.8 shipped in 1.3.0 with nothing to read. Configuration records what a project *intends*: a
migration declares an index, and whether that index exists in the database — and whether the planner
chooses it — are two further questions. Both criteria needed a way to be answered from reality, and a
rule for what happens when there is none.

### Added

- **Precondition 4 — database access must be declared, or its absence acknowledged.** With a
  representative database, 7.9 and 9.8 are answerable. Without one they are scored from intent, the
  evidence says so, and **neither may exceed 8**: an unverified claim is not comprehensive evidence.
  Recording the limit is the point — a score that hides it is worse than a lower score that explains
  itself.
- **A `Database access for query analysis` section in the project framework template** — the command
  to reach it, which environment, what volume, what the grant allows, and what is out of bounds. Or
  the explicit statement that none is available.
- **Phase 1.4 of `/project-audit`** captures index inventory, row counts, the engine's aggregated
  statement statistics, the slow-query settings actually in effect, and `EXPLAIN` plans for the query
  paths in question — only when declared, and never by hunting for credentials in `.env` files.
- **Usage rules in `INSTRUCTIONS.md`**, all hard: never read application data; `EXPLAIN` not
  `EXPLAIN ANALYZE` unless the statement is a plain `SELECT` against a non-production target; nothing
  that writes, not even to test whether the grant would refuse; never put row data in the evidence
  bundle, which ten agents read; never print the connection string; ask before anything outside the
  list.

### Note on scope of access

The access this needs is **narrower than read-only**, which is worth stating because "at least read
access" invites a wider grant than the job requires. Query analysis reads schema and statistics —
`information_schema`, index inventory, `EXPLAIN`, row counts, `pg_stat_statements` — and almost
nothing in 7.9 or 9.8 requires a single row of application data. So the grant should not permit
reading it, and the template's example grant does not.

The environment matters as much as the grant: a development database with two hundred rows produces
query plans that are worse than no evidence, because they look like evidence. Representative volume
is what makes a plan mean anything, and an anonymised replica gets there without handing an agent
production.

## [1.3.0] — 2026-09-03

Covers data-access cost, which the framework measured nowhere. A project could score 8/10 across all
ten categories while running an N+1 that issues 400 queries for one list, an unindexed `WHERE` on a
two-million-row table, and an unpaginated `findAll()` — with no slow query log to notice any of it.
The only prior mentions were incidental: N+1 as an argument *for* using a mature ORM (6.8), a
`latency_ms` field in a health-check example (9.3), and a 200ms fitness function named in passing
(10.9). None of them produced a finding.

### Added

- **7.9 Query analysis in the quality gate** — data-access defects are the one class that reading
  code does not reliably find, because the defect is not in any single line: an N+1 is a loop in one
  file and a lazily loaded association declared in another, each correct alone. What finds it is
  counting queries. The criterion asks for query-count assertions on the routes that matter, a
  lazy-load guard that raises in dev and test (`preventLazyLoading`, `nplusone`, `bullet`), indexes
  shipped in the change that needs them, and `EXPLAIN` run at realistic volume. It also rejects
  duration assertions on a developer machine: those measure the laptop, not the query plan.
- **9.8 Slow query visibility** — a query that was fast at ten thousand rows and takes four seconds
  at two million degraded in public while nobody measured. Requires a threshold tuned to the
  application rather than the engine's 10-second default, attribution to the request or job that
  issued the query, aggregation by query shape (one fingerprint at 4,000 executions is the finding,
  per-execution lines hide it), **p95 and p99 rather than the mean**, row counts alongside duration,
  and somebody actually reading it.
- **Principle 21 — Know the cost of your data access.** The write-time counterpart, mapped to 7.9
  and 9.8. Its rule is not "optimise early" but "be able to say how this query behaves at a hundred
  times the current row count": no query inside a loop, every collection read bounded, aggregation
  where the data is, and an index shipped in the change that introduces the query path.
- The audit's shared evidence bundle now includes database and ORM configuration — small files, and
  the only evidence 7.9 and 9.8 have.

### Note on shape

Performance is arguably a quality dimension in its own right, and this release deliberately does not
give it a category. Data-access defects are design defects, detectable by reading code and counting
queries, so they sit where the framework already puts detection (Cat 7) and visibility (Cat 9), with
a principle for the code shape — the same three-part structure used for security and observability.
The ten categories stay ten. Broader performance work (load behaviour, latency budgets, caching
strategy) remains uncovered, and would need its own category.

## [1.2.1] — 2026-09-03

### Fixed

- **2.8's declaration was repository-global, which authorised the leak it should catch.** The same
  concept legitimately carries different names in different bounded contexts: `Invoice` in a generic
  payments core, `FatturaElettronica` in a module implementing Italian e-invoicing law — there the
  English word names a superset. With a flat glossary, `FatturaElettronica` appearing in the payments
  core read as a declared exception rather than as a concept that crossed a boundary without being
  translated. The Domain language table now carries a **Context** column, a term is correct only
  inside its context, and 2.8 weights a boundary leak above a local naming slip: the first says the
  architecture is eroding, the second says someone was in a hurry.

### Changed

- **The test is now stated explicitly and scoped:** *in this context, does the English word name the
  same thing?* Yes → English; broader, narrower or different → keep the original term. It replaces
  the unfalsifiable "is this domain jargon", and being context-local is what makes two names for one
  concept correct rather than an inconsistency to unify.
- **Seams are named as where this actually breaks.** Half-translated identifiers
  (`getFatturaList()`, `ElectronicInvoiceFattura`) appear almost exclusively at context boundaries,
  where the translation was spread across renamed fields instead of living in a named mapper.
- **Not translating means keeping the domain's grammar.** *FatturaElettronica* is the document,
  *FatturazioneElettronica* the process: a module may be named for the process, an entity may not.
  A compound the domain does not use loses exactly what a translation would have lost.
- One term, one spelling: declaring `FatturaElettronica` rules out `fattura_elettronica` and
  `FattElettr` elsewhere. A glossary row with a meaning but no reason is called out as declaring
  nothing.
- `INSTRUCTIONS.md` now has Claude establish which context a file belongs to *before* consulting the
  glossary, and names the two failure modes that look like tidying: harmonising two names that belong
  to two contexts, and inventing a compound the domain does not use.

## [1.2.0] — 2026-09-03

Adds the language dimension the framework had no opinion on: code in English, domain terms in their
own language, and the exceptions declared rather than improvised.

### Added

- **Subcriteria 2.8 — Language of identifiers.** Code is written in English; domain terms whose
  meaning translation would destroy are kept in their original language and declared. Covers
  identifiers, comments, test names, developer-facing messages and technical documentation.
  Explicitly does *not* cover user-facing text, which belongs to the product's language and is an
  internationalisation concern. A uniformly English codebase with nothing to declare scores full
  marks with no glossary — the criterion measures consistency and intent, not paperwork.
- **Principle 20 — Code speaks English, the domain speaks its own language.** The write-time
  counterpart, mapped to 2.8 in the traceability table.
- **A `Domain language` section in the project `CODING_STANDARDS.md` template** — the declaration
  mechanism: one row per term kept in the local language, with the reason it is not translated. The
  template says to delete the section outright if the codebase is uniformly English.
- **Session behaviour for the cases the glossary does not settle** (`INSTRUCTIONS.md`): a needed term
  that is not declared gets proposed, never used silently and never translated when translation
  loses precision; existing code that disagrees with the glossary is matched for new code and
  flagged rather than propagated.
- An optional non-ASCII-identifier check in the hook stub — the one mechanically detectable part of
  2.8, since accented characters in identifiers are never intentional and break greps and tooling.

### Why both halves of the rule are needed

English-only would be simpler and wrong. A *Codice Fiscale* is not a tax code and a *Cedolino* is not
a payslip: these are legally defined artefacts, and translating them discards the precision the
domain depends on — the ubiquitous language of Category 3 outranks uniformity. Equally, a codebase
where `getUtenti()` sits beside `findOrders()` makes every reader guess which convention applies.
The declared list is what lets both rules hold at once, and 2.8 scores the glossary too: one that has
grown to cover every local word is an amnesty for not renaming, not a glossary.

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
