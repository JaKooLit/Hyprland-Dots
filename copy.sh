#!/bin/bash
### https://github.com/JaKooLit/JaKooLit

clear

wallpaper=$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified
waybar_style="$HOME/.config/waybar/style/[Wallust] Box type.css"
waybar_config="$HOME/.config/waybar/configs/[TOP] Default_v3"
waybar_config_laptop="$HOME/.config/waybar/configs/[TOP] Default Laptop_v3" 

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
WARN="$(tput setaf 166)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
ORANGE=$(tput setaf 166)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

# Create Directory for Copy Logs
if [ ! -d Copy-Logs ]; then
    mkdir Copy-Logs
fi

# Set the name of the log file to include the current date and time
LOG="Copy-Logs/install-$(date +%d-%H%M%S)_dotfiles.log"

# update home folders
xdg-user-dirs-update 2>&1 | tee -a "$LOG" || true

# uncommenting WLR_NO_HARDWARE_CURSORS if nvidia is detected
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
  echo "Nvidia GPU detected. Setting up proper env's" 2>&1 | tee -a "$LOG" || true
  sed -i '/env = WLR_NO_HARDWARE_CURSORS,1/s/^#//' config/hypr/UserConfigs/ENVariables.conf
  sed -i '/env = LIBVA_DRIVER_NAME,nvidia/s/^#//' config/hypr/UserConfigs/ENVariables.conf
  sed -i '/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/s/^#//' config/hypr/UserConfigs/ENVariables.conf
fi

# uncommenting WLR_RENDERER_ALLOW_SOFTWARE,1 if running in a VM is detected
if hostnamectl | grep -q 'Chassis: vm'; then
  echo "System is running in a virtual machine." 2>&1 | tee -a "$LOG" || true
  sed -i '/env = WLR_NO_HARDWARE_CURSORS,1/s/^#//' config/hypr/UserConfigs/ENVariables.conf
  sed -i '/env = WLR_RENDERER_ALLOW_SOFTWARE,1/s/^#//' config/hypr/UserConfigs/ENVariables.conf
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
        echo "$(tput bold)$(tput setaf 3)ATTENTION!!!! VERY IMPORTANT!!!! $(tput sgr0)" 
        echo "$(tput bold)$(tput setaf 1)The keyboard layout could not be detected properly. $(tput sgr0)"
        echo "$(tput bold)$(tput setaf 7)You need to set it manually. $(tput sgr0)"
        echo "$(tput bold)$(tput setaf 2)If you are not sure, type us. You can change later on! $(tput sgr0)"
        printf "\n%.0s" {1..1}
        echo "$(tput bold)$(tput setaf 5)You can also set more than 2 layouts!$(tput sgr0)"
        echo "$(tput bold)$(tput setaf 5)ie: us,kr,es $(tput sgr0)"
        printf "\n%.0s" {1..1}
        read -p "${CAT} - Please enter the correct keyboard layout: " new_layout

        if [ -n "$new_layout" ]; then
            layout="$new_layout"
            break
        else
            echo "Please enter a keyboard layout."
        fi
    done
fi

printf "${NOTE} Detecting keyboard layout to prepare proper Hyprland Settings\n\n"

# Prompt the user to confirm whether the detected layout is correct
while true; do
    read -p "$ORANGE Current keyboard layout is: $layout. Is this correct? [y/n] " confirm

    case $confirm in
        [yY])
            # If the detected layout is correct, update the 'kb_layout=' line in the file
            awk -v layout="$layout" '/kb_layout/ {$0 = "  kb_layout=" layout} 1' config/hypr/UserConfigs/UserSettings.conf > temp.conf
            mv temp.conf config/hypr/UserConfigs/UserSettings.conf
            
            echo "${NOTE} kb_layout $layout configured in settings.  " 2>&1 | tee -a "$LOG"
            break ;;
        [nN])
            printf "\n%.0s" {1..2}
            echo "$(tput bold)$(tput setaf 3)ATTENTION!!!! VERY IMPORTANT!!!! $(tput sgr0)" 
            echo "$(tput bold)$(tput setaf 1)Setting a wrong value here will result in Hyprland not starting $(tput sgr0)"
         		echo "$(tput bold)$(tput setaf 2)If you are not sure, type us. You can change later on! $(tput sgr0)"
        		printf "\n%.0s" {1..1}
        		echo "$(tput bold)$(tput setaf 5)You can also set more than 2 layouts!$(tput sgr0)"
        		echo "$(tput bold)$(tput setaf 5)ie: us,kr,es $(tput sgr0)"
            printf "\n%.0s" {1..1}
            
            read -p "${CAT} - Please enter the correct keyboard layout: " new_layout
            
            # Update the 'kb_layout=' line with the correct layout in the file
            awk -v new_layout="$new_layout" '/kb_layout/ {$0 = "  kb_layout=" new_layout} 1' config/hypr/UserConfigs/UserSettings.conf > temp.conf
            mv temp.conf config/hypr/UserConfigs/UserSettings.conf
            echo "${NOTE} kb_layout $new_layout configured in settings." 2>&1 | tee -a "$LOG" 
            break ;;
        *)
            echo "Please enter either 'y' or 'n'." ;;
    esac
done

printf "\n"

# Check if asusctl is installed and add rog-control-center on Startup
if command -v asusctl >/dev/null 2>&1; then
    sed -i '/exec-once = rog-control-center &/s/^#//' config/hypr/UserConfigs/Startup_Apps.conf
fi

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
    sed -i 's#^    \/\/"format": " {:%I:%M %p}", // AM PM format#    "format": " {:%I:%M %p}", // AM PM format#' config/waybar/modules 2>&1 | tee -a "$LOG"
    sed -i 's#^    "format": " {:%H:%M:%S}", // 24H#    \/\/"format": " {:%H:%M:%S}", // 24H#' config/waybar/modules 2>&1 | tee -a "$LOG"
    
    # Clock 2
    sed -i 's#^    "format": "  {:%H:%M}", // 24H#    \/\/"format": "  {:%H:%M}", // 24H#' config/waybar/modules 2>&1 | tee -a "$LOG"
    
    # Clock 3
    sed -i 's#^    \/\/"format": "{:%I:%M %p - %d/%b}", //for AM/PM#    "format": "{:%I:%M %p - %d/%b}", //for AM/PM#' config/waybar/modules 2>&1 | tee -a "$LOG"
    sed -i 's#^    "format": "{:%H:%M - %d/%b}", // 24H#    \/\/"format": "{:%H:%M - %d/%b}", // 24H#' config/waybar/modules 2>&1 | tee -a "$LOG"
    
    # Clock 4
    sed -i 's#^    \/\/"format": "{:%B | %a %d, %Y | %I:%M %p}", // AM PM format#    "format": "{:%B | %a %d, %Y | %I:%M %p}", // AM PM format#' config/waybar/modules 2>&1 | tee -a "$LOG"
    sed -i 's#^    "format": "{:%B | %a %d, %Y | %H:%M}", // 24H#    \/\/"format": "{:%B | %a %d, %Y | %H:%M}", // 24H#' config/waybar/modules 2>&1 | tee -a "$LOG"

    # Clock 5
    sed -i 's#^    \/\/"format": "{:%A, %I:%M %P}", // AM PM format#    "format": "{:%A, %I:%M %P}", // AM PM format#' config/waybar/modules 2>&1 | tee -a "$LOG"
    sed -i 's#^    "format": "{:%a %d | %H:%M}", // 24H#    \/\/"format": "{:%a %d | %H:%M}", // 24H#' config/waybar/modules 2>&1 | tee -a "$LOG"
            
    # for hyprlock
    sed -i 's|^    #text = cmd\[update:1000\] echo "<b><big> $(date +"%I:%M:%S %p") </big></b>" # AM/PM|    text = cmd\[update:1000\] echo "<b><big> $(date +"%I:%M:%S %p") </big></b>" # AM/PM|' config/hypr/hyprlock.conf 2>&1 | tee -a "$LOG"
    sed -i 's|^    text = cmd\[update:1000\] echo "<b><big> $(date +"%H:%M:%S") </big></b>" # 24H|    #text = cmd\[update:1000\] echo "<b><big> $(date +"%H:%M:%S") </big></b>" # 24H|' config/hypr/hyprlock.conf 2>&1 | tee -a "$LOG"

    # for SDDM (simple-sddm)
    sddm_folder="/usr/share/sddm/themes/simple-sddm"
    if [ -d "$sddm_folder" ]; then
      echo "Simple sddm exists. Editing to 12H format" 2>&1 | tee -a "$LOG"

      sudo sed -i 's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|' "$sddm_folder/theme.conf" 2>&1 | tee -a "$LOG" || true
      sudo sed -i 's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|' "$sddm_folder/theme.conf" 2>&1 | tee -a "$LOG" || true

      echo "12H format set to SDDM theme successfully." 2>&1 | tee -a "$LOG"
    fi

        # for SDDM (simple-sddm-2)
    sddm_folder_2="/usr/share/sddm/themes/simple-sddm-2"
    if [ -d "$sddm_folder_2" ]; then
      echo "Simple sddm 2 exists. Editing to 12H format" 2>&1 | tee -a "$LOG"

      sudo sed -i 's|^## HourFormat="hh:mm AP"|HourFormat="hh:mm AP"|' "$sddm_folder_2/theme.conf" 2>&1 | tee -a "$LOG" || true
      sudo sed -i 's|^HourFormat="HH:mm"|## HourFormat="HH:mm"|' "$sddm_folder_2/theme.conf" 2>&1 | tee -a "$LOG" || true

      echo "12H format set to SDDM theme successfully." 2>&1 | tee -a "$LOG"
    fi

    break
  elif [[ "$answer" == "n" ]]; then
    echo "You chose not to change to 12H format." 2>&1 | tee -a "$LOG"
    break
  else
    echo "Invalid choice. Please enter y for yes or n for no."
  fi
done

printf "\n"

# Action to do for better rofi appearance
while true; do
    echo "$ORANGE Select monitor resolution for better Rofi appearance:"
    echo "$YELLOW 1. Equal to or less than 1080p (≤ 1080p)"
    echo "$YELLOW 2. Equal to or higher than 1440p (≥ 1440p)"
    read -p "$CAT Enter the number of your choice: " choice

    case $choice in
        1)
            resolution="≤ 1080p"
            break
            ;;
        2)
            resolution="≥ 1440p"
            break
            ;;
        *)
            echo "Invalid choice. Please enter 1 for ≤ 1080p or 2 for ≥ 1440p."
            ;;
    esac
done

# Use the selected resolution in your existing script
echo "You chose $resolution resolution for better Rofi appearance." 2>&1 | tee -a "$LOG"

# Add your commands based on the resolution choice
if [ "$resolution" == "≤ 1080p" ]; then
    cp -r config/rofi/resolution/1080p/* config/rofi/
elif [ "$resolution" == "≥ 1440p" ]; then
    cp -r config/rofi/resolution/1440p/* config/rofi/
fi

printf "\n%.0s" {1..2}

### Copy Config Files ###
set -e # Exit immediately if a command exits with a non-zero status.

printf "${NOTE} - copying dotfiles\n"
# Function to create a unique backup directory name with month, day, hours, and minutes
get_backup_dirname() {
  local timestamp
  timestamp=$(date +"%m%d_%H%M")
  echo "back-up_${timestamp}"
}

for DIR in ags btop cava fastfetch hypr kitty Kvantum qt5ct qt6ct rofi swappy swaync wallust waybar wlogout; do 
  DIRPATH=~/.config/"$DIR"
  if [ -d "$DIRPATH" ]; then 
    echo -e "${NOTE} - Config for $DIR found, attempting to back up."
    BACKUP_DIR=$(get_backup_dirname)
    mv "$DIRPATH" "$DIRPATH-backup-$BACKUP_DIR" 2>&1 | tee -a "$LOG"
    echo -e "${NOTE} - Backed up $DIR to $DIRPATH-backup-$BACKUP_DIR."
  fi
done

printf "\n%.0s" {1..2}

# Copying config files
mkdir -p ~/.config
cp -r config/* ~/.config/ && { echo "${OK}Copy completed!"; } || { echo "${ERROR} Failed to copy config files."; exit 1; } 2>&1 | tee -a "$LOG"

# copying Wallpapers
mkdir -p ~/Pictures/wallpapers
cp -r wallpapers ~/Pictures/ && { echo "${OK}Copy completed!"; } || { echo "${ERROR} Failed to copy wallpapers."; exit 1; } 2>&1 | tee -a "$LOG"
 
# Set some files as executable
chmod +x ~/.config/hypr/scripts/* 2>&1 | tee -a "$LOG"
chmod +x ~/.config/hypr/UserScripts/* 2>&1 | tee -a "$LOG"
# Set executable for initial-boot.sh
chmod +x ~/.config/hypr/initial-boot.sh 2>&1 | tee -a "$LOG"
printf "\n%.0s" {1..2}

# Detect machine type and set Waybar configurations accordingly
if hostnamectl | grep -q 'Chassis: desktop'; then
    # Configurations for a desktop
    ln -sf "$waybar_config" "$HOME/.config/waybar/config" 2>&1 | tee -a "$LOG"
    rm -r "$HOME/.config/waybar/configs/[TOP] Default Laptop" "$HOME/.config/waybar/configs/[BOT] Default Laptop" 2>&1 | tee -a "$LOG"
    rm -r "$HOME/.config/waybar/configs/[TOP] Default Laptop_v2" "$HOME/.config/waybar/configs/[TOP] Default Laptop_v3" 2>&1 | tee -a "$LOG"
else
    # Configurations for a laptop or any system other than desktop
    ln -sf "$waybar_config_laptop" "$HOME/.config/waybar/config" 2>&1 | tee -a "$LOG"
    rm -r "$HOME/.config/waybar/configs/[TOP] Default" "$HOME/.config/waybar/configs/[BOT] Default" 2>&1 | tee -a "$LOG"
    rm -r "$HOME/.config/waybar/configs/[TOP] Default_v2" "$HOME/.config/waybar/configs/[TOP] Default_v3" 2>&1 | tee -a "$LOG"
fi

# additional wallpapers
echo "$(tput setaf 6) By default only a few wallpapers are copied...$(tput sgr0)"
printf "\n%.0s" {1..2}

while true; do
    read -rp "${CAT} Would you like to download additional wallpapers? Warning! This is more than >600mb (y/n)" WALL
    case $WALL in
        [Yy])
            echo "${NOTE} Downloading additional wallpapers..."
            if git clone "https://github.com/JaKooLit/Wallpaper-Bank.git"; then
                echo "${NOTE} Wallpapers downloaded successfully." 2>&1 | tee -a "$LOG"

                # Check if wallpapers directory exists and create it if not
                if [ ! -d ~/Pictures/wallpapers ]; then
                    mkdir -p ~/Pictures/wallpapers
                    echo "${NOTE} Created wallpapers directory." 2>&1 | tee -a "$LOG"
                fi

                if cp -R Wallpaper-Bank/wallpapers/* ~/Pictures/wallpapers/ >> "$LOG" 2>&1; then
                    echo "${NOTE} Wallpapers copied successfully." 2>&1 | tee -a "$LOG"
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
            echo "You chose not to download additional wallpapers." 2>&1 | tee -a "$LOG"
            break
            ;;
        *)
            echo "Please enter 'y' or 'n' to proceed."
            ;;
    esac
done

# symlinks for waybar style
ln -sf "$waybar_style" "$HOME/.config/waybar/style.css" && \

# initialize wallust to avoid config error on hyprland
wallust run -s $wallpaper 2>&1 | tee -a "$LOG"


printf "\n%.0s" {1..2}
printf "\n${OK} Copy Completed!\n\n\n"
printf "${ORANGE} ATTENTION!!!! \n"
printf "${ORANGE} YOU NEED to logout and re-login or reboot to avoid issues\n\n"
