#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This script is used to play system sounds.

# Set the directory for system sounds.
sDIR="/usr/share/sounds/freedesktop/stereo"

# Set to true to mute the system sounds.
muted=false

if [[ "$muted" = true ]]; then
	exit 0
fi

if [[ "$1" == "--shutter" ]]; then
	pw-play "$sDIR/camera-shutter.oga"
elif [[ "$1" == "--volume" ]]; then
	pw-play "$sDIR/audio-volume-change.oga"
fi
