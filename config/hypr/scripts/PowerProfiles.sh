#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For applying Pre-configured Power Profiles

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi
# Variables
iDIR="$HOME/.config/swaync/images"

# Check if powerprofilesctl exists and it is executable
if [ ! -x powerprofilesctl ]; then
    notify-send -u low -i "$iDIR/ja.png" "powerprofilesctl is not found"
fi

# list of Monitor Profiles, sorted alphabetically with numbers first
power_profiles_list=$(powerprofilesctl list | grep -oP '([a-z-]+):$' | sed 's/:$//')

# Rofi Menu
chosen_power_profile=$(echo "$power_profiles_list" | rofi -i -dmenu -config $rofi_theme)

if [[ -n "$chosen_power_profile" ]]; then
    notify-send -u low -i "$iDIR/ja.png" "$chosen_power_profile" "Power Profile Loaded"
fi

sleep 1
powerprofilesctl set $chosen_power_profile
