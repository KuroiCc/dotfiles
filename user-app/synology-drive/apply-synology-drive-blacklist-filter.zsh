for f in ~/.SynologyDrive/data/session/*/conf/blacklist.filter; do
    ln -sf $DOTFILES/user-app/synology-drive/drive-global-blacklist.filter $f
done
