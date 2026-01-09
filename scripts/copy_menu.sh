#!/usr/bin/env bash

# show_copy_menu
# Arguments:
#   $1 - express_supported flag (1 if available, 0 otherwise)
# Sets global COPY_MENU_CHOICE to one of: install, upgrade, express, quit
show_copy_menu() {
  local express_supported="${1:-0}"
  local menu_title="      KooL's Hyprland Dotfiles      "
  local prompt="Select what you would like to do:"

  local install_tag="Install"
  local upgrade_tag="Upgrade"
  local express_tag="Express"
  local quit_tag="Quit"

  local install_desc="Fresh copy"
  local upgrade_desc="Backups + prompts"
  local express_desc="Skips restores & wallpapers"
  local quit_desc="Exit without changes"
  if [ "$express_supported" -ne 1 ]; then
    express_body="xpress - Requires dots >= ${MIN_EXPRESS_VERSION}"
  fi

  local choice=""

  if command -v whiptail >/dev/null 2>&1; then
    if ! choice=$(whiptail --title "$menu_title" --menu "$prompt" 17 60 8 \
      "$install_tag" "$install_desc" \
      "$upgrade_tag" "$upgrade_desc" \
      "$express_tag" "$express_desc" \
      "$quit_tag" "$quit_desc" 3>&1 1>&2 2>&3); then
      COPY_MENU_CHOICE="quit"
      return 1
    fi
  else
    while true; do
      printf "\n%s\n" "$menu_title"
      printf "%s\n" "$prompt"
      printf "  1) Install - %s\n" "$install_desc"
      printf "  2) Upgrade - %s\n" "$upgrade_desc"
      printf "  3) Express - %s\n" "$express_desc"
      printf "  4) Quit    - %s\n" "$quit_desc"
      printf "Enter choice [1-4]: "
      read -r text_choice
      case "$text_choice" in
      1) choice="$install_tag"; break ;;
      2) choice="$upgrade_tag"; break ;;
      3) choice="$express_tag"; break ;;
      4) choice="$quit_tag"; break ;;
      *) echo "Invalid selection. Please choose 1-4." ;;
      esac
    done
  fi

  # shellcheck disable=SC2034  # used by parent script after sourcing this file
  COPY_MENU_CHOICE="$choice"
}
