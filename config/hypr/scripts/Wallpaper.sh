#!/bin/bash

DIR="$HOME/Pictures/wallpapers/"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

PICS=($(find ${DIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}


# Transition config
FPS=30
TYPE="any"
DURATION=3
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"


swww query || swww init && swww img ${RANDOMPICS} $SWWW_PARAMS


${SCRIPTSDIR}/PywalSwww.sh &
sleep 1
${SCRIPTSDIR}/Refresh.sh 

