#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This script is used to play system sounds.

theme="freedesktop" # Set the theme for the system sounds.
muted=false         # Set to true to mute the system sounds.

# Exit if the system sounds are muted.
if [[ "$muted" = true ]]; then
    exit 0
fi

# Set the directory defaults for system sounds.
userDIR="$HOME/.local/share/sounds"
systemDIR="/usr/share/sounds"
defaultTheme="freedesktop"

# Prefer the user's theme, but use the system's if it doesn't exist.
sDIR="$systemDIR/$defaultTheme"
if [ -d "$userDIR/$theme" ]; then
    sDIR="$userDIR/$theme"
elif [ -d "$systemDIR/$theme" ]; then
    sDIR="$systemDIR/$theme"
fi

# Get the theme that it inherits.
iTheme=$(cat "$sDIR/index.theme" | grep -i "inherits" | cut -d "=" -f 2)
iDIR="$sDIR/../$iTheme"

# Choose the sound to play.
if [[ "$1" == "--shutter" ]]; then
    soundoption="camera-shutter.*"
elif [[ "$1" == "--volume" ]]; then
    soundoption="audio-volume-change.*"
fi

# Find the sound file and play it.
sound_file=$(find $sDIR/stereo -name "$soundoption" -print -quit)
if test -f "$sound_file"; then
    pw-play "$sound_file"
else
    sound_file=$(find $iDIR/stereo -name "$soundoption" -print -quit)
    if test -f "$sound_file"; then
        pw-play "$sound_file"
    elif test -f "$userDIR/$defaultTheme/$soundoption"; then
        pw-play "$userDIR/$defaultTheme/$soundoption"
    else
        pw-play "$systemDIR/$defaultTheme/$soundoption"
    fi
fi
