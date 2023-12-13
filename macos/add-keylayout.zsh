# add disable option special character.keylayout to ~/Library/Keyboard Layouts
# 防止日文输入法下特殊字符输入
# 尤其是 option + shift + f 会输入的问题

if test ! "$(uname)" = "Darwin"; then
    exit 0
fi

file_name="DisableOptionSpecialCharacter.keylayout"

target_paths=("/Library/Keyboard Layouts" "$HOME/Library/Keyboard Layouts")

# 使用 for 循环遍历数组
for f_path in "${target_paths[@]}"; do
    f_path="$f_path/$file_name"
    if test -f "$f_path"; then
        rm "$f_path"
    fi
    cp "$HOME/.dotfiles/macos/DisableOptionSpecialCharacter.keylayout" "$f_path"
done
