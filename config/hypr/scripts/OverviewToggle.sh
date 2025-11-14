#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Overview toggle wrapper - tries Quickshell first, falls back to AGS

set -euo pipefail

# 1) Try Quickshell via Hyprland global dispatch (works if QS is running and listening)
# Only attempt this if a Quickshell process is running; otherwise Hyprland will
# still return success for the dispatch and we'll never fall back to AGS.
if pgrep -x quickshell >/dev/null 2>&1; then
  if hyprctl dispatch global quickshell:overviewToggle >/dev/null 2>&1; then
    exit 0
  fi
fi

# If QS isn't running, but the CLI exists, try starting it and retry once
if command -v qs >/dev/null 2>&1; then
  qs >/dev/null 2>&1 &
  sleep 0.6
  if hyprctl dispatch global quickshell:overviewToggle >/dev/null 2>&1; then
    exit 0
  fi
fi

# 2) Fall back to AGS template
if command -v ags >/dev/null 2>&1; then
  pkill rofi || true
  if ags -t 'overview' >/dev/null 2>&1; then
    exit 0
  fi
  # If it failed, try starting AGS daemon then call the template
  ags >/dev/null 2>&1 &
  sleep 0.6
  if ags -t 'overview' >/dev/null 2>&1; then
    exit 0
  fi
fi

# If we get here, neither worked
notify-send "Overview" "Neither Quickshell nor AGS is available" -u low 2>/dev/null || true
exit 1
