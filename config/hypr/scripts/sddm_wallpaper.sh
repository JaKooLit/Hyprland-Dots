#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# SDDM Wallpaper and Wallust Colors Setter

# variables
terminal=kitty
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
wallpaper_modified="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
sddm_simple="/usr/share/sddm/themes/simple_sddm_2"

# rofi-wallust-sddm colors path
rofi_wallust="$HOME/.config/rofi/wallust/colors-rofi.rasi"
sddm_theme_conf="$sddm_simple/theme.conf"

# Directory for swaync
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# Parse arguments
mode="effects" # default
if [[ "$1" == "--normal" ]]; then
    mode="normal"
elif [[ "$1" == "--effects" ]]; then
    mode="effects"
fi

# Extract colors from rofi wallust config
main_color=$(grep -oP 'color13:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")
accent_color=$(grep -oP 'color12:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")
bg_color=$(grep -oP 'color0:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")
placeholder_color="$accent_color"
icon_color=$(grep -oP 'foreground:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")

# wallpaper to use
if [[ "$mode" == "normal" ]]; then
    wallpaper_path="$wallpaper_current"
else
    wallpaper_path="$wallpaper_modified"
fi

# Launch terminal and apply changes
$terminal -e bash -c "
echo 'Enter your password to update SDDM wallpapers and colors';
sudo sed -i \"s/MainColor=\\\"#.*\\\"/MainColor=\\\"$main_color\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/AccentColor=\\\"#.*\\\"/AccentColor=\\\"$accent_color\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/BackgroundColor=\\\"#.*\\\"/BackgroundColor=\\\"$bg_color\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/placeholderColor=\\\"#.*\\\"/placeholderColor=\\\"$placeholder_color\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/IconColor=\\\"#.*\\\"/IconColor=\\\"$icon_color\\\"/\" \"$sddm_theme_conf\"

# Copy wallpaper
sudo cp \"$wallpaper_path\" \"$sddm_simple/Backgrounds/default\"

notify-send -i \"$iDIR/ja.png\" \"SDDM\" \"Background SET\"
"
