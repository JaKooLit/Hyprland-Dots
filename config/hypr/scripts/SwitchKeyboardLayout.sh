#!/bin/bash

layout_f="/tmp/kb_layout"
current_layout=$(cat "$layout_f")

# Read keyboard layout settings from Settings.conf
settings_file="$HOME/.config/hypr/configs/Settings.conf"

if [ -f "$settings_file" ]; then
  # Extract the value of kb_layout from Settings.conf
  kb_layout_line=$(grep 'kb_layout=' "$settings_file" | cut -d '=' -f 2)
  IFS=',' read -ra layout_mapping <<< "$kb_layout_line"
fi

layout_count=${#layout_mapping[@]}

# Find the index of the current layout in the mapping
for ((i = 0; i < layout_count; i++)); do
  if [ "$current_layout" == "${layout_mapping[i]}" ]; then
    current_index=$i
    break
  fi
done

# Calculate the index of the next layout
next_index=$(( (current_index + 1) % layout_count ))
new_layout="${layout_mapping[next_index]}"

# Update the keyboard layout
hyprctl keyword input:kb_layout "$new_layout"
echo "$new_layout" > "$layout_f"
