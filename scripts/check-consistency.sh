#!/bin/bash
# check-consistency.sh — the framework's quality gate.
#
# This repo ships documents whose paths are load-bearing: a consumer project resolves
# `.claude/framework/...` references at session start, so a stale path is a live defect
# rather than a typo. Every check below exists because the corresponding mistake was
# actually made during a past migration.
#
# Run from the repo root:  bash scripts/check-consistency.sh

set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

FAILURES=0
CHECKS=0

fail() {
    echo "  ✗  $1"
    FAILURES=$((FAILURES + 1))
}

pass() {
    echo "  ✓  $1"
}

start() {
    CHECKS=$((CHECKS + 1))
    echo ""
    echo "[$CHECKS] $1"
}

# indent <text> — prefix every line, so matched lines nest under the finding above.
indent() {
    local pad="       "
    printf '%s%s\n' "$pad" "${1//$'\n'/$'\n'$pad}"
}

# The corpus under scrutiny: documents that describe the framework as it is *now*.
#
# Two files are deliberately excluded, because both must be able to name things this
# script forbids elsewhere:
#   CHANGELOG.md          — a historical record; it names retired paths on purpose
#   check-consistency.sh  — this file; it defines the forbidden patterns
DOCS=$(git ls-files '*.md' | grep -v '^CHANGELOG\.md$')
SCRIPTS=$(git ls-files 'scripts/*.sh' | grep -v 'check-consistency\.sh$')

echo "────────────────────────────────────────────────"
echo "🔍 claude-audit-framework consistency check"
echo "────────────────────────────────────────────────"

# ── 1. Names retired by past migrations must not reappear ────────────────────

start "Retired names"

# `git pull origin main` was the pre-1.0 upgrade path, replaced by pinned tags.
# It survived in init-project.sh's own output for seven releases.
RETIRED='CODE_QUALITY_STANDARDS|~/\.claude/standards|git pull origin main'
# shellcheck disable=SC2086
if MATCHES=$(grep -nE "$RETIRED" $DOCS $SCRIPTS 2>/dev/null); then
    fail "a name or command retired by a past migration reappeared — see the RETIRED pattern above for what replaced it"
    indent "$MATCHES"
else
    pass "no retired names"
fi

# ── 2. Commands are copies, never symlinks ───────────────────────────────────
# Claude Code does not follow symlinks. Documentation claiming otherwise sent
# developers looking for links that were never created.

start "Symlink claims"

SYMLINK_CLAIM='(creates?|create|via|using|through) symlinks?'
# shellcheck disable=SC2086
if MATCHES=$(grep -nEi "$SYMLINK_CLAIM" $DOCS $SCRIPTS 2>/dev/null); then
    fail "documentation claims symlinks are used — commands are copied, because Claude Code does not follow symlinks"
    indent "$MATCHES"
else
    pass "no symlink claims"
fi

# ── 3. Scripts must edit files portably ──────────────────────────────────────
# `sed -i` takes an argument on BSD (macOS) and none on GNU: either spelling
# breaks on the other platform. Use a temp file + mv.

start "Script portability"

# Comment lines are excluded: explaining why `sed -i` is avoided is not using it.
# shellcheck disable=SC2086
if MATCHES=$(grep -nE '\bsed -i\b' $SCRIPTS 2>/dev/null | grep -vE ':[0-9]+:[[:space:]]*#'); then
    fail "'sed -i' is not portable between BSD and GNU sed — use a temp file + mv"
    indent "$MATCHES"
else
    pass "no in-place sed"
fi

# ── 4. Every framework path cited in a document must exist ───────────────────
# A consumer resolves `.claude/framework/<path>` against this repo's root.

start "Framework path references"

BROKEN=0
# shellcheck disable=SC2086
CITED=$(grep -rhoE '\.claude/framework/[A-Za-z0-9_./*-]+' $DOCS 2>/dev/null |
        sed 's|^\.claude/framework/||' |
        sed 's/[.,:;`)]*$//' |
        sort -u)

for path in $CITED; do
    case "$path" in
        ''|*'*'*) continue ;;   # bare prefix or glob — nothing to resolve
    esac
    if [ ! -e "$path" ]; then
        fail "cited as .claude/framework/$path but no such file in this repo"
        BROKEN=$((BROKEN + 1))
    fi
done

[ "$BROKEN" -eq 0 ] && pass "all $(echo "$CITED" | wc -l | tr -d ' ') cited framework paths resolve"

# ── 5. Every repo-relative path cited in a document must exist ───────────────

start "Repo-relative path references"

BROKEN=0
# shellcheck disable=SC2086
CITED=$(grep -rhoE '\b(standards|templates|commands|scripts)/[A-Za-z0-9_./*-]+' $DOCS 2>/dev/null |
        sed 's/[.,:;`)]*$//' |
        sort -u)

for path in $CITED; do
    case "$path" in
        *'*'*) continue ;;      # glob — nothing to resolve
    esac
    if [ ! -e "$path" ]; then
        fail "cited as $path but no such file in this repo"
        BROKEN=$((BROKEN + 1))
    fi
done

[ "$BROKEN" -eq 0 ] && pass "all $(echo "$CITED" | wc -l | tr -d ' ') cited repo paths resolve"

# ── 6. The @-include target must be the file consumers actually get ──────────

start "@-include target"

INCLUDE_TARGET=$(grep -m1 -oE '^@\.claude/framework/[A-Za-z0-9_.-]+' templates/project-CLAUDE.md 2>/dev/null |
                 sed 's|^@\.claude/framework/||')

if [ -z "$INCLUDE_TARGET" ]; then
    fail "templates/project-CLAUDE.md has no @-include line"
elif [ "$INCLUDE_TARGET" != "INSTRUCTIONS.md" ]; then
    fail "templates/project-CLAUDE.md includes $INCLUDE_TARGET — consumers must include INSTRUCTIONS.md, not the framework's own CLAUDE.md"
elif ! grep -qF '@.claude/framework/INSTRUCTIONS.md' scripts/init-project.sh; then
    fail "init-project.sh does not install the @-include that the template declares"
else
    pass "consumers include INSTRUCTIONS.md, and init-project.sh installs it"
fi

# ── 7. VERSION and CHANGELOG must agree ──────────────────────────────────────

start "Version and changelog"

if [ ! -f VERSION ]; then
    fail "VERSION is missing"
elif [ ! -f CHANGELOG.md ]; then
    fail "CHANGELOG.md is missing"
else
    VERSION=$(tr -d '[:space:]' < VERSION)
    LATEST=$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | tr -d '#[] ')
    if [ -z "$LATEST" ]; then
        fail "CHANGELOG.md has no '## [x.y.z]' entry"
    elif [ "$VERSION" != "$LATEST" ]; then
        fail "VERSION is $VERSION but the newest CHANGELOG entry is $LATEST — bump both in the same commit"
    else
        pass "VERSION and CHANGELOG agree on $VERSION"
    fi

    # The README tells people which tag to pin. A stale example pins them to a
    # version that predates whatever the rest of the README describes.
    STALE=$(grep -oE '\bv[0-9]+\.[0-9]+\.[0-9]+\b' README.md | sort -u | grep -vFx "v$VERSION" || true)
    if [ -n "$STALE" ]; then
        fail "README pins a version other than the current one ($VERSION)"
        indent "$STALE"
    else
        pass "README's pinned version matches VERSION"
    fi
fi

# ── 8. The traceability table must match both documents ─────────────────────
# CODING_STANDARDS.md maps each principle to the criteria that measure it. That
# mapping is the only cross-reference between the write-time and audit-time
# halves of the framework, so it is also the only place they can drift.

start "Traceability table"

PRINCIPLES=$(grep -oE '^## [0-9]+\.' standards/CODING_STANDARDS.md | tr -d '#. ' | sort -n)
MAPPED=$(sed -n '/^## Traceability/,$p' standards/CODING_STANDARDS.md |
         grep -oE '^\| [0-9]+ \|' | tr -d '| ' | sort -n)

if [ "$PRINCIPLES" != "$MAPPED" ]; then
    fail "the traceability table does not list every principle"
    indent "principles defined: $(echo "$PRINCIPLES" | tr '\n' ' ')"
    indent "principles mapped:  $(echo "$MAPPED" | tr '\n' ' ')"
else
    pass "all $(echo "$PRINCIPLES" | wc -l | tr -d ' ') principles appear in the traceability table"
fi

BROKEN=0
CITED=$(sed -n '/^## Traceability/,$p' standards/CODING_STANDARDS.md |
        grep -oE '\b[0-9]{1,2}\.[0-9]{1,2}\b' | sort -u -t. -k1,1n -k2,2n)

for ref in $CITED; do
    if ! grep -qE "^#### $ref " standards/PROJECT_AUDIT_FRAMEWORK.md; then
        fail "traceability cites subcriteria $ref, which is not a heading in PROJECT_AUDIT_FRAMEWORK.md"
        BROKEN=$((BROKEN + 1))
    fi
done

if [ "$BROKEN" -eq 0 ]; then
    pass "all $(echo "$CITED" | wc -l | tr -d ' ') cited subcriteria exist"
fi

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────────────"
if [ "$FAILURES" -eq 0 ]; then
    echo "✅ $CHECKS checks passed."
    exit 0
fi
echo "❌ $FAILURES failure(s) across $CHECKS checks."
exit 1
