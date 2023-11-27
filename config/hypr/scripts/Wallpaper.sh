#!/bin/bash

DIR="$HOME/Pictures/wallpapers/"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

PICS=($(find ${DIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}

swww query || swww init
swww img ${RANDOMPICS} --transition-fps 30 --transition-type any --transition-duration 3



${SCRIPTSDIR}/PywalSwww.sh &
sleep 1
${SCRIPTSDIR}/Refresh.sh &
sleep 1
${SCRIPTSDIR}/PywalDunst.sh