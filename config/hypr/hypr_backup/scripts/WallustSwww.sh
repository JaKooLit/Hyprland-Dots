#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Wallust: derive colors from the current wallpaper and update templates
# Usage: WallustSwww.sh [absolute_path_to_wallpaper]

set -euo pipefail

# Inputs and paths
passed_path="${1:-}"
cache_dir="$HOME/.cache/swww/"
rofi_link="$HOME/.config/rofi/.current_wallpaper"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

# Helper: get focused monitor name (prefer JSON)
get_focused_monitor() {
  if command -v jq >/dev/null 2>&1; then
    hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
  else
    hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}'
  fi
}

# Determine wallpaper_path
wallpaper_path=""
if [[ -n "$passed_path" && -f "$passed_path" ]]; then
  wallpaper_path="$passed_path"
else
  # Try to read from swww cache for the focused monitor, with a short retry loop
  current_monitor="$(get_focused_monitor)"
  cache_file="$cache_dir$current_monitor"

  # Wait briefly for swww to write its cache after an image change
  for i in {1..10}; do
    if [[ -f "$cache_file" ]]; then
      break
    fi
    sleep 0.1
  done

  if [[ -f "$cache_file" ]]; then
    # The first non-filter line is the original wallpaper path
    # wallpaper_path="$(grep -v 'Lanczos3' "$cache_file" | head -n 1)"
    wallpaper_path=$(swww query | grep $current_monitor | awk '{print $9}')
  fi
fi

if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
  # Nothing to do; avoid failing loudly so callers can continue
  exit 0
fi

# Update helpers that depend on the path
ln -sf "$wallpaper_path" "$rofi_link" || true
mkdir -p "$(dirname "$wallpaper_current")"
cp -f "$wallpaper_path" "$wallpaper_current" || true

# Run wallust (silent) to regenerate templates defined in ~/.config/wallust/wallust.toml
# -s is used in this repo to keep things quiet and avoid extra prompts
wallust run -s "$wallpaper_path" || true
