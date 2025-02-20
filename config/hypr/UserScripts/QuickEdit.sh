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
1. view/edit ENV variables
2. view/edit Window Rules
3. view/edit User Keybinds
4. view/edit User Settings
5. view/edit Startup Apps
6. view/edit Decorations
7. view/edit Animations
8. view/edit Laptop Keybinds
9. view/edit Default Keybinds
10. view/edit Monitors (via nwg-display)
11. view/edit Workspace Rules (nwg-display)
EOF
}

# Main function to handle menu selection
main() {
    choice=$(menu | rofi -i -dmenu -config $rofi_theme -mesg "$msg" | cut -d. -f1)
    
    # Map choices to corresponding files
    case $choice in
        1) file="$UserConfigs/ENVariables.conf" ;;
        2) file="$UserConfigs/WindowRules.conf" ;;
        3) file="$UserConfigs/UserKeybinds.conf" ;;
        4) file="$UserConfigs/UserKeybinds.conf" ;;
        5) file="$UserConfigs/UserSettings.conf" ;;
        6) file="$UserConfigs/Startup_Apps.conf" ;;
        7) file="$UserConfigs/UserDecorations.conf" ;;
        8) file="$UserConfigs/UserAnimations.conf" ;;
        9) file="$UserConfigs/Laptops.conf" ;;
        10) nwg-displays ;;
        11) nwg-displays ;;
        *) return ;;  # Do nothing for invalid choices
    esac

    # Open the selected file in the terminal with the text editor
    if [ -n "$file" ]; then
        $tty -e $edit "$file"
    fi
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

main

