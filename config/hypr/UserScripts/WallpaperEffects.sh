#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Wallpaper Effects using ImageMagick (SUPER SHIFT W)

# Variables
terminal=kitty
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
wallpaper_output="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# swww transition config
FPS=60
TYPE="wipe"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

# Define ImageMagick effects
declare -A effects=(
    ["No Effects"]="no-effects"
    ["Black & White"]="magick $wallpaper_current -colorspace gray -sigmoidal-contrast 10,40% $wallpaper_output"
    ["Blurred"]="magick $wallpaper_current -blur 0x10 $wallpaper_output"
    ["Charcoal"]="magick $wallpaper_current -charcoal 0x5 $wallpaper_output"
    ["Edge Detect"]="magick $wallpaper_current -edge 1 $wallpaper_output"
    ["Emboss"]="magick $wallpaper_current -emboss 0x5 $wallpaper_output"
    ["Frame Raised"]="magick $wallpaper_current +raise 150 $wallpaper_output"
    ["Frame Sunk"]="magick $wallpaper_current -raise 150 $wallpaper_output"
    ["Negate"]="magick $wallpaper_current -negate $wallpaper_output"
    ["Oil Paint"]="magick $wallpaper_current -paint 4 $wallpaper_output"
    ["Posterize"]="magick $wallpaper_current -posterize 4 $wallpaper_output"
    ["Polaroid"]="magick $wallpaper_current -polaroid 0 $wallpaper_output"
    ["Sepia Tone"]="magick $wallpaper_current -sepia-tone 65% $wallpaper_output"
    ["Solarize"]="magick $wallpaper_current -solarize 80% $wallpaper_output"
    ["Sharpen"]="magick $wallpaper_current -sharpen 0x5 $wallpaper_output"
    ["Vignette"]="magick $wallpaper_current -vignette 0x3 $wallpaper_output"
    ["Vignette-black"]="magick $wallpaper_current -background black -vignette 0x3 $wallpaper_output"
    ["Zoomed"]="magick $wallpaper_current -gravity Center -extent 1:1 $wallpaper_output"
)

# Function to apply no effects
no-effects() {
    swww img -o "$focused_monitor" "$wallpaper_current" $SWWW_PARAMS &&
    # Wait for swww command to complete
    wait $!
    # Run other commands after swww
    wallust run "$wallpaper_current" -s &&
    wait $!
    # Refresh rofi, waybar, wallust palettes
	sleep 2
	"$SCRIPTSDIR/Refresh.sh"

    notify-send -u low -i "$iDIR/ja.png" "No wallpaper" "effects applied"
    # copying wallpaper for rofi menu
    cp "$wallpaper_current" "$wallpaper_output"
}

# Function to run rofi menu
main() {
    # Populate rofi menu options
    options=("No Effects")
    for effect in "${!effects[@]}"; do
        [[ "$effect" != "No Effects" ]] && options+=("$effect")
    done

    choice=$(printf "%s\n" "${options[@]}" | LC_COLLATE=C sort | rofi -dmenu -i -config ~/.config/rofi/config-wallpaper-effect.rasi)

    # Process user choice
    if [[ -n "$choice" ]]; then
        if [[ "$choice" == "No Effects" ]]; then
            no-effects
        elif [[ "${effects[$choice]+exists}" ]]; then
            # Apply selected effect
            notify-send -u normal -i "$iDIR/ja.png"  "Applying:" "$choice effects"
            eval "${effects[$choice]}"
            # Wait for effects to be applied
            sleep 1
            # Execute swww command after image conversion
            swww img -o "$focused_monitor" "$wallpaper_output" $SWWW_PARAMS &
            # Wait for swww command to complete
            sleep 2
            # Wait for other commands to finish
            wallust run "$wallpaper_output" -s &
            # Wait for other commands to finish
            sleep 0.5
            # Refresh rofi, waybar, wallust palettes
            "${SCRIPTSDIR}/Refresh.sh"
            notify-send -u low -i "$iDIR/ja.png" "$choice" "effects applied"
        else
            echo "Effect '$choice' not recognized."
        fi
    fi
}

# Check if rofi is already running and kill it
if pidof rofi > /dev/null; then
    pkill rofi
fi

main

sleep 1
# Check if user selected a wallpaper
if [[ -n "$choice" ]]; then
    sddm_sequoia="/usr/share/sddm/themes/sequoia_2"
    if [ -d "$sddm_sequoia" ]; then
        notify-send -i "$iDIR/ja.png" "Set wallpaper" "as SDDM background?" \
            -t 10000 \
            -A "yes=Yes" \
            -A "no=No" \
            -h string:x-canonical-private-synchronous:wallpaper-notify

        # Wait for user input using dbus-monitor
        dbus-monitor "interface='org.freedesktop.Notifications',member='ActionInvoked'" |
        while read -r line; do
          if echo "$line" | grep -q "yes"; then
            $terminal -e bash -c "echo 'Enter your password to set wallpaper as SDDM Background'; \
            sudo cp -r $wallpaper_output '$sddm_sequoia/backgrounds/default' && \
            notify-send -i '$iDIR/ja.png' 'SDDM' 'Background SET'"
            break
          elif echo "$line" | grep -q "no"; then
            echo "Wallpaper not set as SDDM background. Exiting."
            break
          fi
        done &
    fi
fi
