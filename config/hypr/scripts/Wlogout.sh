#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */ ##
# wlogout (Power, Screen Lock, Suspend, etc)

# Parameters for screen resolutions
declare -A resolutions=(
    [2160]=450
    [1600]=450
    [1440]=450
    [1080]=350
    [720]=175
)

# Check if wlogout is already running, if so, kill it
if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
    exit 0
fi

# Detect the current monitor's native resolution and scale
monitor_info=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true)')

resolution=$(echo "$monitor_info" | jq -r '.height')
width=$(echo "$monitor_info" | jq -r '.width')
hypr_scale=$(echo "$monitor_info" | jq -r '.scale')

# Round hypr_scale to 2 decimal places for accurate comparison
rounded_scale=$(echo "scale=2; $hypr_scale/1" | bc)

# If resolution or scale is invalid or hypr_scale >= 1.25, run wlogout with -b 3
if [[ -z "$resolution" || ! "$resolution" =~ ^[0-9]+$ || -z "$hypr_scale" || $(echo "$rounded_scale >= 1.25" | bc) -eq 1 ]]; then
    echo "Hypr_scale is greater than or equal to 1.25 or resolution could not be detected, running wlogout with -b 3"
    wlogout --protocol layer-shell -b 3 -T 100 -B 100 &
    exit 0
fi

# Determine the appropriate resolution range and calculate T and B values
if ((resolution >= 2160)); then
    res_key=2160
elif ((resolution >= 1600)); then
    res_key=1600
elif ((resolution >= 1440)); then
    res_key=1440
elif ((resolution >= 1080)); then
    res_key=1080
else
    res_key=720
fi

# Calculate T and B values based on selected resolution and scale
T_val=$(awk "BEGIN {printf \"%.0f\", ${resolutions[$res_key]} * $res_key * $hypr_scale / $resolution}")
B_val=$(awk "BEGIN {printf \"%.0f\", ${resolutions[$res_key]} * $res_key * $hypr_scale / $resolution}")

# Output the resolution setting for debugging purposes
echo "Setting parameters for resolution >= $res_key"

# Run wlogout with -b 6 and calculated T/B values
wlogout --protocol layer-shell -b 6 -T $T_val -B $B_val &