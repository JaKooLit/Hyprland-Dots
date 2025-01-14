#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for refreshing ags, waybar, rofi, swaync, wallust

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

# Define file_exists function
file_exists() {
    if [ -e "$1" ]; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

# Kill already running processes
_ps=(waybar rofi swaync ags)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

killall -SIGUSR2 waybar # added since wallust sometimes not applying

# quit ags
ags -q

# relaunch ags
ags &

# Kill waybar & swaync (yet again) # added since wallust sometimes not applying
_ps2=(waybar swaync)
for _prs2 in "${_ps2[@]}"; do
    if pidof "${_prs2}" >/dev/null; then
        killall "${_prs2}"
    fi
done

# relaunch swaync
sleep 0.5
swaync > /dev/null 2>&1 &

#Restart waybar
sleep 1
waybar &

# Relaunching rainbow borders if the script exists
sleep 1
if file_exists "${UserScripts}/RainbowBorders.sh"; then
    ${UserScripts}/RainbowBorders.sh &
fi



exit 0