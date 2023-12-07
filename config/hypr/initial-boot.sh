#!/bin/bash

# A bash script designed to ran it only once dotfiles installed

# THIS SCRIPT CAN BE DELETED ONCE SUCCESSFULLY BOOTED!! And also, edit ~/.config/hypr/configs/Execs.conf
# not necessary to do since this script is only designed to ran only once as long as the marker exist

# Set swww options
wallpaper=$HOME/Pictures/wallpapers/anime-girl-abyss.png

swww="swww img"
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 60 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

# Check if a marker file exists.
if [ ! -f ~/.config/hypr/.initial_startup_done ]; then

	# Initialize pywal
	printf " Initializing pywal........\n\n"
    wal -i $wallpaper 

	#initial symlink for Pywal Dark and Light for Rofi Themes
	ln -sf "$HOME/.cache/wal/colors-rofi-dark.rasi" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
	
	# Initial scripts to load inorder to have a proper wallpaper waybar and pywal themes
	swww query || swww init && $swww $wallpaper $effect
	
    # Create a marker file to indicate that the script has been executed.
    touch ~/.config/hypr/.initial_startup_done
fi


