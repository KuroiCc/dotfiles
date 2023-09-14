# add disable option special character.keylayout to ~/Library/Keyboard Layouts
# 防止日文输入法下特殊字符输入
# 尤其是 option + shift + f 会输入Ï的问题

if test ! "$(uname)" = "Darwin"; then
    exit 0
fi

ln -sf $DOTFILES/macos/DisableOptionSpecialCharacter.keylayout ~/Library/Keyboard\ Layouts/DisableOptionSpecialCharacter.keylayout
