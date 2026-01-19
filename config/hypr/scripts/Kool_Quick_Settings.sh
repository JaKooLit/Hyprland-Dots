#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Rofi menu for KooL Hyprland Quick Settings (SUPER SHIFT E)
# Updated for UserConfigs/configs separation

# Modify this config file for default terminal and EDITOR
config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"

tmp_config_file=$(mktemp)
sed 's/^\$//g; s/ = /=/g' "$config_file" > "$tmp_config_file"
source "$tmp_config_file"
# ##################################### #

# variables
configs="$HOME/.config/hypr/configs"
UserConfigs="$HOME/.config/hypr/UserConfigs"
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
msg=' ⁉️ Choose what to do ⁉️'
iDIR="$HOME/.config/swaync/images"
scriptsDir="$HOME/.config/hypr/scripts"
UserScripts="$HOME/.config/hypr/UserScripts"

# Function to show info notification
show_info() {
    if [[ -f "$iDIR/info.png" ]]; then
        notify-send -i "$iDIR/info.png" "Info" "$1"
    else
        notify-send "Info" "$1"
    fi
}
# Function to toggle Rainbow Borders script availability and refresh UI components
toggle_rainbow_borders() {
    local rainbow_script="$UserScripts/RainbowBorders.sh"
    local disabled_sh_bak="${rainbow_script}.bak"           # RainbowBorders.sh.bak
    local disabled_bak_sh="$UserScripts/RainbowBorders.bak.sh" # RainbowBorders.bak.sh (created by copy.sh when disabled)
    local refresh_script="$scriptsDir/Refresh.sh"
    local status=""

    # If both disabled variants exist, keep the newer one to avoid ambiguity
    if [[ -f "$disabled_sh_bak" && -f "$disabled_bak_sh" ]]; then
        if [[ "$disabled_sh_bak" -nt "$disabled_bak_sh" ]]; then
            rm -f "$disabled_bak_sh"
        else
            rm -f "$disabled_sh_bak"
        fi
    fi

    if [[ -f "$rainbow_script" ]]; then
        # Currently enabled -> disable to canonical .sh.bak
        if mv "$rainbow_script" "$disabled_sh_bak"; then
            status="disabled"
            if command -v hyprctl &>/dev/null; then
                hyprctl reload >/dev/null 2>&1 || true
            fi
        fi
    elif [[ -f "$disabled_sh_bak" ]]; then
        # Disabled (.sh.bak) -> enable
        if mv "$disabled_sh_bak" "$rainbow_script"; then
            status="enabled"
        fi
    elif [[ -f "$disabled_bak_sh" ]]; then
        # Disabled (.bak.sh) -> enable (normalize to .sh)
        if mv "$disabled_bak_sh" "$rainbow_script"; then
            status="enabled"
        fi
    else
        show_info "RainbowBorders script not found in $UserScripts (checked .sh, .sh.bak, .bak.sh)."
        return
    fi

    # Run refresh if available, otherwise apply borders directly
    if [[ -x "$refresh_script" ]]; then
        "$refresh_script" >/dev/null 2>&1 &
    elif [[ "$current" != "disabled" && -x "$rainbow_script" ]]; then
        "$rainbow_script" >/dev/null 2>&1 &
    fi

    if [[ -n "$status" ]]; then
        show_info "Rainbow Borders ${status}."
    fi
}

# Submenu to choose Rainbow Borders mode (disable, wallust_random, rainbow, gradient_flow)
rainbow_borders_menu() {
    local rainbow_script="$UserScripts/RainbowBorders.sh"
    local disabled_sh_bak="${rainbow_script}.bak"
    local disabled_bak_sh="$UserScripts/RainbowBorders.bak.sh"
    local refresh_script="$scriptsDir/Refresh.sh"

    # Determine current mode/status (internal)
    local current="disabled"
    if [[ -f "$rainbow_script" ]]; then
        current=$(grep -E '^EFFECT_TYPE=' "$rainbow_script" 2>/dev/null | sed -E 's/^EFFECT_TYPE="?([^"]*)"?/\1/')
        [[ -z "$current" ]] && current="unknown"
    fi

    # Map internal mode to friendly display
    local current_display="$current"
    case "$current" in
        wallust_random) current_display="Wallust Color" ;;
        rainbow) current_display="Original Rainbow" ;;
        gradient_flow) current_display="Gradient Flow" ;;
        disabled) current_display="Disabled" ;;
    esac


    # Build options and prompt
    local options="Disable Rainbow Borders\nWallust Color\nOriginal Rainbow\nGradient Flow"
    local choice
    choice=$(printf "%b" "$options" | rofi -i -dmenu -config "$rofi_theme" -mesg "Rainbow Borders: current = $current_display")

    [[ -z "$choice" ]] && return

    local previous="$current"

    case "$choice" in
        "Disable Rainbow Borders")
            if [[ -f "$rainbow_script" ]]; then
                mv "$rainbow_script" "$disabled_sh_bak"
            fi
            current="disabled"
            if command -v hyprctl &>/dev/null; then
                hyprctl reload >/dev/null 2>&1 || true
            fi
            ;;
        "Wallust Color"|"Original Rainbow"|"Gradient Flow")
            local mode=""
            case "$choice" in
                "Wallust Color") mode="wallust_random" ;;
                "Original Rainbow") mode="rainbow" ;;
                "Gradient Flow") mode="gradient_flow" ;;
            esac
            # Ensure script is enabled
            if [[ ! -f "$rainbow_script" ]]; then
                if   [[ -f "$disabled_sh_bak" ]]; then
                    mv "$disabled_sh_bak" "$rainbow_script"
                elif [[ -f "$disabled_bak_sh" ]]; then
                    mv "$disabled_bak_sh" "$rainbow_script"
                else
                    show_info "RainbowBorders script not found in $UserScripts."
                    return
                fi
            fi

            # Update EFFECT_TYPE in place; insert if missing
            if grep -q '^EFFECT_TYPE=' "$rainbow_script" 2>/dev/null; then
                sed -i 's/^EFFECT_TYPE=.*/EFFECT_TYPE="'"$mode"'"/' "$rainbow_script"
            else
                if head -n1 "$rainbow_script" | grep -q '^#!'; then
                    sed -i '1a EFFECT_TYPE="'"$mode"'"' "$rainbow_script"
                else
                    sed -i '1i EFFECT_TYPE="'"$mode"'"' "$rainbow_script"
                fi
            fi
            # Set current to chosen mode
            current="$mode"
            ;;
        *)
            return ;;
    esac

    # Run refresh if available
    if [[ -x "$refresh_script" ]]; then
        "$refresh_script" >/dev/null 2>&1 &
    fi

    # Apply mode immediately (in case refresh doesn't trigger it)
    if [[ "$current" != "disabled" && -x "$rainbow_script" ]]; then
        "$rainbow_script" >/dev/null 2>&1 &
    fi

    # No notifications; mode is shown in the menu
}

# Function to display the menu options without numbers
menu() {
    cat <<EOF
--- USER CUSTOMIZATIONS ---
Edit User Defaults
Edit User Keybinds
Edit User ENV variables
Edit User Startup Apps (overlay)
Edit User Window Rules (overlay)
Edit User Settings
Edit User Decorations
Edit User Animations
Edit User Laptop Settings
--- SYSTEM DEFAULTS  ---
Edit System Default Keybinds
Edit System Default Startup Apps
Edit System Default Window Rules
Edit System Default Settings
--- UTILITIES ---
Set SDDM Wallpaper
Choose Kitty Terminal Theme
Configure Monitors (nwg-displays)
Configure Workspace Rules (nwg-displays)
GTK Settings (nwg-look)
QT Apps Settings (qt6ct)
QT Apps Settings (qt5ct)
Choose Hyprland Animations
Choose Monitor Profiles
Choose Rofi Themes
Search for Keybinds
Toggle Game Mode
Switch Dark-Light Theme
Rainbow Borders Mode
EOF
}

# Main function to handle menu selection
main() {
    choice=$(menu | rofi -i -dmenu -config $rofi_theme -mesg "$msg")
    
    # Map choices to corresponding files
    case "$choice" in
    	"Edit User Defaults") file="$UserConfigs/01-UserDefaults.conf" ;;
        "Edit User ENV variables") file="$UserConfigs/ENVariables.conf" ;;
        "Edit User Keybinds") file="$UserConfigs/UserKeybinds.conf" ;;
        "Edit User Startup Apps (overlay)") file="$UserConfigs/Startup_Apps.conf" ;;
        "Edit User Window Rules (overlay)") file="$UserConfigs/WindowRules.conf" ;;
        "Edit User Settings") file="$configs/SystemSettings.conf"; show_info "Editing default settings. Copy to UserConfigs/UserSettings.conf to override." ;;
        "Edit User Decorations") file="$UserConfigs/UserDecorations.conf" ;;
        "Edit User Animations") file="$UserConfigs/UserAnimations.conf" ;;
        "Edit User Laptop Settings") file="$UserConfigs/Laptops.conf" ;;
        "Edit System Default Keybinds") file="$configs/Keybinds.conf" ;;
        "Edit System Default Startup Apps") file="$configs/Startup_Apps.conf" ;;
        "Edit System Default Window Rules") file="$configs/WindowRules.conf" ;;
        "Edit System Default Settings") file="$configs/SystemSettings.conf" ;;
        "Set SDDM Wallpaper") $scriptsDir/sddm_wallpaper.sh --normal ;;
        "Choose Kitty Terminal Theme") $scriptsDir/Kitty_themes.sh ;;
        "Configure Monitors (nwg-displays)") 
            if ! command -v nwg-displays &>/dev/null; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-displays first"
                exit 1
            fi
            nwg-displays ;;
        "Configure Workspace Rules (nwg-displays)") 
            if ! command -v nwg-displays &>/dev/null; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-displays first"
                exit 1
            fi
            nwg-displays ;;
		"GTK Settings (nwg-look)") 
            if ! command -v nwg-look &>/dev/null; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-look first"
                exit 1
            fi
            nwg-look ;;
		"QT Apps Settings (qt6ct)") 
            if ! command -v qt6ct &>/dev/null; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install qt6ct first"
                exit 1
            fi
            qt6ct ;;
		"QT Apps Settings (qt5ct)") 
            if ! command -v qt5ct &>/dev/null; then
                notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install qt5ct first"
                exit 1
            fi
            qt5ct ;;
        "Choose Hyprland Animations") $scriptsDir/Animations.sh ;;
        "Choose Monitor Profiles") $scriptsDir/MonitorProfiles.sh ;;
        "Choose Rofi Themes") $scriptsDir/RofiThemeSelector.sh ;;
        "Search for Keybinds") $scriptsDir/KeyBinds.sh ;;
        "Toggle Game Mode") $scriptsDir/GameMode.sh ;;
        "Switch Dark-Light Theme") $scriptsDir/DarkLight.sh ;;
        "Rainbow Borders Mode") rainbow_borders_menu ;;
        *) return ;;  # Do nothing for invalid choices
    esac

    # Open the selected file in the terminal with the text editor
    if [ -n "$file" ]; then
        $term -e $edit "$file"
    fi
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

main
