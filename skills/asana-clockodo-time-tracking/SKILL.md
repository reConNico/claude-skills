---
name: asana-clockodo-time-tracking
description: Automatically books time in Clockodo for work Claude did on Asana tasks, based on a T-shirt size on the task (default XS 0.5 h, S 1 h, M 2 h, L 4 h, XL 8 h) instead of measured runtime. No approval step, Claude books directly and reports afterwards. Use at the end of every response or session in which Claude worked on an Asana task of a configured project (implemented, fixed, researched with a result, handed over for review, completed, pushed a merge request). Also use for "book time", "track this in Clockodo", "size changed", "catch up on bookings".
---

# Asana → Clockodo time tracking by T-shirt size

Claude books the time for its work on Asana tasks **directly and without asking** in Clockodo. The booked duration is not the measured runtime but the hours of the T-shirt size set on the task. The size is the human's pricing decision per task, Claude only executes it.

All account specific values (field GIDs, projects, customers, service IDs) live in `config.json` next to this file. Read it first. If it is missing or a required value is empty, do not book, tell the user which value is missing and point to `README.md`.

## Principles

1. **The human sets the size, Claude books.** Never set or change the size on a task.
2. **Size = budget for the whole task.** Across all sessions, exactly the size's hours are booked per task, never more.
3. **No size, no booking.** Report it in the chat instead.
4. **No Asana comments.** In Asana only the two tracking fields are updated (and optionally the board column, see step 6). Everything else is reported in the chat.
5. **Never delete** Clockodo entries, never change entries that are already billed, never touch entries Claude did not create.

## Tools

- Asana MCP: `get_task`, `update_tasks` (connector names differ per setup, find them with ToolSearch if needed).
- Clockodo MCP: `create_time_entry`, `update_time_entry`, `get_time_entry`, `list_time_entries`, `return_current_time`.
- Do not use `add_comment` or any delete tool.

## Procedure per task

Run this separately for every task Claude worked on in this session.

### 1. Read the task

`get_task` with `opt_fields=name,completed,parent.gid,parent.name,memberships.project.gid,memberships.project.name,memberships.section.gid,custom_fields.gid,custom_fields.enum_value.gid,custom_fields.enum_value.name,custom_fields.number_value,custom_fields.text_value,tags.name`.

Determine:
- **Project:** the first membership that appears in `config.projects`. No match → do not book, report "project not configured".
- **Budget task:** if the task has a size, it is the budget task. If not, but its parent has one, the **parent** is the budget task (size and tracking fields live there). If neither has a size → do not book, report "size missing".
- **B** = hours of the size (`config.sizes`).
- **G** = value of the booked-hours field (empty = 0).
- **E** = entry IDs from the entry-IDs field (comma separated).

### 2. Reconcile with Clockodo

- Fetch every entry in E with `get_time_entry`. Sum of durations = **G_actual**. Note which entries are billed (`billable` = 2) and which one was created today.
- Also run `list_time_entries` for the last 12 months with `filter.projects_id` and `filter.text` = task name to find entries that are not in E. Those were booked by a human: do not touch them, do **not** book automatically, and report a possible double booking.
- If G differs from G_actual, G_actual wins, fix the fields in step 5.

### 3. Hours to book (X)

Status of the task at the end of this session:

| Status | X |
|---|---|
| **Done**: completed in this session, handed over for review/testing, merge request pushed, or `completed` = true | B − G_actual |
| **Started, still open**, G_actual = 0 | `first` × B (default 50 %). For sizes below `min_size_for_partial` X = 0, they are booked on completion only |
| **Started, still open**, G_actual < `cap` × B, no partial booking today yet | min(`step` × B, `cap` × B − G_actual) (defaults 25 %, cap 75 %) |
| Only read, asked a question, nothing implemented | 0 |

Values come from `config.partial_booking`. If `enabled` is false, only book on completion.

- X ≤ 0 → book nothing.
- **Size was reduced** (G_actual > B): shorten an unbilled entry from E with `update_time_entry` until G_actual = B (minimum 0.25 h). Never change billed entries. Report any remaining overhang.
- **Reopened task with used-up budget:** no further booking. Suggest a bigger size or a new task.
- **Surcharge:** only if the task carries the tag `config.clockodo.surcharge_tag` and `surcharge_service_id` is set, use that service. Otherwise always `service_id`.

### 4. Create or extend the Clockodo entry

Get the time with `return_current_time` (timezone `config.timezone`).

- **End** = now, rounded down to 15 minutes. **Start** = end − duration.
- If the block falls outside `config.working_hours` or overlaps an existing entry of the user (check the day with `list_time_entries`), move it to the first free gap within working hours on the same working day, otherwise the next working day.
- **If an unbilled entry from E was created today**, extend it (`update_time_entry`, move the start earlier, avoid overlaps) instead of creating a new one. Otherwise `create_time_entry`:
  - `customers_id`, `projects_id` from the project config
  - `services_id` = `config.clockodo.service_id`, `billable` = `config.clockodo.billable`
  - `time_since`, `time_until` as local time `YYYY-MM-DDTHH:MM:SS`
  - `text` = **name of the budget task, verbatim**. No task ID, no link, no mention of Claude or the size, because the text may end up on the customer's invoice.
- Do not send `hourly_rate` or `users_id`, Clockodo uses the defaults of the authenticated user.
- If booking fails: do not update the fields, report "⏱ booking pending (X h): <error>" and retry the next time the task is touched.

### 5. Update Asana

`update_tasks` on the budget task: booked-hours field = new total (number), entry-IDs field = all entry IDs comma separated (append, never remove). Nothing else, **no comment**.

### 6. Board column after a merge request (optional)

If a merge request was created or its branch pushed for the task in this session and the project has a `review_section_gid`, move the task (the one worked on) to that section with `update_tasks` and `add_projects: [{"project_id": "<project gid>", "section_id": "<review_section_gid>"}]`. Do not move it back if it already sits in that or a later column. Without `review_section_gid` do not move it.

### 7. Report

End the response with one line per task, e.g.
`⏱ Clockodo: "Fix wishlist without login" 2 h booked (L, partial, 2 of 4 h).`
Also list every task that was **not** booked and why (size missing, project not configured, budget used up, possible double booking, error). This report is the only notice, because nothing is commented in Asana.

## Hard limits

- Only projects listed in `config.projects`.
- Only change entries whose ID is in the entry-IDs field. Never delete entries. Never change billed entries.
- Never book more than B per task.
- Never set or change the size.
- Work without an Asana task is not booked automatically.
