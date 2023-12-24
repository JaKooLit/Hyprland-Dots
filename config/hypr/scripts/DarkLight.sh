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

# Determine current theme mode
if [ "$(cat $HOME/.cache/.theme_mode)" = "Light" ]; then
    next_mode="Dark"
    # Logic for Dark mode
    wallpaper_path="$dark_wallpapers"
else
    next_mode="Light"
    # Logic for Light mode
    wallpaper_path="$light_wallpapers"
fi

# Function to update theme mode for the next cycle
update_theme_mode() {
    echo "$next_mode" > ~/.cache/.theme_mode
}

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

# Set Dynamic Wallpaper for Dark or Light Mode
if [ "$next_mode" = "Dark" ]; then
    next_wallpaper="$(find "${dark_wallpapers}" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | shuf -n1 -z | xargs -0)"
else
    next_wallpaper="$(find "${light_wallpapers}" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | shuf -n1 -z | xargs -0)"
fi

# Update wallpaper using swww command
$swww "${next_wallpaper}" $effect


# Set Kvantum Manager theme & QT5/QT6 settings
if [ "$next_mode" = "Dark" ]; then
    kvantum_theme="Tokyo-Night"
    qt5ct_color_scheme="$HOME/.config/qt5ct/colors/Tokyo-Night.conf"
    qt6ct_color_scheme="$HOME/.config/qt6ct/colors/Tokyo-Night.conf"
else
    kvantum_theme="Tokyo-Day"
    qt5ct_color_scheme="$HOME/.config/qt5ct/colors/Tokyo-Day.conf"
    qt6ct_color_scheme="$HOME/.config/qt6ct/colors/Tokyo-Day.conf"
fi

kvantummanager --set "$kvantum_theme"
sed -i "s|^color_scheme_path=.*$|color_scheme_path=$qt5ct_color_scheme|" "$HOME/.config/qt5ct/qt5ct.conf"
sed -i "s|^color_scheme_path=.*$|color_scheme_path=$qt6ct_color_scheme|" "$HOME/.config/qt6ct/qt6ct.conf"

# Set Rofi Themes
if [ "$next_mode" = "Dark" ]; then
    ln -sf "$dark_rofi_pywal" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
else
    ln -sf "$light_rofi_pywal" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"
fi

# GTK themes and icons switching
set_custom_gtk_theme() {
    mode=$1
    gtk_themes_directory="$HOME/.themes"
    icon_directory="$HOME/.icons"
    color_setting="org.gnome.desktop.interface color-scheme"
    theme_setting="org.gnome.desktop.interface gtk-theme"
    icon_setting="org.gnome.desktop.interface icon-theme"

    if [ "$mode" == "Light" ]; then
        search_keywords="*Light*"
        gsettings set $color_setting 'prefer-light'
    elif [ "$mode" == "Dark" ]; then
        search_keywords="*Dark*"
        gsettings set $color_setting 'prefer-dark'
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

        # Flatpak GTK apps
        if command -v flatpak &> /dev/null; then
            flatpak --user override --env=GTK_THEME="$selected_theme"
        fi
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
        
        ## QT5ct icon_theme
        sed -i "s|^icon_theme=.*$|icon_theme=$selected_icon|" "$HOME/.config/qt5ct/qt5ct.conf"
        sed -i "s|^icon_theme=.*$|icon_theme=$selected_icon|" "$HOME/.config/qt6ct/qt6ct.conf"

        # Flatpak GTK apps
        if command -v flatpak &> /dev/null; then
            flatpak --user override --env=ICON_THEME="$selected_icon"
        fi
    else
        echo "No $mode icon theme found"
    fi
}

# Call the function to set GTK theme and icon theme based on mode
set_custom_gtk_theme "$next_mode"

# Update theme mode for the next cycle
update_theme_mode

sleep 0.5
# Run remaining scripts
${SCRIPTSDIR}/PywalSwww.sh
sleep 1
${SCRIPTSDIR}/Refresh.sh 

# Display notifications for theme and icon changes
dunstify -u normal -i "$dunst_notif" "Themes are set to $selected_theme"
dunstify -u normal -i "$dunst_notif" "Icon themes set to $selected_icon"

exit 0

