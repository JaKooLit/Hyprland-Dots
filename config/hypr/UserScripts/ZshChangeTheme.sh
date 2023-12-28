#!/bin/bash

themes_dir="$HOME/.oh-my-zsh/themes"
file_extension=".zsh-theme"

themes_array=($(find "$themes_dir" -type f -name "*$file_extension" -exec basename {} \; | sed -e "s/$file_extension//"))

rofi_command="rofi -dmenu -config ~/.config/rofi/config-zsh-theme.rasi"

menu() {
    for theme in "${themes_array[@]}"; do
        echo "$theme"
    done
}

main() {
    choice=$(menu | ${rofi_command})

    # if nothing selected, script wont change anything
    if [ -z "$choice" ]; then
        exit 0
    fi

    zsh_path="$HOME/.zshrc"
    var_name="ZSH_THEME"
    for i in "${themes_array[@]}"; do
        if [[ "$i" == "$choice"* ]]; then
            if [ -f "$zsh_path" ]; then
                sed -i "s/^$var_name=.*/$var_name=\"$i\"/" "$zsh_path"
            else
                echo "File not found"
            fi
            break
        fi
    done
}

main
