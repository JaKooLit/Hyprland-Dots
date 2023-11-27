#!/bin/bash

SCRIPTSDIR="$HOME/.config/hypr/scripts"

# WALLPAPERS PATH
DIR="$HOME/Pictures/wallpapers/"

# Transition config
FPS=30
TYPE="simple"
DURATION=3
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

# Check if swaybg is running
if pidof swaybg > /dev/null; then
  pkill swaybg
fi

# Retrieve image files
PICS=($(ls "${DIR}" | grep -E ".jpg$|.jpeg$|.png$|.gif$"))
RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME="${#PICS[@]}. random"

# Rofi command
rofi_command="rofi -dmenu -config ~/.config/rofi/config-wallpaper.rasi"

menu() {
  for i in "${!PICS[@]}"; do
    # Displaying .gif to indicate animated images
    if [[ -z $(echo "${PICS[$i]}" | grep .gif$) ]]; then
      filename=$(basename "${PICS[$i]}" | sed 's/\.[^.]*$//')  # Remove file extension
      printf "%s\n" "${filename//[[:digit:]]/}"  # Remove leading numbers
    else
      printf "%s\n" "${PICS[$i]}"
    fi
  done

  printf "%s\n" "$RANDOM_PIC_NAME"
}

swww query || swww init

main() {
  choice=$(menu | ${rofi_command})

  # No choice case
  if [[ -z $choice ]]; then
    exit 0
  fi

  # Random choice case
  if [ "$choice" = "$RANDOM_PIC_NAME" ]; then
    swww img "${DIR}/${RANDOM_PIC}" $SWWW_PARAMS
    exit 0
  fi

  pic_index=$(printf '%s\n' "${!PICS[@]}" | grep -E "\b${choice}\b")  # Get index based on choice
  swww img "${DIR}/${PICS[$pic_index]}" $SWWW_PARAMS
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
  exit 0
fi

main

${SCRIPTSDIR}/PywalSwww.sh &
${SCRIPTSDIR}/Refresh.sh &
sleep 1
${SCRIPTSDIR}/PywalDunst.sh
