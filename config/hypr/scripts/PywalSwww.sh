#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Pywal Colors for current wallpaper

# Define the path to the swww cache directory
cache_dir="$HOME/.cache/swww/"

# Get a list of monitor outputs
monitor_outputs=($(ls "$cache_dir"))

# Initialize a flag to determine if the ln command was executed
ln_success=false

# Get first valid monitor
current_monitor=$(hyprctl -j monitors | jq -r '.[0].name')
echo $current_monitor
# Construct the full path to the cache file
cache_file="$cache_dir$current_monitor"
echo $cache_file
# Check if the cache file exists for the current monitor output
if [ -f "$cache_file" ]; then
    # Get the wallpaper path from the cache file
    wallpaper_path=$(cat "$cache_file")
    echo $wallpaper_path
    # Copy the wallpaper to the location Rofi can access
    if ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"; then
        ln_success=true  # Set the flag to true upon successful execution
    fi
fi

# Check the flag before executing further commands
if [ "$ln_success" = true ]; then
    # execute pywal
    # wal -i "$wallpaper_path"
	echo 'about to execute wal'
    # execute pywal skipping tty and terminal changes
    wal -i "$wallpaper_path" -s -t &
fi
