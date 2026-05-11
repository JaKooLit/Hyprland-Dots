#!/bin/bash
# Hyprlock Wallpaper Selector - Images AND Videos

terminal=kitty
wallDIR="$HOME/Pictures/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# Directory for swaync icons/errors
iDIR="$HOME/.config/swaync/images"
iDIRi="$HOME/.config/swaync/icons"

# Ensure bc command exists for calculations
if ! command -v bc &>/dev/null; then
  notify-send -i "$iDIR/error.png" "bc missing" "Please install 'bc' utility"
  exit 1
fi

rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Could not detect focused monitor"
  exit 1
fi

scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')

icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

# Retrieve hyprlock wallpapers - BOTH images AND videos
mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
  -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -print0)

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME=". random"

# Rofi menu command with icons
rofi_command="rofi -i -show -dmenu -config $rofi_theme -theme-str $rofi_override"

menu() {
  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))

  printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$RANDOM_PIC"

  for pic_path in "${sorted_options[@]}"; do
    pic_name=$(basename "$pic_path")
    
    # Handle GIFs
    if [[ "$pic_name" =~ \.gif$ ]]; then
      cache_gif_image="$HOME/.cache/gif_preview/${pic_name}.png"
      if [[ ! -f "$cache_gif_image" ]]; then
        mkdir -p "$HOME/.cache/gif_preview"
        magick "$pic_path[0]" -resize 1920x1080 "$cache_gif_image"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_gif_image"
    
    # Handle Videos (mp4, mkv, mov, webm)
    elif [[ "$pic_name" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
      cache_preview_image="$HOME/.cache/video_preview/${pic_name}.png"
      if [[ ! -f "$cache_preview_image" ]]; then
        mkdir -p "$HOME/.cache/video_preview"
        ffmpeg -v error -y -i "$pic_path" -ss 00:00:01.000 -vframes 1 "$cache_preview_image"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_preview_image"
    
    # Handle regular images
    else
      printf "%s\x00icon\x1f%s\n" "$(echo "$pic_name" | cut -d. -f1)" "$pic_path"
    fi
  done
}

# Set wallpaper in hyprlock - handles both images and videos
set_hyprlock_wallpaper() {
  local selected_file="$1"
  local wallpaper_path="$selected_file"
  
  # Validate file exists
  if [ ! -f "$selected_file" ]; then
    notify-send -i "$iDIR/error.png" "File Error" "Selected wallpaper file not found"
    exit 1
  fi

  # If it's a video, use the cached preview image instead
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    local pic_name=$(basename "$selected_file")
    wallpaper_path="$HOME/.cache/video_preview/${pic_name}.png"
    
    # Generate preview if it doesn't exist (failsafe)
    if [[ ! -f "$wallpaper_path" ]]; then
      mkdir -p "$HOME/.cache/video_preview"
      ffmpeg -v error -y -i "$selected_file" -ss 00:00:01.000 -vframes 1 "$wallpaper_path"
    fi
  fi

  CONF="$HOME/.config/hypr/hyprlock.conf"
  
  # Handle different hyprlock config formats
  if grep -qE '^\s*background\s*=' "$CONF"; then
    # Format: background = /path/to/file
    sed -i "s|^\s*background\s*=.*|background = $wallpaper_path|" "$CONF"
  elif grep -qE '^\s*background\s*\{' "$CONF"; then
    # Format: background { path = /path/to/file }
    sed -i "/^\s*background\s*{/,/}/ s|^\(\s*path\s*=\s*\).*|\1$wallpaper_path|" "$CONF"
  else
    # No background line exists, add one
    echo -e "\n# Hyprlock wallpaper\nbackground = $wallpaper_path" >> "$CONF"
  fi

  # Try to reload hyprlock if running
  pkill -USR1 hyprlock 2>/dev/null || true

  # Check if it's a video or image for notification
  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    notify-send "Hyprlock live wallpaper set" "$(basename "$selected_file")"
  else
    notify-send "Hyprlock wallpaper set" "$(basename "$selected_file")"
  fi
}

# Main execution
main() {
  choice=$(menu | $rofi_command)
  choice=$(echo "$choice" | xargs)
  RANDOM_PIC_NAME=$(echo "$RANDOM_PIC_NAME" | xargs)

  if [[ -z "$choice" ]]; then
    echo "No choice selected. Exiting."
    exit 0
  fi

  if [[ "$choice" == "$RANDOM_PIC_NAME" ]]; then
    choice=$(basename "$RANDOM_PIC")
  fi

  choice_basename=$(basename "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')
  selected_file=$(find "$wallDIR" -iname "$choice_basename.*" -print -quit)

  if [[ -z "$selected_file" ]]; then
    notify-send -i "$iDIR/error.png" "File Not Found" "Selected choice: $choice"
    exit 1
  fi

  set_hyprlock_wallpaper "$selected_file"
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

main
