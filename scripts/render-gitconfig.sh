#!/usr/bin/env bash
set -euo pipefail

SECRETS="$HOME/.config/dotfiles/secrets/git.env"
TEMPLATE="$(dirname "$0")/../templates/gitconfig.private.tmpl"
OUT="$HOME/.gitconfig.private"

if [[ ! -f "$SECRETS" ]]; then
  echo "Missing secrets file: $SECRETS"
  exit 1
fi

# shellcheck disable=SC1090
source "$SECRETS"

export GIT_NAME GIT_EMAIL
envsubst < "$TEMPLATE" > "$OUT"

echo "Wrote $OUT"

