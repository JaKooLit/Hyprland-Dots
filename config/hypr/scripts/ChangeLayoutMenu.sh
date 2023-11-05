#!/bin/bash

# Files
#waybar
CONFIG="$HOME/.config/waybar/configs"
WCONFIG="$HOME/.config/waybar/config"

menu(){
printf "1. default\n" 
printf "2. plasma-style\n" 
printf "3. gnome-style\n"
printf "4. simple panel\n"
printf "5. simple 2 panel\n"
printf "6. top & bot panel\n"
printf "7. left panel\n"
printf "8. right panel\n"
printf "9. top & left panel\n"
printf "10. top & right panel\n"
printf "11. bottom & left panel\n"
printf "12. bottom & right panel\n"
printf "13. all sides\n"
printf "14. no panel" 
}

main() {
    choice=$(menu | rofi -dmenu -config ~/.config/rofi/config-long.rasi | cut -d. -f1)
    case $choice in
    1)
        ln -sf "$CONFIG/config-default" "$WCONFIG"
        ;;
    2)
        ln -sf "$CONFIG/config-plasma" "$WCONFIG"
        ;;
    3)
        ln -sf "$CONFIG/config-gnome" "$WCONFIG"
        ;;
    4)
        ln -sf "$CONFIG/config-simple" "$WCONFIG"
        ;;
    5)
        ln -sf "$CONFIG/config-simple2" "$WCONFIG"
        ;;
    6)
        ln -sf "$CONFIG/config-dual" "$WCONFIG"
        ;;
    7)
        ln -sf "$CONFIG/config-left" "$WCONFIG"
        ;;
    8)
        ln -sf "$CONFIG/config-right" "$WCONFIG"
        ;;
    9)
        ln -sf "$CONFIG/config-dual-TL" "$WCONFIG"
        ;;
    10)
        ln -sf "$CONFIG/config-dual-TR" "$WCONFIG"
        ;;
    11)
        ln -sf "$CONFIG/config-dual-BL" "$WCONFIG"
        ;;
    12)
        ln -sf "$CONFIG/config-dual-BR" "$WCONFIG"
        ;;
    13)
        ln -sf "$CONFIG/config-all" "$WCONFIG"
        ;;
	14)
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
                