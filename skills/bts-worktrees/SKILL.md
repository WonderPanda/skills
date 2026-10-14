---
name: bts-worktrees
description: Converts a Better-T-Stack (create-better-t-stack, `bts.jsonc`) app into a bare git repo with worktrunk (`wt`) worktrees as subdirectories (`<project>/.git`, `<project>/main/`, `<project>/<branch>/`), with post-start hooks that copy `.env`/`node_modules` into new worktrees, install deps, and give each branch its own dev server port shown in `wt list`. Use when the user wants an existing Better-T-Stack or bts-scaffolded app set up for worktrunk, converted to a bare repo, or given per-worktree dev ports.
---

# Better-T-Stack → bare repo + worktrunk

Checked end to end on a Bun + TanStack Start + `webDeploy: cloudflare` (alchemy) + better-auth + varlock scaffold. Read `bts.jsonc` first. If the stack differs, follow the same pattern and say which steps you adapted.

## 1. Convert to the bare layout

Run the bundled `scripts/convert-to-bare` from this skill's directory:

```bash
<skill-dir>/scripts/convert-to-bare <repo>
```

- If `<repo>` is the `bun create` output (`myapp/`), the working tree moves to `myapp/main/`.
- If `<repo>` is already `proj/main/` and is the only entry in `proj/`, it stays put and `proj/` becomes the root.
- It refuses linked worktrees, a detached HEAD, or an already-bare repo.
- Uncommitted, untracked and ignored files move with the working tree.
- It appends `[projects."<id>"] worktree-path = "{{ repo_path }}/../{{ branch | sanitize }}"` to the worktrunk user config. Worktrunk keys a repo by its local `.git` path while it has no remote, and by `host/owner/repo` once it has one. If the user adds a remote later, rename the section to the new `Identifier:` from `wt config show`, after asking them.

Verify: `git worktree list` shows `<root> (bare)` plus `<root>/main`, and `git status` matches what it was before.

Every later step happens in `<root>/main/`.

## 2. Route the dev port through `DEV_PORT`

Find the hardcoded port: `grep -rn --exclude-dir=node_modules -E '3001|localhost' --include='*.ts' --include='*.json' --include='.env*' .`

**alchemy (`webDeploy: cloudflare`)**. `bun run dev` runs `alchemy dev` in `packages/infra`, which owns the port:

1. Append to `packages/infra/.env.schema`:
   ```
   # Local dev server port. Worktrees override it in .env.local (written by .config/wt.toml).
   # @type=port
   DEV_PORT=3001
   ```
2. In `packages/infra/alchemy.run.ts`, set `dev: { port: Number(process.env.DEV_PORT) }`. The file already imports `varlock/auto-load`, which loads `.env.local` over the schema default.
3. Leave `BETTER_AUTH_URL` alone. alchemy binds it to `Cloudflare.Worker.URL`, which follows the dev port.

**No alchemy.** The port is in `apps/web/vite.config.ts` (`server.port`), and `.env` files hold URLs that contain it (`BETTER_AUTH_URL`, `CORS_ORIGIN`, `VITE_SERVER_URL`). Apply the same pattern: a schema default, a hook-written `.env.local` override, and config that reads the variable. Each URL that contains the port must be overridden too. A separate server app (`apps/server`) needs its own port: hash a different key, e.g. `{{ ("server-" ~ branch) | hash_port }}`. This variant hasn't been tested; verify it with step 5.

`apps/web` has a bare-vite script, `dev:web`, that skips alchemy and keeps vite's port. Mention it to the user if it matters.

## 3. Add the project config

Copy `assets/wt.toml` to `.config/wt.toml` and `assets/worktreeinclude` to `.worktreeinclude`, then adjust them:

- Package manager: the install command (`bun install`, `pnpm install`, …) comes from `bts.jsonc` `packageManager`.
- The `port` hook's path (`packages/infra/.env.local`) is wherever step 2 reads `DEV_PORT`.
- The `[list] url` default port (`3001`) matches the schema default.
- `.worktreeinclude`: add any other gitignored file a fresh worktree needs (`apps/server/.env`). Keep `.alchemy/` out.

`wt step copy-ignored` reflinks on btrfs, XFS and APFS, so copying `node_modules` costs no disk.

## 4. Approval (the user's step)

Worktrunk won't run project hooks until the user approves them, and changing any hook command needs approval again. You can't approve on their behalf. Ask them to run `! wt config approvals add` from `<root>/main`, and never pass `--yes` for them.

## 5. Verify

Run each check and report the output. Don't assume a check passed.

1. `wt hook post-start --dry-run` lists `copy`, `port` and `install`.
2. Run the hook commands by hand in a throwaway worktree, which doesn't need approval:
   ```bash
   wt switch --create wt-hook-test --no-cd --no-hooks
   cd ../wt-hook-test && wt step copy-ignored && echo "DEV_PORT=$(wt step eval '{{ branch | hash_port }}')" > packages/infra/.env.local && bun install
   ```
   Check that `.env`, the generated `env.ts` files and `node_modules` exist and `git status` is clean. Then run `wt remove wt-hook-test --no-hooks --foreground`.
3. `wt list` shows `http://localhost:3001` for main and the hashed URL for other worktrees.
4. Dev server (needs cloud auth; if it fails on auth, hand that to the user): in `packages/infra`, write a temporary `.env.local` with a port you've confirmed is free (`ss -ltn`). Run dev, `curl` that port, then remove the file and repeat on 3001.
5. Auth follows the port: with dev running, `POST /api/auth/sign-in/email` from `Origin: http://localhost:<other port>` returns `INVALID_ORIGIN`, and from the dev port it doesn't.
6. Commit `.config/wt.toml`, `.worktreeinclude` and the port changes on main, so new branches carry the config.

## Gotchas

- **`alchemy dev` exits when stdin closes** (`Exited.` in the log). Run it in the background with stdin held open: `(sleep 160 | setsid timeout 150 bunx alchemy dev --no-input > log 2>&1) &`.
- **Don't `pkill -f 'alchemy dev'`.** The pattern matches your own shell's command line and kills it. Kill by PID: `pgrep -f 'alchemy/bin/(alchemy|exec)\.js'`.
- **Confirm the port is free before testing.** Something already listening there makes the test pass falsely. Check `ss -ltn` first.
- **`default_branch` is undefined in `[list] url`**, so the URL renders empty. Compare to a literal `"main"`, and single-quote the TOML value so the inner double quotes parse.
- **alchemy falls back to the next free port** unless `strictPort: true`. Fixed ports are mostly about stable `wt list` URLs, not preventing crashes.
- **Every worktree shares the `dev_${USER}` alchemy stage**, and dev state lives in the Cloudflare state store. Two worktrees running dev at the same time might clash. This hasn't been tested; `alchemy dev --stage <name>` is the escape hatch.
- **`check-types` runs `vite build`** in `apps/web` and leaves `apps/web/dist`. Delete it if you created it.
