#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */ 
# This script for selecting wallpapers (SUPER W)

# WALLPAPERS PATH
terminal=kitty
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# variables
rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

# Monitor details
scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')

icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)

# Apply limit
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')

# Setting the rofi override with the adjusted icon size
rofi_override="element-icon{size:${adjusted_icon_size}%;}"


# swww transition config
FPS=60
TYPE="any"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Check if swaybg is running
if pidof swaybg > /dev/null; then
  pkill swaybg
fi

# Retrieve image files using null delimiter to handle spaces in filenames
mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.pnm" -o -iname "*.tga" -o -iname "*.tiff" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.farbfeld" -o -iname "*.png" -o -iname "*.gif" \) -print0)

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME=". random"

# Rofi command
rofi_command="rofi -i -show -dmenu -config $rofi_theme -theme-str $rofi_override"

# Sorting Wallpapers
menu() {
  # Sort the PICS array
  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))
  
  # Place ". random" at the beginning with the random picture as an icon
  printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$RANDOM_PIC"
  
  for pic_path in "${sorted_options[@]}"; do
    pic_name=$(basename "$pic_path")
    
    # Displaying .gif to indicate animated images
    if [[ ! "$pic_name" =~ \.gif$ ]]; then
      printf "%s\x00icon\x1f%s\n" "$(echo "$pic_name" | cut -d. -f1)" "$pic_path"
    else
      printf "%s\n" "$pic_name"
    fi
  done
}

# initiate swww if not running
swww query || swww-daemon --format xrgb

# Choice of wallpapers
main() {
  choice=$(menu | $rofi_command)
  
  choice=$(echo "$choice" | xargs)
  RANDOM_PIC_NAME=$(echo "$RANDOM_PIC_NAME" | xargs)

  # No choice case
  if [[ -z "$choice" ]]; then
    echo "No choice selected. Exiting."
    exit 0
  fi

  # Random choice case
  if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
	swww img -o "$focused_monitor" "$RANDOM_PIC" $SWWW_PARAMS;
    sleep 2
    "$SCRIPTSDIR/WallustSwww.sh"
    sleep 0.5
    "$SCRIPTSDIR/Refresh.sh"
    exit 0
  fi

  pic_index=-1
  for i in "${!PICS[@]}"; do
    filename=$(basename "${PICS[$i]}")
    if [[ "$filename" == "$choice"* ]]; then
      pic_index=$i
      break
    fi
  done

  if [[ $pic_index -ne -1 ]]; then
    swww img -o "$focused_monitor" "${PICS[$pic_index]}" $SWWW_PARAMS
  else
    echo "Image not found."
    exit 1
  fi

}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

main

wait $!
"$SCRIPTSDIR/WallustSwww.sh" &&

wait $!
sleep 2
"$SCRIPTSDIR/Refresh.sh"

sleep 1
# Check if user selected a wallpaper
if [[ -n "$choice" ]]; then
  sddm_sequoia="/usr/share/sddm/themes/sequoia_2"
  if [ -d "$sddm_sequoia" ]; then
    if yad --info --text="Set current wallpaper as SDDM background?\n\nNOTE: This only applies to SEQUOIA SDDM Theme" \
    --text-align=left \
    --title="SDDM Background" \
    --timeout=10 \
    --timeout-indicator=right \
    --button="yad-yes:0" \
    --button="yad-no:1" \
    ; then

    # Check if terminal exists
    if ! command -v "$terminal" &>/dev/null; then
    notify-send -i "$iDIR/ja.png" "Missing $terminal" "Install $terminal to enable setting of wallpaper background"
    exit 1
    fi

    # Open terminal to enter password
    $terminal -e bash -c "echo 'Enter your password to set wallpaper as SDDM Background'; \
    sudo cp -r $wallpaper_current '$sddm_sequoia/backgrounds/default' && \
    notify-send -i '$iDIR/ja.png' 'SDDM' 'Background SET'"
    fi
  fi
fi