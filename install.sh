#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET_HOME=${DOTFILES_HOME:-$HOME}
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run]

Symlinks the curated configs into $DOTFILES_HOME (default: $HOME).
Existing targets are moved to a timestamped backup directory first.
An existing regular ~/.gitconfig is migrated to ~/.gitconfig.local when that file is absent.
Existing machine-local override files are never overwritten.
EOF
}

case "${1:-}" in
  --dry-run) DRY_RUN=true ;;
  --help|-h) usage; exit 0 ;;
  "") ;;
  *) usage >&2; exit 2 ;;
esac

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
STATE_HOME=${XDG_STATE_HOME:-$TARGET_HOME/.local/state}
BACKUP_ROOT="$STATE_HOME/dotfiles/backups/$STAMP"

run() {
  if $DRY_RUN; then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

link_file() {
  local relative_source=$1
  local relative_target=$2
  local source="$ROOT/$relative_source"
  local target="$TARGET_HOME/$relative_target"
  local parent
  parent=$(dirname "$target")

  if [[ -L "$target" ]] && [[ $(readlink "$target") == "$source" ]]; then
    printf 'ok      %s\n' "$target"
    return
  fi

  run mkdir -p "$parent"
  if [[ -e "$target" || -L "$target" ]]; then
    local backup="$BACKUP_ROOT/$relative_target"
    run mkdir -p "$(dirname "$backup")"
    run mv "$target" "$backup"
    printf 'backup  %s -> %s\n' "$target" "$backup"
  fi

  run ln -s "$source" "$target"
  printf 'link    %s -> %s\n' "$target" "$source"
}

preserve_git_identity() {
  local public_target="$TARGET_HOME/.gitconfig"
  local local_target="$TARGET_HOME/.gitconfig.local"

  if [[ -f "$public_target" && ! -L "$public_target" && ! -e "$local_target" ]]; then
    run mv "$public_target" "$local_target"
    run chmod 600 "$local_target"
    printf 'migrate %s -> %s\n' "$public_target" "$local_target"
  fi
}

link_file config/zsh/zshrc .zshrc
preserve_git_identity
link_file config/git/gitconfig .gitconfig
link_file config/tmux/tmux.conf .tmux.conf
link_file config/nvim/init.lua .config/nvim/init.lua
link_file config/nvim/lazy-lock.json .config/nvim/lazy-lock.json
link_file config/nvim/lua/terminal_palette_overrides.lua .config/nvim/lua/terminal_palette_overrides.lua
link_file config/alacritty/alacritty.toml .config/alacritty/alacritty.toml
link_file config/foot/foot.ini .config/foot/foot.ini

printf '\nLocal override templates:\n'
printf '  cp %q %q\n' "$ROOT/examples/zshrc.local.example" "$TARGET_HOME/.zshrc.local"
printf '  cp %q %q\n' "$ROOT/examples/gitconfig.local.example" "$TARGET_HOME/.gitconfig.local"
