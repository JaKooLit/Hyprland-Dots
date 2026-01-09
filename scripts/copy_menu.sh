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
  local quit_tag="Quit"
  local express_tag="Express"

  local install_body="nstall - Fresh copy"
  local upgrade_body="pgrade - Backups + prompts"
  local quit_body="uit - Exit without changes"
  local express_body="xpress - Quick upgrade (skips restores + SDDM + walls)"
  if [ "$express_supported" -ne 1 ]; then
    express_body="xpress - Requires dots >= ${MIN_EXPRESS_VERSION}"
  fi

  local choice=""

  if command -v whiptail >/dev/null 2>&1; then
    local supports_colors=0
    if whiptail --help 2>&1 | grep -q -- '--colors'; then
      supports_colors=1
    fi

    local desc_install="I$install_body"
    local desc_upgrade="U$upgrade_body"
    local desc_quit="Q$quit_body"
    local desc_express="E$express_body"

    if [ "$supports_colors" -eq 1 ]; then
      desc_install="\\Z2I\\Zn$install_body"
      desc_upgrade="\\Z6U\\Zn$upgrade_body"
      desc_quit="\\Z1Q\\Zn$quit_body"
      desc_express="\\Z5E\\Zn$express_body"
    fi

    if [ "$supports_colors" -eq 1 ]; then
      if ! choice=$(whiptail --title "$menu_title" --colors --menu "$prompt" 17 60 8 \
        "$install_tag" "$desc_install" \
        "$upgrade_tag" "$desc_upgrade" \
        "$express_tag" "$desc_express" \
        "$quit_tag" "$desc_quit" 3>&1 1>&2 2>&3); then
        COPY_MENU_CHOICE="quit"
        return 1
      fi
    else
      if ! choice=$(whiptail --title "$menu_title" --menu "$prompt" 17 60 8 \
        "$install_tag" "$desc_install" \
        "$upgrade_tag" "$desc_upgrade" \
        "$express_tag" "$desc_express" \
        "$quit_tag" "$desc_quit" 3>&1 1>&2 2>&3); then
        COPY_MENU_CHOICE="quit"
        return 1
      fi
    fi
  else
    local c_green
    c_green="$(tput setaf 2 2>/dev/null || printf '')"
    local c_cyan
    c_cyan="$(tput setaf 6 2>/dev/null || printf '')"
    local c_red
    c_red="$(tput setaf 1 2>/dev/null || printf '')"
    local c_magenta
    c_magenta="$(tput setaf 5 2>/dev/null || printf '')"
    local c_reset
    c_reset="$(tput sgr0 2>/dev/null || printf '')"
    while true; do
      printf "\n%s\n" "$menu_title"
      printf "%s\n" "$prompt"
      printf "  1) %s%s%s%s\n" "$c_green" "I" "$c_reset" "$install_body"
      printf "  2) %s%s%s%s\n" "$c_cyan" "U" "$c_reset" "$upgrade_body"
      printf "  3) %s%s%s%s\n" "$c_magenta" "E" "$c_reset" "$express_body"
      printf "  4) %s%s%s%s\n" "$c_red" "Q" "$c_reset" "$quit_body"
      printf "     Express skips restores, SDDM wallpaper, and wallpaper downloads.\n"
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
