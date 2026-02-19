#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */

set -o errexit
set -o nounset
set -o pipefail

rofi_theme="$HOME/.config/rofi/config-emoji.rasi"
emoji_data_file="$HOME/.config/hypr/scripts/RofiEmoji.data"
msg='** note ** 👀 Click or Return to choose || Ctrl V to Paste'

if ! command -v rofi >/dev/null 2>&1 || ! command -v wl-copy >/dev/null 2>&1; then
  echo "Error: rofi and wl-copy are required." >&2
  exit 1
fi

if [[ ! -f "$emoji_data_file" ]]; then
  echo "Error: emoji data file not found at $emoji_data_file" >&2
  exit 1
fi

if pgrep -x rofi >/dev/null; then
  pkill rofi
fi

selection=$(rofi -i -dmenu -mesg "$msg" -config "$rofi_theme" < "$emoji_data_file" | awk '{print $1}' | head -n 1)

if [[ -n "$selection" ]]; then
  printf '%s' "$selection" | wl-copy
fi
