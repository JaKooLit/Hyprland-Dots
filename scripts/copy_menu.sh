#!/usr/bin/env bash

# show_copy_menu
# Arguments:
#   $1 - express_supported flag (1 if available, 0 otherwise)
# Sets global COPY_MENU_CHOICE to one of: install, upgrade, express, quit
show_copy_menu() {
  local express_supported="${1:-0}"
  local menu_title="KooL's Hyprland Dotfiles"
  local prompt="Select what you would like to do:"
  local express_hint="(for upgrades only)"
  local express_desc="Express upgrade $express_hint"
  if [ "$express_supported" -ne 1 ]; then
    express_desc="Express upgrade (requires dots >= ${MIN_EXPRESS_VERSION})"
  fi
  local standard_desc="Standard upgrade (backups + prompts)"
  local install_desc="Initial install (fresh copy)"
  local quit_desc="Exit without changes"
  local info_line="Express skips restores, SDDM wallpaper, and wallpaper downloads."

  local choice=""

  if command -v whiptail >/dev/null 2>&1; then
    choice=$(whiptail --title "$menu_title" --menu "$prompt\n$info_line" 18 70 8 \
      "install" "$install_desc" \
      "upgrade" "$standard_desc" \
      "express" "$express_desc" \
      "quit" "$quit_desc" 3>&1 1>&2 2>&3) || {
      COPY_MENU_CHOICE="quit"
      return 1
    }
  else
    while true; do
      printf "\n%s\n" "$menu_title"
      printf "%s\n" "$prompt"
      printf "  1) %s\n" "$install_desc"
      printf "  2) %s\n" "$standard_desc"
      printf "  3) %s - %s\n" "$express_desc" "$info_line"
      printf "  4) %s\n" "$quit_desc"
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
