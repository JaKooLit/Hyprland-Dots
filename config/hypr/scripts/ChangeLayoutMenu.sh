#!/bin/bash

# Files
#waybar
CONFIG="$HOME/.config/waybar/configs"
WCONFIG="$HOME/.config/waybar/config"

#wofi configs
CONFIGB="$HOME/.config/wofi/WofiBig/config"
STYLE="$HOME/.config/wofi/style.css"
COLORS="$HOME/.config/wofi/colors"
WOFICONFIGS="$HOME/.config/wofi/configs"
WOFICONFIG="$HOME/.config/wofi/config"

# wofi window config (in %)
WIDTH=12
HEIGHT=40

## Wofi Command
wofi_command="wofi --show dmenu \
			--prompt choose...
			--conf $CONFIGB --style $STYLE --color $COLORS \
			--width=$WIDTH% --height=$HEIGHT% \
			--cache-file=/dev/null \
			--hide-scroll --no-actions \
			--matching=fuzzy"


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
    choice=$(menu | ${wofi_command} | cut -d. -f1)
    case $choice in
    1)
        ln -sf "$CONFIG/config-default" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
        ;;
    2)
        ln -sf "$CONFIG/config-plasma" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-plasma" "$WOFICONFIG"
        ;;
    3)
        ln -sf "$CONFIG/config-gnome" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-gnome" "$WOFICONFIG"
        ;;
    4)
        ln -sf "$CONFIG/config-simple" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
        ;;
    5)
        ln -sf "$CONFIG/config-simple2" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
        ;;
    6)
        ln -sf "$CONFIG/config-dual" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
        ;;
    7)
        ln -sf "$CONFIG/config-left" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
        ;;
    8)
        ln -sf "$CONFIG/config-right" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
        ;;
    9)
        ln -sf "$CONFIG/config-dual-TL" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
        ;;
    10)
        ln -sf "$CONFIG/config-dual-TR" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
        ;;
    11)
        ln -sf "$CONFIG/config-dual-BL" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
        ;;
    12)
        ln -sf "$CONFIG/config-dual-BR" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
        ;;
    13)
        ln -sf "$CONFIG/config-all" "$WCONFIG"
        ln -sf "$WOFICONFIGS/config-default" "$WOFICONFIG"
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

# Check if wofi is already running
if pidof wofi >/dev/null; then
    pkill wofi
    exit 0
else
    main
fi

exec ~/.config/hypr/scripts/Refresh.sh &
                