#!/bin/bash
# Rofi menu for Quick Edit / View of Settings (SUPER E)

configs="$HOME/.config/hypr/configs"
UserConfigs="$HOME/.config/hypr/UserConfigs"

menu(){
  printf "1. view Env-variables\n"
  printf "2. view Window-Rules\n"
  printf "3. view Startup_Apps\n"
  printf "4. view User-Keybinds\n"
  printf "5. view Monitors\n"
  printf "6. view Laptop-Keybinds\n"
  printf "7. view User-Settings\n"
  printf "8. view Workspace-Rules\n"
  printf "9. view Default-Settings\n"
  printf "10. view Default-Keybinds\n"
}

main() {
    choice=$(menu | rofi -i -dmenu -config ~/.config/rofi/config-compact.rasi | cut -d. -f1)
    case $choice in
        1)
            kitty -e nano "$UserConfigs/ENVariables.conf"
            ;;
        2)
            kitty -e nano "$UserConfigs/WindowRules.conf"
            ;;
        3)
            kitty -e nano "$UserConfigs/Startup_Apps.conf"
            ;;
        4)
            kitty -e nano "$UserConfigs/UserKeybinds.conf"
            ;;
        5)
            kitty -e nano "$UserConfigs/Monitors.conf"
            ;;
        6)
            kitty -e nano "$UserConfigs/Laptops.conf"
            ;;
        7)
            kitty -e nano "$UserConfigs/UserSettings.conf"
            ;;
        8)
            kitty -e nano "$UserConfigs/WorkspaceRules.conf"
            ;;
		9)
            kitty -e nano "$configs/Settings.conf"
            ;;
        10)
            kitty -e nano "$configs/Keybinds.conf"
            ;;
        *)
            ;;
    esac
}

main