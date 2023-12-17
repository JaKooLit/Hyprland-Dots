#!/bin/bash

dunst_notif="$HOME/.config/dunst/images/bell.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"


HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==2{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:drop_shadow 0;\
        keyword decoration:blur:passes 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
    swww kill 
    dunstify -u low -i "$dunst_notif" "gamemode enabled. All animations off"
    exit
else
	swww init && swww img "$HOME/.config/rofi/.current_wallpaper"
	sleep 0.1
	${SCRIPTSDIR}/PywalSwww.sh
	sleep 0.5
	${SCRIPTSDIR}/Refresh.sh	 
    dunstify -u normal -i "$dunst_notif" "gamemode disabled. All animations normal"
    exit
fi
hyprctl reload
