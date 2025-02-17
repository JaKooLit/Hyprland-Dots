#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Rofi menu for Quick Edit/View of Settings (SUPER E)

# Define preferred text editor and terminal
edit=${EDITOR:-nano}
tty=kitty

# Paths to configuration directories
configs="$HOME/.config/hypr/configs"
UserConfigs="$HOME/.config/hypr/UserConfigs"
rofi_theme="~/.config/rofi/config-edit.rasi"
msg=' ⁉️ Choose which config to View or Edit ⁉️'

# Function to display the menu options
menu() {
    cat <<EOF
1. ENV variables
2. Window Rules
3. Monitors
4. User Keybinds
5. User Settings
6. Startup Apps
7. Decorations
8. Animations
9. Workspace Rules
10. Laptop Keybinds
11. Default Keybinds
EOF
}

# Main function to handle menu selection
main() {
    choice=$(menu | rofi -i -dmenu -config $rofi_theme -mesg "$msg" | cut -d. -f1)
    
    # Map choices to corresponding files
    case $choice in
        1) file="$UserConfigs/ENVariables.conf" ;;
        2) file="$UserConfigs/WindowRules.conf" ;;
        3) file="$UserConfigs/Monitors.conf" ;;
        4) file="$UserConfigs/UserKeybinds.conf" ;;
        5) file="$UserConfigs/UserSettings.conf" ;;
        6) file="$UserConfigs/Startup_Apps.conf" ;;
        7) file="$UserConfigs/UserDecorations.conf" ;;
        8) file="$UserConfigs/UserAnimations.conf" ;;
        9) file="$UserConfigs/WorkspaceRules.conf" ;;
        10) file="$UserConfigs/Laptops.conf" ;;
        11) file="$configs/Keybinds.conf" ;;
        *) return ;;  # Do nothing for invalid choices
    esac

    # Open the selected file in the terminal with the text editor
    $tty -e $edit "$file"
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

main
