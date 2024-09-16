#!/bin/bash
# Rofi menu for Quick Edit/View of Settings (SUPER E)

# Define preferred text editor and terminal
edit=${EDITOR:-nano}
tty=kitty

# Paths to configuration directories
configs="$HOME/.config/hypr/configs"
UserConfigs="$HOME/.config/hypr/UserConfigs"

# Function to display the menu options
menu() {
    cat <<EOF
1. Edit Env-variables
2. Edit Window-Rules
3. Edit Startup_Apps
4. Edit User-Keybinds
5. Edit Monitors
6. Edit Laptop-Keybinds
7. Edit User-Settings
8. Edit Decorations & Animations
9. Edit Workspace-Rules
10. Edit Default-Settings
11. Edit Default-Keybinds
EOF
}

# Main function to handle menu selection
main() {
    choice=$(menu | rofi -i -dmenu -config ~/.config/rofi/config-compact.rasi | cut -d. -f1)
    
    # Map choices to corresponding files
    case $choice in
        1) file="$UserConfigs/ENVariables.conf" ;;
        2) file="$UserConfigs/WindowRules.conf" ;;
        3) file="$UserConfigs/Startup_Apps.conf" ;;
        4) file="$UserConfigs/UserKeybinds.conf" ;;
        5) file="$UserConfigs/Monitors.conf" ;;
        6) file="$UserConfigs/Laptops.conf" ;;
        7) file="$UserConfigs/UserSettings.conf" ;;
        8) file="$UserConfigs/UserDecorAnimations.conf" ;;
        9) file="$UserConfigs/WorkspaceRules.conf" ;;
        10) file="$configs/Settings.conf" ;;
        11) file="$configs/Keybinds.conf" ;;
        *) return ;;  # Do nothing for invalid choices
    esac

    # Open the selected file in the terminal with the text editor
    $tty -e $edit "$file"
}

main
