#!/bin/bash
# uninstall.sh — Remove claude-audit-framework from a project
# Run from the project root BEFORE removing the submodule:
#   bash .claude/framework/scripts/uninstall.sh
#
# Exit codes:  0 removed · 2 cannot run (wrong location, not a git repo, bad option)

set -euo pipefail

# This script deletes files. Silently ignoring an unrecognised option means an
# operator who tries --dry-run gets a real uninstall instead of a rehearsal.
for arg in "$@"; do
    case "$arg" in
        *) echo "❌ Unknown option: $arg"
           echo "   uninstall.sh takes no options — it always performs a real removal."
           echo "   There is no --dry-run. To preview, read the list below in this file."
           exit 2 ;;
    esac
done

# pwd -P: on macOS a path through a symlink (/tmp, /var/folders) keeps its logical
# form here while `git rev-parse` returns the physical one, and the two would not
# compare equal — the scripts then refused to work in a perfectly valid checkout.
SCRIPT_DIR=$(cd -P "$(dirname "$0")" && pwd -P)
FRAMEWORK_DIR=$(dirname "$SCRIPT_DIR")

if [ "$(basename "$FRAMEWORK_DIR")" != "framework" ] ||
   [ "$(basename "$(dirname "$FRAMEWORK_DIR")")" != ".claude" ]; then
    echo "❌ Not a consumer install."
    echo "   Run this as <project>/.claude/framework/scripts/uninstall.sh"
    echo "   Found instead: $FRAMEWORK_DIR"
    exit 2
fi

PROJECT_ROOT=$(cd -P "$FRAMEWORK_DIR/../.." && pwd -P)

if ! git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ $PROJECT_ROOT is not a git repository — nothing was installed here by this framework."
    exit 2
fi

COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"

# strip_line <file> <extended-regex> — delete matching lines in place.
# Temp file + mv: portable across BSD (macOS) and GNU sed, unlike `sed -i`.
# -E because BSD sed does not support `\|` alternation in basic regexes.
# Slashes in the pattern must be escaped — `/` is the address delimiter.
strip_line() {
    local file="$1" pattern="$2" tmp
    tmp=$(mktemp)
    sed -E "/$pattern/d" "$file" > "$tmp"
    mv "$tmp" "$file"
}

# strip_leading_blanks <file> — drop blank lines at the top of the file.
strip_leading_blanks() {
    local file="$1" tmp
    tmp=$(mktemp)
    sed '/./,$!d' "$file" > "$tmp"
    mv "$tmp" "$file"
}

echo "🗑  Removing claude-audit-framework..."
echo ""

# ── Installed commands ──────────────────────────────────────────────────────────
# Remove only the command files this framework installed. Commands the project
# owns are left in place, and the directory is removed only if it ends up empty.

if [ -d "$COMMANDS_DIR" ]; then
    REMOVED=0
    if [ -d "$FRAMEWORK_DIR/commands" ]; then
        for command_file in "$FRAMEWORK_DIR"/commands/*.md; do
            [ -e "$command_file" ] || continue
            target="$COMMANDS_DIR/$(basename "$command_file")"
            if [ -f "$target" ]; then
                rm "$target"
                echo "  ✓  Removed command: /$(basename "$command_file" .md)"
                REMOVED=$((REMOVED + 1))
            fi
        done
    else
        # Submodule already gone — fall back to the known command names
        for name in project-audit competency-review init-profile; do
            if [ -f "$COMMANDS_DIR/$name.md" ]; then
                rm "$COMMANDS_DIR/$name.md"
                echo "  ✓  Removed command: /$name"
                REMOVED=$((REMOVED + 1))
            fi
        done
    fi

    [ "$REMOVED" -eq 0 ] && echo "  ↩  No framework commands found in .claude/commands/ (skipped)"

    if rmdir "$COMMANDS_DIR" 2>/dev/null; then
        echo "  ✓  Removed empty .claude/commands/"
    else
        echo "  ℹ  .claude/commands/ kept — it still contains project-owned commands"
    fi
else
    echo "  ↩  .claude/commands/ not found (skipped)"
fi

# ── Specialization files ──────────────────────────────────────────────────────

for spec in PROJECT_AUDIT_FRAMEWORK.md CODING_STANDARDS.md audit-focus.md; do
    if [ -f "$PROJECT_ROOT/.claude/$spec" ]; then
        rm "$PROJECT_ROOT/.claude/$spec"
        echo "  ✓  Removed .claude/$spec"
    else
        echo "  ↩  .claude/$spec not found (skipped)"
    fi
done

# ── Per-file check hook ───────────────────────────────────────────────────────
# The script goes; the settings.json entry is left alone, because that file may
# hold settings the project owns. A leftover entry is harmless: its command ends
# in `|| true`, so a missing script is a silent no-op rather than an error.

if [ -f "$PROJECT_ROOT/.claude/hooks/on-file-edit.sh" ]; then
    rm "$PROJECT_ROOT/.claude/hooks/on-file-edit.sh"
    echo "  ✓  Removed .claude/hooks/on-file-edit.sh"
    if rmdir "$PROJECT_ROOT/.claude/hooks" 2>/dev/null; then
        echo "  ✓  Removed empty .claude/hooks/"
    fi
    if grep -qF "on-file-edit.sh" "$PROJECT_ROOT/.claude/settings.json" 2>/dev/null; then
        echo "  ℹ  .claude/settings.json still references the hook — harmless, but you can"
        echo "     drop the PostToolUse entry (or run /hooks in Claude Code) to tidy up"
    fi
fi

# ── Version marker ────────────────────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/.claude/.framework-version" ]; then
    rm "$PROJECT_ROOT/.claude/.framework-version"
    echo "  ✓  Removed .claude/.framework-version"
fi

# ── @-include in CLAUDE.md ────────────────────────────────────────────────────
# Both forms are handled: INSTRUCTIONS.md (current) and CLAUDE.md (pre-1.0 installs).

if [ -f "$PROJECT_ROOT/CLAUDE.md" ] &&
   grep -qE '^@\.claude/framework/(INSTRUCTIONS|CLAUDE)\.md$' "$PROJECT_ROOT/CLAUDE.md"; then
    strip_line "$PROJECT_ROOT/CLAUDE.md" '^@\.claude\/framework\/(INSTRUCTIONS|CLAUDE)\.md$'
    strip_leading_blanks "$PROJECT_ROOT/CLAUDE.md"
    echo "  ✓  Removed framework @-include from CLAUDE.md"
else
    echo "  ↩  @-include not found in CLAUDE.md (skipped)"
fi

# ── .gitattributes export-ignore ──────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/.gitattributes" ] && grep -qF ".claude/ export-ignore" "$PROJECT_ROOT/.gitattributes"; then
    strip_line "$PROJECT_ROOT/.gitattributes" '^\.claude\/ export-ignore$'
    echo "  ✓  Removed .claude/ export-ignore from .gitattributes"
    if [ ! -s "$PROJECT_ROOT/.gitattributes" ]; then
        rm "$PROJECT_ROOT/.gitattributes"
        echo "  ✓  Removed empty .gitattributes"
    fi
else
    echo "  ↩  export-ignore entry not found in .gitattributes (skipped)"
fi

# ── Submodule removal (must be done manually — script runs from inside it) ────

echo ""
echo "────────────────────────────────────────────────"
echo ""
echo "⚠  One step remaining — run these commands to remove the submodule:"
echo "   (the script cannot remove the directory it is running from)"
echo ""
echo "   git submodule deinit -f .claude/framework"
echo "   git rm -f .claude/framework"
echo "   rm -rf .git/modules/.claude/framework"
echo ""
echo "────────────────────────────────────────────────"
echo ""
echo "✅ Framework files removed. Run the three commands above to finish."
echo ""
echo "Two things were deliberately kept:"
echo "  • ~/.claude/context/user_profile.md — personal, shared across projects"
echo "  • docs/audits/ — the project's own quality history, valuable without the framework"
echo ""
echo "To reinstall:"
echo "  git submodule add git@github.com:nicolx/claude-audit-framework.git .claude/framework"
echo "  bash .claude/framework/scripts/init-project.sh"
echo ""
