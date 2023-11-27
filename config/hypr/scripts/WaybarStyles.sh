#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Define directories
config_dir="$HOME/.config/waybar/style"
waybar_config="$HOME/.config/waybar/style.css"
scripts_dir="$HOME/.config/hypr/scripts"
rofi_config="$HOME/.config/rofi/config-waybar-style.rasi"

# Function to display menu options
menu() {
    options=()
    while IFS= read -r file; do
        if [ -f "$config_dir/$file" ]; then
            options+=("$(basename "$file" .css)")
        fi
    done < <(find "$config_dir" -maxdepth 1 -type f -name '*.css' -exec basename {} \; | sort)
    
    printf '%s\n' "${options[@]}"
}

# Apply selected style
apply_style() {
    ln -sf "$config_dir/$1.css" "$waybar_config"
    restart_waybar_if_needed
}

# Restart Waybar if it's running
restart_waybar_if_needed() {
    if pgrep -x "waybar" >/dev/null; then
        pkill waybar
        sleep 0.1  # Delay for Waybar to completely terminate
    fi
    "${scripts_dir}/Refresh.sh" &
}

# Main function
main() {
    choice=$(menu | rofi -dmenu -config "$rofi_config")

    if [[ -z "$choice" ]]; then
        echo "No option selected. Exiting."
        exit 0
    fi

    apply_style "$choice"
}

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    exit 0
fi

main
