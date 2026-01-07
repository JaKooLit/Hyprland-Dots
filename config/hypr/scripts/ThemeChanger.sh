#!/usr/bin/env bash
set -euo pipefail

# SPDX-FileCopyrightText: 2025-present Ahum Maitra theahummaitra@gmail.com
#
# SPDX-License-Identifier: 	GPL-3.0-or-later

# Repository url : https://github.com/TheAhumMaitra/cautious-waddle

require() {
  command -v "$1" >/dev/null 2>&1 || {
    printf '%s\n' "Missing dependency: $1" >&2
    exit 127
  }
}

require wallust
require rofi

# notify-send is optional
have_notify() { command -v notify-send >/dev/null 2>&1; }

# Prompt for theme; guard -e on cancel
set +e
choice="$(wallust theme list \
  | sed -e '1d' -e 's/^- //' \
  | rofi -dmenu -i -p 'Select Global Theme')"
prompt_status=$?
set -e

# Exit cleanly on cancel or empty selection
if (( prompt_status != 0 )) || [[ -z "${choice}" ]]; then
  exit 0
fi

# Apply the theme and report result
if wallust theme -- "${choice}"; then
  have_notify && notify-send -a ThemeChanger \
    -h string:x-dunst-stack-tag:themechanger \
    "Global theme changed" "Selected: ${choice}"

  # Regenerate templates from the current wallpaper to ensure Wallust rewrites waybar/rofi files
  start_ts=$(date +%s)
  wp_cur="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
  if [ -f "$wp_cur" ]; then
    wallust run -s "$wp_cur" >/dev/null 2>&1 || true
  fi

  # Wait until template targets exist and are non-empty/newer than the start time
  targets=("$HOME/.config/waybar/wallust/colors-waybar.css" "$HOME/.config/rofi/wallust/colors-rofi.rasi")
  for i in $(seq 1 40); do
    ok=1
    for f in "${targets[@]}"; do
      if [ ! -s "$f" ]; then ok=0; break; fi
      mtime=$(stat -c %Y "$f" 2>/dev/null || echo 0)
      if [ "$mtime" -lt "$start_ts" ]; then ok=0; break; fi
    done
    [ $ok -eq 1 ] && break
    sleep 0.1
  done

  # Refresh bars/menus after files are in place
  if [ -x "$HOME/.config/hypr/scripts/Refresh.sh" ]; then
    "$HOME/.config/hypr/scripts/Refresh.sh" >/dev/null 2>&1 || true
  else
    if command -v waybar-msg >/dev/null 2>&1; then
      waybar-msg cmd reload >/dev/null 2>&1 || true
    else
      pkill -SIGUSR2 waybar >/dev/null 2>&1 || true
    fi
  fi
else
  have_notify && notify-send -u critical -a ThemeChanger \
    -h string:x-dunst-stack-tag:themechanger \
    "Failed to apply theme" "${choice}"
  exit 1
fi
