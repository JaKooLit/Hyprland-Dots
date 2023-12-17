#!/bin/bash

dunst_notif="$HOME/.config/dunst/images/bell.png"

wifi="$(nmcli r wifi | awk 'FNR = 2 {print $1}')"
if [ "$wifi" == "enabled" ]; then
    rfkill block all &
    dunstify -u normal -i "$dunst_notif" -t 1000 'airplane mode: active'
else
    rfkill unblock all &
    dunstify -u normal -i "$dunst_notif" -t 1000 'airplane mode: inactive'
fi
