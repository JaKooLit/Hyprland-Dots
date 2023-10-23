#!/bin/bash

# WOFI STYLES
CONFIG="$HOME/.config/wofi/WofiBig/config"
STYLE="$HOME/.config/wofi/style.css"
COLORS="$HOME/.config/wofi/colors"

if [[ ! $(pidof wofi) ]]; then
  cliphist list | wofi --show dmenu --prompt 'Search...' \
    --conf ${CONFIG} --style ${STYLE} --color ${COLORS} \
    --width=600 --height=400 | cliphist decode | wl-copy
else
	pkill wofi
fi