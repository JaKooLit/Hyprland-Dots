#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# wlogout (Power, Screen Lock, Suspend, etc)

# Set variables for parameters
A_2160=680
B_2160=750
A_1440=500
B_1440=550
A_1080=400
B_1080=400
A_720=50
B_720=50

# Check if wlogout is already running
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# Detect monitor resolution and scaling factor
resolution=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .height / .scale' | awk -F'.' '{print $1}')
hypr_scale=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .scale')

echo "Detected Resolution: $resolution"

# Set parameters based on screen resolution and scaling factor
if ((resolution >= 2160)); then
    wlogout --protocol layer-shell -b 3 -T $(awk "BEGIN {printf \"%.0f\", $A_2160 * 2160 * $hypr_scale / $resolution}") -B $(awk "BEGIN {printf \"%.0f\", $B_2160 * 2160 * $hypr_scale / $resolution}") &
    echo "Setting parameters for resolution >= 2160p"
elif ((resolution >= 1440)); then
    wlogout --protocol layer-shell -b 6 -T $(awk "BEGIN {printf \"%.0f\", $A_1440 * 1440 * $hypr_scale / $resolution}") -B $(awk "BEGIN {printf \"%.0f\", $B_1440 * 1440 * $hypr_scale / $resolution}") &
    echo "Setting parameters for resolution >= 1440p"
elif ((resolution >= 1080)); then
    wlogout --protocol layer-shell -b 6 -T $(awk "BEGIN {printf \"%.0f\", $A_1080 * 1080 * $hypr_scale / $resolution}") -B $(awk "BEGIN {printf \"%.0f\", $B_1080 * 1080 * $hypr_scale / $resolution}") &
    echo "Setting parameters for resolution >= 1080p"
elif ((resolution > 720)); then
    wlogout --protocol layer-shell -b 3 -T $(awk "BEGIN {printf \"%.0f\", $A_720 * 720 * $hypr_scale / $resolution}") -B $(awk "BEGIN {printf \"%.0f\", $B_720 * 720 * $hypr_scale / $resolution}") &
    echo "Setting parameters for resolution >= 720p"
else
    wlogout &
    echo "Setting default parameters for resolution <= 720p"
fi