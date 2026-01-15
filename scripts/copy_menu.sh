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
  local update_tag="Update"
  local quit_tag="Quit"

  local install_desc="Fresh copy"
  local upgrade_desc="Backups + prompts"
  local express_desc="Skips restores & wallpapers"
  local update_desc="Stash + git pull"
  local quit_desc="Exit without changes"

  local choice=""

  # Prefer Python TUI if available (mouse + keyboard, styled hotkeys, help)
  # Determine repo dir robustly: prefer SCRIPT_DIR if set by caller (copy.sh); fallback to this file's parent
  local __self_dir __repo_dir
  __self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  __repo_dir="${SCRIPT_DIR:-$(cd "${__self_dir}/.." 2>/dev/null && pwd)}"
  local py_menu="${__repo_dir}/scripts/tui_menu.py"
  if command -v python3 >/dev/null 2>&1 && [ -f "$py_menu" ]; then
    if choice=$(python3 "$py_menu" --express-supported "$express_supported"); then
      # shellcheck disable=SC2034  # used by parent script after sourcing this file
      COPY_MENU_CHOICE="$choice"
      return 0
    fi
  fi

  # Fallback to whiptail if present
  if command -v whiptail >/dev/null 2>&1; then
    if ! choice=$(whiptail --title "$menu_title" --menu "$prompt" 17 60 8 \
      "$install_tag" "$install_desc" \
      "$upgrade_tag" "$upgrade_desc" \
      "$express_tag" "$express_desc" \
      "$update_tag" "$update_desc" \
      "$quit_tag" "$quit_desc" 3>&1 1>&2 2>&3); then
      COPY_MENU_CHOICE="quit"
      return 1
    fi
  else
    # Plain-text fallback
    while true; do
      printf "\n%s\n" "$menu_title"
      printf "%s\n" "$prompt"
      printf "  1) Install - %s\n" "$install_desc"
      printf "  2) Upgrade - %s\n" "$upgrade_desc"
      printf "  3) Express - %s\n" "$express_desc"
      printf "  4) Update  - %s\n" "$update_desc"
      printf "  5) Quit    - %s\n" "$quit_desc"
      printf "Enter choice [1-5]: "
      read -r text_choice
      case "$text_choice" in
      1) choice="$install_tag"; break ;;
      2) choice="$upgrade_tag"; break ;;
      3) choice="$express_tag"; break ;;
      4) choice="$update_tag"; break ;;
      5) choice="$quit_tag"; break ;;
      *) echo "Invalid selection. Please choose 1-5." ;;
      esac
    done
  fi

  # shellcheck disable=SC2034  # used by parent script after sourcing this file
  COPY_MENU_CHOICE="$choice"
}
