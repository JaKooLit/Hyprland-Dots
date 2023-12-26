#!/bin/bash

dunst_notif="$HOME/.config/dunst/images/bell.png"

STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [ "${STATE}" == "2" ]; then
	hyprctl keyword decoration:blur:size 2
	hyprctl keyword decoration:blur:passes 1
  notify-send -e -u low -i "$dunst_notif" "Less blur"
else
	hyprctl keyword decoration:blur:size 5
	hyprctl keyword decoration:blur:passes 2
  notify-send -e -u low -i "$dunst_notif" "Normal blur"
fi
