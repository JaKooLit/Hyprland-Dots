#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #

clear
wallpaper=$HOME/.config/hypr/wallpaper_effects/.wallpaper_current
waybar_style="$HOME/.config/waybar/style/[Extra] Neon Circuit.css"
waybar_config="$HOME/.config/waybar/configs/[TOP] Default"
waybar_config_laptop="$HOME/.config/waybar/configs/[TOP] Default Laptop"

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
  echo "${ERROR}  This script should ${WARNING}NOT${RESET} be executed as root!! Exiting......."
  printf "\n%.0s" {1..2}
  exit 1
fi

# Function to print colorful text
print_color() {
  printf "%b%s%b\n" "$1" "$2" "$RESET"
}

# Check /etc/os-release for Ubuntu or Debian and warn about Hyprland version requirement
if grep -iqE '^(ID_LIKE|ID)=.*(ubuntu|debian)' /etc/os-release >/dev/null 2>&1; then
  printf "\n%.0s" {1..1}
  print_color $WARNING "\nThese Dotfiles are only supported on Hyprland v0.50 or greater. Do not install on older versions of Hyprland.\n"
  while true; do
    echo -n "${CAT} Do you want to continue anyway? (y/N): "
    read _continue
    _continue=$(echo "${_continue}" | tr '[:upper:]' '[:lower:]')
    case "${_continue}" in
    y | yes)
      echo "${NOTE} Proceeding on Ubuntu/Debian by user confirmation."
      break
      ;;
    n | no | "")
      printf "\n%.0s" {1..1}
      echo "${INFO} Aborting per user choice. No changes made."
      printf "\n%.0s" {1..1}
      exit 1
      ;;
    *)
      echo "${WARN} Please answer 'y' or 'n'."
      ;;
    esac
  done
fi

printf "\n%.0s" {1..1}
echo -e "\e[35m
    ╦╔═┌─┐┌─┐╦    ╔╦╗┌─┐┌┬┐┌─┐
    ╠╩╗│ ││ │║     ║║│ │ │ └─┐ 2025
    ╩ ╩└─┘└─┘╩═╝  ═╩╝└─┘ ┴ └─┘
\e[0m"
printf "\n%.0s" {1..1}

####### Announcement
echo "${WARNING}A T T E N T I O N !${RESET}"
echo "${MAGENTA}Kindly visit KooL Hyprland Own Wiki for changelogs${RESET}"
printf "\n%.0s" {1..1}

# Create Directory for Copy Logs
if [ ! -d Copy-Logs ]; then
  mkdir Copy-Logs
fi

# Set the name of the log file to include the current date and time
LOG="Copy-Logs/install-$(date +%d-%H%M%S)_dotfiles.log"

# update home directories
xdg-user-dirs-update 2>&1 | tee -a "$LOG" || true

# setting up for NVIDIA
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
  echo "${INFO} Nvidia GPU detected. Setting up proper env's and configs" 2>&1 | tee -a "$LOG" || true
  sed -i '/env = LIBVA_DRIVER_NAME,nvidia/s/^#//' config/hypr/configs/ENVariables.conf
  sed -i '/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/s/^#//' config/hypr/configs/ENVariables.conf
  sed -i '/env = NVD_BACKEND,direct/s/^#//' config/hypr/configs/ENVariables.conf
  sed -i '/env = GSK_RENDERER,ngl/s/^#//' config/hypr/configs/ENVariables.conf

  # no hardware cursors if nvidia detected
  sed -i 's/^\([[:space:]]*no_hardware_cursors[[:space:]]*=[[:space:]]*\)2/\1 1/' config/hypr/configs/SystemSettings.conf
fi

# uncommenting WLR_RENDERER_ALLOW_SOFTWARE,1 if running in a VM is detected
if hostnamectl | grep -q 'Chassis: vm'; then
  echo "${INFO} System is running in a virtual machine. Setting up proper env's and configs" 2>&1 | tee -a "$LOG" || true
  sed -i 's/^\([[:space:]]*no_hardware_cursors[[:space:]]*=[[:space:]]*\)2/\1 1/' config/hypr/configs/SystemSettings.conf
  # enabling proper ENV's for Virtual Environment which should help
  sed -i '/env = WLR_RENDERER_ALLOW_SOFTWARE,1/s/^#//' config/hypr/configs/ENVariables.conf
  sed -i '/monitor = Virtual-1, 1920x1080@60,auto,1/s/^#//' config/hypr/monitors.conf
fi

# Proper Polkit for NixOS
if hostnamectl | grep -q 'Operating System: NixOS'; then
  echo "${INFO} NixOS Distro Detected. Setting up proper env's and configs." 2>&1 | tee -a "$LOG" || true
  # Ensure NixOS polkit is enabled via overlay and default polkit is disabled via disable list
  OVERLAY_SA="config/hypr/configs/Startup_Apps.conf"
  DISABLE_SA="config/hypr/configs/Startup_Apps.disable"
  mkdir -p "$(dirname "$OVERLAY_SA")"
  touch "$OVERLAY_SA" "$DISABLE_SA"
  if ! grep -qx 'exec-once = $scriptsDir/Polkit-NixOS.sh' "$OVERLAY_SA"; then
    echo 'exec-once = $scriptsDir/Polkit-NixOS.sh' >>"$OVERLAY_SA"
  fi
  if ! grep -qx '\$scriptsDir/Polkit.sh' "$DISABLE_SA"; then
    echo '$scriptsDir/Polkit.sh' >>"$DISABLE_SA"
  fi
fi

# activating hyprcursor on env by checking if the directory ~/.icons/Bibata-Modern-Ice/hyprcursors exists
if [ -d "$HOME/.icons/Bibata-Modern-Ice/hyprcursors" ]; then
  HYPRCURSOR_ENV_FILE="config/hypr/configs/ENVariables.conf"
  echo "${INFO} Bibata-Hyprcursor directory detected. Activating Hyprcursor...." 2>&1 | tee -a "$LOG" || true
  sed -i 's/^#env = HYPRCURSOR_THEME,Bibata-Modern-Ice/env = HYPRCURSOR_THEME,Bibata-Modern-Ice/' "$HYPRCURSOR_ENV_FILE"
  sed -i 's/^#env = HYPRCURSOR_SIZE,24/env = HYPRCURSOR_SIZE,24/' "$HYPRCURSOR_ENV_FILE"
fi

printf "\n%.0s" {1..1}

# Function to detect keyboard layout using localectl or setxkbmap
detect_layout() {
  if command -v localectl >/dev/null 2>&1; then
    layout=$(localectl status --no-pager | awk '/X11 Layout/ {print $3}')
    if [ -n "$layout" ]; then
      echo "$layout"
    fi
  elif command -v setxkbmap >/dev/null 2>&1; then
    layout=$(setxkbmap -query | grep layout | awk '{print $2}')
    if [ -n "$layout" ]; then
      echo "$layout"
    fi
  fi
}

# Detect the current keyboard layout
layout=$(detect_layout)

if [ "$layout" = "(unset)" ]; then
  while true; do
    printf "\n%.0s" {1..1}
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

    if [ -n "$new_layout" ]; then
      layout="$new_layout"
      break
    else
      echo "${CAT} Please enter a keyboard layout."
    fi
  done
fi

printf "${NOTE} Detecting keyboard layout to prepare proper Hyprland Settings\n"

# Prompt the user to confirm whether the detected layout is correct
while true; do
  printf "${INFO} Current keyboard layout is ${MAGENTA}$layout${RESET}\n"
  echo -n "${CAT} Is this correct? [y/n] "
  read keyboard_layout

  case $keyboard_layout in
  [yY])
    awk -v layout="$layout" '/kb_layout/ {$0 = "  kb_layout = " layout} 1' config/hypr/configs/SystemSettings.conf >temp.conf
    mv temp.conf config/hypr/configs/SystemSettings.conf

    echo "${NOTE} kb_layout ${MAGENTA}$layout${RESET} configured in settings." 2>&1 | tee -a "$LOG"
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

    awk -v new_layout="$new_layout" '/kb_layout/ {$0 = "  kb_layout = " new_layout} 1' config/hypr/configs/SystemSettings.conf >temp.conf
    mv temp.conf config/hypr/configs/SystemSettings.conf
    echo "${OK} kb_layout $new_layout configured in settings." 2>&1 | tee -a "$LOG"
    break
    ;;
  *)
    echo "${ERROR} Please enter either 'y' or 'n'."
    ;;
  esac
done

# Check if asusctl is installed and add rog-control-center on Startup
if command -v asusctl >/dev/null 2>&1; then
  OVERLAY_SA="config/hypr/configs/Startup_Apps.conf"
  mkdir -p "$(dirname "$OVERLAY_SA")"
  touch "$OVERLAY_SA"
  grep -qx 'exec-once = rog-control-center' "$OVERLAY_SA" || echo 'exec-once = rog-control-center' >>"$OVERLAY_SA"
fi

# Check if blueman-applet is installed and add blueman-applet on Startup
if command -v blueman-applet >/dev/null 2>&1; then
  OVERLAY_SA="config/hypr/configs/Startup_Apps.conf"
  mkdir -p "$(dirname "$OVERLAY_SA")"
  touch "$OVERLAY_SA"
  grep -qx 'exec-once = blueman-applet' "$OVERLAY_SA" || echo 'exec-once = blueman-applet' >>"$OVERLAY_SA"
fi

# Check if ags is installed and enable it
if command -v ags >/dev/null 2>&1; then
  echo "${INFO} AGS detected - enabling in startup and refresh scripts" 2>&1 | tee -a "$LOG"
  OVERLAY_SA="config/hypr/configs/Startup_Apps.conf"
  mkdir -p "$(dirname "$OVERLAY_SA")"
  touch "$OVERLAY_SA"
  grep -qx 'exec-once = ags' "$OVERLAY_SA" || echo 'exec-once = ags' >>"$OVERLAY_SA"
  sed -i '/#ags -q && ags &/s/^#//' config/hypr/scripts/RefreshNoWaybar.sh
  sed -i '/#ags -q && ags &/s/^#//' config/hypr/scripts/Refresh.sh
fi

# Check if quickshell is installed and enable it
if command -v qs >/dev/null 2>&1; then
  echo "${INFO} Quickshell detected - enabling in startup and refresh scripts" 2>&1 | tee -a "$LOG"
  OVERLAY_SA="config/hypr/configs/Startup_Apps.conf"
  mkdir -p "$(dirname "$OVERLAY_SA")"
  touch "$OVERLAY_SA"
  grep -qx 'exec-once = qs' "$OVERLAY_SA" || echo 'exec-once = qs' >>"$OVERLAY_SA"
  sed -i '/#pkill qs && qs &/s/^#//' config/hypr/scripts/RefreshNoWaybar.sh
  sed -i '/#pkill qs && qs &/s/^#//' config/hypr/scripts/Refresh.sh
fi

# Ensure layout-aware keybinds init runs on startup (adds to user overlay so it survives composes)
OVERLAY_SA="config/hypr/configs/Startup_Apps.conf"
mkdir -p "$(dirname "$OVERLAY_SA")"
if ! grep -qx 'exec-once = \$scriptsDir/KeybindsLayoutInit.sh' "$OVERLAY_SA"; then
  echo 'exec-once = $scriptsDir/KeybindsLayoutInit.sh' >>"$OVERLAY_SA"
  echo "${INFO} Added KeybindsLayoutInit.sh to user Startup_Apps overlay" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..1}

# Checking if neovim or vim is installed and offer user if they want to make as default editor
# Function to modify the ENVariables.conf file
update_editor() {
  local editor=$1
  sed -i "s/#env = EDITOR,.*/env = EDITOR,$editor #default editor/" config/hypr/UserConfigs/01-UserDefaults.conf
  echo "${OK} Default editor set to ${MAGENTA}$editor${RESET}." 2>&1 | tee -a "$LOG"
}

EDITOR_SET=0
# Check for neovim if installed
if command -v nvim &>/dev/null; then
  printf "${INFO} ${MAGENTA}neovim${RESET} is detected as installed\n"
  echo -n "${CAT} Do you want to make ${MAGENTA}neovim${RESET} the default editor? (y/N): "
  read EDITOR_CHOICE
  if [[ "$EDITOR_CHOICE" == "y" || "$EDITOR_CHOICE" == "Y" ]]; then
    update_editor "nvim"
    EDITOR_SET=1
  fi
fi

printf "\n"

# Check for vim if installed, but only if neovim wasn't chosen
if [[ "$EDITOR_SET" -eq 0 ]] && command -v vim &>/dev/null; then
  printf "${INFO} ${MAGENTA}vim${RESET} is detected as installed\n"
  echo -n "${CAT} Do you want to make ${MAGENTA}vim${RESET} the default editor? (y/N): "
  read EDITOR_CHOICE
  if [[ "$EDITOR_CHOICE" == "y" || "$EDITOR_CHOICE" == "Y" ]]; then
    update_editor "vim"
    EDITOR_SET=1
  fi
fi

printf "\n"

# Action to do for better appearance
while true; do
  echo "${NOTE} ${SKY_BLUE} By default, KooL's Dots are configured for 1440p or 2k."
  echo "${WARN} If you dont select proper resolution, Hyprlock will look FUNKY!"
  echo "${INFO} If you are not sure what is your resolution, choose 1 here!"
  echo "${MAGENTA}Select monitor resolution to properly configure appearance and fonts:"
  echo "$YELLOW  -- Enter 1. for monitor resolution less than 1440p (< 1440p)"
  echo "$YELLOW  -- Enter 2. for monitor resolution equal to or higher than 1440p (≥ 1440p)"

  echo -n "$CAT Enter the number of your choice (1 or 2): "
  read res_choice

  case $res_choice in
  1)
    resolution="< 1440p"
    break
    ;;
  2)
    resolution="≥ 1440p"
    break
    ;;
  *)
    echo "${ERROR} Invalid choice. Please enter 1 for < 1440p or 2 for ≥ 1440p."
    ;;
  esac
done

# Use the selected resolution in your existing script
echo "${OK} You have chosen $resolution resolution." 2>&1 | tee -a "$LOG"

# actions if < 1440p is chosen
if [ "$resolution" == "< 1440p" ]; then
  # kitty font size
  sed -i 's/font_size 16.0/font_size 14.0/' config/kitty/kitty.conf

  # hyprlock matters
  if [ -f config/hypr/hyprlock.conf ]; then
    mv config/hypr/hyprlock.conf config/hypr/hyprlock-2k.conf
  fi
  if [ -f config/hypr/hyprlock-1080p.conf ]; then
    mv config/hypr/hyprlock-1080p.conf config/hypr/hyprlock.conf
  fi

  # rofi fonts reduction
  rofi_config_file="config/rofi/0-shared-fonts.rasi"
  if [ -f "$rofi_config_file" ]; then
    sed -i '/element-text {/,/}/s/[[:space:]]*font: "JetBrainsMono Nerd Font SemiBold 13"/font: "JetBrainsMono Nerd Font SemiBold 11"/' "$rofi_config_file" 2>&1 | tee -a "$LOG"
    sed -i '/configuration {/,/}/s/[[:space:]]*font: "JetBrainsMono Nerd Font SemiBold 15"/font: "JetBrainsMono Nerd Font SemiBold 13"/' "$rofi_config_file" 2>&1 | tee -a "$LOG"
  fi
fi

printf "\n%.0s" {1..1}

# Ask whether to change to 12hr format
while true; do
  echo -e "${NOTE} ${SKY_BLUE} By default, KooL's Dots are configured in 24H clock format."
  echo -n "$CAT Do you want to change to 12H (AM/PM) clock format? (y/n): "
  read answer

  # Convert the answer to lowercase for comparison
  answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

  # Check if the answer is valid
  if [[ "$answer" == "y" ]]; then
    # Modify waybar clock modules if 12hr is selected
    # Clock 1
    sed -i 's#^\(\s*\)//\("format": " {:%I:%M %p}",\) #\1\2 #g' config/waybar/Modules 2>&1 | tee -a "$LOG"
    sed -i 's#^\(\s*\)\("format": " {:%H:%M:%S}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$LOG"

    # Clock 2
    sed -i 's#^\(\s*\)\("format": "  {:%H:%M}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$LOG"

    # Clock 3
    sed -i 's#^\(\s*\)//\("format": "{:%I:%M %p - %d/%b}",\) #\1\2#g' config/waybar/Modules 2>&1 | tee -a "$LOG"
    sed -i 's#^\(\s*\)\("format": "{:%H:%M - %d/%b}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$LOG"

    # Clock 4
    sed -i 's#^\(\s*\)//\("format": "{:%B | %a %d, %Y | %I:%M %p}",\) #\1\2#g' config/waybar/Modules 2>&1 | tee -a "$LOG"
    sed -i 's#^\(\s*\)\("format": "{:%B | %a %d, %Y | %H:%M}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$LOG"

    # Clock 5
    sed -i 's#^\(\s*\)//\("format": "{:%A, %I:%M %P}",\) #\1\2#g' config/waybar/Modules 2>&1 | tee -a "$LOG"
    sed -i 's#^\(\s*\)\("format": "{:%a %d | %H:%M}",\) #\1//\2#g' config/waybar/Modules 2>&1 | tee -a "$LOG"

    # for hyprlock
    HYPRLOCK_FILE="config/hypr/hyprlock.conf"
    if [ ! -f "$HYPRLOCK_FILE" ] && [ -f "config/hypr/hyprlock-1080p.conf" ]; then
      HYPRLOCK_FILE="config/hypr/hyprlock-1080p.conf"
    fi
    if [ -f "$HYPRLOCK_FILE" ]; then
      sed -i 's/^\s*text = cmd\[update:1000\] echo "\$(date +"%H")"/# &/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$LOG"
      sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo "\$(date +"%I")" #AM\/PM/\1    text = cmd\[update:1000\] echo "\$(date +"%I")" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$LOG"

      sed -i 's/^\s*text = cmd\[update:1000\] echo "\$(date +"%S")"/# &/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$LOG"
      sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo "\$(date +"%S %p")" #AM\/PM/\1    text = cmd\[update:1000\] echo "\$(date +"%S %p")" #AM\/PM/' "$HYPRLOCK_FILE" 2>&1 | tee -a "$LOG"
    else
      echo "${WARN} hyprlock template not found; skipping 12H lock format edits" 2>&1 | tee -a "$LOG"
    fi

    echo "${OK} 12H format set on waybar clocks succesfully." 2>&1 | tee -a "$LOG"

    # Function to apply 12H format to SDDM themes
    apply_sddm_12h_format() {
      local sddm_directory=$1

      # Check if the directory exists
      if [ -d "$sddm_directory" ]; then
        echo "Editing ${SKY_BLUE}$sddm_directory${RESET} to 12H format" 2>&1 | tee -a "$LOG"

        sudo sed -i 's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$LOG" || true
        sudo sed -i 's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|' "$sddm_directory/theme.conf" 2>&1 | tee -a "$LOG" || true
      fi
    }

    # Applying to different SDDM themes
    apply_sddm_12h_format "/usr/share/sddm/themes/simple-sddm"
    apply_sddm_12h_format "/usr/share/sddm/themes/simple_sddm_2"

    # For SDDM (sequoia_2)
    sddm_directory_3="/usr/share/sddm/themes/sequoia_2"
    if [ -d "$sddm_directory_3" ]; then
      echo "${YELLOW}sddm sequoia_2${RESET} theme exists. Editing to 12H format" 2>&1 | tee -a "$LOG"

      # Comment out the existing clockFormat="HH:mm" line
      sudo sed -i 's|^clockFormat="HH:mm"|## clockFormat="HH:mm"|' "$sddm_directory_3/theme.conf" 2>&1 | tee -a "$LOG" || true

      # Insert the new clockFormat="hh:mm AP" line if it's not already present
      if ! grep -q 'clockFormat="hh:mm AP"' "$sddm_directory_3/theme.conf"; then
        sudo sed -i '/^clockFormat=/a clockFormat="hh:mm AP"' "$sddm_directory_3/theme.conf" 2>&1 | tee -a "$LOG" || true
      fi

      echo "${OK} 12H format set to SDDM successfully." 2>&1 | tee -a "$LOG"
    fi

    break

  elif [[ "$answer" == "n" ]]; then
    echo "${NOTE} You chose not to change to 12H format." 2>&1 | tee -a "$LOG"
    break # Exit the loop if the user chooses "n"
  else
    echo "${ERROR} Invalid choice. Please enter y for yes or n for no."
  fi
done
printf "\n%.0s" {1..1}

# Check if the user wants to disable Rainbow borders
echo "${NOTE} ${SKY_BLUE}By default, Rainbow Borders animation is enabled"
echo "${WARN} However, this uses a bit more CPU and Memory resources."

# Ask whether to disable Rainbow Borders animation
echo -n "${CAT} Do you want to disable Rainbow Borders animation? (y/N): "
read border_choice

# Check user's choice
if [[ "$border_choice" =~ ^[Yy]$ ]]; then
  # Disable Rainbow Borders
  mv config/hypr/UserScripts/RainbowBorders.sh config/hypr/UserScripts/RainbowBorders.bak.sh

  # Comment out the exec-once and animation lines
  sed -i '/exec-once = \$UserScripts\/RainbowBorders.sh/s/^/#/' config/hypr/configs/Startup_Apps.conf
  sed -i '/^[[:space:]]*animation = borderangle, 1, 180, liner, loop/s/^/#/' config/hypr/configs/UserAnimations.conf

  echo "${OK} Rainbow borders are now disabled." 2>&1 | tee -a "$LOG"
else
  echo "${NOTE} No changes made. Rainbow borders remain enabled." 2>&1 | tee -a "$LOG"
fi
printf "\n%.0s" {1..1}

set -e

# Function to create a unique backup directory name with month, day, hours, and minutes
get_backup_dirname() {
  local timestamp
  timestamp=$(date +"%m%d_%H%M")
  echo "back-up_${timestamp}"
}

# Check if the ~/.config/ directory exists
if [ ! -d "$HOME/.config" ]; then
  echo "${ERROR} - $HOME/.config directory does not exist. Creating it now."
  mkdir -p "$HOME/.config" && echo "Directory created successfully." || echo "Failed to create directory."
fi

printf "${INFO} - copying dotfiles ${SKY_BLUE}first${RESET} part\n"
# Config directories which will ask the user whether to replace or not
DIRS="fastfetch kitty rofi swaync"

for DIR2 in $DIRS; do
  DIRPATH="$HOME/.config/$DIR2"

  if [ -d "$DIRPATH" ]; then
    while true; do
      printf "\n${INFO} Found ${YELLOW}$DIR2${RESET} config found in ~/.config/\n"
      echo -n "${CAT} Do you want to replace ${YELLOW}$DIR2${RESET} config? (y/n): "
      read DIR1_CHOICE

      case "$DIR1_CHOICE" in
      [Yy]*)
        BACKUP_DIR=$(get_backup_dirname)
        # Backup the existing directory
        mv "$DIRPATH" "$DIRPATH-backup-$BACKUP_DIR" 2>&1 | tee -a "$LOG"
        echo -e "${NOTE} - Backed up $DIR2 to $DIRPATH-backup-$BACKUP_DIR." 2>&1 | tee -a "$LOG"

        # Copy the new config
        cp -r "config/$DIR2" "$HOME/.config/$DIR2" 2>&1 | tee -a "$LOG"
        echo -e "${OK} - Replaced $DIR2 with new configuration." 2>&1 | tee -a "$LOG"

        # Restoring rofi themes directory unique themes
        if [ "$DIR2" = "rofi" ]; then
          if [ -d "$DIRPATH-backup-$BACKUP_DIR/themes" ]; then
            for file in "$DIRPATH-backup-$BACKUP_DIR/themes"/*; do
              [ -e "$file" ] || continue # Skip if no files are found
              echo "Copying $file to $HOME/.config/rofi/themes/" >>"$LOG"
              cp -n "$file" "$HOME/.config/rofi/themes/" >>"$LOG" 2>&1
            done || true
          fi

          # restoring global 0-shared-fonts.rasi
          if [ -f "$DIRPATH-backup-$BACKUP_DIR/0-shared-fonts.rasi" ]; then
            echo "Restoring $DIRPATH-backup-$BACKUP_DIR/0-shared-fonts.rasi to $HOME/.config/rofi/" >>"$LOG"
            cp "$DIRPATH-backup-$BACKUP_DIR/0-shared-fonts.rasi" "$HOME/.config/rofi/0-shared-fonts.rasi" >>"$LOG" 2>&1
          fi

        fi

        break
        ;;
      [Nn]*)
        echo -e "${NOTE} - Skipping ${YELLOW}$DIR2${RESET}" 2>&1 | tee -a "$LOG"
        break
        ;;
      *)
        echo -e "${WARN} - Invalid choice. Please enter Y or N."
        ;;
      esac
    done
  else
    # Copy new config if directory does not exist
    cp -r "config/$DIR2" "$HOME/.config/$DIR2" 2>&1 | tee -a "$LOG"
    echo -e "${OK} - Copy completed for ${YELLOW}$DIR2${RESET}" 2>&1 | tee -a "$LOG"
  fi
done

printf "\n%.0s" {1..1}

# for waybar special part since it contains symlink
DIRW="waybar"
DIRPATHw="$HOME/.config/$DIRW"
if [ -d "$DIRPATHw" ]; then
  while true; do
    echo -n "${CAT} Do you want to replace ${YELLOW}$DIRW${RESET} config? (y/n): "
    read DIR1_CHOICE

    case "$DIR1_CHOICE" in
    [Yy]*)
      BACKUP_DIR=$(get_backup_dirname)
      cp -r "$DIRPATHw" "$DIRPATHw-backup-$BACKUP_DIR" 2>&1 | tee -a "$LOG"
      echo -e "${NOTE} - Backed up $DIRW to $DIRPATHw-backup-$BACKUP_DIR." 2>&1 | tee -a "$LOG"

      # Remove the old $DIRPATHw and copy the new one
      rm -rf "$DIRPATHw" && cp -r "config/$DIRW" "$DIRPATHw" 2>&1 | tee -a "$LOG"

      # Step 1: Handle waybar symlinks
      for file in "config" "style.css"; do
        symlink="$DIRPATHw-backup-$BACKUP_DIR/$file"
        target_file="$DIRPATHw/$file"

        if [ -L "$symlink" ]; then
          symlink_target=$(readlink "$symlink")
          if [ -f "$symlink_target" ]; then
            rm -f "$target_file" && cp -f "$symlink_target" "$target_file"
            echo -e "${NOTE} - Copied $file as a regular file."
          else
            echo -e "${WARN} - Symlink target for $file does not exist."
          fi
        fi
      done

      # Step 2: Copy non-existing directories and files under waybar/configs
      for dir in "$DIRPATHw-backup-$BACKUP_DIR/configs"/*; do
        [ -e "$dir" ] || continue # Skip if no files are found
        if [ -d "$dir" ]; then
          target_dir="$HOME/.config/waybar/configs/$(basename "$dir")"
          if [ ! -d "$target_dir" ]; then
            echo "Copying directory $dir to $HOME/.config/waybar/configs/" >>"$LOG"
            cp -r "$dir" "$HOME/.config/waybar/configs/"
          else
            echo "Directory $target_dir already exists. Skipping." >>"$LOG"
          fi
        fi
      done

      for file in "$DIRPATHw-backup-$BACKUP_DIR/configs"/*; do
        [ -e "$file" ] || continue
        target_file="$HOME/.config/waybar/configs/$(basename "$file")"
        if [ ! -e "$target_file" ]; then
          echo "Copying $file to $HOME/.config/waybar/configs/" >>"$LOG"
          cp "$file" "$HOME/.config/waybar/configs/"
        else
          echo "File $target_file already exists. Skipping." >>"$LOG"
        fi
      done || true

      # Step 3: Copy unique files in waybar/style
      for file in "$DIRPATHw-backup-$BACKUP_DIR/style"/*; do
        [ -e "$file" ] || continue

        if [ -d "$file" ]; then
          target_dir="$HOME/.config/waybar/style/$(basename "$file")"
          if [ ! -d "$target_dir" ]; then
            echo "Copying directory $file to $HOME/.config/waybar/style/" >>"$LOG"
            cp -r "$file" "$HOME/.config/waybar/style/"
          else
            echo "Directory $target_dir already exists. Skipping." >>"$LOG"
          fi
        else
          target_file="$HOME/.config/waybar/style/$(basename "$file")"
          if [ ! -e "$target_file" ]; then
            echo "Copying file $file to $HOME/.config/waybar/style/" >>"$LOG"
            cp "$file" "$HOME/.config/waybar/style/"
          else
            echo "File $target_file already exists. Skipping." >>"$LOG"
          fi
        fi
      done || true

      # Step 4: restore Modules_Extras
      BACKUP_FILEw="$DIRPATHw-backup-$BACKUP_DIR/UserModules"
      if [ -f "$BACKUP_FILEw" ]; then
        cp -f "$BACKUP_FILEw" "$DIRPATHw/UserModules"
      fi

      break
      ;;
    [Nn]*)
      echo -e "${NOTE} - Skipping ${YELLOW}$DIRW${RESET} config replacement." 2>&1 | tee -a "$LOG"
      break
      ;;
    *)
      echo -e "${WARN} - Invalid choice. Please enter Y or N."
      ;;
    esac
  done
else
  cp -r "config/$DIRW" "$DIRPATHw" 2>&1 | tee -a "$LOG"
  echo -e "${OK} - Copy completed for ${YELLOW}$DIRW${RESET}" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..1}

printf "${INFO} - Copying dotfiles ${SKY_BLUE}second${RESET} part\n"

# Check if the config directory exists
if [ ! -d "config" ]; then
  echo "${ERROR} - The 'config' directory does not exist."
  exit 1
fi

DIR="btop cava hypr Kvantum qt5ct qt6ct swappy wallust wlogout"

for DIR_NAME in $DIR; do
  DIRPATH="$HOME/.config/$DIR_NAME"

  # Backup the existing directory if it exists
  if [ -d "$DIRPATH" ]; then
    echo -e "\n${NOTE} - Config for ${YELLOW}$DIR_NAME${RESET} found, attempting to back up."
    BACKUP_DIR=$(get_backup_dirname)

    # Backup the existing directory
    mv "$DIRPATH" "$DIRPATH-backup-$BACKUP_DIR" 2>&1 | tee -a "$LOG"
    if [ $? -eq 0 ]; then
      echo -e "${NOTE} - Backed up $DIR_NAME to $DIRPATH-backup-$BACKUP_DIR."
    else
      echo "${ERROR} - Failed to back up $DIR_NAME."
      exit 1
    fi
  fi

  # Copy the new config
  if [ -d "config/$DIR_NAME" ]; then
    cp -r "config/$DIR_NAME/" "$HOME/.config/$DIR_NAME" 2>&1 | tee -a "$LOG"
    if [ $? -eq 0 ]; then
      echo "${OK} - Copy of config for ${YELLOW}$DIR_NAME${RESET} completed!"
    else
      echo "${ERROR} - Failed to copy $DIR_NAME."
      exit 1
    fi
  else
    echo "${ERROR} - Directory config/$DIR_NAME does not exist to copy."
  fi
done

printf "\n%.0s" {1..1}

# ags config
# Check if ags is installed
if command -v ags >/dev/null 2>&1; then
  echo -e "${NOTE} - ${YELLOW}ags${RESET} is detected as installed"

  DIRPATH_AGS="$HOME/.config/ags"

  if [ ! -d "$DIRPATH_AGS" ]; then
    echo "${INFO} - ags config not found, copying new config."
    if [ -d "config/ags" ]; then
      cp -r "config/ags/" "$DIRPATH_AGS" 2>&1 | tee -a "$LOG"
    fi
  else
    read -p "${CAT} Do you want to overwrite your existing ${YELLOW}ags${RESET} config? [y/N] " answer_ags
    case "$answer_ags" in
    [Yy]*)
      BACKUP_DIR=$(get_backup_dirname)
      mv "$DIRPATH_AGS" "$DIRPATH_AGS-backup-$BACKUP_DIR" 2>&1 | tee -a "$LOG"
      echo -e "${NOTE} - Backed up ags config to $DIRPATH_AGS-backup-$BACKUP_DIR"

      if cp -r "config/ags/" "$DIRPATH_AGS" 2>&1 | tee -a "$LOG"; then
        echo "${OK} - ${YELLOW}ags configs${RESET} overwritten successfully."
      else
        echo "${ERROR} - Failed to copy ${YELLOW}ags${RESET} config."
        exit 1
      fi
      ;;
    *)
      echo "${NOTE} - Skipping overwrite of ags config."
      ;;
    esac
  fi
fi

printf "\n%.0s" {1..1}

# quickshell (ags alternative)
# Check if quickshell is installed
if command -v qs >/dev/null 2>&1; then
  echo -e "${NOTE} - ${YELLOW}quickshell${RESET} is detected as installed"

  DIRPATH_QS="$HOME/.config/quickshell"

  if [ ! -d "$DIRPATH_QS" ]; then
    echo "${INFO} - quickshell config not found, copying new config."
    if [ -d "config/quickshell" ]; then
      cp -r "config/quickshell/" "$DIRPATH_QS" 2>&1 | tee -a "$LOG"
    fi
  else
    # If default shell.qml exists, it blocks named config subdirectory detection
    # Remove it to enable the overview config to be found
    if [ -f "$DIRPATH_QS/shell.qml" ]; then
      echo "${NOTE} - Removing default shell.qml to enable quickshell overview config detection" 2>&1 | tee -a "$LOG"
      rm "$DIRPATH_QS/shell.qml"
    fi
    
    read -p "${CAT} Do you want to overwrite your existing ${YELLOW}quickshell${RESET} config? [y/N] " answer_qs
    case "$answer_qs" in
    [Yy]*)
      BACKUP_DIR=$(get_backup_dirname)
      mv "$DIRPATH_QS" "$DIRPATH_QS-backup-$BACKUP_DIR" 2>&1 | tee -a "$LOG"
      echo -e "${NOTE} - Backed up quickshell to $DIRPATH_QS-backup-$BACKUP_DIR"

      cp -r "config/quickshell/" "$DIRPATH_QS" 2>&1 | tee -a "$LOG"
      if [ $? -eq 0 ]; then
        echo "${OK} - ${YELLOW}quickshell${RESET} overwritten successfully."
        # Remove default shell.qml from new copy to enable overview detection
        rm -f "$DIRPATH_QS/shell.qml" 2>&1 | tee -a "$LOG"
      else
        echo "${ERROR} - Failed to copy ${YELLOW}quickshell${RESET} config."
        exit 1
      fi
      ;;
    *)
      echo "${NOTE} - Skipping overwrite of quickshell config."
      ;;
    esac
  fi
  
  # Ensure overview subdirectory exists and is up to date
  DIRPATH_OVERVIEW="$DIRPATH_QS/overview"
  if [ ! -d "$DIRPATH_OVERVIEW" ] && [ -d "config/quickshell/overview" ]; then
    echo "${INFO} - Copying quickshell overview config..." 2>&1 | tee -a "$LOG"
    cp -r "config/quickshell/overview" "$DIRPATH_QS/" 2>&1 | tee -a "$LOG"
    echo "${OK} - Quickshell overview config copied successfully" 2>&1 | tee -a "$LOG"
  fi
  
  # Check for old quickshell startup commands and update them
  HYPR_STARTUP="$HOME/.config/hypr/configs/Startup_Apps.conf"
  if [ -f "$HYPR_STARTUP" ]; then
    if grep -q '^exec-once = qs\s*$\|^exec-once = qs &' "$HYPR_STARTUP"; then
      echo "${NOTE} - Found old Quickshell startup command, updating to new overview config..." 2>&1 | tee -a "$LOG"
      # Replace old 'qs' or 'qs &' with new 'qs -c overview'
      sed -i 's/^\(\s*\)exec-once = qs\s*$/\1exec-once = qs -c overview  # Quickshell Overview/' "$HYPR_STARTUP" 2>&1 | tee -a "$LOG"
      sed -i 's/^\(\s*\)exec-once = qs &$/\1exec-once = qs -c overview  # Quickshell Overview/' "$HYPR_STARTUP" 2>&1 | tee -a "$LOG"
      echo "${OK} - Updated Quickshell startup command to use overview config" 2>&1 | tee -a "$LOG"
    fi
  fi
fi
printf "\n%.0s" {1..1}

# Restore automatically Animations and Monitor-Profiles
# including monitors.conf and workspaces.conf
HYPR_DIR="$HOME/.config/hypr"
BACKUP_DIR=$(get_backup_dirname)
BACKUP_HYPR_PATH="$HYPR_DIR-backup-$BACKUP_DIR"

if [ -d "$BACKUP_HYPR_PATH" ]; then
  echo -e "\n${NOTE} Restoring ${SKY_BLUE}Animations & Monitor Profiles${RESET} directories into ${YELLOW}$HYPR_DIR${RESET}..."

  DIR_B=("Monitor_Profiles" "animations" "wallpaper_effects")
  # Restore directories automatically
  for DIR_RESTORE in "${DIR_B[@]}"; do
    BACKUP_SUBDIR="$BACKUP_HYPR_PATH/$DIR_RESTORE"
    if [ -d "$BACKUP_SUBDIR" ]; then
      cp -r "$BACKUP_SUBDIR" "$HYPR_DIR/"
      echo "${OK} - Restored directory: ${MAGENTA}$DIR_RESTORE${RESET}" 2>&1 | tee -a "$LOG"
    fi
  done

  # Restore files automatically
  FILE_B=("monitors.conf" "workspaces.conf")
  for FILE_RESTORE in "${FILE_B[@]}"; do
    BACKUP_FILE="$BACKUP_HYPR_PATH/$FILE_RESTORE"

    if [ -f "$BACKUP_FILE" ]; then
      cp "$BACKUP_FILE" "$HYPR_DIR/$FILE_RESTORE"
      echo "${OK} - Restored file: ${MAGENTA}$FILE_RESTORE${RESET}" 2>&1 | tee -a "$LOG"
    fi
  done
fi

printf "\n%.0s" {1..1}

# Restoring UserConfigs and UserScripts
# Helper to extract overlay (additions) and optional disables from a previous user file compared to vendor base
compose_overlay_from_backup() {
  local type="$1" # startup|windowrules
  local base_file="$2"
  local old_user_file="$3"
  local new_user_file="$4"
  local disable_file="$5"

  mkdir -p "$(dirname "$new_user_file")"
  : >"$new_user_file"
  : >"$disable_file"

  if [ "$type" = "startup" ]; then
    # additions: exec-once lines present in old user but not in base
    grep -E '^\s*exec-once\s*=' "$old_user_file" | sed -E 's/^\s+//;s/\s+$//' | sort -u >"$old_user_file.tmp.exec"
    grep -E '^\s*exec-once\s*=' "$base_file" | sed -E 's/^\s+//;s/\s+$//' | sort -u >"$base_file.tmp.exec"
    comm -23 "$old_user_file.tmp.exec" "$base_file.tmp.exec" >"$new_user_file"
    # treat commented exec-once in old user as disables
    grep -E '^\s*#\s*exec-once\s*=' "$old_user_file" |
      sed -E 's/^\s*#\s*exec-once\s*=\s*//' |
      sed -E 's/^\s+//;s/\s+$//' |
      grep -Ev '^\$scriptsDir/KeybindsLayoutInit\.sh$' |
      sort -u >"$disable_file"
    rm -f "$old_user_file.tmp.exec" "$base_file.tmp.exec"
  elif [ "$type" = "windowrules" ]; then
    # additions
    grep -E '^(windowrule|layerrule)\s*=' "$old_user_file" | sed -E 's/^\s+//;s/\s+$//' | sort -u >"$old_user_file.tmp.rules"
    grep -E '^(windowrule|layerrule)\s*=' "$base_file" | sed -E 's/^\s+//;s/\s+$//' | sort -u >"$base_file.tmp.rules"
    comm -23 "$old_user_file.tmp.rules" "$base_file.tmp.rules" >"$new_user_file"
    # disables: lines commented in old user
    grep -E '^\s*#\s*(windowrule|layerrule)\s*=' "$old_user_file" | sed -E 's/^\s*#\s*//' | sed -E 's/^\s+//;s/\s+$//' | sort -u >"$disable_file"
    rm -f "$old_user_file.tmp.rules" "$base_file.tmp.rules"
  fi
}

# Function to compare versions
version_gte() {
  # Returns 0 if $1 >= $2, 1 otherwise
  [ "$1" = "$(echo -e "$1\n$2" | sort -V | tail -n1)" ]
}

DIRH="hypr"
DIRPATH="$HOME/.config/$DIRH"
BACKUP_DIR=$(get_backup_dirname)
BACKUP_DIR_PATH="$DIRPATH-backup-$BACKUP_DIR/UserConfigs"

if [ -z "$BACKUP_DIR" ]; then
  echo "${ERROR} - Backup directory name is empty. Exiting."
  exit 1
fi

if [ -d "$BACKUP_DIR_PATH" ]; then
  # Detect version
  VERSION_FILE=$(find "$DIRPATH" -maxdepth 1 -name "v*.*.*" | head -n 1)
  CURRENT_VERSION="999.9.9"
  if [ -n "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(basename "$VERSION_FILE" | sed 's/^v//')
  fi

  TARGET_VERSION="2.3.19"

  echo -e "${NOTE} Restoring previous ${MAGENTA}User-Configs${RESET}... "
  print_color $WARNING "
    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
            NOTES for RESTORING PREVIOUS CONFIGS
    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    The 'UserConfigs' directory is for all your personal settings.
    Files in this directory will override the default configurations,
    so your customizations are not lost when you update.
    "

  if version_gte "$CURRENT_VERSION" "$TARGET_VERSION"; then
    # NEW BEHAVIOR (>= 2.3.19) - Bulk Restore
    echo -n "${CAT} Do you want to restore your previous UserConfigs directory? (Y/n): "
    read -r restore_userconfigs_dir

    if [[ "$restore_userconfigs_dir" != [Nn]* ]]; then
      echo "${NOTE} Restoring UserConfigs directory..." 2>&1 | tee -a "$LOG"
      # Use rsync to copy contents, overwriting existing files.
      rsync -a "$BACKUP_DIR_PATH/" "$DIRPATH/UserConfigs/" 2>&1 | tee -a "$LOG"
      echo "${OK} - UserConfigs directory restored." 2>&1 | tee -a "$LOG"
    else
      echo "${NOTE} - Skipped restoring UserConfigs." 2>&1 | tee -a "$LOG"
    fi

  else
    # OLD BEHAVIOR (<= 2.3.18) - Selective Restore
    echo -e "${NOTE} Detected version ${YELLOW}v$CURRENT_VERSION${RESET} (older than v$TARGET_VERSION). Using legacy restoration mode."

    FILES_TO_RESTORE=(
      "01-UserDefaults.conf"
      "ENVariables.conf"
      "LaptopDisplay.conf"
      "Laptops.conf"
      "Startup_Apps.conf"
      "UserDecorations.conf"
      "UserAnimations.conf"
      "UserKeybinds.conf"
      "UserSettings.conf"
      "WindowRules.conf"
    )

    for FILE_NAME in "${FILES_TO_RESTORE[@]}"; do
      BACKUP_FILE="$BACKUP_DIR_PATH/$FILE_NAME"
      if [ -f "$BACKUP_FILE" ]; then
        # Special handling for Startup_Apps.conf and WindowRules.conf
        if [ "$FILE_NAME" = "Startup_Apps.conf" ]; then
          compose_overlay_from_backup "startup" "$DIRPATH/configs/Startup_Apps.conf" "$BACKUP_FILE" "$DIRPATH/UserConfigs/Startup_Apps.conf" "$DIRPATH/UserConfigs/Startup_Apps.disable"
          echo "${OK} - Migrated overlay for ${YELLOW}$FILE_NAME${RESET}" 2>&1 | tee -a "$LOG"
          continue
        fi
        if [ "$FILE_NAME" = "WindowRules.conf" ]; then
          compose_overlay_from_backup "windowrules" "$DIRPATH/configs/WindowRules.conf" "$BACKUP_FILE" "$DIRPATH/UserConfigs/WindowRules.conf" "$DIRPATH/UserConfigs/WindowRules.disable"
          echo "${OK} - Migrated overlay for ${YELLOW}$FILE_NAME${RESET}" 2>&1 | tee -a "$LOG"
          continue
        fi

        printf "\n${INFO} Found ${YELLOW}$FILE_NAME${RESET} in hypr backup...\n"
        echo -n "${CAT} Do you want to restore ${YELLOW}$FILE_NAME${RESET} from backup? (Y/n): "
        read file_restore

        if [[ "$file_restore" != [Nn]* ]]; then
          if cp "$BACKUP_FILE" "$DIRPATH/UserConfigs/$FILE_NAME"; then
            echo "${OK} - $FILE_NAME restored!" 2>&1 | tee -a "$LOG"
          else
            echo "${ERROR} - Failed to restore $FILE_NAME!" 2>&1 | tee -a "$LOG"
          fi
        else
          echo "${NOTE} - Skipped restoring $FILE_NAME." 2>&1 | tee -a "$LOG"
        fi
      fi
    done
  fi
fi

printf "\n%.0s" {1..1}

# Restoring previous UserScripts
DIRSH="hypr"
SCRIPTS_TO_RESTORE=(
  "RofiBeats.sh"
  "Weather.py"
  "Weather.sh"
)

DIRSHPATH="$HOME/.config/$DIRSH"
BACKUP_DIR_PATH_S="$DIRSHPATH-backup-$BACKUP_DIR/UserScripts"

if [ -d "$BACKUP_DIR_PATH_S" ]; then
  echo -e "${NOTE} Restoring previous ${MAGENTA}User-Scripts${RESET}..."

  for SCRIPT_NAME in "${SCRIPTS_TO_RESTORE[@]}"; do
    BACKUP_SCRIPT="$BACKUP_DIR_PATH_S/$SCRIPT_NAME"

    if [ -f "$BACKUP_SCRIPT" ]; then
      printf "\n${INFO} Found ${YELLOW}$SCRIPT_NAME${RESET} in hypr backup...\n"
      echo -n "${CAT} Do you want to restore ${YELLOW}$SCRIPT_NAME${RESET} from backup? (y/N): "
      read script_restore

      if [[ "$script_restore" == [Yy]* ]]; then
        if cp "$BACKUP_SCRIPT" "$DIRSHPATH/UserScripts/$SCRIPT_NAME"; then
          echo "${OK} - $SCRIPT_NAME restored!" 2>&1 | tee -a "$LOG"
        else
          echo "${ERROR} - Failed to restore $SCRIPT_NAME!" 2>&1 | tee -a "$LOG"
        fi
      else
        echo "${NOTE} - Skipped restoring $SCRIPT_NAME." 2>&1 | tee -a "$LOG"
      fi
    fi
  done
fi

printf "\n%.0s" {1..1}

# restoring some files in ~/.config/hypr
DIR_H="hypr"
FILES_2_RESTORE=(
  "hyprlock.conf"
  "hypridle.conf"
)

DIRPATH="$HOME/.config/$DIR_H"
BACKUP_DIR=$(get_backup_dirname)
BACKUP_DIR_PATH_F="$DIRPATH-backup-$BACKUP_DIR"

if [ -d "$BACKUP_DIR_PATH_F" ]; then
  echo -e "${NOTE} Restoring some files in ${MAGENTA}$HOME/.config/hypr directory${RESET}..."

  for FILE_RESTORE in "${FILES_2_RESTORE[@]}"; do
    BACKUP_FILE="$BACKUP_DIR_PATH_F/$FILE_RESTORE"

    if [ -f "$BACKUP_FILE" ]; then
      echo -e "\n${INFO} Found ${YELLOW}$FILE_RESTORE${RESET} in hypr backup..."
      echo -n "${CAT} Do you want to restore ${YELLOW}$FILE_RESTORE${RESET} from backup? (y/N): "
      read file2restore

      if [[ "$file2restore" == [Yy]* ]]; then
        if cp "$BACKUP_FILE" "$DIRPATH/$FILE_RESTORE"; then
          echo "${OK} - $FILE_RESTORE restored!" 2>&1 | tee -a "$LOG"
        else
          echo "${ERROR} - Failed to restore $FILE_RESTORE!" 2>&1 | tee -a "$LOG"
        fi
      else
        echo "${NOTE} - Skipped restoring $FILE_RESTORE." 2>&1 | tee -a "$LOG"
      fi
    else
      echo "${ERROR} - Backup file $BACKUP_FILE does not exist."
    fi
  done
fi

printf "\n%.0s" {1..1}

# Define the target directory for rofi themes
rofi_DIR="$HOME/.local/share/rofi/themes"

if [ ! -d "$rofi_DIR" ]; then
  mkdir -p "$rofi_DIR"
fi
if [ -d "$HOME/.config/rofi/themes" ]; then
  if [ -z "$(ls -A $HOME/.config/rofi/themes)" ]; then
    echo '/* Dummy Rofi theme */' >"$HOME/.config/rofi/themes/dummy.rasi"
  fi
  ln -snf "$HOME/.config/rofi/themes/"* "$HOME/.local/share/rofi/themes/"
  # Delete the dummy file if it was created
  if [ -f "$HOME/.config/rofi/themes/dummy.rasi" ]; then
    rm "$HOME/.config/rofi/themes/dummy.rasi"
  fi
fi

printf "\n%.0s" {1..1}

# wallpaper stuff
mkdir -p $HOME/Pictures/wallpapers
if cp -r wallpapers $HOME/Pictures/; then
  echo "${OK} Some ${MAGENTA}wallpapers${RESET} copied successfully!" | tee -a "$LOG"
else
  echo "${ERROR} Failed to copy some ${YELLOW}wallpapers${RESET}" | tee -a "$LOG"
fi

# Set some files as executable
chmod +x "$HOME/.config/hypr/scripts/"* 2>&1 | tee -a "$LOG"
chmod +x "$HOME/.config/hypr/UserScripts/"* 2>&1 | tee -a "$LOG"
# Set executable for initial-boot.sh
chmod +x "$HOME/.config/hypr/initial-boot.sh" 2>&1 | tee -a "$LOG"

# Waybar config to symlink & retain based on machine type
if hostnamectl | grep -q 'Chassis: desktop'; then
  config_file="$waybar_config"
  config_remove=" Laptop"
else
  config_file="$waybar_config_laptop"
  config_remove=""
fi

# Check if ~/.config/waybar/config does not exist or is a symlink
if [ ! -e "$HOME/.config/waybar/config" ] || [ -L "$HOME/.config/waybar/config" ]; then
  ln -sf "$config_file" "$HOME/.config/waybar/config" 2>&1 | tee -a "$LOG"
fi

# Remove inappropriate waybar configs
rm -rf "$HOME/.config/waybar/configs/[TOP] Default$config_remove" \
  "$HOME/.config/waybar/configs/[BOT] Default$config_remove" \
  "$HOME/.config/waybar/configs/[TOP] Default$config_remove (old v1)" \
  "$HOME/.config/waybar/configs/[TOP] Default$config_remove (old v2)" \
  "$HOME/.config/waybar/configs/[TOP] Default$config_remove (old v3)" \
  "$HOME/.config/waybar/configs/[TOP] Default$config_remove (old v4)" 2>&1 | tee -a "$LOG" || true

printf "\n%.0s" {1..1}

# for SDDM (simple_sddm_2)
sddm_simple_sddm_2="/usr/share/sddm/themes/simple_sddm_2"
if [ -d "$sddm_simple_sddm_2" ]; then
  while true; do
    echo -n "${CAT} SDDM simple_sddm_2 theme detected! Apply current wallpaper as SDDM background? (y/n): "
    read SDDM_WALL

    # Remove any leading/trailing whitespace or newlines from input
    SDDM_WALL=$(echo "$SDDM_WALL" | tr -d '\n' | tr -d ' ')

    case $SDDM_WALL in
    [Yy])
      # Copy the wallpaper, ignore errors if the file exists or fails
      sudo cp -r "config/hypr/wallpaper_effects/.wallpaper_current" "/usr/share/sddm/themes/simple_sddm_2/Backgrounds/default" || true
      echo "${NOTE} Current wallpaper applied as default SDDM background" 2>&1 | tee -a "$LOG"
      break
      ;;
    [Nn])
      echo "${NOTE} You chose not to apply the current wallpaper to SDDM." 2>&1 | tee -a "$LOG"
      break
      ;;
    *)
      echo "Please enter 'y' or 'n' to proceed."
      ;;
    esac
  done
fi

# additional wallpapers
printf "\n%.0s" {1..1}
echo "${MAGENTA}By default only a few wallpapers are copied${RESET}..."

while true; do
  echo "${NOTE} A number of these wallpapers are AI generated or enhanced. Select (N/n) if this is an issue for you. "
  echo -n "${CAT} Would you like to download additional wallpapers? ${WARN} This is 1GB in size (y/n): "
  read WALL

  case $WALL in
  [Yy])
    echo "${NOTE} Downloading additional wallpapers..."
    if git clone "https://github.com/JaKooLit/Wallpaper-Bank.git"; then
      echo "${OK} Wallpapers downloaded successfully." 2>&1 | tee -a "$LOG"

      # Check if wallpapers directory exists and create it if not
      if [ ! -d "$HOME/Pictures/wallpapers" ]; then
        mkdir -p "$HOME/Pictures/wallpapers"
        echo "${OK} Created wallpapers directory." 2>&1 | tee -a "$LOG"
      fi

      if cp -R Wallpaper-Bank/wallpapers/* "$HOME/Pictures/wallpapers/" >>"$LOG" 2>&1; then
        echo "${OK} Wallpapers copied successfully." 2>&1 | tee -a "$LOG"
        rm -rf Wallpaper-Bank 2>&1 # Remove cloned repository after copying wallpapers
        break
      else
        echo "${ERROR} Copying wallpapers failed" 2>&1 | tee -a "$LOG"
      fi
    else
      echo "${ERROR} Downloading additional wallpapers failed" 2>&1 | tee -a "$LOG"
    fi
    ;;
  [Nn])
    echo "${NOTE} You chose not to download additional wallpapers." 2>&1 | tee -a "$LOG"
    break
    ;;
  *)
    echo "Please enter 'y' or 'n' to proceed."
    ;;
  esac
done

# CLeaning up of ~/.config/ backups
cleanup_backups() {
  CONFIG_DIR="$HOME/.config"
  BACKUP_PREFIX="-backup"

  # Loop through directories in $HOME/.config
  for DIR in "$CONFIG_DIR"/*; do
    if [ -d "$DIR" ]; then
      BACKUP_DIRS=()

      # Check for backup directories
      for BACKUP in "$DIR"$BACKUP_PREFIX*; do
        if [ -d "$BACKUP" ]; then
          BACKUP_DIRS+=("$BACKUP")
        fi
      done

      # If more than one backup found
      if [ ${#BACKUP_DIRS[@]} -gt 1 ]; then
        printf "\n%.0s" {1..2}
        echo -e "${INFO} Found ${MAGENTA}multiple backups${RESET} for: ${YELLOW}${DIR##*/}${RESET}"
        echo "${YELLOW}Backups: ${RESET}"

        # List the backups
        for BACKUP in "${BACKUP_DIRS[@]}"; do
          echo "  - ${BACKUP##*/}"
        done

        echo -n "${CAT} Do you want to delete the older backups of ${YELLOW}${DIR##*/}${RESET} and keep the latest backup only? (y/N): "
        read back_choice

        if [[ "$back_choice" == [Yy]* ]]; then
          # Sort backups by modification time
          latest_backup="${BACKUP_DIRS[0]}"
          for BACKUP in "${BACKUP_DIRS[@]}"; do
            if [ "$BACKUP" -nt "$latest_backup" ]; then
              latest_backup="$BACKUP"
            fi
          done

          for BACKUP in "${BACKUP_DIRS[@]}"; do
            if [ "$BACKUP" != "$latest_backup" ]; then
              echo "Deleting: ${BACKUP##*/}"
              rm -rf "$BACKUP"
            fi
          done
          echo "Old backups of ${YELLOW}${DIR##*/}${RESET} deleted, keeping: ${MAGENTA}${latest_backup##*/}${RESET}"
        fi
      fi
    fi
  done
}
# Execute the cleanup function
cleanup_backups

# Check if ~/.config/waybar/style.css does not exist or is a symlink
if [ ! -e "$HOME/.config/waybar/style.css" ] || [ -L "$HOME/.config/waybar/style.css" ]; then
  ln -sf "$waybar_style" "$HOME/.config/waybar/style.css" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..1}

# initialize wallust to avoid config error on hyprland
wallust run -s $wallpaper 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}
printf "${OK} GREAT! KooL's Hyprland-Dots is now Loaded & Ready !!! "
printf "\n%.0s" {1..1}
printf "${INFO} However, it is ${MAGENTA}HIGHLY SUGGESTED${RESET} to logout and re-login or better reboot to avoid any issues"
printf "\n%.0s" {1..1}
printf "${SKY_BLUE}Thank you${RESET} for using ${MAGENTA}KooL's Hyprland Configuration${RESET}... ${YELLOW}ENJOY!!!${RESET}"
printf "\n%.0s" {1..3}
