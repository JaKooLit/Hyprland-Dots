#!/bin/bash

notif="$HOME/.config/swaync/images/bell.png"

wifi="$(nmcli r wifi | awk 'FNR = 2 {print $1}')"
if [ "$wifi" == "enabled" ]; then
    rfkill block all &
    notify-send -u low -i "$notif" 'airplane mode: active'
else
    rfkill unblock all &
    notify-send -u low -i "$notif" 'airplane mode: inactive'
fi
