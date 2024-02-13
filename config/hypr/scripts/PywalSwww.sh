#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Pywal Colors for current wallpaper

# Define the path to the swww cache directory
cache_dir="$HOME/.cache/swww/"
laptop_display_file="$HOME/.config/hypr/UserConfigs/LaptopDisplay.conf"

# Get a list of monitor outputs
monitor_outputs=($(ls "$cache_dir"))

# Initialize a flag to determine if the ln command was executed
ln_success=false

# Loop through monitor outputs
for output in "${monitor_outputs[@]}"; do
    # Construct the full path to the cache file
    cache_file="$cache_dir$output"

    # Check if the cache file exists for the current monitor output
    if [ -f "$cache_file" ]; then
        # Get the wallpaper path from the cache file
        wallpaper_path=$(cat "$cache_file")

        # Copy the wallpaper to the location Rofi can access
        if ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"; then
            ln_success=true  # Set the flag to true upon successful execution
        fi

        # Check if the laptop display is not disabled
		if grep -q "preffered" $laptop_display_file; then
			break
		fi
    fi
done

# Check the flag before executing further commands
if [ "$ln_success" = true ]; then
    # execute pywal
    # wal -i "$wallpaper_path"

    # execute pywal skipping tty and terminal changes
    wal -i "$wallpaper_path" -s -t &
fi
