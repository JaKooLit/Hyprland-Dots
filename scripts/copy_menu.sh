#!/usr/bin/env bash

# show_copy_menu
# Arguments:
#   $1 - express_supported flag (1 if available, 0 otherwise)
# Sets global COPY_MENU_CHOICE to one of: install, upgrade, express, quit
show_copy_menu() {
  local express_supported="${1:-0}"
  local menu_title="KooL's Hyprland Dotfiles"
  local prompt="Select what you would like to do:"
  local express_desc="For upgrades only - skips restore prompts, SDDM wallpaper, and wallpaper download steps."
  if [ "$express_supported" -ne 1 ]; then
    express_desc="For upgrades only - requires installed dots >= ${MIN_EXPRESS_VERSION}."
  fi

  local choice=""

  if command -v whiptail >/dev/null 2>&1; then
    choice=$(whiptail --title "$menu_title" --menu "$prompt" 20 90 10 \
      "install" "Initial install (fresh copy of configs)." \
      "upgrade" "Standard upgrade (backup + prompts)." \
      "express" "$express_desc" \
      "quit" "Exit without changes." 3>&1 1>&2 2>&3) || {
      COPY_MENU_CHOICE="quit"
      return 1
    }
  else
    while true; do
      printf "\n%s\n" "$menu_title"
      printf "%s\n" "$prompt"
      printf "  1) Initial install (fresh copy of configs)\n"
      printf "  2) Standard upgrade (backup + prompts)\n"
      printf "  3) Express upgrade - %s\n" "$express_desc"
      printf "  4) Quit\n"
      printf "Enter choice [1-4]: "
      read -r text_choice
      case "$text_choice" in
      1) choice="install"; break ;;
      2) choice="upgrade"; break ;;
      3) choice="express"; break ;;
      4) choice="quit"; break ;;
      *) echo "Invalid selection. Please choose 1-4." ;;
      esac
    done
  fi

  COPY_MENU_CHOICE="$choice"
}
