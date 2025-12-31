#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This is for changing kb_layouts. Set kb_layouts in "$HOME/.config/hypr/UserConfigs/UserSettings.conf"

notif_icon="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# Refined ignore list with patterns or specific device names
ignore_patterns=(
  "--(avrcp)"
  "Bluetooth Speaker"
  "Other Device 
  Name"
)

# Function to get keyboard names
get_keyboard_names() {
  hyprctl devices -j | jq -r '.keyboards[].name'
}

# Function to check if a device matches any ignore pattern
is_ignored() {
  local device_name=$1
  for pattern in "${ignore_patterns[@]}"; do
    if [[ "$device_name" == *"$pattern"* ]]; then
      return 0 # Device matches ignore pattern
    fi
  done
  return 1 # Device does not match any ignore pattern
}

# Function to get current layout info
# Stores values in layout_mapping, variant_mapping and layout_index
get_current_layout_info() {
  local found_kb=false

  # Read from the first non-ignored layout
  while read -r name; do
    if ! is_ignored "$name"; then
      found_kb=true
      local layout_mapping_str=$(hyprctl devices -j |
        jq -r --arg name "$name" '.keyboards[] | select(.name==$name).layout')
      IFS="," read -r -a layout_mapping <<<"$layout_mapping_str"

      local variant_mapping_str=$(hyprctl devices -j |
        jq -r --arg name "$name" '.keyboards[] | select(.name==$name).variant')
      IFS="," read -r -a variant_mapping <<<"$variant_mapping_str"

      layout_index=$(hyprctl devices -j |
        jq -r --arg name "$name" '.keyboards[] | select(.name==$name).active_layout_index')
      break
    fi
  done <<< "$(get_keyboard_names)"

  $found_kb && return 0
  return 1
}

# Function to change keyboard layout
change_layout() {
  local error_found=false

  while read -r name; do
    if is_ignored "$name"; then
      echo "Skipping ignored device: $name"
      continue
    fi

    echo "Switching layout for $name to $new_layout..."
    hyprctl switchxkblayout "$name" "$next_index"
    if [ $? -ne 0 ]; then
      echo "Error while switching layout for $name." >&2
      error_found=true
    fi
  done <<<"$(get_keyboard_names)"

  $error_found && return 1
  return 0
}


# Stores values in layout_mapping, variant_mapping and layout_index
if ! get_current_layout_info; then
  echo "Could not get current layout information." >&2
  echo "There might not be any keyboards available, \
    or some were unnecessarily set as ignored." >&2
  notify-send -u low -t 2000 'kb_layout' " Error:" " Layout change failed"
  echo "Exiting $0 $@" >&2
  exit 1
fi

current_layout=${layout_mapping[$layout_index]}
current_variant=${variant_mapping[$layout_index]}

if [[ "$1" == "status" ]]; then
  echo "$current_layout${current_variant:+($current_variant)}"
elif [[ "$1" == "switch" ]]; then
  echo "Current layout: $current_layout($current_variant)"

  layout_count=${#layout_mapping[@]}
  echo "Number of layouts: $layout_count"

  next_index=$(( (layout_index + 1) % layout_count ))
  new_layout="${layout_mapping[$next_index]}"
  new_variant="${variant_mapping[$next_index]}"
  echo "Next layout: $new_layout"

  # Execute layout change and notify
  if ! change_layout; then
    notify-send -u low -t 2000 'kb_layout' " Error:" " Layout change failed"
    echo "Layout change failed." >&2
    exit 1
  else
    notify-send -u low -i "$notif_icon" " kb_layout: $new_layout${new_variant:+($new_variant)}"
    echo "Layout change notification sent."
  fi
else
  echo "Usage: $0 {status|switch}"
fi
