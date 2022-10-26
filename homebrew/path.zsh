if test "$(uname)" = "Darwin"; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if test "$(uname)" = "Linux"; then
    eval "$(/bin/brew shellenv)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
