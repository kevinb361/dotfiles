SHELL := /bin/bash

.PHONY: ci lint syntax test

ci: lint syntax test

lint:
	shellcheck install.sh uninstall.sh tests/smoke.sh

syntax:
	bash -n install.sh uninstall.sh tests/smoke.sh
	zsh -n config/zsh/zshrc
	git config -f config/git/gitconfig --list >/dev/null
	python3 -c 'import pathlib,tomllib; [tomllib.loads(p.read_text()) for p in pathlib.Path("config").rglob("*.toml")]'
	@if command -v luac >/dev/null 2>&1; then \
		luac -p config/nvim/init.lua config/nvim/lua/terminal_palette_overrides.lua; \
	fi

test:
	bash tests/smoke.sh
