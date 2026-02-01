#!/usr/bin/env bash
# User interaction helpers extracted from copy.sh. Each helper echoes state or sets
# globals deliberately to minimize side effects.

# Detect keyboard layout via localectl or setxkbmap.
prompt_detect_layout() {
  if command -v localectl >/dev/null 2>&1; then
    local layout
    layout=$(localectl status --no-pager | awk '/X11 Layout/ {print $3}')
    [ -n "$layout" ] && { echo "$layout"; return; }
  fi
  if command -v setxkbmap >/dev/null 2>&1; then
    local layout
    layout=$(setxkbmap -query | awk '/layout/ {print $2}')
    [ -n "$layout" ] && { echo "$layout"; return; }
  fi
  echo "(unset)"
}

# Confirm or set keyboard layout; writes to SystemSettings.conf.
prompt_keyboard_layout() {
  local layout="$1"
  local log="$2"
  local base="${DOTFILES_DIR:-.}"

  if [ "$layout" = "(unset)" ]; then
    while true; do
      printf "\n%.0s" {1..1}
      print_color $WARNING "\n    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
            STOP AND READ
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    !!! IMPORTANT WARNING !!!

The Default Keyboard Layout could not be detected
You need to set it Manually

    !!! WARNING !!!

Setting a wrong Keyboard Layout will cause Hyprland to crash
If you are not sure, just type ${YELLOW}us${RESET}
${SKYBLUE}You can change later in ~/.config/hypr/UserConfigs/UserSettings.conf${RESET}

${MAGENTA} NOTE:${RESET}
•  You can also set more than 2 keyboard layouts
•  For example: ${YELLOW}us, kr, gb, ru${RESET}
"
      printf "\n%.0s" {1..1}

      echo -n "${CAT} - Please enter the correct keyboard layout: "
      read new_layout

      if [ -n "$new_layout" ]; then
        layout="$new_layout"
        break
      else
        echo "${CAT} Please enter a keyboard layout."
      fi
    done
  fi

  printf "${NOTE} Detecting keyboard layout to prepare proper Hyprland Settings\n"
  while true; do
    printf "${INFO} Current keyboard layout is ${MAGENTA}$layout${RESET}\n"
    echo -n "${CAT} Is this correct? [y/n] "
    read keyboard_layout
    case $keyboard_layout in
      [yY])
        awk -v layout="$layout" '/kb_layout/ {$0 = "  kb_layout = " layout} 1' "$base/config/hypr/configs/SystemSettings.conf" >temp.conf
        mv temp.conf "$base/config/hypr/configs/SystemSettings.conf"
        echo "${NOTE} kb_layout ${MAGENTA}$layout${RESET} configured in settings." 2>&1 | tee -a "$log"
        break
        ;;
      [nN])
        printf "\n%.0s" {1..2}
        print_color $WARNING "
    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
            STOP AND READ
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    !!! IMPORTANT WARNING !!!

The Default Keyboard Layout could not be detected
You need to set it Manually

    !!! WARNING !!!

Setting a wrong Keyboard Layout will cause Hyprland to crash
If you are not sure, just type ${YELLOW}us${RESET}
${SKYBLUE}You can change later in ~/.config/hypr/UserConfigs/UserSettings.conf${RESET}

${MAGENTA} NOTE:${RESET}
•  You can also set more than 2 keyboard layouts
•  For example: ${YELLOW}us, kr, gb, ru${RESET}
"
        printf "\n%.0s" {1..1}
        echo -n "${CAT} - Please enter the correct keyboard layout: "
        read new_layout
        awk -v new_layout="$new_layout" '/kb_layout/ {$0 = "  kb_layout = " new_layout} 1' "$base/config/hypr/configs/SystemSettings.conf" >temp.conf
        mv temp.conf "$base/config/hypr/configs/SystemSettings.conf"
        echo "${OK} kb_layout $new_layout configured in settings." 2>&1 | tee -a "$log"
        break
        ;;
      *)
        echo "${ERROR} Please enter either 'y' or 'n'."
        ;;
    esac
  done
}

# Prompt for resolution choice; echoes "< 1440p" or "≥ 1440p".
prompt_resolution_choice() {
  local choice
  while true; do
    echo "${INFO:-[INFO]} Select monitor resolution for scaling:"
    echo "  1) < 1440p   (lower DPI; smaller displays)"
    echo "  2) ≥ 1440p   (default; 1440p/2k/4k)"

    if ! read -r -p "${CAT} Enter the number of your choice (1 or 2): " choice </dev/tty; then
      echo "${ERROR} Unable to read input (tty unavailable)."
      continue
    fi
    echo "${INFO:-[INFO]} You entered: '$choice'"
    case "$choice" in
      1) echo "< 1440p"; return ;;
      2) echo "≥ 1440p"; return ;;
      *) echo "${ERROR} Invalid choice. Please enter 1 for < 1440p or 2 for ≥ 1440p." ;;
    esac
  done
}

# Prompt for 12H clock; sets waybar/hyprlock/SDDM changes when accepted.
prompt_clock_12h() {
  local log="$1"
  local base="${DOTFILES_DIR:-.}"
  while true; do
    echo -e "${NOTE} ${SKY_BLUE} By default, KooL's Dots are configured in 24H clock format."
    echo -n "$CAT Do you want to change to 12H (AM/PM) clock format? (y/n): "
    read answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [[ "$answer" == "y" ]]; then
      # waybar clocks
      sed -i 's#^\(\s*\)//\("format": " {:%I:%M %p}",\) #\1\2 #g' "$base/config/waybar/Modules" 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)\("format": " {:%H:%M:%S}",\) #\1//\2#g' "$base/config/waybar/Modules" 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)\("format": "  {:%H:%M}",\) #\1//\2#g' "$base/config/waybar/Modules" 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)//\("format": "{:%I:%M %p - %d/%b}",\) #\1\2#g' "$base/config/waybar/Modules" 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)\("format": "{:%H:%M - %d/%b}",\) #\1//\2#g' "$base/config/waybar/Modules" 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)//\("format": "{:%B | %a %d, %Y | %I:%M %p}",\) #\1\2#g' "$base/config/waybar/Modules" 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)\("format": "{:%B | %a %d, %Y | %H:%M}",\) #\1//\2#g' "$base/config/waybar/Modules" 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)//\("format": "{:%A, %I:%M %P}",\) #\1\2#g' "$base/config/waybar/Modules" 2>&1 | tee -a "$log"
      sed -i 's#^\(\s*\)\("format": "{:%a %d | %H:%M}",\) #\1//\2#g' "$base/config/waybar/Modules" 2>&1 | tee -a "$log"

      # hyprlock
      local HYPRLOCK_FILE="$base/config/hypr/hyprlock.conf"
      if [ ! -f "$HYPRLOCK_FILE" ] && [ -f "$base/config/hypr/hyprlock-1080p.conf" ]; then
        HYPRLOCK_FILE="$base/config/hypr/hyprlock-1080p.conf"
      fi
      if [ -f "$HYPRLOCK_FILE" ]; then
        sed -i 's/^\s*text = cmd\[update:1000\] echo \"\$(date +\"%H\")\"/# &/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
        sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo \"\$(date +\"%I\")\" #AM\/PM/\1    text = cmd\[update:1000\] echo \"\$(date +\"%I\")\" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
        sed -i 's/^\s*text = cmd\[update:1000\] echo \"\$(date +\"%S\")\"/# &/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
        sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo \"\$(date +\"%S %p\")\" #AM\/PM/\1    text = cmd\[update:1000\] echo \"\$(date +\"%S %p\")\" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$log"
      else
        echo "${WARN} hyprlock template not found; skipping 12H lock format edits" 2>&1 | tee -a "$log"
      fi

      if [ "${EXPRESS_MODE:-0}" -eq 0 ]; then
        apply_sddm_12h_format "/usr/share/sddm/themes/simple-sddm" "$log"
        apply_sddm_12h_format "/usr/share/sddm/themes/simple_sddm_2" "$log"
        apply_sddm_12h_format_sequoia "/usr/share/sddm/themes/sequoia_2" "$log"
      else
        echo "${NOTE:-[NOTE]} Express mode: skipping SDDM 12H edits to avoid sudo prompts." 2>&1 | tee -a "$log"
      fi
      echo "${OK} 12H format set on waybar clocks succesfully." 2>&1 | tee -a "$log"
      return
    elif [[ "$answer" == "n" ]]; then
      echo "${NOTE} You chose not to change to 12H format." 2>&1 | tee -a "$log"
      return
    else
      echo "${ERROR} Invalid choice. Please enter y for yes or n for no."
    fi
  done
}

apply_sddm_12h_format() {
  local sddm_directory="$1"
  local log="$2"
  if [ -d "$sddm_directory" ]; then
    echo "Editing ${SKY_BLUE}$sddm_directory${RESET} to 12H format" 2>&1 | tee -a "$log"
    if ! sudo -n sed -i 's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log"; then
      echo "${WARN:-[WARN]} Skipping SDDM 12H edit (sudo password required)." 2>&1 | tee -a "$log"
      return
    fi
    sudo -n sed -i 's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log" || true
  fi
}

apply_sddm_12h_format_sequoia() {
  local sddm_directory="$1"
  local log="$2"
  if [ -d "$sddm_directory" ]; then
    echo "${YELLOW}sddm sequoia_2${RESET} theme exists. Editing to 12H format" 2>&1 | tee -a "$log"
    if ! sudo -n sed -i 's|^clockFormat="HH:mm"|## clockFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log"; then
      echo "${WARN:-[WARN]} Skipping sequoia SDDM 12H edit (sudo password required)." 2>&1 | tee -a "$log"
      return
    fi
    if ! grep -q 'clockFormat="hh:mm AP"' "$sddm_directory/theme.conf"; then
      sudo -n sed -i '/^clockFormat=/a clockFormat="hh:mm AP"' "$sddm_directory/theme.conf" 2>&1 | tee -a "$log" || true
    fi
    echo "${OK} 12H format set to SDDM successfully." 2>&1 | tee -a "$log"
  fi
}


# Express upgrade confirmation; may set EXPRESS_MODE=1.
prompt_express_upgrade() {
  local express_supported="$1"
  local log="$2"
  if [ "$EXPRESS_MODE" -eq 1 ] && [ "$express_supported" -eq 0 ]; then
    echo "${NOTE} Express mode requires installed dotfiles v${MIN_EXPRESS_VERSION} or newer. Continuing with standard upgrade prompts." 2>&1 | tee -a "$log"
    EXPRESS_MODE=0
    return
  fi
  if [ "$UPGRADE_MODE" -eq 1 ] && [ "$EXPRESS_MODE" -eq 0 ]; then
    if [ "$express_supported" -eq 0 ]; then
      echo "${NOTE} Express mode requires installed dotfiles v${MIN_EXPRESS_VERSION} or newer. Continuing with standard upgrade prompts." 2>&1 | tee -a "$log"
    else
      while true; do
        echo "${NOTE} Express mode skips config restore prompts, SDDM/background questions, and trims old backups."
        if ! read -r -p "${CAT} Do you want to continue with EXPRESS upgrade mode? (y/N): " express_choice </dev/tty; then
          echo "${ERROR} Unable to read input for express choice; defaulting to standard prompts." 2>&1 | tee -a "$log"
          break
        fi
        case "$express_choice" in
          [Yy])
            EXPRESS_MODE=1
            echo "${INFO} Express mode enabled for this upgrade." 2>&1 | tee -a "$log"
            break
            ;;
          [Nn] | "")
            echo "${NOTE} Continuing with standard upgrade prompts." 2>&1 | tee -a "$log"
            break
            ;;
          *)
            echo "${WARN} Please answer y or n."
            ;;
        esac
      done
    fi
  fi
}
