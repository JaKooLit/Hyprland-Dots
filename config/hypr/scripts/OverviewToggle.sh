#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Overview toggle wrapper - tries quickshell first, falls back to AGS

# Try quickshell first if installed
if command -v qs >/dev/null 2>&1; then
  # Check if quickshell is running
  if pgrep -x qs >/dev/null 2>&1; then
    # Try to toggle quickshell overview
    hyprctl dispatch global quickshell:overviewToggle 2>/dev/null && exit 0
  fi
fi

# Fall back to AGS if quickshell failed or isn't available
if command -v ags >/dev/null 2>&1; then
  # Check if AGS is running, start it if not
  if ! pgrep -x ags >/dev/null 2>&1; then
    ags &
    sleep 0.5
  fi
  # Toggle AGS overview
  pkill rofi || true
  ags -t 'overview' 2>/dev/null && exit 0
fi

# If we get here, neither worked
notify-send "Overview" "Neither Quickshell nor AGS is available" -u low 2>/dev/null || true
exit 1
