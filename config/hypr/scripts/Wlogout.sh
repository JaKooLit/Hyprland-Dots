#!/bin/bash

# Check if wlogout is already running
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# detect monitor res
x_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
y_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .height')
hypr_scale=$(hyprctl -j monitors | jq '.[] | select (.focused == true) | .scale' | sed 's/\.//')

# Set parameters based on screen resolution
if [[ $x_mon =~ ^[0-9]+$ && $y_mon =~ ^[0-9]+$ && $hypr_scale =~ ^[0-9]+$ ]]; then
    resolution=$((y_mon * hypr_scale / 100))
    
    echo "Detected Resolution: $resolution"

    if ((resolution >= 2160)); then
        wlogout --protocol layer-shell -b 6 -T 600 -B 700 &
        echo "Setting parameters for resolution >= 2160p"
    elif ((resolution >= 1440)); then
        wlogout --protocol layer-shell -b 6 -T 500 -B 550 &
        echo "Setting parameters for resolution >= 1440p"
    elif ((resolution >= 1080)); then
        wlogout --protocol layer-shell -b 6 -T 400 -B 400 &
        echo "Setting parameters for resolution >= 1080p"
    elif ((resolution >= 720)); then
        wlogout --protocol layer-shell -b 3 -T 50 -B 50 &
        echo "Setting parameters for resolution >= 720p"
 	fi
fi

# Give some time for wlogout to start and exit
#sleep 30

# Check if wlogout is still running after starting
#if pgrep -x "wlogout" > /dev/null; then
#    pkill -x "wlogout"
#fi
