#!/usr/bin/env bash
set -euo pipefail

# Hyprsunset toggle + Waybar status helper
# Phase 1: manual toggle only (no scheduling)
# Icons:
# - Off: bright sun
# - On: sunset icon if available, otherwise a blue sun
#
# Customize via env vars:
#   HYPERSUNSET_TEMP   default 4500 (K)
#   HYPERSUNSET_ICON_MODE  sunset|blue  (default: sunset)

STATE_FILE="$HOME/.cache/.hyprsunset_state"
TARGET_TEMP="${HYPERSUNSET_TEMP:-4500}"
ICON_MODE="${HYPERSUNSET_ICON_MODE:-sunset}"

ensure_state() {
  [[ -f "$STATE_FILE" ]] || echo "off" > "$STATE_FILE"
}

# Render icons using pango markup to allow colorization
icon_off() {
  # bright sun when not activated
  printf "<span foreground='gold'></span>"
}

icon_on() {
  case "$ICON_MODE" in
    sunset)
      printf "<span foreground='orange'></span>"
      ;;
    blue)
      printf "<span foreground='deepskyblue'></span>"
      ;;
    *)
      printf "<span foreground='orange'></span>"
      ;;
  esac
}

cmd_toggle() {
  ensure_state
  state="$(cat "$STATE_FILE" || echo off)"
  if [[ "$state" == "on" ]]; then
    if command -v hyprsunset >/dev/null 2>&1; then
      hyprsunset -r || true
    fi
    echo off > "$STATE_FILE"
  else
    if command -v hyprsunset >/dev/null 2>&1; then
      hyprsunset -t "$TARGET_TEMP" || true
    fi
    echo on > "$STATE_FILE"
  fi
}

cmd_status() {
  ensure_state
  state="$(cat "$STATE_FILE" || echo off)"
  if [[ "$state" == "on" ]]; then
    txt="$(icon_on)"
    cls="on"
    tip="Night light on @ ${TARGET_TEMP}K"
  else
    txt="$(icon_off)"
    cls="off"
    tip="Night light off"
  fi
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$txt" "$cls" "$tip"
}

case "${1:-}" in
  toggle) cmd_toggle ;;
  status) cmd_status ;;
  *) echo "usage: $0 [toggle|status]" >&2; exit 2 ;;
 esac
