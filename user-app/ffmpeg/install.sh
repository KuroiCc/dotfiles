#!/bin/bash
#
# Download the latest ffmpeg snapshot build from evermeet.cx
# The site recommends snapshot builds over release builds.

set -e

if test ! "$(uname)" = "Darwin"; then
  echo "This script is only for macOS."
  exit 1
fi

echo "› downloading ffmpeg snapshot"
curl -JL -o /tmp/ffmpeg-snapshot.zip "https://evermeet.cx/ffmpeg/get/zip"

echo "› extracting ffmpeg"
unzip -o /tmp/ffmpeg-snapshot.zip -d "$DOTFILES/bin"

chmod +x "$DOTFILES/bin/ffmpeg"
rm -f /tmp/ffmpeg-snapshot.zip

echo "› ffmpeg installed to $DOTFILES/bin/ffmpeg"
ffmpeg -version | head -1
