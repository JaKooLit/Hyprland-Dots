#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Random Wallpaper ( CTRL ALT W)

wallDIR="$HOME/Pictures/wallpapers"
scriptsDir="$HOME/.config/hypr/scripts"

monitors=$(hyprctl monitors | grep 'Monitor' | awk '{ print $2 }')

PICS=($(find ${wallDIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}


# Transition config
FPS=60
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"


for monitor in $monitors; do
  swww query || swww-daemon --format xrgb && swww img -o $monitor ${RANDOMPICS} $SWWW_PARAMS
done

sleep 1
${scriptsDir}/WallustSwww.sh
sleep 0.5
${scriptsDir}/Refresh.sh 

