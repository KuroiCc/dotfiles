# Build fpath in the path phase: oh-my-zsh (loaded later from
# user-app/ohmyzsh/config.zsh) runs the single compinit for this shell, so
# every completion/function dir must already be in fpath by then.

# add each topic folder to fpath so that they can add functions and completion scripts
for topic_folder ($DOTFILES/*) if [ -d $topic_folder ]; then  fpath=($topic_folder $fpath); fi;

fpath=($DOTFILES/functions $fpath)
