#!/bin/bash

# Check which waybar theme is set
THEMEIS=$(realpath ~/.config/waybar/style.css | sed 's/.*-\(.*\)\.css/\1/')

# Change theme
if [ "$THEMEIS" == "default" ]; then
    SWITCHTO="-b&w"
elif [ "$THEMEIS" == "b&w" ]; then
    SWITCHTO="-rgb"
elif [ "$THEMEIS" == "rgb" ]; then
    SWITCHTO="-default_alter"
elif [ "$THEMEIS" == "default_alter" ]; then
    SWITCHTO="-mauve"
elif [ "$THEMEIS" == "mauve" ]; then
    SWITCHTO="-light"
elif [ "$THEMEIS" == "light" ]; then
    SWITCHTO="-dark"
elif [ "$THEMEIS" == "dark" ]; then
    SWITCHTO="-uline"      
else
    SWITCHTO="-default"
fi

# Set the waybar theme
THEMEFILE="$HOME/.config/waybar/style/style${SWITCHTO}.css"
if [ -f "$THEMEFILE" ]; then
    ln -sf "$THEMEFILE" "$HOME/.config/waybar/style.css"

else
    echo "Error: $THEMEFILE not found"
    exit 1
fi

# Restart waybar
# Kill already running process
_ps=(waybar mako dunst)
for _prs in "${_ps[@]}"; do
	if [[ $(pidof ${_prs}) ]]; then
		pkill ${_prs}
	fi
done

exec ~/.config/hypr/scripts/Refresh.sh



