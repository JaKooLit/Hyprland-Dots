#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */ 
# This script for selecting wallpapers (SUPER W)

# WALLPAPERS PATH
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# variables
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')
# swww transition config
FPS=60
TYPE="any"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

# Check if swaybg is running
if pidof swaybg > /dev/null; then
  pkill swaybg
fi

# Retrieve image files using null delimiter to handle spaces in filenames
mapfile -d '' PICS < <(find "${wallDIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print0)

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME=". random"

# Rofi command
rofi_command="rofi -i -show -dmenu -config ~/.config/rofi/config-wallpaper.rasi"

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
  
  # Trim any potential whitespace or hidden characters
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

  # Find the index of the selected file
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

