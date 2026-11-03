#!/usr/bin/env bash
# Installer for the current-datetime skill (Claude Code).
#
#   curl -fsSL https://raw.githubusercontent.com/reConNico/claude-skills/main/skills/current-datetime/install.sh | bash
#
# Options (pass after "bash -s --"):
#   --uninstall          remove the skill
#
# Environment:
#   CLAUDE_HOME          default ~/.claude
#   SKILLS_REF           git ref to install from, default "main"
#   SKILLS_BASE_URL      override the download location (e.g. a fork or file:// for testing)
set -euo pipefail

SKILL="current-datetime"
REF="${SKILLS_REF:-main}"
BASE="${SKILLS_BASE_URL:-https://raw.githubusercontent.com/reConNico/claude-skills/$REF/skills/$SKILL}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
TARGET="$CLAUDE_HOME/skills/$SKILL"

case "${1:-}" in
  "") ;;
  --uninstall)
    rm -f "$TARGET/SKILL.md"
    rmdir "$TARGET" 2>/dev/null || true
    echo "Removed $SKILL."
    exit 0 ;;
  *) echo "Unknown option: $1" >&2; exit 1 ;;
esac

command -v curl >/dev/null || { echo "curl is required." >&2; exit 1; }

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
curl -fsSL "$BASE/SKILL.md" -o "$TMP"
mkdir -p "$TARGET"
cp "$TMP" "$TARGET/SKILL.md"

echo "Installed $SKILL to $TARGET. Claude Code picks it up in the next session."
