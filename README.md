# dotfiles

Personal Linux dotfiles. Current, curated, and intentionally boring to operate.

The common path is a small set of symlinked configs with machine-local overrides kept outside
Git. This is not a framework and it does not attempt to capture an entire home directory.

## Included

- Zsh: history, completion, portable aliases, a small VCS prompt, optional tool hooks, and
  prefix-history arrow bindings
- Git: public defaults with identity and signing delegated to `~/.gitconfig.local`
- tmux: vi navigation and the Blackout Moss status palette
- Neovim 0.11+: a small lazy.nvim setup and matching terminal-first highlights
- Alacritty and foot: matching Blackout Moss terminal palettes
- Git hooks: a documentation-freshness `pre-commit` gate, installed per repository

Host-specific window-manager, display, GPU, service, secret, and work configuration is excluded.

## Install

Inspect first:

```bash
git clone https://github.com/kevinb361/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run
```

Then install:

```bash
./install.sh
```

Existing targets are moved under:

```text
~/.local/state/dotfiles/backups/<UTC timestamp>/
```

### Git hooks

`.git/hooks/` is never version controlled, so each repository otherwise grows its own drifting
copy of a hook. `install.sh` links the tracked hook to `~/.claude/git-hooks/pre-commit`, and the
per-repository installer points individual checkouts at the same file:

```bash
./install-git-hooks.sh --dry-run ~/projects/example
./install-git-hooks.sh ~/projects/example
```

A hook that has diverged is reported and left alone; `--force` replaces it after taking a backup.
That protects repositories which deliberately wrap the shared gate in extra checks.

The check itself lives in `config/git/hooks/lib/doc-check.sh` and is linked to
`~/.claude/git-hooks/lib/`. A repository that needs extra gates keeps its own hook and sources
that library rather than copying the logic:

```bash
DOC_CHECK_LIB=${DOC_CHECK_LIB:-$HOME/.claude/git-hooks/lib/doc-check.sh}
[ -r "$DOC_CHECK_LIB" ] || { printf 'missing doc-check library\n' >&2; exit 1; }
. "$DOC_CHECK_LIB"
doc_check_run
```

A missing library blocks the commit instead of quietly skipping the gate.

The installer uses absolute symlinks and is safe to rerun. It never overwrites machine-local
files. If `~/.gitconfig` already exists and `~/.gitconfig.local` does not, the existing file is
migrated to `~/.gitconfig.local`, set to mode `0600`, and included by the public config. This
preserves identity, signing, and credential-helper settings without publishing them.

Create local overrides only when needed:

```bash
cp examples/zshrc.local.example ~/.zshrc.local
cp examples/gitconfig.local.example ~/.gitconfig.local
chmod 600 ~/.zshrc.local ~/.gitconfig.local
```

Edit the copies; never commit them.

## Uninstall

```bash
./uninstall.sh
```

The uninstaller removes only symlinks managed by the current checkout. Backups and local override
files remain untouched.

## Validation

```bash
make ci
```

The gate checks Bash and Zsh syntax, ShellCheck, Git config parsing, TOML parsing, Lua syntax when
`luac` is available, tmux config loading, and an install/uninstall smoke test in a disposable
home directory.

## Layout

```text
config/      Files linked into the home directory
examples/    Untracked local-override templates
install.sh   Backup-first linker
uninstall.sh Conservative managed-link removal
tests/       Disposable-home smoke tests
```

## Notes

- The portable baseline is tmux 3.2a+ and Neovim 0.11+.
- Terminal fonts are not installed automatically. The configs expect JetBrains Mono Nerd Font.
- Neovim bootstraps lazy.nvim on first launch and installs plugins from `lazy-lock.json`.
- Update pinned Neovim plugins with `:Lazy update`, review the result, and commit the updated
  `lazy-lock.json`.
- The Alacritty configuration is Linux-oriented. Machine-specific window/font adjustments belong
  in a local copy or a separate host overlay.
- This public repository is the distributable configuration. Private operational state is not
  mirrored into it.
