# add disable option special character.keylayout to ~/Library/Keyboard Layouts
# 防止日文输入法下特殊字符输入
# 尤其是 option + shift + f 会输入的问题

if test ! "$(uname)" = "Darwin"; then
    return
fi

file_name="DisableOptionSpecialCharacter.keylayout"

target_paths=("/Library/Keyboard Layouts" "$HOME/Library/Keyboard Layouts")

# 判断target_paths目录的owner是否是$USER
for f_path in "${target_paths[@]}"; do
    if test -d "$f_path" && test ! "$(stat -f %Su $f_path)" = "$USER"; then
        echo "Change $f_path owner to $USER"
        sudo chown -R "$USER" "$f_path"
    fi
done

# 使用 for 循环遍历数组
for f_path in "${target_paths[@]}"; do
    f_path="$f_path/$file_name"
    if test -f "$f_path"; then
        rm "$f_path"
    fi
    cp "$HOME/.dotfiles/macos/DisableOptionSpecialCharacter.keylayout" "$f_path"
done
