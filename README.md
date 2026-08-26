# Claude Skills

Eine persönliche Sammlung von [Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview) für Claude Code.
Von Nico Allers, [Allers Technology](https://allers-technology.com).

Skills sind kleine, wiederverwendbare Fähigkeiten, die Claude bei passenden Aufgaben automatisch dazuholt. Jeder Skill ist ein Ordner mit einer `SKILL.md` (Frontmatter plus Anleitung).

## Skills

| Skill | Was er macht |
|-------|--------------|
| [current-datetime](skills/current-datetime) | Holt das echte aktuelle Datum, die Uhrzeit, Zeitzone und den Wochentag aus der Systemuhr. Weil das Modell nie weiß, welcher Tag heute ist. |

## Nutzung

Skill in dein persönliches Skill-Verzeichnis kopieren:

```bash
cp -r skills/current-datetime ~/.claude/skills/
```

Claude Code erkennt den Skill danach automatisch und aktiviert ihn, sobald die Beschreibung zur Aufgabe passt.

## Neuen Skill anlegen

1. Ordner unter `skills/<skill-name>/` anlegen.
2. Eine `SKILL.md` mit Frontmatter (`name`, `description`) und der Anleitung im Markdown-Body schreiben.
3. Die `description` entscheidet, wann der Skill greift, also konkret formulieren, mit Auslöse-Stichworten.

## Lizenz

MIT
