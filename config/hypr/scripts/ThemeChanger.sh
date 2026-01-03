#!/usr/bin/env bash

set -euo pipefail

# SPDX-FileCopyrightText: 2025-present Ahum Maitra theahummaitra@gmail.com
#
# SPDX-License-Identifier: 	GPL-3.0-or-later

# Repository url : https://github.com/TheAhumMaitra/cautious-waddle

# User choice
choice=$(wallust theme list \
  | sed '1d' \
  | sed 's/^- //' \
  | rofi -dmenu -p "Select Global Theme")

# If user requested to exit, then exit
[[ -z "$choice" ]] && exit 0

# Apply the theme
wallust theme "$choice"

# Inform user about theme changed
notify-send "Global theme changed" "Global Theme selected $choice"

# Give warning to user for Waybar theme refresh
notify-send "Press SUPER+ALT+R to Refresh Waybar Theme"
