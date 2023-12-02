#!/bin/bash

#### By default will not show the keyboard shortcuts as it looks Hideous :)

SwayLock=$HOME/.config/hypr/scripts/LockScreen.sh

# CMDs
uptime_info=$(uptime -p | sed -e 's/up //g')
host=$(hostnamectl hostname)

# Options with Icons and Text
options=("Lock" "Suspend" "Logout" "Reboot" "Shutdown" "Hibernate")
icons=("" "" "󰿅" "󱄌" "" "󰒲")

# Rofi CMD
rofi_cmd() {
    options_with_icons=()
    for ((i = 0; i < ${#options[@]}; i++)); do
        options_with_icons+=("${icons[$i]} ${options[$i]}")
    done

    chosen_option=$(printf "%s\n" "${options_with_icons[@]}" | \
	rofi -dmenu -i -p " $USER@$host" -mesg " Uptime: $uptime_info" \
	-kb-select-1 "l" \
	-kb-select-2 "u" \
	-kb-select-3 "e" \
	-kb-select-4 "r" \
	-kb-select-5 "s" \
	-kb-select-6 "h" \
	-theme ~/.config/rofi/config-powermenu.rasi | awk '{print $1}')
    echo "$chosen_option"
}

# Execute Command
run_cmd() {
    case $1 in
        "")
            $SwayLock &
            ;;
        "")
            systemctl suspend
            ;;
        "󰿅")
            hyprctl dispatch exit 0
            ;;
        "󱄌")
            systemctl reboot
            ;;
        "")
            systemctl poweroff
            ;;
        "󰒲")
            systemctl hibernate
            ;;
        *)
            echo "choose: $1"
            ;;
    esac
}

# Actions
chosen_option=$(rofi_cmd)
run_cmd "${chosen_option% *}"
