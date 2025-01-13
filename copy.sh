#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #

clear
wallpaper=$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified
waybar_style="$HOME/.config/waybar/style/[Dark] Latte-Wallust combined.css"
waybar_config="$HOME/.config/waybar/configs/[TOP] Default_v4"
waybar_config_laptop="$HOME/.config/waybar/configs/[TOP] Default Laptop_v4" 

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be executed as root! Exiting......."
    exit 1
fi

printf "\n%.0s" {1..2}  
echo '  ╦╔═┌─┐┌─┐╦    ╦ ╦┬ ┬┌─┐┬─┐┬  ┌─┐┌┐┌┌┬┐  ╔╦╗┌─┐┌┬┐┌─┐ '
echo '  ╠╩╗│ ││ │║    ╠═╣└┬┘├─┘├┬┘│  ├─┤│││ ││───║║│ │ │ └─┐ '
echo '  ╩ ╩└─┘└─┘╩═╝  ╩ ╩ ┴ ┴  ┴└─┴─┘┴ ┴┘└┘─┴┘  ═╩╝└─┘ ┴ └─┘ '
printf "\n%.0s" {1..2} 
 
# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 5)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
ORANGE=$(tput setaf 166)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4) 
RESET=$(tput sgr0)

# Create Directory for Copy Logs
if [ ! -d Copy-Logs ]; then
    mkdir Copy-Logs
fi

# Function to print colorful text
print_color() {
    printf "%b%s%b\n" "$1" "$2" "$CLEAR"
}

# Set the name of the log file to include the current date and time
LOG="Copy-Logs/install-$(date +%d-%H%M%S)_dotfiles.log"

# update home folders
xdg-user-dirs-update 2>&1 | tee -a "$LOG" || true

# setting up for nvidia
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
  echo "Nvidia GPU detected. Setting up proper env's and configs" 2>&1 | tee -a "$LOG" || true
  sed -i '/env = LIBVA_DRIVER_NAME,nvidia/s/^#//' config/hypr/UserConfigs/ENVariables.conf
  sed -i '/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/s/^#//' config/hypr/UserConfigs/ENVariables.conf
  sed -i '/env = NVD_BACKEND,direct/s/^#//' config/hypr/UserConfigs/ENVariables.conf
  # enabling no hardware cursors if nvidia detected
  sed -i 's/^\([[:space:]]*no_hardware_cursors[[:space:]]*=[[:space:]]*\)2/\1true/' config/hypr/UserConfigs/UserSettings.conf  
  # disabling explicit sync for nvidia for now (Hyprland 0.42.0)
  #sed -i 's/  explicit_sync = 2/  explicit_sync = 0/' config/hypr/UserConfigs/UserSettings.conf
fi

# uncommenting WLR_RENDERER_ALLOW_SOFTWARE,1 if running in a VM is detected
if hostnamectl | grep -q 'Chassis: vm'; then
  echo "System is running in a virtual machine." 2>&1 | tee -a "$LOG" || true
  # enabling proper ENV's for Virtual Environment which should help
  sed -i 's/^\([[:space:]]*no_hardware_cursors[[:space:]]*=[[:space:]]*\)2/\1true/' config/hypr/UserConfigs/UserSettings.conf
  sed -i '/env = WLR_RENDERER_ALLOW_SOFTWARE,1/s/^#//' config/hypr/UserConfigs/ENVariables.conf
  #sed -i '/env = LIBGL_ALWAYS_SOFTWARE,1/s/^#//' config/hypr/UserConfigs/ENVariables.conf
  sed -i '/monitor = Virtual-1, 1920x1080@60,auto,1/s/^#//' config/hypr/UserConfigs/Monitors.conf
fi

# Proper Polkit for NixOS
if hostnamectl | grep -q 'Operating System: NixOS'; then
  echo "You Distro is NixOS. Setting up properly." 2>&1 | tee -a "$LOG" || true
  sed -i -E '/^#?exec-once = \$scriptsDir\/Polkit-NixOS\.sh/s/^#//' config/hypr/UserConfigs/Startup_Apps.conf
  sed -i '/^exec-once = \$scriptsDir\/Polkit\.sh$/ s/^#*/#/' config/hypr/UserConfigs/Startup_Apps.conf
fi

# Check if dpkg is installed (use to check if Debian or Ubuntu or based distros
if command -v dpkg &> /dev/null; then
	echo "Debian/Ubuntu based distro. Disabling pyprland" 2>&1 | tee -a "$LOG" || true
  # disabling pyprland as causing issues
  sed -i '/^exec-once = pypr &/ s/^/#/' config/hypr/UserConfigs/Startup_Apps.conf
fi

# activating hyprcursor on env by checking if the directory ~/.icons/Bibata-Modern-Ice/hyprcursors exists
if [ -d "$HOME/.icons/Bibata-Modern-Ice/hyprcursors" ]; then
    # Define the config file path
    HYPRCURSOR_ENV_FILE="config/hypr/UserConfigs/ENVariables.conf"

    sed -i 's/^#env = HYPRCURSOR_THEME,Bibata-Modern-Ice/env = HYPRCURSOR_THEME,Bibata-Modern-Ice/' "$HYPRCURSOR_ENV_FILE"
    sed -i 's/^#env = HYPRCURSOR_SIZE,24/env = HYPRCURSOR_SIZE,24/' "$HYPRCURSOR_ENV_FILE"
fi

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
    print_color $ORANGE "
█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
        STOP AND READ
█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    !!! IMPORTANT WARNING !!!

The Default Keyboard Layout could not be detected

You need to set it Manually

!!! WARNING !!!
Setting a wrong Keyboard Layout will cause Hyprland to crash

If you are not sure, just type us

NOTE:
•  You can also set more than 2 keyboard layouts
•  For example us, kr, gb, ru
"
    printf "\n%.0s" {1..1}
    read -p "${CAT} - Please enter the correct keyboard layout: " new_layout

    if [ -n "$new_layout" ]; then
        layout="$new_layout"
        break
    else
        echo "${CAT} Please enter a keyboard layout."
    fi
  done
fi

printf "${NOTE} Detecting keyboard layout to prepare proper Hyprland Settings\n\n"

# Prompt the user to confirm whether the detected layout is correct
while true; do
  printf "${INFO} Current keyboard layout is ${ORANGE}$layout${RESET}\n"
  read -p "${CAT} Is this correct? [y/n] " keyboard_layout

  case $keyboard_layout in
    [yY])
        # If the detected layout is correct, update the 'kb_layout =' line in the file
        awk -v layout="$layout" '/kb_layout/ {$0 = "  kb_layout = " layout} 1' config/hypr/UserConfigs/UserSettings.conf > temp.conf
        mv temp.conf config/hypr/UserConfigs/UserSettings.conf
        
        echo "${NOTE} kb_layout ${ORANGE}$layout${RESET} configured in settings." 2>&1 | tee -a "$LOG"
        break ;;
    [nN])
        printf "\n%.0s" {1..2}
        print_color $ORANGE "
█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
        STOP AND READ
█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█

    !!! IMPORTANT WARNING !!!

The Default Keyboard Layout could not be detected

You need to set it Manually

!!! WARNING !!!
Setting a wrong Keyboard Layout will cause Hyprland to crash

If you are not sure, just type us

NOTE:
•  You can also set more than 2 keyboard layouts
•  For example us, kr, gb, ru
"
        printf "\n%.0s" {1..1}
        
        read -p "${CAT} - Please enter the correct keyboard layout: " new_layout
        
        # Update the 'kb_layout =' line with the correct layout in the file
        awk -v new_layout="$new_layout" '/kb_layout/ {$0 = "  kb_layout = " new_layout} 1' config/hypr/UserConfigs/UserSettings.conf > temp.conf
        mv temp.conf config/hypr/UserConfigs/UserSettings.conf
        echo "${OK} kb_layout $new_layout configured in settings." 2>&1 | tee -a "$LOG" 
        break ;;
    *)
        echo "${ERROR} Please enter either 'y' or 'n'." ;;
  esac
done

printf "\n"

# Check if asusctl is installed and add rog-control-center on Startup
if command -v asusctl >/dev/null 2>&1; then
    sed -i '/exec-once = rog-control-center &/s/^#//' config/hypr/UserConfigs/Startup_Apps.conf
fi

# Check if blueman-applet is installed and add blueman-applet on Startup
if command -v blueman-applet >/dev/null 2>&1; then
    sed -i '/exec-once = blueman-applet &/s/^#//' config/hypr/UserConfigs/Startup_Apps.conf
fi

printf "\n"

# Checking if neovim or vim is installed and offer user if they want to make as default editor
# Function to modify the ENVariables.conf file
update_editor() {
    local editor=$1
    sed -i "s/#env = EDITOR,.*/env = EDITOR,$editor #default editor/" config/hypr/UserConfigs/ENVariables.conf
    echo "${OK} Default editor set to ${ORANGE}$editor${RESET}." 2>&1 | tee -a "$LOG"
}

EDITOR_SET=0
# Check for neovim if installed
if command -v nvim &> /dev/null; then
    printf "${INFO} ${ORANGE}neovim${RESET} is detected as installed\n"
    read -p "${CAT} Do you want to make ${ORANGE}neovim${RESET} the default editor? (y/N): " EDITOR_CHOICE
    if [[ "$EDITOR_CHOICE" == "y" ]]; then
        update_editor "nvim"
        EDITOR_SET=1
    fi
fi

printf "\n"

# Check for vim if installed, but only if neovim wasn't chosen
if [[ "$EDITOR_SET" -eq 0 ]] && command -v vim &> /dev/null; then
    printf "${INFO} ${ORANGE}vim${RESET} is detected as installed\n"
    read -p "${CAT} Do you want to make ${ORANGE}vim${RESET} the default editor? (y/N): " EDITOR_CHOICE
    if [[ "$EDITOR_CHOICE" == "y" ]]; then
        update_editor "vim"
        EDITOR_SET=1
    fi
fi

if [[ "$EDITOR_SET" -eq 0 ]]; then
    echo "${ORANGE} Neither neovim nor vim is installed or selected as default."
fi

printf "\n"

# Action to do for better rofi and kitty appearance
while true; do
  echo "$ORANGE Select monitor resolution to properly configure appearance and fonts:"
  echo "$YELLOW   -- Enter 1. for monitor res 1440p or less (< 1440p)"
  echo "$YELLOW   -- Enter 2. for monitors res higher than 1440p (≥ 1440p)"
  read -p "$CAT Enter the number of your choice (1 or 2): " res_choice

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

# Add your commands based on the resolution choice
if [ "$resolution" == "< 1440p" ]; then
  cp -r config/rofi/resolution/1080p/* config/rofi/
  sed -i 's/font_size 16.0/font_size 12.0/' config/kitty/kitty.conf

  # hyprlock matters
  mv config/hypr/hyprlock.conf config/hypr/hyprlock-2k.conf
  mv config/hypr/hyprlock-1080p.conf config/hypr/hyprlock.conf

elif [ "$resolution" == "≥ 1440p" ]; then
  cp -r config/rofi/resolution/1440p/* config/rofi/
fi

printf "\n"

# Ask whether to change to 12hr format
while true; do
  echo -e "$ORANGE By default, configs are in 24H format."
  read -p "$CAT Do you want to change to 12H format (AM/PM)? (y/n): " answer

  # Convert the answer to lowercase for comparison
  answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

# Check if the answer is valid
if [[ "$answer" == "y" ]]; then
    # Modify waybar config if 12hr is selected
    # Clock 1
    sed -i 's#^\(\s*\)//"format": " {:%I:%M %p}", // AM PM format#\1"format": " {:%I:%M %p}", // AM PM format#' config/waybar/Modules 2>&1 | tee -a "$LOG"
    sed -i 's#^\(\s*\) "format": " {:%H:%M:%S}", // 24H#\1// "format": " {:%H:%M:%S}", // 24H#' config/waybar/Modules 2>&1 | tee -a "$LOG"
    
    # Clock 2
    sed -i 's#^\(\s*\) "format": "  {:%H:%M}", // 24H#\1// "format": "  {:%H:%M}", // 24H#' config/waybar/Modules 2>&1 | tee -a "$LOG"
    
    # Clock 3
    sed -i 's#^\(\s*\)//"format": "{:%I:%M %p - %d/%b}", //for AM/PM#\1"format": "{:%I:%M %p - %d/%b}", //for AM/PM#' config/waybar/Modules 2>&1 | tee -a "$LOG"
    sed -i 's#^\(\s*\) "format": "{:%H:%M - %d/%b}", // 24H#\1// "format": "{:%H:%M - %d/%b}", // 24H#' config/waybar/Modules 2>&1 | tee -a "$LOG"
    
    # Clock 4
    sed -i 's#^\(\s*\)//"format": "{:%B | %a %d, %Y | %I:%M %p}", // AM PM format#\1"format": "{:%B | %a %d, %Y | %I:%M %p}", // AM PM format#' config/waybar/Modules 2>&1 | tee -a "$LOG"
    sed -i 's#^\(\s*\) "format": "{:%B | %a %d, %Y | %H:%M}", // 24H#\1// "format": "{:%B | %a %d, %Y | %H:%M}", // 24H#' config/waybar/Modules 2>&1 | tee -a "$LOG"

    # Clock 5
    sed -i 's#^\(\s*\)//"format": "{:%A, %I:%M %P}", // AM PM format#\1"format": "{:%A, %I:%M %P}", // AM PM format#' config/waybar/Modules 2>&1 | tee -a "$LOG"
    sed -i 's#^\(\s*\) "format": "{:%a %d | %H:%M}", // 24H#\1// "format": "{:%a %d | %H:%M}", // 24H#' config/waybar/Modules 2>&1 | tee -a "$LOG"
            
    # for hyprlock
    sed -i 's/^\s*text = cmd\[update:1000\] echo "\$(date +"%H")"/# &/' config/hypr/hyprlock.conf 2>&1 | tee -a "$LOG"
    sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo "\$(date +"%I")" #AM\/PM/\1    text = cmd\[update:1000\] echo "\$(date +"%I")" #AM\/PM/' config/hypr/hyprlock.conf 2>&1 | tee -a "$LOG"

    sed -i 's/^\s*text = cmd\[update:1000\] echo "\$(date +"%S")"/# &/' config/hypr/hyprlock.conf 2>&1 | tee -a "$LOG"
    sed -i 's/^\(\s*\)# *text = cmd\[update:1000\] echo "\$(date +"%S %p")" #AM\/PM/\1    text = cmd\[update:1000\] echo "\$(date +"%S %p")" #AM\/PM/' config/hypr/hyprlock.conf 2>&1 | tee -a "$LOG"

    # for SDDM (simple-sddm)
    sddm_folder="/usr/share/sddm/themes/simple-sddm"
    if [ -d "$sddm_folder" ]; then
      echo "Simple sddm exists. Editing to 12H format" 2>&1 | tee -a "$LOG"

      sudo sed -i 's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|' "$sddm_folder/theme.conf" 2>&1 | tee -a "$LOG" || true
      sudo sed -i 's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|' "$sddm_folder/theme.conf" 2>&1 | tee -a "$LOG" || true

      echo "${OK} 12H format set to SDDM theme successfully." 2>&1 | tee -a "$LOG"
    fi

        # for SDDM (simple-sddm-2)
    sddm_folder_2="/usr/share/sddm/themes/simple-sddm-2"
    if [ -d "$sddm_folder_2" ]; then
      echo "Simple sddm 2 exists. Editing to 12H format" 2>&1 | tee -a "$LOG"

      sudo sed -i 's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|' "$sddm_folder_2/theme.conf" 2>&1 | tee -a "$LOG" || true
      sudo sed -i 's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|' "$sddm_folder_2/theme.conf" 2>&1 | tee -a "$LOG" || true

      echo "${OK} 12H format set to SDDM theme successfully." 2>&1 | tee -a "$LOG"
    fi

    break
  elif [[ "$answer" == "n" ]]; then
    echo "${NOTE} You chose not to change to 12H format." 2>&1 | tee -a "$LOG"
    break
  else
    echo "${ERROR} Invalid choice. Please enter y for yes or n for no."
  fi
done

printf "\n"

# Check if the user wants to disable Rainbow borders
printf "${ORANGE} By default, Rainbow Borders animation is enabled.\n"
printf "${WARN} - However, this uses a bit more CPU and Memory resources.\n"

read -p "${CAT} Do you want to disable Rainbow Borders animation? (y/N): " border_choice
if [[ "$border_choice" =~ ^[Yy]$ ]]; then
    mv config/hypr/UserScripts/RainbowBorders.sh config/hypr/UserScripts/RainbowBorders.bak.sh
    
    sed -i '/exec-once = \$UserScripts\/RainbowBorders.sh \&/s/^/#/' config/hypr/UserConfigs/Startup_Apps.conf
    sed -i '/  animation = borderangle, 1, 180, liner, loop/s/^/#/' config/hypr/UserConfigs/UserDecorAnimations.conf
    
    echo "${OK} Rainbow borders is now disabled." 2>&1 | tee -a "$LOG"
else
    echo "${NOTE} No changes made. Rainbow borders remain enabled." 2>&1 | tee -a "$LOG"
fi
printf "\n"

set -e

# Function to create a unique backup directory name with month, day, hours, and minutes
get_backup_dirname() {
  local timestamp
  timestamp=$(date +"%m%d_%H%M")
  echo "back-up_${timestamp}"
}

# Check if the ~/.config/ directory exists
if [ ! -d "$HOME/.config" ]; then
  echo "${ERROR} - The ~/.config directory does not exist."
  exit 1
fi

printf "${INFO} - copying dotfiles ${BLUE}first${RESET} part\n"
# Config directories which will ask the user whether to replace or not
DIRS="
  ags 
  fastfetch 
  kitty 
  rofi 
  swaync 
  waybar
"
for DIR2 in $DIRS; do
  DIRPATH=~/.config/"$DIR2"
  
  if [ -d "$DIRPATH" ]; then
    while true; do
      read -p "${CAT} ${ORANGE}$DIR2${RESET} config found in ~/.config/ Do you want to replace ${ORANGE}$DIR2${RESET} config? (y/n): " DIR1_CHOICE
      case "$DIR1_CHOICE" in
        [Yy]* )
          BACKUP_DIR=$(get_backup_dirname)
          echo -e "${NOTE} - Config for ${YELLOW}$DIR2${RESET} found, attempting to back up."
          
          mv "$DIRPATH" "$DIRPATH-backup-$BACKUP_DIR" 2>&1 | tee -a "$LOG"
          if [ $? -eq 0 ]; then
            echo -e "${NOTE} - Backed up $DIR2 to $DIRPATH-backup-$BACKUP_DIR." 2>&1 | tee -a "$LOG"
            
            cp -r config/"$DIR2" ~/.config/"$DIR2"
            if [ $? -eq 0 ]; then
              echo -e "${OK} - Replaced $DIR2 with new configuration." 2>&1 | tee -a "$LOG"
            else
              echo "${ERROR} - Failed to copy $DIR2." 2>&1 | tee -a "$LOG"
              exit 1
            fi
          else
            echo "${ERROR} - Failed to back up $DIR2." 2>&1 | tee -a "$LOG"
            exit 1
          fi
          break
          ;;
        [Nn]* )
          # Skip the directory
          echo -e "${NOTE} - Skipping ${ORANGE}$DIR2${RESET} " 2>&1 | tee -a "$LOG"
          break
          ;;
        * )
          echo -e "${WARN} - Invalid choice. Please enter Y or N."
          ;;
      esac
    done
  else
    # Copy new config if directory does not exist
    cp -r config/"$DIR2" ~/.config/"$DIR2" 2>&1 | tee -a "$LOG"
    if [ $? -eq 0 ]; then
      echo "${OK} - Copy completed for ${YELLOW}$DIR2${RESET}" 2>&1 | tee -a "$LOG"
    else
      echo "${ERROR} - Failed to copy ${YELLOW}$DIR2${RESET}" 2>&1 | tee -a "$LOG"
      exit 1
    fi
  fi
done

printf "\n%.0s" {1..1}

printf "${INFO} - Copying dotfiles ${BLUE}second${RESET} part\n"

# Check if the config directory exists
if [ ! -d "config" ]; then
  echo "${ERROR} - The 'config' directory does not exist."
  exit 1
fi

DIR="
  btop
  cava
  hypr
  Kvantum
  qt5ct
  qt6ct
  swappy
  wallust
  wlogout
"

for DIR_NAME in $DIR; do
  DIRPATH=~/.config/"$DIR_NAME"
  
  # Backup the existing directory if it exists
  if [ -d "$DIRPATH" ]; then
    echo -e "${NOTE} - Config for ${ORANGE}$DIR_NAME${RESET} found, attempting to back up."
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
    cp -r "config/$DIR_NAME/" ~/.config/"$DIR_NAME" 2>&1 | tee -a "$LOG"
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

printf "\n%.0s" {1..2}

# Restoring UserConfigs and UserScripts
DIRH="hypr"
FILES_TO_RESTORE=(
  "ENVariables.conf"
  "LaptopDisplay.conf"
  "Laptops.conf"
  "Monitors.conf"
  "Startup_Apps.conf"
  "UserDecorAnimations.conf"
  "UserKeybinds.conf"
  "UserSettings.conf"
  "WindowRules.conf"
  "WorkspaceRules.conf"
)

DIRPATH=~/.config/"$DIRH"
BACKUP_DIR=$(get_backup_dirname)
BACKUP_DIR_PATH="$DIRPATH-backup-$BACKUP_DIR/UserConfigs"

if [ -z "$BACKUP_DIR" ]; then
  echo "${ERROR} - Backup directory name is empty. Exiting."
  exit 1
fi

if [ -d "$BACKUP_DIR_PATH" ]; then
  echo -e "${NOTE} Restoring previous ${ORANGE}User-Configs${RESET}... "
  echo -e "${WARN} If you decide to restore the old configs, make sure to handle the updates or changes manually."
  echo -e "${INFO} Kindly Visit and check KooL's Hyprland-Dots GitHub page for the commits."

  for FILE_NAME in "${FILES_TO_RESTORE[@]}"; do
    BACKUP_FILE="$BACKUP_DIR_PATH/$FILE_NAME"
    if [ -f "$BACKUP_FILE" ]; then
      printf "\n${INFO} Found ${YELLOW}$FILE_NAME${RESET} in hypr backup...\n"
      read -p "${CAT} Do you want to restore ${ORANGE}$FILE_NAME${RESET} from backup? (y/N): " file_restore

      if [[ "$file_restore" == [Yy]* ]]; then
        if cp "$BACKUP_FILE" "$DIRPATH/UserConfigs/$FILE_NAME"; then
          echo "${OK} - $FILE_NAME restored!" 2>&1 | tee -a "$LOG"
        else
          echo "${ERROR} - Failed to restore $FILE_NAME!" 2>&1 | tee -a "$LOG"
        fi
      else
        echo "${NOTE} - Skipped restoring $FILE_NAME."
      fi
    fi
  done
fi

printf "\n%.0s" {1..2}

# Restoring previous UserScripts
DIRSH="hypr"
SCRIPTS_TO_RESTORE=(
  "RofiBeats.sh"
  "Weather.py"
  "Weather.sh"
)

DIRSHPATH=~/.config/"$DIRSH"
BACKUP_DIR_PATH="$DIRSHPATH-backup-$BACKUP_DIR/UserScripts"

if [ -d "$BACKUP_DIR_PATH" ]; then
  echo -e "${NOTE} Restoring previous ${ORANGE}User-Scripts${RESET}..."

  for SCRIPT_NAME in "${SCRIPTS_TO_RESTORE[@]}"; do
    BACKUP_SCRIPT="$BACKUP_DIR_PATH/$SCRIPT_NAME"

    if [ -f "$BACKUP_SCRIPT" ]; then
      printf "\n${INFO} Found ${YELLOW}$SCRIPT_NAME${RESET} in hypr backup...\n"
      read -p "${CAT} Do you want to restore ${ORANGE}$SCRIPT_NAME${RESET} from backup? (y/N): " script_restore
      if [[ "$script_restore" == [Yy]* ]]; then
        if cp "$BACKUP_SCRIPT" "$DIRSHPATH/UserScripts/$SCRIPT_NAME"; then
          echo "${OK} - $SCRIPT_NAME restored!" 2>&1 | tee -a "$LOG"
        else
          echo "${ERROR} - Failed to restore $SCRIPT_NAME!" 2>&1 | tee -a "$LOG"
        fi
      else
        echo "${NOTE} - Skipped restoring $SCRIPT_NAME."
      fi
    fi
  done
fi

printf "\n%.0s" {1..2}

# Wallpapers
mkdir -p ~/Pictures/wallpapers
cp -r wallpapers ~/Pictures/ && { echo "${OK} some wallpapers compied!"; } || { echo "${ERROR} Failed to copy some wallpapers."; exit 1; } 2>&1 | tee -a "$LOG"
 
# Set some files as executable
chmod +x ~/.config/hypr/scripts/* 2>&1 | tee -a "$LOG"
chmod +x ~/.config/hypr/UserScripts/* 2>&1 | tee -a "$LOG"
# Set executable for initial-boot.sh
chmod +x ~/.config/hypr/initial-boot.sh 2>&1 | tee -a "$LOG"

# Detect machine type and set waybar configurations accordingly
if hostnamectl | grep -q 'Chassis: desktop'; then
    # Configurations for a desktop
    ln -sf "$waybar_config" "$HOME/.config/waybar/config" 2>&1 | tee -a "$LOG"
    # Remove waybar configs for laptop
    rm -rf "$HOME/.config/waybar/configs/[TOP] Default Laptop" \
           "$HOME/.config/waybar/configs/[BOT] Default Laptop" \
           "$HOME/.config/waybar/configs/[TOP] Default Laptop_v2" \
           "$HOME/.config/waybar/configs/[TOP] Default Laptop_v3" \
           "$HOME/.config/waybar/configs/[TOP] Default Laptop_v4" 2>&1 | tee -a "$LOG" || true
else
    # Configurations for a laptop or any system other than desktop
    ln -sf "$waybar_config_laptop" "$HOME/.config/waybar/config" 2>&1 | tee -a "$LOG"
    # Remove waybar configs for desktop
    rm -rf "$HOME/.config/waybar/configs/[TOP] Default" \
           "$HOME/.config/waybar/configs/[BOT] Default" \
           "$HOME/.config/waybar/configs/[TOP] Default_v2" \
           "$HOME/.config/waybar/configs/[TOP] Default_v3" \
           "$HOME/.config/waybar/configs/[TOP] Default_v4" 2>&1 | tee -a "$LOG" || true
fi

# additional wallpapers
echo "$(tput setaf 6) By default only a few wallpapers are copied...$(tput sgr0)"
printf "\n"

while true; do
  read -rp "${CAT} Would you like to download additional wallpapers? ${WARN} This is more than >700mb (y/n)" WALL
  case $WALL in
    [Yy])
      echo "${NOTE} Downloading additional wallpapers..."
      if git clone "https://github.com/JaKooLit/Wallpaper-Bank.git"; then
          echo "${OK} Wallpapers downloaded successfully." 2>&1 | tee -a "$LOG"

          # Check if wallpapers directory exists and create it if not
          if [ ! -d ~/Pictures/wallpapers ]; then
              mkdir -p ~/Pictures/wallpapers
              echo "${OK} Created wallpapers directory." 2>&1 | tee -a "$LOG"
          fi

          if cp -R Wallpaper-Bank/wallpapers/* ~/Pictures/wallpapers/ >> "$LOG" 2>&1; then
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
  CONFIG_DIR=~/.config
  BACKUP_PREFIX="-backup"

  # Loop through directories in ~/.config
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
		printf "\n\n ${INFO} Performing clean up for ${ORANGE}${DIR##*/}${RESET}\n"

        echo -e "${NOTE} Found multiple backups for: ${ORANGE}${DIR##*/}${RESET}"
        echo "${YELLOW}Backups: ${RESET}"

        # List the backups
        for BACKUP in "${BACKUP_DIRS[@]}"; do
          echo "  - ${BACKUP##*/}"
        done

        read -p "${CAT} Do you want to delete the older backups of ${ORANGE}${DIR##*/}${RESET} and keep the latest backup only? (y/N): " back_choice
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
          echo "Old backups of ${ORANGE}${DIR##*/}${RESET} deleted, keeping: ${YELLOW}${latest_backup##*/}${RESET}"
        fi
      fi
    fi
  done
}
# Execute the cleanup function
cleanup_backups

# symlinks for waybar style
ln -sf "$waybar_style" "$HOME/.config/waybar/style.css" && \

printf "\n%.0s" {1..2}

# initialize wallust to avoid config error on hyprland
wallust run -s $wallpaper 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..4}
printf "${OK} GREAT! KooL's Hyprland-Dots is now Loaded & Ready !!!"
printf "\n%.0s" {1..1}
printf "${ORANGE} HOWEVER I HIGHLY SUGGEST to logout and re-login or better reboot to avoid any issues\n\n"
