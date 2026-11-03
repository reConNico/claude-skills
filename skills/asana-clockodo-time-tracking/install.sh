#!/usr/bin/env bash
# Installer for the asana-clockodo-time-tracking skill (Claude Code).
#
#   curl -fsSL https://raw.githubusercontent.com/reConNico/claude-skills/main/skills/asana-clockodo-time-tracking/install.sh | bash
#
# Options (pass after "bash -s --"):
#   --with-permissions   allow the Clockodo booking tools without prompts, deny deleting entries
#   --no-hook            do not register the Stop reminder hook
#   --uninstall          remove the skill and its hook (config.json is kept as a backup)
#
# Environment:
#   CLAUDE_HOME          default ~/.claude
#   CLOCKODO_MCP         name of your Clockodo MCP server, default "clockodo"
#   SKILLS_REF           git ref to install from, default "main"
#   SKILLS_BASE_URL      override the download location (e.g. a fork or file:// for testing)
set -euo pipefail

SKILL="asana-clockodo-time-tracking"
REF="${SKILLS_REF:-main}"
BASE="${SKILLS_BASE_URL:-https://raw.githubusercontent.com/reConNico/claude-skills/$REF/skills/$SKILL}"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
TARGET="$CLAUDE_HOME/skills/$SKILL"
SETTINGS="$CLAUDE_HOME/settings.json"
CLOCKODO_MCP="${CLOCKODO_MCP:-clockodo}"
FILES="SKILL.md README.md config.example.json hooks/time-tracking-reminder.py"

WITH_PERMISSIONS=0
WITH_HOOK=1
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --with-permissions) WITH_PERMISSIONS=1 ;;
    --no-hook) WITH_HOOK=0 ;;
    --uninstall) UNINSTALL=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

command -v curl >/dev/null || { echo "curl is required." >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required." >&2; exit 1; }

HOOK_CMD="python3 -I $TARGET/hooks/time-tracking-reminder.py"

# Edits settings.json in place (with a timestamped backup). $1 = install|uninstall
edit_settings() {
  mkdir -p "$CLAUDE_HOME"
  [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
  MODE="$1" HOOK_CMD="$HOOK_CMD" WITH_HOOK="$WITH_HOOK" WITH_PERMISSIONS="$WITH_PERMISSIONS" \
  CLOCKODO_MCP="$CLOCKODO_MCP" SETTINGS="$SETTINGS" python3 -I - <<'PY'
import json, os
path = os.environ["SETTINGS"]
with open(path, encoding="utf-8") as fh:
    settings = json.load(fh)
hook_cmd = os.environ["HOOK_CMD"]
prefix = "mcp__%s__" % os.environ["CLOCKODO_MCP"]
allow = [prefix + t for t in ("create_time_entry", "update_time_entry", "get_time_entry",
                              "list_time_entries", "return_current_time")]
deny = [prefix + "delete_time_entry"]
stop = settings.setdefault("hooks", {}).setdefault("Stop", [])
stop[:] = [g for g in stop if not any(h.get("command") == hook_cmd for h in g.get("hooks", []))]
perms = settings.setdefault("permissions", {})
if os.environ["MODE"] == "install":
    if os.environ["WITH_HOOK"] == "1":
        stop.append({"hooks": [{"type": "command", "command": hook_cmd}]})
    if os.environ["WITH_PERMISSIONS"] == "1":
        for key, values in (("allow", allow), ("deny", deny)):
            current = perms.setdefault(key, [])
            current += [v for v in values if v not in current]
if not perms:
    settings.pop("permissions")
if not stop:
    settings["hooks"].pop("Stop")
if not settings["hooks"]:
    settings.pop("hooks")
with open(path, "w", encoding="utf-8") as fh:
    json.dump(settings, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PY
}

if [ "$UNINSTALL" = 1 ]; then
  if [ -f "$TARGET/config.json" ]; then
    cp "$TARGET/config.json" "$CLAUDE_HOME/$SKILL.config.json.bak"
    echo "Kept your config as $CLAUDE_HOME/$SKILL.config.json.bak"
  fi
  rm -rf "$TARGET"
  [ -f "$SETTINGS" ] && edit_settings uninstall
  echo "Removed $SKILL. Permission entries (if any) were left in $SETTINGS."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for f in $FILES; do
  mkdir -p "$TMP/$(dirname "$f")"
  curl -fsSL "$BASE/$f" -o "$TMP/$f"
done

mkdir -p "$TARGET/hooks"
for f in $FILES; do
  cp "$TMP/$f" "$TARGET/$f"
done
chmod +x "$TARGET/hooks/time-tracking-reminder.py"

if [ -f "$TARGET/config.json" ]; then
  echo "Kept existing $TARGET/config.json"
else
  cp "$TARGET/config.example.json" "$TARGET/config.json"
  echo "Created $TARGET/config.json from the example"
fi

if [ "$WITH_HOOK" = 1 ] || [ "$WITH_PERMISSIONS" = 1 ]; then
  edit_settings install
  [ "$WITH_HOOK" = 1 ] && echo "Registered the Stop reminder hook in $SETTINGS"
  [ "$WITH_PERMISSIONS" = 1 ] && echo "Allowed Clockodo booking tools ($CLOCKODO_MCP) and denied delete_time_entry"
fi

cat <<MSG

Installed $SKILL to $TARGET

Next steps:
  1. In Asana, create three custom fields (add them to the organization's field library):
     "Size" (single-select XS, S, M, L, XL), "Clockodo booked" (number, 2 decimals),
     "Clockodo entries" (text). Add them to every project you want to track.
  2. Fill in $TARGET/config.json (field and option GIDs, Clockodo service,
     and one entry per Asana project with its Clockodo customer and project).
     Tip: ask Claude "fill in the config for asana-clockodo-time-tracking", it can look the IDs up.
  3. Make sure the Asana and Clockodo MCP servers are connected in Claude Code.
  Details: $TARGET/README.md
MSG
