#!/bin/bash

# A bash script designed to run only once dotfiles installed

# THIS SCRIPT CAN BE DELETED ONCE SUCCESSFULLY BOOTED!! And also, edit ~/.config/hypr/configs/Execs.conf
# not necessary to do since this script is only designed to run only once as long as the marker exists

# Variables
scriptsDir=$HOME/.config/hypr/scripts
wallpaper=$HOME/Pictures/wallpapers/Cute-Cat_ja.png

swww="swww img"
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 30 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

# Check if a marker file exists.
if [ ! -f ~/.config/hypr/.initial_startup_done ]; then

    # Initialize pywal
    printf " Initializing pywal........\n\n"
    wal -i $wallpaper -s -t

    # Initial symlink for Pywal Dark and Light for Rofi Themes
    ln -sf "$HOME/.cache/wal/colors-rofi-dark.rasi" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"

    # Initial scripts to load in order to have a proper wallpaper waybar and pywal themes
    swww init || swww query && $swww "$wallpaper" $effect

    # Refreshing waybar, dunst, rofi etc. 
    "$scriptsDir/PywalSwww.sh" > /dev/null 2>&1 &
    "$scriptsDir/Refresh.sh" > /dev/null 2>&1 &
    
    # initiate GTK dark mode and apply icon and cursor theme
    gsettings set org.gnome.desktop.interface gtk-theme Tokyonight-Dark-BL-LB > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface icon-theme Tokyonight-Dark > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-size 24 > /dev/null 2>&1 &
    
    # initiate the kb_layout (for some reason) waybar cant launch it
    "$scriptsDir/SwitchKeyboardLayout.sh" > /dev/null 2>&1 &

    # Create a marker file to indicate that the script has been executed.
    touch ~/.config/hypr/.initial_startup_done

    exit
fi
