#!/bin/bash
# check-install.sh — does this project's install satisfy the version it has checked out?
#
# Read-only. Changes nothing, so it is safe to run any time — in CI, in a hook,
# or just to answer "did the upgrade actually take?".
#
# Three scripts, three questions, no overlap:
#
#   check-updates.sh   is a NEWER version available?        (contacts the remote)
#   check-install.sh   is my install CONFORMANT with the     (read-only)
#                      version I already have?
#   init-project.sh    make it conformant.                   (mutates)
#
# The conformance rules live here rather than in a per-version migration matrix,
# because this script ships *with* the version whose requirements it encodes.
# Checking out v1.6.0 gets you v1.6.0's checks, for free and without a lookup.
#
# Run from anywhere in the project:
#   bash .claude/framework/scripts/check-install.sh
#
# Exit codes:  0 conformant · 1 errors found · 2 cannot tell

set -uo pipefail

# --compare-from <version>: report breaking changes since this version instead of
# since the recorded marker. init-project.sh passes the marker it is about to
# overwrite, so the report survives the documented upgrade order — running the
# installer first would otherwise leave nothing to compare against.
COMPARE_FROM=""
while [ $# -gt 0 ]; do
    case "$1" in
        --compare-from)
            [ $# -ge 2 ] || { echo "❌ --compare-from needs a version"; exit 2; }
            COMPARE_FROM="$2"; shift 2 ;;
        *) echo "❌ Unknown option: $1"; echo "   Usage: check-install.sh [--compare-from <version>]"; exit 2 ;;
    esac
done

# pwd -P: on macOS a path through a symlink (/tmp, /var/folders) keeps its logical
# form here while `git rev-parse` returns the physical one, and the two would not
# compare equal — the scripts then refused to work in a perfectly valid checkout.
SCRIPT_BOOTSTRAP_DIR=$(cd "$(dirname "$0")" && pwd)
if [ ! -f "$SCRIPT_BOOTSTRAP_DIR/lib/framework-paths.sh" ]; then
    echo "❌ $SCRIPT_BOOTSTRAP_DIR/lib/framework-paths.sh is missing."
    echo "   The framework checkout is incomplete — usually a partial or sparse checkout."
    echo "   → git submodule update --init --recursive"
    exit 2
fi
# shellcheck source=scripts/lib/framework-paths.sh
. "$SCRIPT_BOOTSTRAP_DIR/lib/framework-paths.sh"

framework_paths_init "$0"

COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"
VERSION_MARKER="$PROJECT_ROOT/.claude/.framework-version"
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"
HOOK_SCRIPT="$PROJECT_ROOT/.claude/hooks/on-file-edit.sh"

INCLUDE_LINE="@.claude/framework/INSTRUCTIONS.md"
LEGACY_INCLUDE_LINE="@.claude/framework/CLAUDE.md"

FRAMEWORK_VERSION=$(read_framework_version)

ERRORS=0
WARNINGS=0

# ── Is the submodule actually checked out? ───────────────────────────────────
# `git clone` without --recurse-submodules leaves .claude/framework an empty
# directory. Every check below would then pass vacuously — zero commands compare
# equal to zero commands — and report a broken install as conformant.

FRAMEWORK_HAS_COMMANDS=0
for f in "$FRAMEWORK_DIR"/commands/*.md; do
    [ -e "$f" ] && FRAMEWORK_HAS_COMMANDS=1 && break
done

if [ "$FRAMEWORK_HAS_COMMANDS" -eq 0 ]; then
    echo "  ✗  The framework submodule is not checked out — $FRAMEWORK_DIR has no commands"
    echo "     Nothing below can be verified against an empty framework."
    echo "     Usually a clone without --recurse-submodules."
    echo "     → git submodule update --init --recursive"
    echo "       bash .claude/framework/scripts/init-project.sh"
    echo ""
    echo "────────────────────────────────────────────────"
    # 2, not 1: the header reserves 2 for "cannot tell", and that is exactly this
    # case — nothing about conformance can be assessed against an empty framework.
    echo "❌ Cannot verify: the framework itself is missing."
    exit 2
fi

err()  { echo "  ✗  $1"; shift; for l in "$@"; do echo "     $l"; done; ERRORS=$((ERRORS + 1)); }
warn() { echo "  ⚠  $1"; shift; for l in "$@"; do echo "     $l"; done; WARNINGS=$((WARNINGS + 1)); }
ok()   { echo "  ✓  $1"; }

echo "────────────────────────────────────────────────"
echo "🩺 claude-audit-framework — install conformance"
echo "   project:   $PROJECT_ROOT"
echo "   framework: $FRAMEWORK_DIR ($FRAMEWORK_VERSION)"
echo "────────────────────────────────────────────────"
echo ""

# ── The @-include: the single point of failure ───────────────────────────────
# Everything the framework does in a session flows through this one line. A
# submodule updated without it is a submodule that does nothing at all.

if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    err "No CLAUDE.md at the project root" \
        "Nothing loads the framework into a session." \
        "→ bash .claude/framework/scripts/init-project.sh"
elif grep -qF "$INCLUDE_LINE" "$PROJECT_ROOT/CLAUDE.md"; then
    ok "CLAUDE.md includes $INCLUDE_LINE"
    if grep -qF "$LEGACY_INCLUDE_LINE" "$PROJECT_ROOT/CLAUDE.md"; then
        warn "CLAUDE.md also includes the pre-1.0 line $LEGACY_INCLUDE_LINE" \
             "That file is now the framework's own development guide, and would be" \
             "loaded into your sessions alongside the right one. Remove that line."
    fi
elif grep -qF "$LEGACY_INCLUDE_LINE" "$PROJECT_ROOT/CLAUDE.md"; then
    err "CLAUDE.md still includes the pre-1.0 line $LEGACY_INCLUDE_LINE" \
        "Since 1.0.0 consumers must include INSTRUCTIONS.md. As it stands, this" \
        "project loads the framework's development guide instead of its instructions." \
        "→ bash .claude/framework/scripts/init-project.sh    (rewrites the line)"
else
    err "CLAUDE.md does not include $INCLUDE_LINE" \
        "The framework is installed but nothing loads it into a session." \
        "→ bash .claude/framework/scripts/init-project.sh"
fi

# ── Command copies: present, and byte-identical to this version ──────────────
# The version marker can be right while a file was hand-edited, so compare
# content rather than trusting the record.

MISSING=0
STALE=0
TOTAL=0
DETAIL=""
for command_file in "$FRAMEWORK_DIR"/commands/*.md; do
    [ -e "$command_file" ] || continue
    TOTAL=$((TOTAL + 1))
    target="$COMMANDS_DIR/$(basename "$command_file")"
    name="/$(basename "$command_file" .md)"
    if [ ! -f "$target" ]; then
        DETAIL="$DETAIL
missing: $name"
        MISSING=$((MISSING + 1))
    elif ! cmp -s "$command_file" "$target"; then
        DETAIL="$DETAIL
differs: $name"
        STALE=$((STALE + 1))
    fi
done

# The detail lines are collected rather than printed as they are found: printed
# inline they appeared above the ✗ they belong to, and read as continuation of
# whatever finding came before.
if [ "$MISSING" -eq 0 ] && [ "$STALE" -eq 0 ]; then
    ok "All $TOTAL commands installed and identical to this version"
else
    err "$MISSING command(s) missing, $STALE differing from version $FRAMEWORK_VERSION" \
        "Commands are copies; updating the submodule does not refresh them." \
        "→ bash .claude/framework/scripts/init-project.sh"
    printf '%s\n' "$DETAIL" | sed '/^$/d; s/^/       /'
fi

# ── Version marker ───────────────────────────────────────────────────────────

if [ ! -f "$VERSION_MARKER" ]; then
    warn "No .claude/.framework-version" \
         "Installed before version tracking, or init-project.sh was never run." \
         "→ bash .claude/framework/scripts/init-project.sh"
    INSTALLED_VERSION=""
else
    INSTALLED_VERSION=$(read_marker_version)
    if [ "$INSTALLED_VERSION" = "$FRAMEWORK_VERSION" ]; then
        ok "Install was last run against $INSTALLED_VERSION, matching the submodule"
    else
        err "Install was last run against $INSTALLED_VERSION, submodule is $FRAMEWORK_VERSION" \
            "→ bash .claude/framework/scripts/init-project.sh"
    fi
fi

# ── Project specialization files ─────────────────────────────────────────────

for spec in PROJECT_AUDIT_FRAMEWORK.md CODING_STANDARDS.md; do
    if [ -f "$PROJECT_ROOT/.claude/$spec" ]; then
        ok ".claude/$spec present"
    else
        warn ".claude/$spec missing" \
             "→ cp .claude/framework/templates/$spec .claude/$spec, then fill it in"
    fi
done

# ── Hook coherence ───────────────────────────────────────────────────────────
# A wired hook whose script is gone is a dead entry: harmless, because the
# command ends in `|| true`, but it is not doing the job it was added for.

if grep -qF "on-file-edit.sh" "$SETTINGS_FILE" 2>/dev/null; then
    if [ ! -f "$HOOK_SCRIPT" ]; then
        err "settings.json wires the per-file hook, but .claude/hooks/on-file-edit.sh is missing" \
            "The hook runs and does nothing on every edit." \
            "→ bash .claude/framework/scripts/init-project.sh --with-hooks"
    elif grep -qE '^[[:space:]]*(vendor/bin|node_modules/\.bin|ruff|npx|php|python)' "$HOOK_SCRIPT"; then
        ok "Per-file check hook wired and configured"
    else
        warn "Per-file check hook wired but no checks enabled" \
             "→ edit .claude/hooks/on-file-edit.sh; verify with --selftest"
    fi
fi

# ── Project hygiene the framework depends on ─────────────────────────────────

if [ -f "$PROJECT_ROOT/.claudeignore" ]; then
    ok ".claudeignore present"
else
    warn "No .claudeignore — analysis will traverse dependency trees" \
         "Required before /project-audit. Exclude vendor/, node_modules/, build artefacts."
fi

if grep -qF ".claude/ export-ignore" "$PROJECT_ROOT/.gitattributes" 2>/dev/null; then
    ok ".claude/ excluded from git archive"
else
    warn ".claude/ not excluded from git archive — deploy tools may ship it" \
         "The framework still works; this is deploy hygiene, and irrelevant if you" \
         "never package with git archive." \
         "→ echo '.claude/ export-ignore' >> .gitattributes"
fi

# ── Breaking changes between the recorded install and this version ───────────
# init-project.sh migrates what it can. What it cannot — a new declaration, a
# decision only the developer can make — lives in the changelog, and this is
# where the relevant range gets surfaced instead of being hoped for.

FROM_VERSION="${COMPARE_FROM:-$INSTALLED_VERSION}"

if [ -n "$FROM_VERSION" ] &&
   [ "$FROM_VERSION" != "$FRAMEWORK_VERSION" ] &&
   [ -f "$FRAMEWORK_DIR/CHANGELOG.md" ]; then
    # Versions whose changelog entry has a "### Breaking" section...
    BREAKING_ALL=$(awk '
        /^## \[[0-9]+\.[0-9]+\.[0-9]+\]/ {
            match($0, /[0-9]+\.[0-9]+\.[0-9]+/)
            current = substr($0, RSTART, RLENGTH)
            next
        }
        /^### Breaking/ && current != "" { print current; current = "" }
    ' "$FRAMEWORK_DIR/CHANGELOG.md")

    # ...narrowed to those released after the recorded install, up to this version.
    BREAKING=""
    for v in $BREAKING_ALL; do
        [ "$v" = "$FROM_VERSION" ] && continue
        [ "$(printf '%s\n%s\n' "$FROM_VERSION" "$v" | sort -V | head -1)" = "$FROM_VERSION" ] || continue
        [ "$(printf '%s\n%s\n' "$v" "$FRAMEWORK_VERSION" | sort -V | head -1)" = "$v" ] || continue
        BREAKING="$BREAKING $v"
    done
    BREAKING=$(echo "$BREAKING" | tr -s ' ' | sed 's/^ //;s/ $//')

    echo ""
    if [ -n "$BREAKING" ]; then
        warn "Releases with breaking changes since $FROM_VERSION: $BREAKING" \
             "init-project.sh migrates what it can automatically; read those entries for" \
             "anything it cannot." \
             "→ sed -n '/## \\[$FRAMEWORK_VERSION\\]/,/## \\[$FROM_VERSION\\]/p' .claude/framework/CHANGELOG.md"
    else
        ok "No breaking changes recorded between $FROM_VERSION and $FRAMEWORK_VERSION"
    fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────────────"

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "✅ Install is conformant with version $FRAMEWORK_VERSION."
    exit 0
fi
if [ "$ERRORS" -eq 0 ]; then
    echo "✅ Conformant, with $WARNINGS warning(s) — the framework works, but not fully."
    exit 0
fi
echo "❌ $ERRORS error(s) and $WARNINGS warning(s) — the framework is not working as installed."
exit 1
