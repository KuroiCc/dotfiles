if [ ! -d ~/.oh-my-zsh ]; then
  info '  Installing oh-my-zsh'
  git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh

  # Install zsh-wakatime, a ZSH plugin for wakatime
  cd ~/.oh-my-zsh/custom/plugins && git clone https://github.com/wbingli/zsh-wakatime.git

  # Install romkatv/powerlevel10k, a theme for ZSH
  if test "$(uname)" = "Darwin"; then

    cd ~/Library/Fonts && {
      curl -L "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf" -o "./MesloLGS NF Regular.ttf"
      curl -L "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf" -o "./MesloLGS NF Bold.ttf"
      curl -L "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf" -o "./MesloLGS NF Italic.ttf"
      curl -L "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf" -o "./MesloLGS NF Bold Italic.ttf"
      cd -
    }
  fi
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi
