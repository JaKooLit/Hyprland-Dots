#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Kitty Themes Source https://github.com/dexpota/kitty-themes #

# Define directories and variables
kitty_themes_DiR="$HOME/.config/kitty/kitty-themes" # Kitty Themes Directory
theme_path="$kitty_themes_DiR/$theme.conf"
kitty_config="$HOME/.config/kitty/kitty.conf"
iDIR="$HOME/.config/swaync/images"
rofi_theme="$HOME/.config/rofi/config-kitty-theme.rasi"

# List the kitty-theme files from the themes directory
theme=$(ls "$kitty_themes_DiR"/*.conf | xargs -n 1 basename | sed 's/\.conf$//' | rofi -dmenu -config $rofi_theme)

# Check if the user selected a theme
if [ -z "$theme" ]; then
  echo "No theme selected, exiting..."
  exit 1
fi

# Uncomment the line that includes the kitty themes if it's commented
if grep -q '#include ./kitty-themes/' "$kitty_config"; then
	sed -i "s|#include ./kitty-themes/|include ./kitty-themes/$theme.conf|g" "$kitty_config"
	
	notify-send -u low -i "$iDIR/ja.png" "$theme" "Kitty Theme Loaded"
	
	for pid_kitty in $(pidof kitty); do
	  kill -SIGUSR1 "$pid_kitty"
	done
else
  # If the line is already uncommented, just add the chosen theme
	sed -i "s|include ./kitty-themes/.*|include ./kitty-themes/$theme.conf|g" "$kitty_config"
	
	notify-send -u low -i "$iDIR/ja.png" "$theme" "Kitty Theme Loaded"
	
	for pid_kitty in $(pidof kitty); do
      kill -SIGUSR1 "$pid_kitty"
	done
fi
