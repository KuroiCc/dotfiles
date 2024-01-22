if test ! "$(uname)" = "Darwin"; then
  return
fi

# The Brewfile handles Homebrew-based app and library installs, but there may
# still be updates and installables in the Mac App Store. There's a nifty
# command line interface to it that we can use to just install everything, so
# yeah, let's do that.

if [[ "$(sysctl -n machdep.cpu.brand_string)" == *'Apple'* ]] && ! arch -x86_64 /usr/bin/true 2>/dev/null; then
  echo "› installing rosetta 2"
  sudo softwareupdate --install-rosetta --agree-to-license
fi
