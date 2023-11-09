if [ ! -d $ZSH_CUSTOM/plugins/poetry ]; then
    mkdir $ZSH_CUSTOM/plugins/poetry
fi
poetry completions zsh >$ZSH_CUSTOM/plugins/poetry/_poetry
