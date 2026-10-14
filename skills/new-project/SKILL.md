---
name: new-project
description: Creates a new project as a bare git repo whose worktrunk (`wt`) worktrees live as subdirectories of one project directory (`<project>/.git` bare, `<project>/main/`, `<project>/<branch>/`), and registers the per-project worktrunk `worktree-path`. Use when the user wants to start a new project or repo, set up a bare-repo or worktree-native layout, or keep all of a project's worktrees in one directory.
---

# New Project

Run the bundled CLI. It's `new-project` on PATH after `scripts/link.sh`; otherwise it's `scripts/new-project` in this skill's directory.

```bash
new-project <path> [--remote <url>]
```

It:
1. Runs `git init --bare` into `<path>/.git`, using `init.defaultBranch` (default `main`).
2. Adds `origin` if `--remote` is given.
3. Creates the default-branch worktree at `<path>/<branch>/` with `wt switch --create`.
4. Appends `[projects."<id>"] worktree-path = "{{ repo_path }}/../{{ branch | sanitize }}"` to the worktrunk user config. `<id>` comes from `wt config show`.

Resolve `<path>` against the user's current directory unless they name another location. The CLI fails if `<path>` already exists.

## After it runs

- Do all work in `<path>/<branch>/`. The project root holds only `.git/` and worktrees, so never put files there.
- The branch is unborn. `wt switch --create <other>` fails until the first commit exists in `<path>/main/`.
- Project config (`.config/wt.toml`) goes inside a worktree, never the bare repo.

## Remote keying

Worktrunk keys a project by its local `.git` path until it has a remote, then by `host/owner/repo`. If the user already knows the remote URL, pass `--remote` so the config is keyed correctly from the start.

If a remote is added later, the existing `[projects."<local path>/.git"]` entry stops matching. New worktrees then land at `<path>/.git.<branch>`. To fix it, get the new key from `wt config show` (`Identifier:` line) inside a worktree, and rename the config section header to that key. Ask the user before editing their worktrunk config.
