#!/bin/bash

rofi_config="$HOME/.config/rofi/config-calc.rasi"

while true; do
    result=$(
        rofi -i -dmenu \
            -config "$rofi_config" \
            -mesg "$result      =    $calc_result"
    )

    if [ $? -ne 0 ]; then
        exit
    fi

    if [ -n "$result" ]; then
        calc_result=$(qalc -t "$result")
        echo "$calc_result" | wl-copy
    fi
done
