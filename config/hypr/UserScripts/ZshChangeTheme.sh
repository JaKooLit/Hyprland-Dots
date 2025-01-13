#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Oh my ZSH theme ( CTRL SHIFT O)

# preview of theme can be view here: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# after choosing theme, TTY need to be closed and re-open

themes_dir="$HOME/.oh-my-zsh/themes"
file_extension=".zsh-theme"

themes_array=($(find "$themes_dir" -type f -name "*$file_extension" -exec basename {} \; | sed -e "s/$file_extension//"))

# Add "Random" option to the beginning of the array
themes_array=("Random" "${themes_array[@]}")

rofi_command="rofi -i -dmenu -config ~/.config/rofi/config-zsh-theme.rasi"

menu() {
    for theme in "${themes_array[@]}"; do
        echo "$theme"
    done
}

main() {
    choice=$(menu | ${rofi_command})

    # if nothing selected, script won't change anything
    if [ -z "$choice" ]; then
        exit 0
    fi

    zsh_path="$HOME/.zshrc"
    var_name="ZSH_THEME"

    if [[ "$choice" == "Random" ]]; then
        # Pick a random theme from the original themes_array (excluding "Random")
        random_theme=${themes_array[$((RANDOM % (${#themes_array[@]} - 1) + 1))]}
        theme_to_set="$random_theme"
    else
        # Set theme to the selected choice
        theme_to_set="$choice"
    fi

    if [ -f "$zsh_path" ]; then
        sed -i "s/^$var_name=.*/$var_name=\"$theme_to_set\"/" "$zsh_path"
    else
        echo "File not found"
    fi
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

main
