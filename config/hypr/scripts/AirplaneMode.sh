#!/bin/bash
wifi="$(nmcli r wifi | awk 'FNR = 2 {print $1}')"
if [ "$wifi" == "enabled" ]; then
    rfkill block all &
    dunstify -t 1000 'airplane mode: active'
else
    rfkill unblock all &
    dunstify -t 1000 'airplane mode: inactive'
fi
