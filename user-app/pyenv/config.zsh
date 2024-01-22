if test ! "$(uname)" = "Darwin"; then
    return
fi

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

if test $(uname) = "Linux"; then
    export LDFLAGS="-Wl,-rpath,$(brew --prefix openssl)/lib"
    export CPPFLAGS="-I$(brew --prefix openssl)/include"
    export CONFIGURE_OPTS="--with-openssl=$(brew --prefix openssl)"
fi
