if test ! "$(uname)" = "Darwin"; then
    exit 0
fi

if [ -d ~/Library/Application\ Support/SynologyDrive/data/session ]; then
    for f in ~/Library/Application\ Support/SynologyDrive/data/session/*/conf/blacklist.filter; do
        ln -sf $DOTFILES/user-app/synology-drive/drive-global-blacklist.filter $f
    done

else
    echo "SynologyDrive/data not found"
fi
