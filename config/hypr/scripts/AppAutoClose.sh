#!/bin/bash

# Variables: put the process names you want to auto close here. Make sure to add "" and inside the ()
processes=("pavucontrol")

# Loop through each process name
while true; do
    active_window=$(hyprctl activewindow | grep class | awk '{print $2}')

    # Loop through each process name in the array
    for process in "${processes[@]}"; do
        if [ "$active_window" == "$process" ]; then
            # If the active window matches the process, mark it as active
            process_active=true
        else
            # If not, mark it as inactive and try to kill the process
            process_active=false
            pkill "$process"
        fi
    done

    sleep 5
done
