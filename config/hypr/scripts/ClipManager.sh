#!/bin/bash
#   
# Clipboard Manager

if [[ ! $(pidof rofi) ]]; then
	cliphist list | rofi -dmenu -config ~/.config/rofi/config-long.rasi | cliphist decode | wl-copy
else
	pkill rofi
fi
