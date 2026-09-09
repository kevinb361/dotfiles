#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
HOME_UNDER_TEST="$TMP/home"
mkdir -p "$HOME_UNDER_TEST"

printf 'pre-existing zsh config\n' > "$HOME_UNDER_TEST/.zshrc"
printf '[user]\n  name = Local User\n' > "$HOME_UNDER_TEST/.gitconfig"
printf 'local shell override\n' > "$HOME_UNDER_TEST/.zshrc.local"

DOTFILES_HOME="$HOME_UNDER_TEST" "$ROOT/install.sh" >/dev/null

managed=(
  .zshrc
  .gitconfig
  .tmux.conf
  .config/nvim/init.lua
  .config/nvim/lazy-lock.json
  .config/nvim/lua/terminal_palette_overrides.lua
  .config/alacritty/alacritty.toml
  .config/foot/foot.ini
  .claude/git-hooks/pre-commit
)

for relative in "${managed[@]}"; do
  [[ -L "$HOME_UNDER_TEST/$relative" ]] || {
    printf 'missing managed symlink: %s\n' "$relative" >&2
    exit 1
  }
done

# Existing files are backed up, and local overrides are untouched.
backup_matches=("$HOME_UNDER_TEST"/.local/state/dotfiles/backups/*/.zshrc)
[[ -f "${backup_matches[0]}" ]]
grep -q '^pre-existing zsh config$' "${backup_matches[0]}"
grep -q '^local shell override$' "$HOME_UNDER_TEST/.zshrc.local"
grep -q 'name = Local User' "$HOME_UNDER_TEST/.gitconfig.local"
[[ $(stat -c '%a' "$HOME_UNDER_TEST/.gitconfig.local") == 600 ]]

# Reinstall is idempotent.
DOTFILES_HOME="$HOME_UNDER_TEST" "$ROOT/install.sh" >/dev/null

DOTFILES_HOME="$HOME_UNDER_TEST" "$ROOT/uninstall.sh" >/dev/null
for relative in "${managed[@]}"; do
  [[ ! -L "$HOME_UNDER_TEST/$relative" ]] || {
    printf 'managed symlink survived uninstall: %s\n' "$relative" >&2
    exit 1
  }
done
[[ -f "${backup_matches[0]}" ]]
[[ -f "$HOME_UNDER_TEST/.zshrc.local" ]]
[[ -f "$HOME_UNDER_TEST/.gitconfig.local" ]]

# Dry-run must not alter an existing target.
DRY_HOME="$TMP/dry-home"
mkdir -p "$DRY_HOME"
printf 'keep me\n' > "$DRY_HOME/.zshrc"
DOTFILES_HOME="$DRY_HOME" "$ROOT/install.sh" --dry-run >/dev/null
[[ ! -L "$DRY_HOME/.zshrc" ]]
grep -q '^keep me$' "$DRY_HOME/.zshrc"

# Compatibility guardrails for the documented public baseline.
if grep -q 'vim\.loop' "$ROOT/config/nvim/init.lua"; then
  printf 'deprecated Neovim vim.loop alias is not allowed\n' >&2
  exit 1
fi
if grep -q 'allow-passthrough' "$ROOT/config/tmux/tmux.conf"; then
  printf 'tmux config requires an option unavailable in Ubuntu 22.04 tmux 3.2a\n' >&2
  exit 1
fi
if grep -q '^\[debug\]$' "$ROOT/config/alacritty/alacritty.toml"; then
  printf 'Alacritty debug defaults should not be pinned in the public config\n' >&2
  exit 1
fi

# tmux must accept the public config.
mkdir -p "$TMP/tmux"
TMUX_TMPDIR="$TMP/tmux" tmux -L dotfiles-ci -f "$ROOT/config/tmux/tmux.conf" \
  new-session -d -s dotfiles-ci
TMUX_TMPDIR="$TMP/tmux" tmux -L dotfiles-ci kill-server

# The per-repo git hook installer links, is idempotent, protects divergence,
# and never writes during a dry run.
HOOK_SOURCE="$ROOT/config/git/hooks/pre-commit"
HOOK_STATE="$TMP/hook-state"
repo_hook() { git -C "$1" rev-parse --absolute-git-dir; }

git init -q "$TMP/repo-fresh"
XDG_STATE_HOME="$HOOK_STATE" "$ROOT/install-git-hooks.sh" "$TMP/repo-fresh" >/dev/null
fresh_hook="$(repo_hook "$TMP/repo-fresh")/hooks/pre-commit"
[[ -L "$fresh_hook" ]]
[[ $(readlink "$fresh_hook") == "$HOOK_SOURCE" ]]

# Re-running is a no-op, not a second backup.
XDG_STATE_HOME="$HOOK_STATE" "$ROOT/install-git-hooks.sh" "$TMP/repo-fresh" >/dev/null
[[ $(readlink "$fresh_hook") == "$HOOK_SOURCE" ]]

# An identical plain-file hook is adopted.
git init -q "$TMP/repo-copy"
copy_hook="$(repo_hook "$TMP/repo-copy")/hooks/pre-commit"
mkdir -p "$(dirname "$copy_hook")"
cp "$HOOK_SOURCE" "$copy_hook"
XDG_STATE_HOME="$HOOK_STATE" "$ROOT/install-git-hooks.sh" "$TMP/repo-copy" >/dev/null
[[ -L "$copy_hook" ]]

# A diverged hook is preserved unless forced.
git init -q "$TMP/repo-diverged"
div_hook="$(repo_hook "$TMP/repo-diverged")/hooks/pre-commit"
mkdir -p "$(dirname "$div_hook")"
printf '#!/usr/bin/env bash\n# local gate\nexit 0\n' > "$div_hook"
if XDG_STATE_HOME="$HOOK_STATE" "$ROOT/install-git-hooks.sh" "$TMP/repo-diverged" >/dev/null 2>&1; then
  printf 'diverged hook was replaced without --force\n' >&2
  exit 1
fi
grep -q '^# local gate$' "$div_hook"

XDG_STATE_HOME="$HOOK_STATE" "$ROOT/install-git-hooks.sh" --force "$TMP/repo-diverged" >/dev/null
[[ -L "$div_hook" ]]
div_backups=("$HOOK_STATE"/dotfiles/backups/*/git-hooks/repo-diverged-pre-commit)
grep -q '^# local gate$' "${div_backups[0]}"

# Dry run leaves an untouched repository alone.
git init -q "$TMP/repo-dry"
dry_hook="$(repo_hook "$TMP/repo-dry")/hooks/pre-commit"
XDG_STATE_HOME="$HOOK_STATE" "$ROOT/install-git-hooks.sh" --dry-run "$TMP/repo-dry" >/dev/null
[[ ! -L "$dry_hook" ]]

printf 'dotfiles smoke test passed\n'
