#!/bin/bash
set -x
# Define the path
wallpaper_path="$HOME/Pictures/wallpapers/Dynamic-Wallpapers"
hypr_config_path="$HOME/.config/hypr"
waybar_config="$HOME/.config/waybar"
dunst_config="$HOME/.config/dunst"

dark_rofi_pywal="$HOME/.cache/wal/colors-rofi-dark.rasi"
light_rofi_pywal="$HOME/.cache/wal/colors-rofi-light.rasi"


# Tokyo Night
light_gtk_theme="Tokyonight-Light-B"
dark_gtk_theme="Tokyonight-Dark-B"
light_icon_theme="TokyoNight-SE"
dark_icon_theme="TokyoNight-SE"

pkill swaybg

# Initialize swww if needed
swww query || swww init

# Set swww options
swww="swww img"
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 60 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

# Define functions for notifying user and updating symlinks
notify_user() {
	notify-send -h string:x-canonical-private-synchronous:sys-notify -u normal "Switching to $1 mode"
}

# Determine the current wallpaper mode by checking a configuration file
if [ "$(cat ~/.cache/.wallpaper_mode)" = "light" ]; then
  current_mode="light"
  next_mode="dark"
else
  current_mode="dark"
  next_mode="light"
fi
path_param=$(echo $next_mode | sed 's/.*/\u&/')

notify_user "$next_mode"
#ln -sf "${waybar_config}/style/style-pywal.css" "${waybar_config}/style.css"
ln -sf "${dunst_config}/styles/dunstrc-${next_mode}" "${dunst_config}/styles/dunstrc"

# Symlink for rofi theme
if [ "$next_mode" = "dark" ]; then
  ln -sf $dark_rofi_pywal "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
else
  ln -sf $light_rofi_pywal "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
fi

gtk_theme="${next_mode}_gtk_theme"
icon_theme="${next_mode}_icon_theme"

gsettings set org.gnome.desktop.interface gtk-theme "${!gtk_theme}"
gsettings set org.gnome.desktop.interface icon-theme "${!icon_theme}"

# Find the next wallpaper if one exists
current_wallpaper="$(cat ~/.cache/.current_wallpaper)"
next_wallpaper="${current_wallpaper/_"$current_mode"/_"$next_mode"}"

if ! [ -f "$next_wallpaper" ]; then
  next_wallpaper="$(find "${wallpaper_path/"${path_param}"}" -type f -iname "*_"${next_mode}".jpg" -print0 | shuf -n1 -z | xargs -0)"
fi

$swww "${next_wallpaper}" $effect

# Update the configuration file to reflect the new wallpaper mode and current wallpaper
echo "$next_mode" > ~/.cache/.wallpaper_mode
echo "$next_wallpaper" > ~/.cache/.current_wallpaper

exec ~/.config/hypr/scripts/PywalSwww.sh &
sleep 2
exec ~/.config/hypr/scripts/Refresh.sh &