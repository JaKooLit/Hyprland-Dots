#!/bin/bash

# THIS SCRIPT CAN BE DELETED ONCE BOOTED!!

# A bash script designed to ran it only once dotfiles installed
# Check if a marker file exists.
if [ ! -f ~/.config/hypr/.initial_startup_done ]; then

	# Check if the ~/.cache/wal directory exists
	if [ ! -d ~/.cache/wal ]; then
    	printf " Initializing pywal........\n\n"
    	# Check if the ~/Pictures/wallpapers directory exists
    	if [ -d ~/Pictures/wallpapers ]; then
        	# Run wal with random wallpapers from ~/Pictures/wallpapers
        	wal -i ~/Pictures/wallpapers/mecha-nostalgia.png 
        	echo "Pywal initialized"
		fi
	fi

	#initial symlink for Pywal Dark and Light for Rofi Themes
	ln -sf "$HOME/.cache/wal/colors-rofi-dark.rasi" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
	
	# Initial scripts to load inorder to have a proper wallpaper waybar and pywal themes
	exec $HOME/.config/hypr/scripts/Wallpaper.sh &
	
    # Create a marker file to indicate that the script has been executed.
    touch ~/.config/hypr/.initial_startup_done
fi


