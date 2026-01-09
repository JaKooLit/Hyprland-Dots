#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Wallust: derive colors from the current wallpaper and update templates
# Usage: WallustSwww.sh [absolute_path_to_wallpaper]

set -euo pipefail

# Inputs and paths
passed_path="${1:-}"
cache_dir="$HOME/.cache/swww/"
rofi_link="$HOME/.config/rofi/.current_wallpaper"
wallpaper_current="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
read_cached_wallpaper() {
  local cache_file="$1"
  if [[ -f "$cache_file" ]]; then
    awk 'NF && $0 !~ /^filter/ {print; exit}' "$cache_file"
  fi
}

read_wallpaper_from_query() {
  local monitor="$1"
  swww query | awk -v mon="$monitor" '
    /^Monitor/ {
      cur=$2
      gsub(":", "", cur)
    }
    /image:/ && cur==mon {
      sub(/^.*image: /,"")
      print
      exit
    }
  '
}

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
    wallpaper_path="$(read_cached_wallpaper "$cache_file")"
  fi

  if [[ -z "$wallpaper_path" ]]; then
    wallpaper_path="$(read_wallpaper_from_query "$current_monitor")"
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

# Ensure Ghostty directory exists so Wallust can write target even if Ghostty isn't installed
mkdir -p "$HOME/.config/ghostty" || true
wait_for_templates() {
  local start_ts="$1"
  shift
  local files=("$@")
  for _ in {1..50}; do
    local ready=true
    for file in "${files[@]}"; do
      if [[ ! -s "$file" ]]; then
        ready=false
        break
      fi
      local mtime
      mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
      if (( mtime < start_ts )); then
        ready=false
        break
      fi
    done
    $ready && return 0
    sleep 0.1
  done
  return 1
}

# Run wallust (silent) to regenerate templates defined in ~/.config/wallust/wallust.toml
# -s is used in this repo to keep things quiet and avoid extra prompts
start_ts=$(date +%s)
wallust run -s "$wallpaper_path" || true
wallust_targets=(
  "$HOME/.config/waybar/wallust/colors-waybar.css"
  "$HOME/.config/rofi/wallust/colors-rofi.rasi"
)
wait_for_templates "$start_ts" "${wallust_targets[@]}" || true

# Normalize Ghostty palette syntax in case ':' was used by older files
if [ -f "$HOME/.config/ghostty/wallust.conf" ]; then
  sed -i -E 's/^(\s*palette\s*=\s*)([0-9]{1,2}):/\1\2=/' "$HOME/.config/ghostty/wallust.conf" 2>/dev/null || true
fi

# Light wait for Ghostty colors file to be present then signal Ghostty to reload (SIGUSR2)
for _ in 1 2 3; do
  [ -s "$HOME/.config/ghostty/wallust.conf" ] && break
  sleep 0.1
done
if pidof ghostty >/dev/null; then
  for pid in $(pidof ghostty); do kill -SIGUSR2 "$pid" 2>/dev/null || true; done
fi

# Prompt Waybar to reload colors
if command -v waybar-msg >/dev/null 2>&1; then
  waybar-msg cmd reload >/dev/null 2>&1 || true
elif pidof waybar >/dev/null; then
  killall -SIGUSR2 waybar 2>/dev/null || true
fi
