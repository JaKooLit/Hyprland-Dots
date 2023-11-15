#!/bin/bash

# Files
#waybar
CONFIG="$HOME/.config/waybar/configs"
WCONFIG="$HOME/.config/waybar/config"

menu(){
printf "1. Peony\n" 
printf "2. Chrysanthemum\n" 
printf "3. Gardenia\n"
printf "4. Camellia\n"
}

main() {
    choice=$(menu | rofi -dmenu -config ~/.config/rofi/config-long.rasi | cut -d. -f1)
    case $choice in
    1)
        ln -sf "$CONFIG/Peony" "$WCONFIG"
        ;;
    2)
        ln -sf "$CONFIG/Chrysanthemum" "$WCONFIG"
        ;;
    3)
        ln -sf "$CONFIG/Gardenia" "$WCONFIG"
        ;;
    4)
        ln -sf "$CONFIG/Camellia" "$WCONFIG"
        ;;
	10)
        if pgrep -x "waybar" >/dev/null; then
        pkill waybar
        exit
        fi
        ;;        
        *)
        ;;
    esac
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
    pkill rofi
    exit 0
else
    main
fi

exec ~/.config/hypr/scripts/Refresh.sh &
                