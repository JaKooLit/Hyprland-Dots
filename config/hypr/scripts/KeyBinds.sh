#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Searchable enabled keybinds using rofi

# Kill yad to not interfere with this binds
pkill yad || true

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Define the config files
KEYBINDS_CONF="$HOME/.config/hypr/configs/Keybinds.conf"
USER_KEYBINDS_CONF="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
LAPTOP_CONF="$HOME/.config/hypr/UserConfigs/Laptop.conf"

# Combine the contents of the keybinds files and filter for keybinds
KEYBINDS=$(cat "$KEYBINDS_CONF" "$USER_KEYBINDS_CONF" | grep -E '^(bind|bindl|binde|bindm)')

# Check if Laptop.conf exists and add its keybinds if present
if [[ -f "$LAPTOP_CONF" ]]; then
    LAPTOP_BINDS=$(grep -E '^(bind|bindl|binde|bindm)' "$LAPTOP_CONF")
    KEYBINDS+=$'\n'"$LAPTOP_BINDS"
fi

# check for any keybinds to display
if [[ -z "$KEYBINDS" ]]; then
    echo "No keybinds found."
    exit 1
fi

# Use rofi to display the keybinds
echo "$KEYBINDS" | rofi -dmenu -i -p "Keybinds" -config ~/.config/rofi/config-keybinds.rasi