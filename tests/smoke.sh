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

printf 'dotfiles smoke test passed\n'
