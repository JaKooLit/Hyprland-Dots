#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Initialize J/K keybinds to match the current default layout at startup

# Query current layout (master|dwindle)
LAYOUT=$(hyprctl -j getoption general:layout | jq -r '.str')

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
    hyprctl keyword bind SUPER,O,togglesplit
    ;;
  *)
    # Do nothing for unexpected values
    :
    ;;
 esac
