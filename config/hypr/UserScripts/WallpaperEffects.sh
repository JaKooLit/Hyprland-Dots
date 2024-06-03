#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Wallpaper Effects using imagemagick
# Inspiration from ML4W - Stephan Raabe https://gitlab.com/stephan-raabe/dotfiles

# variables
current_wallpaper="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
wallpaper_output="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

# Directory for swaync
iDIR="$HOME/.config/swaync/images"

# swww transition config
FPS=60
TYPE="wipe"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

# Define ImageMagick effects
# https://imagemagick.org/script/magick.php

declare -A effects=(
["Black & White"]="magick $current_wallpaper -colorspace gray -sigmoidal-contrast 10,40% $wallpaper_output"
["Blurred"]="magick $current_wallpaper -blur 0x5 $wallpaper_output"
["Solarize"]="magick $current_wallpaper -solarize 80% $wallpaper_output"
["Sepia Tone"]="magick $current_wallpaper -sepia-tone 65% $wallpaper_output"
["Negate"]="magick $current_wallpaper -negate $wallpaper_output"
["Charcoal"]="magick $current_wallpaper -charcoal 0x5 $wallpaper_output"
["Edge Detect"]="magick $current_wallpaper -edge 1 $wallpaper_output"
["Emboss"]="magick $current_wallpaper -emboss 0x5 $wallpaper_output"
["Sharpen"]="magick $current_wallpaper -sharpen 0x5 $wallpaper_output"
["Oil Paint"]="magick $current_wallpaper -paint 4 $wallpaper_output"
["Vignette"]="magick $current_wallpaper -vignette 0x5 $wallpaper_output"
["Posterize"]="magick $current_wallpaper -posterize 4 $wallpaper_output"
["Polaroid"]="magick $current_wallpaper -polaroid 0 $wallpaper_output"
["No Effects"]="no-effects"
)

# Function to apply no effects
no_effects() {
    swww img -o "$focused_monitor" "$current_wallpaper" $SWWW_PARAMS &
    # Wait for swww command to complete
    wait $!
    # Run other commands after swww
    wallust run "$current_wallpaper" -s &
    # Wait to complete
    wait $!
    # Refresh rofi, waybar, wallust palettes
    "${SCRIPTSDIR}/Refresh.sh"
    notify-send -u low -i "$iDIR/bell.png" "No wallpaper effects"
	
	# copying wallpaper for rofi menu
	cp $current_wallpaper $wallpaper_output
}

# Function to run rofi menu
main() {
    # Populate rofi menu options
    options="No Effects"
    for effect in "${!effects[@]}"; do
        if [ "$effect" != "No Effects" ]; then
            options+="\n$effect"
        fi
    done

    # rofi
    choice=$(echo -e "$options" | rofi -i -dmenu -config ~/.config/rofi/config-wallpaper-effect.rasi) 
    if [ ! -z "$choice" ]; then
        # Check if the choice exists in the array
        if [[ "${effects[$choice]+exists}" ]]; then
            if [ "$choice" == "No Effects" ]; then
                no_effects
            else
                # Apply selected effect
                notify-send -u normal -i "$iDIR/bell.png" "Applying $choice effects"
                eval "${effects[$choice]}"
                # Wait for effects to be applied
                sleep 1
                # Execute swww command after image conversion
                swww img -o "$focused_monitor" "$wallpaper_output" $SWWW_PARAMS &
                # Wait for swww command to complete
                wait $!
                # Run other commands after swww
                wallust run "$wallpaper_output" -s &
                # Wait for other commands to finish
                wait $!
                # Refresh rofi, waybar, wallust palettes
                "${SCRIPTSDIR}/Refresh.sh"
                notify-send -u low -i "$iDIR/bell.png" "$choice effects applied"
            fi
        else
            echo "Effects not recognized."
        fi
    fi
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
  exit 0
fi

main
