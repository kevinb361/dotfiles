#!/usr/bin/env bash
set -euo pipefail

# Symlinks the tracked pre-commit hook into one or more repositories.
#
# Git hooks live in .git/hooks/, which is never version controlled, so every
# repository otherwise ends up with its own drifting copy. Linking them at the
# checkout keeps one file of record.

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SOURCE="$ROOT/config/git/hooks/pre-commit"
DRY_RUN=false
FORCE=false

usage() {
  cat <<'USAGE'
Usage: ./install-git-hooks.sh [--dry-run] [--force] <repo> [<repo>...]

Symlinks <repo>/.git/hooks/pre-commit to the tracked hook in this checkout.

An existing hook identical to the tracked one is backed up and replaced.
An existing hook that has diverged is left alone unless --force is given,
because a repository may deliberately wrap the shared hook in extra gates.
Backups are written under ~/.local/state/dotfiles/backups/<UTC timestamp>/.
USAGE
}

repos=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --help|-h) usage; exit 0 ;;
    -*) usage >&2; exit 2 ;;
    *) repos+=("$1") ;;
  esac
  shift
done

if [[ ${#repos[@]} -eq 0 ]]; then
  usage >&2
  exit 2
fi

if [[ ! -f "$SOURCE" ]]; then
  printf 'missing tracked hook: %s\n' "$SOURCE" >&2
  exit 1
fi

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
STATE_HOME=${XDG_STATE_HOME:-${DOTFILES_HOME:-$HOME}/.local/state}
BACKUP_ROOT="$STATE_HOME/dotfiles/backups/$STAMP/git-hooks"

run() {
  if $DRY_RUN; then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

status=0

for repo in "${repos[@]}"; do
  if ! git_dir=$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null); then
    printf 'skip    %s (not a git repository)\n' "$repo"
    status=1
    continue
  fi

  target="$git_dir/hooks/pre-commit"
  label=$(basename "$(git -C "$repo" rev-parse --show-toplevel)")

  if [[ -L "$target" ]] && [[ $(readlink "$target") == "$SOURCE" ]]; then
    printf 'ok      %s\n' "$target"
    continue
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    if ! $FORCE && ! cmp -s "$target" "$SOURCE"; then
      printf 'diverged %s (left alone; re-run with --force to replace)\n' "$target"
      status=1
      continue
    fi
    backup="$BACKUP_ROOT/$label-pre-commit"
    run mkdir -p "$BACKUP_ROOT"
    run mv "$target" "$backup"
    printf 'backup  %s -> %s\n' "$target" "$backup"
  fi

  run mkdir -p "$(dirname "$target")"
  run ln -s "$SOURCE" "$target"
  printf 'link    %s -> %s\n' "$target" "$SOURCE"
done

# Repositories that keep their own hook (because they wrap the shared gate in
# project-specific checks) source the library from the path install.sh links.
if [[ ! -r "${DOTFILES_HOME:-$HOME}/.claude/git-hooks/lib/doc-check.sh" ]]; then
  printf '\nnote    %s is not linked yet;\n' "${DOTFILES_HOME:-$HOME}/.claude/git-hooks/lib/doc-check.sh"
  printf '        run ./install.sh so hooks that wrap the shared gate can find it.\n'
fi

exit "$status"
