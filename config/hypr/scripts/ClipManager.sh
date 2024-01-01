#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Clipboard Manager. This needed cliphist & wl-copy and of course rofi

if [[ ! $(pidof rofi) ]]; then
	cliphist list | rofi -dmenu -config ~/.config/rofi/config-long.rasi | cliphist decode | wl-copy
else
	pkill rofi
fi
