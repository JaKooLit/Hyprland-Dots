#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This is for changing kb_layouts. Set kb_layouts in $settings_file

layout_f="$HOME/.cache/kb_layout"
settings_file="$HOME/.config/hypr/UserConfigs/UserSettings.conf"
notif="$HOME/.config/swaync/images/bell.png"

# Check if ~/.cache/kb_layout exists and create it with a default layout from Settings.conf if not found
if [ ! -f "$layout_f" ]; then
  default_layout=$(grep 'kb_layout = ' "$settings_file" | cut -d '=' -f 2 | cut -d ',' -f 1 2>/dev/null)
  if [ -z "$default_layout" ]; then
    default_layout="us" # Default to 'us' layout if Settings.conf or 'kb_layout' is not found
  fi
  echo "$default_layout" > "$layout_f"
fi

current_layout=$(cat "$layout_f")

# Read keyboard layout settings from Settings.conf
if [ -f "$settings_file" ]; then
  kb_layout_line=$(grep 'kb_layout = ' "$settings_file" | cut -d '=' -f 2)
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
hyprctl switchxkblayout "at-translated-set-2-keyboard" "$new_layout"
echo "$new_layout" > "$layout_f"

# Created by T-Crypt

get_keyboard_names() {
    hyprctl devices -j | jq -r '.keyboards[].name'
}

change_layout() {
    local got_error=false

    while read -r name; do
        hyprctl switchxkblayout "$name" next
        if [[ $? -eq 0 ]]; then
            echo "Switched the layout for $name."
        else
            >&2 echo "Error while switching the layout for $name."
            got_error=true
        fi
    done <<< "$(get_keyboard_names)"

    if [ "$got_error" = true ]; then
        >&2 echo "Some errors were found during the process..."
        return 1
    fi

    return 0 # All layouts had been cycled successfully
}

if ! change_layout; then
    notify-send -u low -t 2000 'Keyboard layout' 'Error: Layout change failed'
    >&2 echo "Layout change failed."
    exit 1
else
    # Notification for the new keyboard layout
	  notify-send -u low -i "$notif" "new KB_Layout: $new_layout"
fi
