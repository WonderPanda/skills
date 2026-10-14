# skills

Agent skills following the [Agent Skills spec](https://agentskills.io/specification). Works with Claude Code, Codex, Cursor, and [other agents supported by the skills CLI](https://github.com/vercel-labs/skills#supported-agents).

## Install

Any agent, via the [skills CLI](https://skills.sh):

```bash
npx skills add WonderPanda/skills --list              # see what's available
npx skills add WonderPanda/skills --skill <name>      # install one
npx skills add WonderPanda/skills --skill '*'         # install all
```

Claude Code, as a plugin:

```
/plugin marketplace add WonderPanda/skills
/plugin install wonderpanda-skills@wonderpanda
```

## Skills

| Skill | Description |
| --- | --- |
| [`bts-worktrees`](skills/bts-worktrees/SKILL.md) | Convert a Better-T-Stack app to a bare repo + worktrunk worktrees, with post-start hooks that copy env/deps and give each branch its own dev port. |
| [`new-project`](skills/new-project/SKILL.md) | Start a project as a bare repo with worktrunk worktrees as subdirectories (`<project>/.git`, `<project>/main/`). Ships a `new-project` CLI. |
| [`whiteboard-defense`](skills/whiteboard-defense/SKILL.md) | Build a whiteboard-level model of a system or feature, then get quizzed until you can defend it. For pre-planning and for reviewing code you didn't write. |

## Adding a skill

```bash
cd skills && npx skills init <name>
```

- Folder name must equal the `name` frontmatter field (`a-z0-9-`, ≤64 chars).
- `description` says what it does **and when to use it** (≤1024 chars).
- Keep `SKILL.md` under ~500 lines; put detail in `references/`, code in `scripts/`, templates in `assets/`.
- Set `metadata.internal: true` to hide a work-in-progress skill from `npx skills add`.

Check discovery locally before pushing:

```bash
npx skills add ./ --list
```

## Local development

```bash
scripts/link.sh
```

Symlinks every skill into `~/.agents/skills` (Codex and other universal agents) and `~/.claude/skills`, so edits here are live in both. A skill's CLI at `skills/<name>/scripts/<name>` is also linked into `~/.local/bin`. Re-run after adding a skill. Skips any skill already installed as a copy; remove it with `npx skills remove -g <name>` first.

## License

MIT
