#!/bin/bash

script_path="$HOME/.config/hypr/scripts"

if hyprctl activewindow | grep "Invalid"; then
  source "$script_path/Wlogout.sh"
else
  hyprctl dispatch killactive
fi
