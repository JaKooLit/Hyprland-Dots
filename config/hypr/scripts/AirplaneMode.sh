#!/bin/bash
wifi="$(nmcli r wifi | awk 'FNR = 2 {print $1}')"
if [ "$wifi" == "enabled" ]; then
    rfkill block all &
    notify-send -t 1000 'airplane mode: active'
else
    rfkill unblock all &
    notify-send -t 1000 'airplane mode: inactive'
fi
