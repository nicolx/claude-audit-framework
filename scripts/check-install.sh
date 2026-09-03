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

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
FRAMEWORK_DIR=$(dirname "$SCRIPT_DIR")

if [ "$(basename "$FRAMEWORK_DIR")" != "framework" ] ||
   [ "$(basename "$(dirname "$FRAMEWORK_DIR")")" != ".claude" ]; then
    echo "ℹ  This is the framework's own repository, not a project that installs it."
    echo "   Run this from a consumer project:"
    echo "     bash .claude/framework/scripts/check-install.sh"
    exit 2
fi

PROJECT_ROOT=$(cd "$FRAMEWORK_DIR/../.." && pwd)
COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"
VERSION_MARKER="$PROJECT_ROOT/.claude/.framework-version"
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"
HOOK_SCRIPT="$PROJECT_ROOT/.claude/hooks/on-file-edit.sh"

INCLUDE_LINE="@.claude/framework/INSTRUCTIONS.md"
LEGACY_INCLUDE_LINE="@.claude/framework/CLAUDE.md"

FRAMEWORK_VERSION="unknown"
if [ -f "$FRAMEWORK_DIR/VERSION" ]; then
    FRAMEWORK_VERSION=$(tr -d '[:space:]' < "$FRAMEWORK_DIR/VERSION")
fi

ERRORS=0
WARNINGS=0

err()  { echo "  ✗  $1"; shift; for l in "$@"; do echo "     $l"; done; ERRORS=$((ERRORS + 1)); }
warn() { echo "  ⚠  $1"; shift; for l in "$@"; do echo "     $l"; done; WARNINGS=$((WARNINGS + 1)); }
ok()   { echo "  ✓  $1"; }

echo "────────────────────────────────────────────────"
echo "🩺 claude-audit-framework — install conformance"
echo "   framework version: $FRAMEWORK_VERSION"
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
for skill in "$FRAMEWORK_DIR"/commands/*.md; do
    [ -e "$skill" ] || continue
    TOTAL=$((TOTAL + 1))
    target="$COMMANDS_DIR/$(basename "$skill")"
    name="/$(basename "$skill" .md)"
    if [ ! -f "$target" ]; then
        echo "     missing: $name"
        MISSING=$((MISSING + 1))
    elif ! cmp -s "$skill" "$target"; then
        echo "     differs: $name"
        STALE=$((STALE + 1))
    fi
done

if [ "$MISSING" -eq 0 ] && [ "$STALE" -eq 0 ]; then
    ok "All $TOTAL commands installed and identical to this version"
else
    err "$MISSING command(s) missing, $STALE differing from version $FRAMEWORK_VERSION" \
        "Commands are copies; updating the submodule does not refresh them." \
        "→ bash .claude/framework/scripts/init-project.sh"
fi

# ── Version marker ───────────────────────────────────────────────────────────

if [ ! -f "$VERSION_MARKER" ]; then
    warn "No .claude/.framework-version" \
         "Installed before version tracking, or init-project.sh was never run." \
         "→ bash .claude/framework/scripts/init-project.sh"
    INSTALLED_VERSION=""
else
    INSTALLED_VERSION=$(grep '^version=' "$VERSION_MARKER" | cut -d= -f2)
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
    err ".claude/ not excluded from git archive — deploy tools may ship it" \
        "→ echo '.claude/ export-ignore' >> .gitattributes"
fi

# ── Breaking changes between the recorded install and this version ───────────
# init-project.sh migrates what it can. What it cannot — a new declaration, a
# decision only the developer can make — lives in the changelog, and this is
# where the relevant range gets surfaced instead of being hoped for.

if [ -n "$INSTALLED_VERSION" ] &&
   [ "$INSTALLED_VERSION" != "$FRAMEWORK_VERSION" ] &&
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
        [ "$v" = "$INSTALLED_VERSION" ] && continue
        [ "$(printf '%s\n%s\n' "$INSTALLED_VERSION" "$v" | sort -V | head -1)" = "$INSTALLED_VERSION" ] || continue
        [ "$(printf '%s\n%s\n' "$v" "$FRAMEWORK_VERSION" | sort -V | head -1)" = "$v" ] || continue
        BREAKING="$BREAKING $v"
    done
    BREAKING=$(echo "$BREAKING" | tr -s ' ' | sed 's/^ //;s/ $//')

    echo ""
    if [ -n "$BREAKING" ]; then
        warn "Releases with breaking changes since $INSTALLED_VERSION: $BREAKING" \
             "init-project.sh migrates what it can automatically; read those entries for" \
             "anything it cannot." \
             "→ sed -n '/## \\[$FRAMEWORK_VERSION\\]/,/## \\[$INSTALLED_VERSION\\]/p' .claude/framework/CHANGELOG.md"
    else
        ok "No breaking changes recorded between $INSTALLED_VERSION and $FRAMEWORK_VERSION"
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
