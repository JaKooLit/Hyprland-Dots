#!/bin/bash

# WALLPAPERS PATH
DIR=$HOME/Pictures/wallpapers

# Transition config (type swww img --help for more settings
FPS=30
TYPE="simple"
DURATION=3

SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

PICS=($(ls ${DIR} | grep -e ".jpg$" -e ".jpeg$" -e ".png$" -e ".gif$"))
#PICS=($(find ${DIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \)))

RANDOM_PIC=${PICS[ $RANDOM % ${#PICS[@]} ]}
RANDOM_PIC_NAME="${#PICS[@]}. random"

# to check if swaybg is running
if [[ $(pidof swaybg) ]]; then
  pkill swaybg
fi

## Rofi Command
rofi_command="rofi -dmenu -config ~/.config/rofi/config-short.rasi"

menu(){
    # Here we are looping in the PICS array that is composed of all images in the $DIR folder
    for i in ${!PICS[@]}; do
        # keeping the .gif to make sue you know it is animated
        if [[ -z $(echo ${PICS[$i]} | grep .gif$) ]]; then
            printf "$i. $(echo ${PICS[$i]} | cut -d. -f1)\n" # n°. <name_of_file_without_identifier>
        else
            printf "$i. ${PICS[$i]}\n"
        fi
    done

    printf "$RANDOM_PIC_NAME"
}

swww query || swww init

main() {
    choice=$(menu | ${rofi_command})

    # no choice case
    if [[ -z $choice ]]; then return; fi

    # random choice case
    if [ "$choice" = "$RANDOM_PIC_NAME" ]; then
        swww img ${DIR}/${RANDOM_PIC} $SWWW_PARAMS
        return
    fi
    
    pic_index=$(echo $choice | cut -d. -f1)
    swww img ${DIR}/${PICS[$pic_index]} $SWWW_PARAMS
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
    pkill rofi
    exit 0
else
    main
fi

exec $HOME/.config/hypr/scripts/PywalSwww.sh &

exec $HOME/.config/hypr/scripts/Refresh.sh

# Uncomment to launch something if a choice was made 
# if [[ -n "$choice" ]]; then
    # Restart Waybar
# fi