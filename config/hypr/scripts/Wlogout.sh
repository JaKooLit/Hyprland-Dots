#!/bin/bash

# Set variables for parameters
A_2160=1000
B_2160=1000
A_1440=500
B_1440=550
A_1080=300
B_1080=380
A_720=50
B_720=50

# Check if wlogout is already running
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# Detect monitor resolution and scaling factor
resolution=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .height / .scale' | bc -l | cut -d '.' -f 1)
hypr_scale=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .scale')

echo "Detected Resolution: $resolution"

# Set parameters based on screen resolution and scaling factor
if ((resolution >= 2160)); then
    wlogout --protocol layer-shell -b 3 -T $(echo "$A_2160 * 2160 / $resolution * $hypr_scale" | bc -l) -B $(echo "$B_2160 * 2160 / $resolution * $hypr_scale" | bc -l) &
    echo "Setting parameters for resolution >= 2160p"
elif ((resolution >= 1440)); then
    wlogout --protocol layer-shell -b 6 -T $(echo "$A_1440 * 1440 / $resolution * $hypr_scale" | bc -l) -B $(echo "$B_1440 * 1440 / $resolution * $hypr_scale" | bc -l) &
    echo "Setting parameters for resolution >= 1440p"
elif ((resolution >= 1080)); then
    wlogout --protocol layer-shell -b 6 -T $(echo "$A_1080 * 1080 / $resolution * $hypr_scale" | bc -l) -B $(echo "$B_1080 * 1080 / $resolution * $hypr_scale" | bc -l) &
    echo "Setting parameters for resolution >= 1080p"
elif ((resolution > 720)); then
    wlogout --protocol layer-shell -b 3 -T $(echo "$A_720 * 720 / $resolution * $hypr_scale" | bc -l) -B $(echo "$B_720 * 720 / $resolution * $hypr_scale" | bc -l) &
    echo "Setting parameters for resolution >= 720p"
else
    wlogout &
    echo "Setting default parameters for resolution <= 720p"
fi

# Give some time for wlogout to start and exit
#sleep 30

# Check if wlogout is still running after starting
#if pgrep -x "wlogout" > /dev/null; then
#    pkill -x "wlogout"
#fi