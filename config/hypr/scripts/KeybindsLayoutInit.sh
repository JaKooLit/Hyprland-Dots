#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Initialize J/K keybinds to match the current default layout at startup

set -euo pipefail

# Determine current layout (master|dwindle); be robust to null at startup
LAYOUT=$(hyprctl -j getoption general:layout | jq -r '.str // empty' 2>/dev/null || true)
if [ -z "${LAYOUT:-}" ]; then
  # Fallback: parse non-JSON output (e.g., "str: dwindle")
  LAYOUT=$(hyprctl getoption general:layout 2>/dev/null | awk -F'str:' 'NF>1 {gsub(/^ +| +$/,"",$2); print $2}')
fi
[ -z "${LAYOUT:-}" ] && exit 0

case "$LAYOUT" in
  master)
    # Ensure master layout-style binds
    hyprctl keyword unbind SUPER,J
    hyprctl keyword unbind SUPER,K
    hyprctl keyword unbind SUPER,O
    hyprctl keyword bind SUPER,J,layoutmsg,cyclenext
    hyprctl keyword bind SUPER,K,layoutmsg,cycleprev
    ;;
  dwindle)
    # Ensure dwindle layout-style binds
    hyprctl keyword unbind SUPER,J
    hyprctl keyword unbind SUPER,K
    hyprctl keyword unbind SUPER,O
    hyprctl keyword bind SUPER,J,cyclenext
    hyprctl keyword bind SUPER,K,cyclenext,prev
    # ensure SUPER+O togglesplit is available on dwindle
    hyprctl keyword bind SUPER,O,togglesplit
    ;;
  *)
    # Do nothing for unexpected values
    :
    ;;
 esac
