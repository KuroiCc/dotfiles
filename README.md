# dotfiles

Thanks to [holman](https://github.com/holman)'s great work! [original repo is here](https://github.com/holman/dotfiles).

This repo is a fork of his dotfiles repo. And customize it to my preference.

The main change is following:
  - using oh-my-zsh instead of zsh
  - using Homebrew Bundle to install all the packages, including:
    - CLI tools by Homebrew
    - GUI tools by Homebrew Cask
    - App Store apps by mas-cli
  - fix some errors that happened in my environment
  - using user-app directory to manage non-critical apps
  - symlink hosts file (DEPRECATED)

## Getting Started
1. Install Xcode
```shell
Xcode-select --install
```
2. Run this
```shell
git clone https://github.com/KuroiCc/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```
3. Follow the [checklist]() to finish the setting.
