---
name: current-datetime
description: Get the real current date, time, timezone and weekday from the system clock. Use whenever the user asks what day or time it is, needs today's date or a timestamp, mentions "today", "now", "current date/time", or asks to resolve a relative date like "in 3 days", "next Monday", "tomorrow". Language models do not know the current moment, so fetch it instead of guessing.
---

# Current Date & Time

A language model has no built-in knowledge of the current date or time. Never guess it, never infer "today" from training data or from earlier messages in the conversation. Always read the real moment from the system clock before answering.

## Get the current local time

```bash
date "+%Y-%m-%d %H:%M:%S %Z (%A)"
```

Example output: `2026-09-01 09:00:00 CEST (Monday)` — ISO date, 24h time, timezone, and weekday.

## Get UTC

```bash
date -u "+%Y-%m-%dT%H:%M:%SZ"
```

## Get the time in a specific timezone

```bash
TZ="America/New_York" date "+%Y-%m-%d %H:%M %Z"
```

## Resolve relative dates

For requests like "in 3 days" or "next Friday", read today first, then compute from it.

```bash
# 3 days from now
date -v+3d "+%Y-%m-%d"        # macOS / BSD date
date -d "+3 days" "+%Y-%m-%d" # GNU / Linux date
```

## Rules

- Fetch the real time before answering any date or time question, or before computing a relative date.
- Always report the timezone alongside the time so it is unambiguous.
- If the user names a timezone, answer in that timezone. Otherwise use the system's local timezone and say which one it is.
