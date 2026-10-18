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
# The conformance rules ship with the version whose requirements they encode, so
# no per-version migration matrix is needed.
#
# Run from anywhere in the project:
#   bash .claude/framework/scripts/check-install.sh
#
# Exit codes:  0 conformant · 1 errors found · 2 cannot tell

set -uo pipefail

# --compare-from <version>: report breaking changes since this version instead of
# since the recorded marker. init-project.sh passes the marker it is about to
# overwrite, because it runs before this check in the documented upgrade order.
COMPARE_FROM=""
while [ $# -gt 0 ]; do
    case "$1" in
        --compare-from)
            [ $# -ge 2 ] || { echo "❌ --compare-from needs a version"; exit 2; }
            COMPARE_FROM="$2"; shift 2 ;;
        *) echo "❌ Unknown option: $1"; echo "   Usage: check-install.sh [--compare-from <version>]"; exit 2 ;;
    esac
done

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
AGENTS_DIR="$PROJECT_ROOT/.claude/agents"
VERSION_MARKER="$PROJECT_ROOT/.claude/.framework-version"
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"
HOOK_SCRIPT="$PROJECT_ROOT/.claude/hooks/on-file-edit.sh"

INCLUDE_LINE="@.claude/framework/INSTRUCTIONS.md"
LEGACY_INCLUDE_LINE="@.claude/framework/CLAUDE.md"

FRAMEWORK_VERSION=$(read_framework_version)

ERRORS=0
WARNINGS=0

# ── Is the submodule actually checked out? ───────────────────────────────────
# `git clone` without --recurse-submodules leaves .claude/framework empty, and
# every check below would pass vacuously.

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
    # Exit 2, "cannot tell": an empty framework has no conformance to assess.
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
# Without this line the framework loads nothing in a session.

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

# Detail lines are collected so they print under the ✗ they belong to.
if [ "$MISSING" -eq 0 ] && [ "$STALE" -eq 0 ]; then
    ok "All $TOTAL commands installed and identical to this version"
else
    err "$MISSING command(s) missing, $STALE differing from version $FRAMEWORK_VERSION" \
        "Commands are copies; updating the submodule does not refresh them." \
        "→ bash .claude/framework/scripts/init-project.sh"
    printf '%s\n' "$DETAIL" | sed '/^$/d; s/^/       /'
fi

# ── Agent copies: present, and byte-identical to this version ────────────────
# A drifted agent is worse than a missing one: it still answers, with rules this
# version no longer ships.

A_MISSING=0
A_STALE=0
A_TOTAL=0
A_DETAIL=""
for agent_file in "$FRAMEWORK_DIR"/agents/*.md; do
    [ -e "$agent_file" ] || continue
    A_TOTAL=$((A_TOTAL + 1))
    target="$AGENTS_DIR/$(basename "$agent_file")"
    name=$(basename "$agent_file" .md)
    if [ ! -f "$target" ]; then
        A_DETAIL="$A_DETAIL
missing: $name"
        A_MISSING=$((A_MISSING + 1))
    elif ! cmp -s "$agent_file" "$target"; then
        A_DETAIL="$A_DETAIL
differs: $name"
        A_STALE=$((A_STALE + 1))
    fi
done

if [ "$A_TOTAL" -eq 0 ]; then
    # This version ships agents, so finding none means an incomplete checkout.
    warn "The framework has no agents/ directory — the checkout is incomplete" \
         "→ git submodule update --init --recursive"
elif [ "$A_MISSING" -eq 0 ] && [ "$A_STALE" -eq 0 ]; then
    ok "All $A_TOTAL agents installed and identical to this version"
else
    err "$A_MISSING agent(s) missing, $A_STALE differing from version $FRAMEWORK_VERSION" \
        "Agents are copies; updating the submodule does not refresh them." \
        "→ bash .claude/framework/scripts/init-project.sh"
    printf '%s\n' "$A_DETAIL" | sed '/^$/d; s/^/       /'
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
# A wired hook whose script is gone fails silently: its command ends in `|| true`.

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

# ── Declaration blocks the template offers and this project does not carry ───
# init-project.sh never writes a declaration block: it is a grant of authority only
# the developer can make. A new block is additive, so no `### Breaking` section
# announces it; comparing the template against the project surfaces every one.

TEMPLATE_SPEC="$FRAMEWORK_DIR/templates/PROJECT_AUDIT_FRAMEWORK.md"
PROJECT_SPEC="$PROJECT_ROOT/.claude/PROJECT_AUDIT_FRAMEWORK.md"

if [ -f "$TEMPLATE_SPEC" ] && [ -f "$PROJECT_SPEC" ]; then
    MISSING_BLOCKS=""
    BLOCK_COUNT=0
    while IFS= read -r block; do
        [ -n "$block" ] || continue
        BLOCK_COUNT=$((BLOCK_COUNT + 1))
        grep -qF "## $block" "$PROJECT_SPEC" || MISSING_BLOCKS="$MISSING_BLOCKS, $block"
    done <<EOF
$(grep '^## ' "$TEMPLATE_SPEC" | sed 's/^## //' | grep -v '^Category ')
EOF
    MISSING_BLOCKS=${MISSING_BLOCKS#, }

    if [ -n "$MISSING_BLOCKS" ]; then
        warn "Declaration blocks offered by v$FRAMEWORK_VERSION, absent from .claude/PROJECT_AUDIT_FRAMEWORK.md:" \
             "$(sanitize_display "$MISSING_BLOCKS")" \
             "Each decides what a session may do, or what an audit is able to verify. Declining one" \
             "is a legitimate answer that sets a ceiling — it breaks nothing." \
             "→ copy the block from .claude/framework/templates/PROJECT_AUDIT_FRAMEWORK.md and fill it in"
    elif [ "$BLOCK_COUNT" -gt 0 ]; then
        ok "All $BLOCK_COUNT declaration blocks present in .claude/PROJECT_AUDIT_FRAMEWORK.md"
    fi
fi

# ── Breaking changes between the recorded install and this version ───────────
# What init-project.sh cannot migrate — a decision only the developer can make —
# is in the changelog; this surfaces the relevant range.

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
