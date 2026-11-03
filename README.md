# Claude Skills

A personal collection of [Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview) for Claude Code.
By Nico Allers, [Allers Technology](https://allers-technology.com).

Skills are small, reusable capabilities that Claude pulls in automatically whenever a task matches. Each skill is a folder with a `SKILL.md` (frontmatter plus instructions).

## Skills

| Skill | What it does |
|-------|--------------|
| [current-datetime](skills/current-datetime) | Fetches the real current date, time, timezone and weekday from the system clock. Because the model never knows what day it is. |
| [asana-clockodo-time-tracking](skills/asana-clockodo-time-tracking) | Books Claude's work on Asana tasks automatically in Clockodo, based on a T-shirt size (XS to XL) on the task. No stopwatch, no approval step. |

## Install

Every skill installs with a single command, no clone needed. It lands in `~/.claude/skills/<skill-name>/`, and Claude Code picks it up automatically in the next session and activates it as soon as its description matches the task. Running the command again updates the skill.

### current-datetime

```bash
curl -fsSL https://raw.githubusercontent.com/reConNico/claude-skills/main/skills/current-datetime/install.sh | bash
```

### asana-clockodo-time-tracking

```bash
curl -fsSL https://raw.githubusercontent.com/reConNico/claude-skills/main/skills/asana-clockodo-time-tracking/install.sh | bash
```

Needs a short setup afterwards (Asana fields and `config.json`), see its [README](skills/asana-clockodo-time-tracking/README.md). Add `bash -s -- --with-permissions` instead of `bash` to let Claude book without permission prompts.

### Uninstall

Pass `--uninstall` to the same installer:

```bash
curl -fsSL https://raw.githubusercontent.com/reConNico/claude-skills/main/skills/<skill-name>/install.sh | bash -s -- --uninstall
```

### Manual install

Clone the repo and copy a skill folder into your personal skills directory:

```bash
cp -r skills/current-datetime ~/.claude/skills/
```

## Adding a new skill

1. Create a folder under `skills/<skill-name>/`.
2. Write a `SKILL.md` with frontmatter (`name`, `description`) and the instructions in the markdown body.
3. The `description` decides when the skill triggers, so be specific and include trigger keywords.
4. Add an `install.sh` to the folder (copy the one from `current-datetime` and adjust the skill name and files), then add its one-line install command to the Install section above.

## License

MIT
