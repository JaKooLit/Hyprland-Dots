#!/bin/bash

SCRIPTSDIR=$HOME/.config/hypr/scripts

# Kill already running process
_ps=(waybar mako dunst rofi)
for _prs in "${_ps[@]}"; do
	if [[ $(pidof ${_prs}) ]]; then
		pkill ${_prs}
	fi
done

# Lauch notification daemon (dunst)
${SCRIPTSDIR}/Dunst.sh &

# Lauch statusbar (waybar)
${SCRIPTSDIR}/Waybar.sh &
