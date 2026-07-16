#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET_HOME=${DOTFILES_HOME:-$HOME}

remove_link() {
  local relative_source=$1
  local relative_target=$2
  local source="$ROOT/$relative_source"
  local target="$TARGET_HOME/$relative_target"

  if [[ -L "$target" ]] && [[ $(readlink "$target") == "$source" ]]; then
    rm "$target"
    printf 'removed %s\n' "$target"
  elif [[ -e "$target" || -L "$target" ]]; then
    printf 'keep    %s (not managed by this checkout)\n' "$target"
  else
    printf 'absent  %s\n' "$target"
  fi
}

remove_link config/zsh/zshrc .zshrc
remove_link config/git/gitconfig .gitconfig
remove_link config/tmux/tmux.conf .tmux.conf
remove_link config/nvim/init.lua .config/nvim/init.lua
remove_link config/nvim/lazy-lock.json .config/nvim/lazy-lock.json
remove_link config/nvim/lua/terminal_palette_overrides.lua .config/nvim/lua/terminal_palette_overrides.lua
remove_link config/alacritty/alacritty.toml .config/alacritty/alacritty.toml
remove_link config/foot/foot.ini .config/foot/foot.ini

printf '\nBackups and machine-local override files were left untouched.\n'
