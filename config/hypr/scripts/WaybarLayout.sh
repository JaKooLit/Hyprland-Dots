#!/bin/bash

CONFIG="$HOME/.config/waybar/configs"
WCONFIG="$HOME/.config/waybar/config"

menu() {
    # List only files (excluding directories) in the directory and sort alphabetically
    options=()
    while IFS= read -r file; do
        if [ -f "$CONFIG/$file" ]; then
            options+=("$file")
        fi
    done < <(find "$CONFIG" -maxdepth 1 -type f -exec basename {} \; | sort)
    
    printf '%s\n' "${options[@]}"
}

apply_config() {
    ln -sf "$CONFIG/$1" "$WCONFIG"
}

main() {
    choice=$(menu | rofi -dmenu -config ~/.config/rofi/config-waybar-layout.rasi)

    if [[ -z "$choice" ]]; then
        echo "No option selected. Exiting."
        exit 0
    fi

    case $choice in
        "no panel")
            if pgrep -x "waybar" >/dev/null; then
                pkill waybar
            fi
            exit 0
            ;;
        *)
            apply_config "$choice"
            ;;
    esac
}

# Check if rofi is already running
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    exit 0
fi

main

~/.config/hypr/scripts/Refresh.sh &
