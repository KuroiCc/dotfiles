# dotfiles
[Original Repo](https://github.com/holman/dotfiles)

Thanks to [holman](https://github.com/holman)'s great work! 

This repo is a fork of his dotfiles repo. And customize it to my preference.

The main change is following:
  - using oh-my-zsh instead of zsh
  - using Homebrew Bundle to install all the packages, including:
    - CLI tools by Homebrew
    - GUI tools by Homebrew Cask
    - App Store apps by mas-cli
  - symlink hosts file 
  - fix some errors that happened in my environment

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