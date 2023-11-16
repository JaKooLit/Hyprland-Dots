#!/bin/bash

CONFIG="$HOME/.config/waybar/style"
WCONFIG="$HOME/.config/waybar/style.css"

menu() {
    # List only files (excluding directories) in the directory and sort alphabetically
    options=()
    while IFS= read -r file; do
        if [ -f "$CONFIG/$file" ]; then
            options+=("$(basename "$file" .css)")
        fi
    done < <(find "$CONFIG" -maxdepth 1 -type f -name '*.css' -exec basename {} \; | sort)
    
    printf '%s\n' "${options[@]}"
}

apply_style() {
    ln -sf "$CONFIG/$1.css" "$WCONFIG"
}

main() {
    choice=$(menu | rofi -dmenu -config ~/.config/rofi/config-waybar-style.rasi)

    if [[ -z "$choice" ]]; then
        echo "No option selected. Exiting."
        exit 0
    fi

    apply_style "$choice"

    # Restart relevant processes
    for process in waybar mako dunst; do
        if pgrep -x "$process" >/dev/null; then
            pkill "$process"
        fi
    done

    # Launch Refresh.sh in the background
    ~/.config/hypr/scripts/Refresh.sh &
}

# Check if rofi is already running
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    exit 0
fi

main
