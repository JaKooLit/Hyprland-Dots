#!/usr/bin/env bash

SCRIPTSDIR=$HOME/.config/hypr/scripts

# Kill already running processes
_ps=(waybar rofi)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

# Relaunch waybar
waybar &

# Relaunch dunst with pywal-borders
${SCRIPTSDIR}/PywalDunst.sh &

# Relaunching rainbow borders
sleep 1
${SCRIPTSDIR}/RainbowBorders.sh &

# for cava-pywal (note, need to manually restart cava once wallpaper changes)
ln -sf "$HOME/.cache/wal/cava-colors" "$HOME/.config/cava/config" || true