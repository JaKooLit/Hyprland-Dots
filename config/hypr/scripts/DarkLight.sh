#!/bin/bash
#set -x
# Paths
wallpaper_base_path="$HOME/Pictures/wallpapers/Dynamic-Wallpapers"
dark_wallpapers="$wallpaper_base_path/Dark"
light_wallpapers="$wallpaper_base_path/Light"
hypr_config_path="$HOME/.config/hypr"
dunst_config="$HOME/.config/dunst"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
dunst_notif="$HOME/.config/dunst/images/bell.png"
dark_rofi_pywal="$HOME/.cache/wal/colors-rofi-dark.rasi"
light_rofi_pywal="$HOME/.cache/wal/colors-rofi-light.rasi"

pkill swaybg

# Initialize swww if needed
swww query || swww init

# Set swww options
swww="swww img"
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 60 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

# Function to notify user
notify_user() {
    dunstify -u low -i "$dunst_notif" "Switching to $1 mode"
}

# Function to set Waybar style
set_waybar_style() {
    theme="$1"
    waybar_styles="$HOME/.config/waybar/style"
    waybar_style_link="$HOME/.config/waybar/style.css"
    style_prefix="\\[${theme}\\].*\\.css$"

    style_file=$(find "$waybar_styles" -maxdepth 1 -type f -regex ".*$style_prefix" | shuf -n 1)

    if [ -n "$style_file" ]; then
        ln -sf "$style_file" "$waybar_style_link"
    else
        echo "Style file not found for $theme theme."
    fi
}

# Determine current wallpaper mode
if [ "$(cat ~/.cache/.wallpaper_mode)" = "Light" ]; then
    next_mode="Dark"
    wallpaper_path="$dark_wallpapers"
else
    next_mode="Light"
    wallpaper_path="$light_wallpapers"
fi

# Call the function after determining the mode
set_waybar_style "$next_mode"

notify_user "$next_mode"

# Change background for dunst
if [ "$next_mode" = "Dark" ]; then
    sed -i '/background = /s/.*/    background = "#00000095"/' "${dunst_config}/dunstrc"
    sed -i '/foreground = /s/.*/    foreground = "#fafafa"/' "${dunst_config}/dunstrc"
else
    sed -i '/background = /s/.*/    background = "#ffffff99"/' "${dunst_config}/dunstrc"
    sed -i '/foreground = /s/.*/    foreground = "#00000095"/' "${dunst_config}/dunstrc"
fi

# Set Rofi Themes
if [ "$next_mode" = "Dark" ]; then
    ln -sf $dark_rofi_pywal "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
else
    ln -sf $light_rofi_pywal "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
fi

# Set Dynamic Wallpaper for Dark Mode
if [ "$next_mode" = "Dark" ]; then
    next_wallpaper="$(find "${dark_wallpapers}" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | shuf -n1 -z | xargs -0)"
fi

# Set Dynamic Wallpaper for Light Mode
if [ "$next_mode" = "Light" ]; then
    next_wallpaper="$(find "${light_wallpapers}" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | shuf -n1 -z | xargs -0)"
fi


$swww "${next_wallpaper}" $effect

# This is a referrence point for next cycle
echo "$next_mode" > ~/.cache/.wallpaper_mode
echo "$next_wallpaper" > ~/.cache/.current_wallpaper

# GTK themes and icons switching
set_custom_gtk_theme() {
    mode=$1
    gtk_themes_directory="$HOME/.themes"
    icon_directory="$HOME/.icons"
    theme_setting="org.gnome.desktop.interface gtk-theme"
    icon_setting="org.gnome.desktop.interface icon-theme"

    if [ "$mode" == "Light" ]; then
        search_keywords="*Light*"
    elif [ "$mode" == "Dark" ]; then
        search_keywords="*Dark*"
    else
        echo "Invalid mode provided."
        return 1
    fi

    themes=()
    icons=()

    while IFS= read -r -d '' theme_search; do
        themes+=("$(basename "$theme_search")")
    done < <(find "$gtk_themes_directory" -maxdepth 1 -type d -iname "$search_keywords" -print0)

    while IFS= read -r -d '' icon_search; do
        icons+=("$(basename "$icon_search")")
    done < <(find "$icon_directory" -maxdepth 1 -type d -iname "$search_keywords" -print0)

    if [ ${#themes[@]} -gt 0 ]; then
        if [ "$mode" == "Dark" ]; then
            selected_theme=${themes[RANDOM % ${#themes[@]}]}
        else
            selected_theme=${themes[$RANDOM % ${#themes[@]}]}
        fi
        echo "Selected GTK theme for $mode mode: $selected_theme"
        gsettings set $theme_setting "$selected_theme"
    else
        echo "No $mode GTK theme found"
    fi

    if [ ${#icons[@]} -gt 0 ]; then
        if [ "$mode" == "Dark" ]; then
            selected_icon=${icons[RANDOM % ${#icons[@]}]}
        else
            selected_icon=${icons[$RANDOM % ${#icons[@]}]}
        fi
        echo "Selected icon theme for $mode mode: $selected_icon"
        gsettings set $icon_setting "$selected_icon"
    else
        echo "No $mode icon theme found"
    fi
}

# Call the function to set GTK theme and icon theme based on mode
set_custom_gtk_theme "$next_mode"

# Run remaining scripts
${SCRIPTSDIR}/PywalSwww.sh &
sleep 2
${SCRIPTSDIR}/Refresh.sh 

dunstify -u low -i "$dunst_notif" "GTK theme set to $selected_theme"
dunstify -u low -i "$dunst_notif" "Icon theme set to $selected_icon"

exit 0

