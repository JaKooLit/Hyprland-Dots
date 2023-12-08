#!/bin/bash

# Check if wlogout is already running
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# detect monitor res
x_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
y_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .height')
hypr_scale=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .scale')

# Set parameters based on screen resolution and scaling factor
if [[ $x_mon =~ ^[0-9]+$ && $y_mon =~ ^[0-9]+$ && $(echo "$hypr_scale > 0" | bc -l) -eq 1 ]]; then
    resolution=$(echo "$y_mon / $hypr_scale" | bc -l | cut -d '.' -f 1)
    
    echo "Detected Resolution: $resolution"

    if ((resolution >= 2160)); then
        wlogout --protocol layer-shell -b 6 -T $(echo "600 * 2160 / $resolution * $hypr_scale" | bc -l) -B $(echo "700 * 2160 / $resolution * $hypr_scale" | bc -l) &
        echo "Setting parameters for resolution >= 2160p"
    elif ((resolution >= 1440)); then
        wlogout --protocol layer-shell -b 6 -T $(echo "500 * 1440 / $resolution * $hypr_scale" | bc -l) -B $(echo "550 * 1440 / $resolution * $hypr_scale" | bc -l) &
        echo "Setting parameters for resolution >= 1440p"
    elif ((resolution >= 1080)); then
        wlogout --protocol layer-shell -b 6 -T $(echo "400 * 1080 / $resolution * $hypr_scale" | bc -l) -B $(echo "400 * 1080 / $resolution * $hypr_scale" | bc -l) &
        echo "Setting parameters for resolution >= 1080p"
    elif ((resolution > 720)); then
        wlogout --protocol layer-shell -b 3 -T $(echo "50 * 720 / $resolution * $hypr_scale" | bc -l) -B $(echo "50 * 720 / $resolution * $hypr_scale" | bc -l) &
        echo "Setting parameters for resolution >= 720p"
    else
        wlogout &
        echo "Setting default parameters for resolution <= 720p"
    fi
fi

# Give some time for wlogout to start and exit
#sleep 30

# Check if wlogout is still running after starting
#if pgrep -x "wlogout" > /dev/null; then
#    pkill -x "wlogout"
#fi
