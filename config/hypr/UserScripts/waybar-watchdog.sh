#!/usr/bin/env bash
# ~/bin/waybar-watchdog.sh

CONFIG="$1"
STYLE="$2"

while true; do
    waybar -c "$CONFIG" -s "$STYLE" 2>&1 | while read -r line; do
        if [[ "$line" =~ "terminated  waybar -c" ]]; then
            echo "[watchdog] Crash detected for $CONFIG"
            break
        fi
    done
    sleep 2
done
