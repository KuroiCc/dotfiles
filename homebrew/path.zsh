if test "$(uname)" = "Darwin"; then
    # on apple silicon, homebrew is installed in /opt/homebrew/bin/brew
    # on intel, homebrew is installed in /usr/local/bin/brew
    if test -f "/opt/homebrew/bin/brew"; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    if test -f "/usr/local/bin/brew"; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi
