# Build fpath in the path phase: oh-my-zsh (loaded later from
# user-app/ohmyzsh/config.zsh) runs the single compinit for this shell, so
# every completion/function dir must already be in fpath by then.

# add each topic folder to fpath so that they can add functions and completion scripts
# (folders wholly ignored by .dotfilesignore.local are skipped; see script/lib/dotfiles-files)
for topic_folder ($DOTFILES/*) if [ -d $topic_folder ] && ! dotfiles_dir_ignored $topic_folder; then  fpath=($topic_folder $fpath); fi;

dotfiles_dir_ignored $DOTFILES/functions || fpath=($DOTFILES/functions $fpath)
