#!/bin/bash
#   
# Clipboard Manager

if [[ ! $(pidof rofi) ]]; then
	#cliphist list | rofi -dmenu -config ~/.config/rofi/config-cliphist.rasi | cliphist decode | wl-copy
	cliphist list | rofi -dmenu | cliphist decode | wl-copy
else
	pkill rofi
fi
