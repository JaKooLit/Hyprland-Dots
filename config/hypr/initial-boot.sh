#!/bin/bash

# THIS SCRIPT CAN BE DELETED ONCE BOOTED!!

# A bash script designed to ran it only once dotfiles installed
# Check if a marker file exists.
if [ ! -f ~/.hyprland_startup_done ]; then

	# Check if the ~/.cache/wal directory exists
	if [ ! -d ~/.cache/wal ]; then
    	printf " Initializing pywal........\n\n"
    	# Check if the ~/Pictures/wallpapers directory exists
    	if [ -d ~/Pictures/wallpapers ]; then
        	# Run wal with random wallpapers from ~/Pictures/wallpapers
        	wal -i ~/Pictures/wallpapers/* 
        	echo "Pywal initialized"

			#initial symlink for Pywal Dark and Light for Rofi Themes
			ln -sf "$HOME/.cache/wal/colors-rofi-dark.rasi" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
		fi
	fi

	# Initializing the initial wallpaper and wal
	exec ~/.config/hypr/scripts/Wallpaper.sh &

    # Create a marker file to indicate that the script has been executed.
    touch ~/.hyprland_startup_done
fi


