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

# Record time before applying so we can wait for fresh template outputs
start_ts=$(date +%s)

# Apply the theme and report result
if wallust theme -- "${choice}"; then
  have_notify && notify-send -a ThemeChanger \
    -h string:x-dunst-stack-tag:themechanger \
    "Global theme changed" "Selected: ${choice}"

  # Wait until template targets exist, are newer than start_ts, and are stable (size/mtime stops changing)
  targets=(
    "$HOME/.config/waybar/wallust/colors-waybar.css"
    "$HOME/.config/rofi/wallust/colors-rofi.rasi"
    "$HOME/.config/kitty/kitty-themes/01-Wallust.conf"
  )

  # Phase 1: appearance + freshness
  for _ in $(seq 1 100); do # up to ~10s
    ok=1
    for f in "${targets[@]}"; do
      [ -s "$f" ] || { ok=0; break; }
      mtime=$(stat -c %Y "$f" 2>/dev/null || echo 0)
      [ "$mtime" -ge "$start_ts" ] || { ok=0; break; }
    done
    [ $ok -eq 1 ] && break
    sleep 0.1
  done

  # Phase 2: stability (avoid reading half-written files)
  if [ $ok -eq 1 ]; then
    for _ in 1 2 3; do
      sizes_a=(); mtimes_a=()
      for f in "${targets[@]}"; do
        sizes_a+=("$(stat -c %s "$f" 2>/dev/null || echo 0)")
        mtimes_a+=("$(stat -c %Y "$f" 2>/dev/null || echo 0)")
      done
      sleep 0.15
      sizes_b=(); mtimes_b=()
      for f in "${targets[@]}"; do
        sizes_b+=("$(stat -c %s "$f" 2>/dev/null || echo 0)")
        mtimes_b+=("$(stat -c %Y "$f" 2>/dev/null || echo 0)")
      done
      if [ "${sizes_a[*]}" = "${sizes_b[*]}" ] && [ "${mtimes_a[*]}" = "${mtimes_b[*]}" ]; then
        break
      fi
    done
  else
    # As a safety net, wait a bit to avoid racing rofi reload against template writes
    sleep 0.5
  fi

  # Small cushion before refresh to mirror wallpaper flow
  sleep 0.2
  # Refresh bars/menus after files are ready
  if [ -x "$HOME/.config/hypr/scripts/Refresh.sh" ]; then
    "$HOME/.config/hypr/scripts/Refresh.sh" >/dev/null 2>&1 || true
  else
    if command -v waybar-msg >/dev/null 2>&1; then
      waybar-msg cmd reload >/dev/null 2>&1 || true
    else
      pkill -SIGUSR2 waybar >/dev/null 2>&1 || true
    fi
  fi

  # Ask kitty to reload its config so the new 01-Wallust.conf is picked up
  if pidof kitty >/dev/null; then
    for pid in $(pidof kitty); do kill -SIGUSR1 "$pid" 2>/dev/null || true; done
  fi
else
  have_notify && notify-send -u critical -a ThemeChanger \
    -h string:x-dunst-stack-tag:themechanger \
    "Failed to apply theme" "${choice}"
  exit 1
fi
