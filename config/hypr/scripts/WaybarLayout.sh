#!/bin/bash

CONFIG="$HOME/.config/waybar/configs"
WCONFIG="$HOME/.config/waybar/config"

menu() {
    cat <<EOF
default
default-Bottom
Top(gnome)
Bottom(plasma)
simple-long
simple-short
Top-&-Bottom
Left
Right
Top-Left
Top-Right
Bottom-Left
Bottom-Right
all-sides
no panel
EOF
}

apply_config() {
    ln -sf "$CONFIG/config-$1" "$WCONFIG"
}

main() {
    choice=$(menu | rofi -dmenu -config ~/.config/rofi/config-waybar.rasi)

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
