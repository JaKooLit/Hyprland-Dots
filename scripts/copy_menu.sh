#!/usr/bin/env bash

# show_copy_menu
# Arguments:
#   $1 - express_supported flag (1 if available, 0 otherwise)
# Sets global COPY_MENU_CHOICE to one of: install, upgrade, express, quit
show_copy_menu() {
  local express_supported="${1:-0}"
  local menu_title="KooL's Hyprland Dotfiles"
  local prompt="Select what you would like to do:"
  local info_line="Express skips restores, SDDM wallpaper, and wallpaper downloads."

  local install_tag="Install"
  local upgrade_tag="Upgrade"
  local quit_tag="Quit"
  local express_tag="Express"

  local install_body="nstall - Fresh copy"
  local upgrade_body="pgrade - Backups + prompts"
  local quit_body="uit - Exit without changes"
  local express_body="xpress - For upgrades only"
  if [ "$express_supported" -ne 1 ]; then
    express_body="xpress - Requires dots >= ${MIN_EXPRESS_VERSION}"
  fi

  local choice=""

  if command -v whiptail >/dev/null 2>&1; then
    local hi_install="\\Z2I\\Zn$install_body"
    local hi_upgrade="\\Z6U\\Zn$upgrade_body"
    local hi_quit="\\Z1Q\\Zn$quit_body"
    local hi_express="\\Z5E\\Zn$express_body"

    choice=$(whiptail --title "$menu_title" --colors --menu "$prompt\n$info_line" 18 70 8 \
      "$install_tag" "$hi_install" \
      "$upgrade_tag" "$hi_upgrade" \
      "$quit_tag" "$hi_quit" \
      "$express_tag" "$hi_express" 3>&1 1>&2 2>&3) || {
      COPY_MENU_CHOICE="quit"
      return 1
    }
  else
    local c_green="$(tput setaf 2 2>/dev/null || printf '')"
    local c_cyan="$(tput setaf 6 2>/dev/null || printf '')"
    local c_red="$(tput setaf 1 2>/dev/null || printf '')"
    local c_magenta="$(tput setaf 5 2>/dev/null || printf '')"
    local c_reset="$(tput sgr0 2>/dev/null || printf '')"
    while true; do
      printf "\n%s\n" "$menu_title"
      printf "%s\n" "$prompt"
      printf "  1) %s%s%s%s\n" "$c_green" "I" "$c_reset" "$install_body"
      printf "  2) %s%s%s%s\n" "$c_cyan" "U" "$c_reset" "$upgrade_body"
      printf "  3) %s%s%s%s\n" "$c_red" "Q" "$c_reset" "$quit_body"
      printf "  4) %s%s%s%s\n" "$c_magenta" "E" "$c_reset" "$express_body"
      printf "     %s\n" "$info_line"
      printf "Enter choice [1-4]: "
      read -r text_choice
      case "$text_choice" in
      1) choice="$install_tag"; break ;;
      2) choice="$upgrade_tag"; break ;;
      3) choice="$quit_tag"; break ;;
      4) choice="$express_tag"; break ;;
      *) echo "Invalid selection. Please choose 1-4." ;;
      esac
    done
  fi

  COPY_MENU_CHOICE="$choice"
}
}
