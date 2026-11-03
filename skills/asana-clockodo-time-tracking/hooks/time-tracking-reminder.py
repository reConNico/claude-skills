#!/usr/bin/env python3
"""Claude Code Stop hook for the asana-clockodo-time-tracking skill.

Reminds Claude once to run the skill when an Asana task was worked on in
this session (get_task, update_tasks) but neither the skill ran nor a
Clockodo entry was created or updated afterwards.

Reminds only once per Asana activity and session, so merely reading a task
does not nag on every response. The Asana tool name pattern is read from
the skill's config.json (asana.tool_pattern), default "asana".
"""

import json
import os
import re
import sys

SKILL = "asana-clockodo-time-tracking"
SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE_DIR = os.path.expanduser("~/.claude/state/" + SKILL)
CLOCKODO_BOOKING = re.compile(r"clockodo.*__(create_time_entry|update_time_entry)$")


def asana_pattern():
    try:
        with open(os.path.join(SKILL_DIR, "config.json"), encoding="utf-8") as fh:
            pattern = json.load(fh).get("asana", {}).get("tool_pattern") or "asana"
    except (OSError, ValueError):
        pattern = "asana"
    return re.compile(r"(%s).*__(get_task|update_tasks)$" % pattern)


def tool_uses(transcript_path):
    """Yields name and input of every tool_use block in order."""
    with open(transcript_path, encoding="utf-8") as fh:
        for line in fh:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if entry.get("type") != "assistant":
                continue
            content = (entry.get("message") or {}).get("content")
            if not isinstance(content, list):
                continue
            for block in content:
                if isinstance(block, dict) and block.get("type") == "tool_use":
                    yield block.get("name") or "", block.get("input") or {}


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return 0
    if data.get("stop_hook_active"):
        return 0
    transcript_path = data.get("transcript_path")
    if not transcript_path or not os.path.exists(transcript_path):
        return 0

    asana_task_tool = asana_pattern()
    last_asana = last_handled = -1
    for index, (name, tool_input) in enumerate(tool_uses(transcript_path)):
        if asana_task_tool.search(name):
            last_asana = index
        elif CLOCKODO_BOOKING.search(name):
            last_handled = index
        elif name == "Skill" and SKILL in str(tool_input.get("skill", "")):
            last_handled = index

    if last_asana < 0 or last_handled > last_asana:
        return 0

    session = re.sub(r"[^A-Za-z0-9_-]", "_", str(data.get("session_id") or "default"))
    state_file = os.path.join(STATE_DIR, session)
    try:
        with open(state_file, encoding="utf-8") as fh:
            if int(fh.read().strip() or -1) >= last_asana:
                return 0
    except (OSError, ValueError):
        pass
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(state_file, "w", encoding="utf-8") as fh:
        fh.write(str(last_asana))

    print(json.dumps({
        "decision": "block",
        "reason": (
            "An Asana task was touched in this session, but no time has been booked. "
            "If you actually worked on a task (not just read it), run the skill "
            + SKILL + " now. Otherwise end the response without booking."
        ),
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
