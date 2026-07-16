# CLAUDE.md — dotfiles

Personal Linux dotfiles with a small, inspectable symlink installer.

## Safety

- Never commit identity, email, credentials, tokens, private endpoints, hostnames, personal paths,
  work configuration, or secret-bearing local overrides.
- Keep `~/.zshrc.local` and `~/.gitconfig.local` outside Git.
- Do not add destructive adoption behavior. Existing targets must be backed up before linking.
- The uninstaller may remove only symlinks that point into the current checkout.
- Host-specific display, GPU, service, and window-manager configuration does not belong in the
  portable default set.
- Preserve compatibility with tmux 3.2a+ and Neovim 0.11+; avoid newer config options or deprecated
  Neovim aliases unless the documented baseline changes with matching tests.

## Structure

- `config/` contains public files linked into `$HOME`.
- `examples/` contains safe templates for local files.
- `install.sh` and `uninstall.sh` define the complete managed-file list.
- `tests/smoke.sh` exercises install, idempotency, backups, dry-run, and uninstall.

## Gate

```bash
make ci
```

Run the gate and review the exact public tree before every commit. For config changes, validate
with the native parser when available in addition to static syntax checks.
