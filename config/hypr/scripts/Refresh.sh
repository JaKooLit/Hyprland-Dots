#!/bin/bash

SCRIPTSDIR=$HOME/.config/hypr/scripts

# Kill already running processes
_ps=(waybar dunst rofi)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

# relaunch apps
dunst &
waybar &

#sleep 1
#${SCRIPTSDIR}/RainbowBorders.sh &