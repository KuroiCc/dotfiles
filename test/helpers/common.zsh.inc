# Shared helpers for test/*_test.zsh.
# Each test file must set REPO_ROOT (absolute path of the repo under test)
# before sourcing this file.

fail() { print -ru2 -- "  FAIL: $*"; exit 1 }
pass() { print -r -- "  ok: $*" }

assert_eq() { # <actual> <expected> <message>
  [[ "$1" == "$2" ]] || fail "$3 — expected [$2], got [$1]"
  pass "$3"
}

assert_lt() { # <actual> <max> <message>
  (( $1 < $2 )) || fail "$3 — expected < $2, got $1"
  pass "$3"
}

# Create an isolated ZDOTDIR whose .zshrc loads the repo under test.
# Keeps compinit dumps inside the temp dir so the real $HOME stays untouched.
# Prints the directory path; caller is responsible for removing it.
make_zdotdir() {
  local dir
  dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX") || return 1
  {
    print -r -- "export DOTFILES=${(q)REPO_ROOT}"
    print -r -- "source ${(q)REPO_ROOT}/zsh/zshrc.symlink"
  } > "$dir/.zshrc"
  print -r -- "$dir"
}

# Run an interactive zsh in the isolated ZDOTDIR and print its stdout.
# stderr is discarded: sandboxed runs emit gitstatus/monitor noise.
run_interactive() { # <zdotdir> <command>
  ZDOTDIR="$1" zsh -i -c "$2" 2>/dev/null
}

# Trace an interactive startup with xtrace into <trace-file>.
trace_startup() { # <zdotdir> <trace-file>
  ZDOTDIR="$1" zsh -x -i -c exit 2>"$2" >/dev/null
}
