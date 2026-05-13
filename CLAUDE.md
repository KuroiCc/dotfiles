# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository for macOS, forked from [holman/dotfiles](https://github.com/holman/dotfiles). It uses a **topic-based organization** where each directory is a "topic" (e.g., `git/`, `zsh/`, `homebrew/`). The shell auto-loads `*.zsh` files from all topic directories at startup.

## Key Commands

```bash
# Initial setup on a new machine
script/bootstrap

# Update dependencies (homebrew, installers)
bin/dot

# Install all Homebrew packages (merges Brewfile.core + Brewfile.local)
homebrew/my_brew_bundle

# Open dotfiles directory in $EDITOR
dot -e
```

## Architecture: Topic-based Auto-loading

The shell startup (`zsh/zshrc.symlink`) auto-sources all `*.zsh` files found under `$DOTFILES/` in this order:

1. `**/path.zsh` — PATH modifications (loaded first)
2. Everything except `path.zsh` and `completion.zsh` — aliases, config, env vars
3. `**/completion.zsh` — completion scripts (loaded after `compinit`)

To add new functionality, create a `.zsh` file in the appropriate topic directory. It will be picked up automatically.

## Conventions

- **`*.symlink` files** are symlinked to `$HOME` as dotfiles by `script/bootstrap` (e.g., `git/gitconfig.symlink` → `~/.gitconfig`).
- **`install.sh`** in any topic directory is run by `script/install` during setup.
- **`Brewfile.core`** contains shared packages (tracked in git). **`Brewfile.local`** contains machine-specific packages (gitignored). `my_brew_bundle` merges both at install time.
- **`user-app/`** manages non-critical or work-specific app configurations. Each subdirectory typically has `path.zsh`, `aliases.zsh`, or `config.zsh`.
- **`bin/`** is added to `$PATH`. Scripts here are globally available. Work-specific scripts (e.g., `t`, `dbup`, `feup`) are gitignored.
- **`functions/`** contains zsh autoload functions, added to `fpath`.

## Shell Environment

- Shell: zsh with oh-my-zsh (configured in `user-app/ohmyzsh/config.zsh`)
- Theme: Powerlevel10k
- Plugins: git, git-auto-fetch, zsh-wakatime, poetry
- `$DOTFILES` = `~/.dotfiles`
- `$PROJECTS` = `~/important/git-repositories` (macOS)
- `$EDITOR` = `code` (VS Code)

## Editor Shortcuts in `bin/`

- `e` — open in `$EDITOR` (VS Code)
- `ec` — open in Cursor
- `ei` — open in IntelliJ IDEA
