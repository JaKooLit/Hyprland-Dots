#!/bin/bash

# Killall running notification agents
_ps=(mako dunst swaync)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

# relaunch sway
sleep 0.5
swaync