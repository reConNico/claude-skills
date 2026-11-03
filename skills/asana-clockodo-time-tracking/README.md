# asana-clockodo-time-tracking

Claude Code skill that books the time for Claude's work on Asana tasks automatically in [Clockodo](https://www.clockodo.com), based on a **T-shirt size** you put on the task. No stopwatch, no estimating afterwards, no approval step: you decide the value of a task with its size, Claude books it when it works on the task.

## How it works

1. You give an Asana task a size (XS, S, M, L, XL).
2. Claude works on the task.
3. At the end of the session Claude books the size's hours in Clockodo on the mapped customer and project, with the task name as entry text.
4. Claude writes the booked hours and the Clockodo entry IDs into two Asana fields and reports the booking in the chat. **No Asana comments.**

| Size | Default hours |
|------|---------------|
| XS | 0.5 h |
| S | 1 h |
| M | 2 h |
| L | 4 h |
| XL | 8 h |

The size is a budget for the whole task. Work spread over several sessions gets partial bookings (by default 50 %, then 25 % steps up to 75 %), the rest is booked when the task is done or a merge request is pushed. Per task never more than the size is booked.

Safety rules built into the skill: never delete entries, never change billed entries, only touch entries Claude created itself, no booking without a size, no booking on projects that are not configured, and no automatic booking if a human already booked the same task.

The default hours are a starting point. Calibrate them against your own past bookings (median and percentiles of hours per task) so the total stays close to what you billed before.

## Requirements

- [Claude Code](https://docs.claude.com/en/docs/claude-code/overview)
- An Asana MCP server or connector (needs `get_task`, `update_tasks`)
- A Clockodo MCP server (needs `create_time_entry`, `update_time_entry`, `get_time_entry`, `list_time_entries`, `return_current_time`)
- `curl` and `python3` for the installer and the reminder hook

## Install

One command, no clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/reConNico/claude-skills/main/skills/asana-clockodo-time-tracking/install.sh | bash
```

This copies the skill to `~/.claude/skills/asana-clockodo-time-tracking/`, creates `config.json` from the example and registers a small Stop hook that reminds Claude once per session if it touched an Asana task without booking.

To also let Claude book without permission prompts (and block deleting entries):

```bash
curl -fsSL https://raw.githubusercontent.com/reConNico/claude-skills/main/skills/asana-clockodo-time-tracking/install.sh | bash -s -- --with-permissions
```

If your Clockodo MCP server is not named `clockodo`, set `CLOCKODO_MCP=<name>` before `bash`. Other options: `--no-hook`, `--uninstall`. Running the installer again updates the skill and keeps your `config.json`. Every change to `settings.json` is preceded by a backup.

## Setup

### 1. Asana fields

Create three custom fields, add them to your organization's field library and to every project you want to track:

| Field | Type |
|---|---|
| Size | Single-select: XS, S, M, L, XL |
| Clockodo booked | Number, 2 decimals |
| Clockodo entries | Text |

### 2. config.json

Edit `~/.claude/skills/asana-clockodo-time-tracking/config.json`. The easiest way is to ask Claude: *"Fill in the config for asana-clockodo-time-tracking"*. It can read the field GIDs from Asana and the IDs from Clockodo.

| Key | Meaning |
|---|---|
| `timezone` | Your timezone for entry times |
| `sizes` | Hours per size |
| `asana.tool_pattern` | Part of the Asana MCP tool names (used by the hook). For claude.ai connectors this is the connector ID shown in the tool name |
| `asana.fields.size.gid` / `.options` | GID of the Size field and of each option |
| `asana.fields.booked_hours_gid` | GID of "Clockodo booked" |
| `asana.fields.entry_ids_gid` | GID of "Clockodo entries" |
| `clockodo.service_id` | Clockodo service (activity) to book on |
| `clockodo.billable` | 1 = billable, 0 = not billable |
| `clockodo.surcharge_service_id` / `surcharge_tag` | Optional: service used when the task has this tag |
| `working_hours` | Time window and weekdays (1 = Monday) in which entries are placed |
| `partial_booking` | Partial bookings for tasks that span several sessions |
| `projects[]` | One entry per Asana project: `asana_project_gid`, `clockodo_customer_id`, `clockodo_project_id`, optional `review_section_gid` (column a task moves to after a merge request was pushed) |

### 3. Make sure Claude runs it

The skill triggers on its own after work on Asana tasks, and the Stop hook catches forgotten bookings. If you want to be explicit, add a line to your `~/.claude/CLAUDE.md`:

```markdown
- After working on an Asana task, run the skill `asana-clockodo-time-tracking` before ending the response.
```

## Good to know

- Entry texts are the task name only, because they may appear on invoices.
- Don't book tasks manually that Claude works on, or you'll get double bookings. If you put significant work of your own into a task, raise its size.
- Meetings and project management are out of scope, keep booking those by time.
