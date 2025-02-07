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
mapfile -d '' PICS < <(find "${wallDIR}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.pnm" -o -iname "*.tga" -o -iname "*.tiff" -o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.farbfeld" -o -iname "*.png" -o -iname "*.gif" \) -print0)

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

sleep 3 # add delay of 3 seconds for those who have slow machines
sddm_sequoia="/usr/share/sddm/themes/sequoia_2"
if [ -d "$sddm_sequoia" ]; then
    notify-send -i "$iDIR/ja.png" "Set wallpaper" "as SDDM background?" \
        -t 10000 \
        -A "yes=Yes" \
        -A "no=No" \
        -h string:x-canonical-private-synchronous:wallpaper-notify

    # Wait for user input using a background process
    dbus-monitor "interface='org.freedesktop.Notifications',member='ActionInvoked'" |
    while read -r line; do
      if echo "$line" | grep -q "yes"; then
      $terminal -e bash -c "echo 'Enter your password to set wallpaper as SDDM Background'; \
      sudo cp -r $wallpaper_current '$sddm_sequoia/backgrounds/default' && \
      notify-send -i '$iDIR/ja.png' 'SDDM' 'Background SET'"
            break
        elif echo "$line" | grep -q "no"; then
            break
        fi
    done &
fi

