#!/usr/bin/env bash
# Symlink every skill in skills/ into ~/.agents/skills (read by Codex and other
# universal agents) and ~/.claude/skills, so edits in this repo are live.
# A skill's CLI at skills/<name>/scripts/<name> is also linked into ~/.local/bin.
# Re-run after adding a skill.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"

link() { # link <target> <path>
  if [[ -e $2 && ! -L $2 ]]; then
    echo "skip $2: not a symlink; run 'npx skills remove -g $(basename "$2")' first" >&2
    return
  fi
  ln -sfn "$1" "$2"
  echo "$2 -> $1"
}

mkdir -p ~/.agents/skills ~/.claude/skills ~/.local/bin
for dir in "$repo"/skills/*/; do
  [[ -f $dir/SKILL.md ]] || continue
  name=$(basename "$dir")
  link "${dir%/}" ~/.agents/skills/"$name"
  link ../../.agents/skills/"$name" ~/.claude/skills/"$name"
  if [[ -x $dir/scripts/$name ]]; then link "$dir"scripts/"$name" ~/.local/bin/"$name"; fi
done
