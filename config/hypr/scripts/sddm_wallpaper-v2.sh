#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# SDDM Wallpaper and Wallust Colors Setter

# for the upcoming changes on the simple_sddm_theme

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
get_color() {
    grep -oP "$1:\s*\K#[A-Fa-f0-9]+" "$rofi_wallust"
}

color11=$(get_color 'color11')
HeaderTextColor=$(get_color 'color12')
DateTextColor=$(get_color 'color13')
bg_color=$(get_color 'color0')
placeholder_color="$accent_color"
icon_color=$(get_color 'foreground')
color11=$(get_color 'color11')

# Define an array of key-value pairs for SDDM config updates
declare -A color_updates=(
    [HeaderTextColor]="$HeaderTextColor"
    [DateTextColor]="$DateTextColor"
    [TimeTextColor]="$DateTextColor"
    [SystemButtonsIconsColor]="$DateTextColor"
    [SessionButtonTextColor]="$DateTextColor"
    [VirtualKeyboardButtonTextColor]="$DateTextColor"
    [BackgroundColor]="$bg_color"
    [PlaceholderTextColor]="$placeholder_color"
    [IconColor]="$icon_color"
	[DropdownBackgroundColor]="$bg_color"
	[HighlightBackgroundColor]="$color11"
)

# Apply changes via terminal and sudo
$terminal -e bash -c "
echo 'Enter your password to update SDDM wallpapers and colors';
$(for key in "${!color_updates[@]}"; do
    value="${color_updates[$key]}"
    echo "sudo sed -i \"s/${key}=\\\"#.*\\\"/${key}=\\\"$value\\\"/\" \"$sddm_theme_conf\""
done)
"

# Set wallpaper path based on mode
wallpaper_path=$([[ "$mode" == "normal" ]] && echo "$wallpaper_current" || echo "$wallpaper_modified")

# Copy wallpaper safely
if [[ -f "$wallpaper_path" ]]; then
    sudo cp "$wallpaper_path" "$sddm_simple/Backgrounds/default"
    notify-send -i "$iDIR/ja.png" "SDDM" "Background SET"
else
    notify-send -i "$iDIR/ja.png" "SDDM" "Wallpaper not found: $wallpaper_path"
    echo "Error: Wallpaper file not found: $wallpaper_path"
    exit 1
fi

