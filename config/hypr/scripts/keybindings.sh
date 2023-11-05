#!/bin/bash

# Define keybindings.conf location
# ----------------------------------------------------- 
config_file="~/.config/hypr/configs/Keybinds.conf"

# ----------------------------------------------------- 
# Parse keybindings
# ----------------------------------------------------- 
keybinds=$(grep -oP '(?<=bind = ).*' $config_file)
keybinds=$(echo "$keybinds" | sed 's/$mainMod/SUPER/g'|  sed 's/,\([^,]*\)$/ = \1/' | sed 's/, exec//g' | sed 's/^,//g')

# ----------------------------------------------------- 
# Show keybindings in rofi
# ----------------------------------------------------- 
rofi -dmenu -p "Keybinds" -config ~/.config/rofi/config-short <<< "$keybinds"