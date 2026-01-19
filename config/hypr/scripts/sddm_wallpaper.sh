#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# SDDM Wallpaper and Wallust Colors Setter

# for the upcoming changes on the simple_sddm_theme

# variables
terminal=kitty
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
wallpaper_modified="$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
# Resolve SDDM themes directory (standard paths and NixOS path)
sddm_themes_dir="/usr/share/sddm/themes"
if [ ! -d "$sddm_themes_dir" ] && [ -d "/run/current-system/sw/share/sddm/themes" ]; then
    sddm_themes_dir="/run/current-system/sw/share/sddm/themes"
fi
sddm_simple="$sddm_themes_dir/simple_sddm_2"

# rofi-wallust-sddm colors path
rofi_wallust="$HOME/.config/rofi/wallust/colors-rofi.rasi"
sddm_theme_conf="$sddm_simple/theme.conf"
if [[ ! -f "$rofi_wallust" ]]; then
    notify-send -i "$iDIR/error.png" "SDDM" "Wallust colors file not found ($rofi_wallust). Aborting."
    exit 1
fi

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

# Abort if SDDM is not running (avoid errors on non-SDDM systems)
if command -v systemctl >/dev/null 2>&1; then
    if ! systemctl is-active --quiet sddm; then
        notify-send -i "$iDIR/error.png" "SDDM" "SDDM is not running. Skipping SDDM wallpaper update."
        exit 0
    fi
elif ! pidof sddm >/dev/null 2>&1; then
    notify-send -i "$iDIR/error.png" "SDDM" "SDDM is not running. Skipping SDDM wallpaper update."
    exit 0
fi

# Extract colors from rofi wallust config

extract_color() {
    local key="$1"
    local value
    value=$(grep -oP "$key:\s*\K#[A-Fa-f0-9]+" "$rofi_wallust" | head -n1)
    echo "$value"
}

color0=$(extract_color "color1")
color1=$(extract_color "color0")
color7=$(extract_color "color14")
color10=$(extract_color "color10")
color12=$(extract_color "color12")
color13=$(extract_color "color13")
foreground=$(extract_color "foreground")

missing_colors=()
for var in color0 color1 color7 color10 color12 color13 foreground; do
    if [[ -z "${!var}" ]]; then
        missing_colors+=("$var")
    fi
done

if [[ ${#missing_colors[@]} -gt 0 ]]; then
    notify-send -i "$iDIR/error.png" "SDDM" "Missing color(s): ${missing_colors[*]}. Run Wallust first."
    exit 1
fi
#background-color=$(grep -oP 'background:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")

# wallpaper to use
if [[ "$mode" == "normal" ]]; then
    wallpaper_path="$wallpaper_current"
else
    wallpaper_path="$wallpaper_modified"
fi

# Abort on NixOS where this repo doesn't manage SDDM and themes are typically read-only
if hostnamectl 2>/dev/null | grep -q 'Operating System: NixOS'; then
    notify-send -i "$iDIR/error.png" "SDDM" "NixOS detected: skipping SDDM background change."
    exit 0
fi

# Launch terminal and apply changes
$terminal -e bash -c "
echo 'Enter your password to update SDDM wallpapers and colors';

# Update the colors in the SDDM config
sudo sed -i \"s/HeaderTextColor=\\\"#.*\\\"/HeaderTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/DateTextColor=\\\"#.*\\\"/DateTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/TimeTextColor=\\\"#.*\\\"/TimeTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/DropdownSelectedBackgroundColor=\\\"#.*\\\"/DropdownSelectedBackgroundColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/SystemButtonsIconsColor=\\\"#.*\\\"/SystemButtonsIconsColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/SessionButtonTextColor=\\\"#.*\\\"/SessionButtonTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/VirtualKeyboardButtonTextColor=\\\"#.*\\\"/VirtualKeyboardButtonTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/HighlightBackgroundColor=\\\"#.*\\\"/HighlightBackgroundColor=\\\"$color12\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/LoginFieldTextColor=\\\"#.*\\\"/LoginFieldTextColor=\\\"$color12\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/PasswordFieldTextColor=\\\"#.*\\\"/PasswordFieldTextColor=\\\"$color12\\\"/\" \"$sddm_theme_conf\"

sudo sed -i \"s/DropdownBackgroundColor=\\\"#.*\\\"/DropdownBackgroundColor=\\\"$color1\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/HighlightTextColor=\\\"#.*\\\"/HighlightTextColor=\\\"$color10\\\"/\" \"$sddm_theme_conf\"

sudo sed -i \"s/PlaceholderTextColor=\\\"#.*\\\"/PlaceholderTextColor=\\\"$color7\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/UserIconColor=\\\"#.*\\\"/UserIconColor=\\\"$color7\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/PasswordIconColor=\\\"#.*\\\"/PasswordIconColor=\\\"$color7\\\"/\" \"$sddm_theme_conf\"

# Copy wallpaper to SDDM theme
# Primary: set Backgrounds/default (no extension) for simple_sddm_2
sudo cp -f \"$wallpaper_path\" \"$sddm_simple/Backgrounds/default\" || true
# Fallbacks: if theme ships default.jpg or default.png, update those too
if [ -e \"$sddm_simple/Backgrounds/default.jpg\" ]; then
  sudo cp -f \"$wallpaper_path\" \"$sddm_simple/Backgrounds/default.jpg\"
fi
if [ -e \"$sddm_simple/Backgrounds/default.png\" ]; then
  sudo cp -f \"$wallpaper_path\" \"$sddm_simple/Backgrounds/default.png\"
fi

notify-send -i \"$iDIR/ja.png\" \"SDDM\" \"Background SET\"
"