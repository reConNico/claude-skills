# Claude Skills

A personal collection of [Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview) for Claude Code.
By Nico Allers, [Allers Technology](https://allers-technology.com).

Skills are small, reusable capabilities that Claude pulls in automatically whenever a task matches. Each skill is a folder with a `SKILL.md` (frontmatter plus instructions).

## Skills

| Skill | What it does |
|-------|--------------|
| [current-datetime](skills/current-datetime) | Fetches the real current date, time, timezone and weekday from the system clock. Because the model never knows what day it is. |
| [asana-clockodo-time-tracking](skills/asana-clockodo-time-tracking) | Books Claude's work on Asana tasks automatically in Clockodo, based on a T-shirt size (XS to XL) on the task. No stopwatch, no approval step. Comes with a one-command installer. |

## Usage

Copy a skill into your personal skills directory:

```bash
cp -r skills/current-datetime ~/.claude/skills/
```

Claude Code picks the skill up automatically and activates it as soon as its description matches the task.

Skills that need setup ship their own installer, which works without cloning this repo, e.g.:

```bash
curl -fsSL https://raw.githubusercontent.com/reConNico/claude-skills/main/skills/asana-clockodo-time-tracking/install.sh | bash
```

## Adding a new skill

1. Create a folder under `skills/<skill-name>/`.
2. Write a `SKILL.md` with frontmatter (`name`, `description`) and the instructions in the markdown body.
3. The `description` decides when the skill triggers, so be specific and include trigger keywords.

## License

MIT
