#!/bin/bash

### https://github.com/JaKooLit/JaKooLit

# Check if running as root. If root, script will exit
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be executed as root! Exiting......."
    exit 1
fi

printf "\n%.0s" {1..3}  
echo "                                   _   _ ___ __ "
echo "   |  _.   |/  _   _  |  o _|_ __ | \ / \ | (_  "
echo " \_| (_| o |\ (_) (_) |_ |  |_    |_/ \_/ | __) "
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

# Set the name of the log file to include the current date and time
LOG="install-$(date +%d-%H%M%S)_dotfiles.log"

# update home folders
xdg-user-dirs-update 2>&1 | tee -a "$LOG" || true

# uncommenting WLR_NO_HARDWARE_CURSORS if nvidia is detected
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
  # NVIDIA GPU detected, uncomment line 23 in ENVariables.conf
  sed -i '/env = WLR_NO_HARDWARE_CURSORS,1/s/^#//' config/hypr/configs/ENVariables.conf
  sed -i '/env = LIBVA_DRIVER_NAME,nvidia/s/^#//' config/hypr/configs/ENVariables.conf
  sed -i '/env = __GLX_VENDOR_LIBRARY_NAME,nvidia/s/^#//' config/hypr/configs/ENVariables.conf
fi

# uncommenting WLR_RENDERER_ALLOW_SOFTWARE,1 if running in a VM is detected
if hostnamectl | grep -q 'Chassis: vm'; then
  echo "This script is running in a virtual machine."
  sed -i '/env = WLR_NO_HARDWARE_CURSORS,1/s/^#//' config/hypr/configs/ENVariables.conf
  sed -i '/env = WLR_RENDERER_ALLOW_SOFTWARE,1/s/^#//' config/hypr/configs/ENVariables.conf
  sed -i '/monitor = Virtual-1, 1920x1080@60,auto,1/s/^#//' config/hypr/configs/Monitors.conf
fi

# Preparing hyprland.conf to check for current keyboard layout
# Function to detect keyboard layout in an X server environment
detect_x_layout() {
  if command -v setxkbmap >/dev/null 2>&1; then
    layout=$(setxkbmap -query | grep layout | awk '{print $2}')
    if [ -n "$layout" ]; then
      echo "$layout"
    else
      echo "unknown"
    fi
  else
    echo "unknown"
  fi
}

# Function to detect keyboard layout in a tty environment
detect_tty_layout() {
  if command -v localectl >/dev/null 2>&1; then
    layout=$(localectl status --no-pager | awk '/X11 Layout/ {print $3}')
    if [ -n "$layout" ]; then
      echo "$layout"
    else
      echo "unknown"
    fi
  else
    echo "unknown"
  fi
}

# Detect the current keyboard layout based on the environment
if [ -n "$DISPLAY" ]; then
  # System is in an X server environment
  layout=$(detect_x_layout)
else
  # System is in a tty environment
  layout=$(detect_tty_layout)
fi

echo "Keyboard layout: $layout"

printf "${NOTE} Detecting keyboard layout to prepare necessary changes in hyprland.conf before copying\n\n"

# Prompt the user to confirm whether the detected layout is correct
read -p "$ORANGE Detected keyboard layout or keymap: $layout. Is this correct? [y/n] " confirm

if [ "$confirm" = "y" ]; then
  # If the detected layout is correct, update the 'kb_layout=' line in the file
  awk -v layout="$layout" '/kb_layout/ {$0 = "  kb_layout=" layout} 1' config/hypr/configs/Settings.conf > temp.conf
  mv temp.conf config/hypr/configs/Settings.conf
else
  # If the detected layout is not correct, prompt the user to enter the correct layout
  printf "${YELLOW} Ensure to type in the proper keyboard layout else Hyprland will crash and might not start!!!\n\n"
  printf "${WARN} - Sample Keyboard layouts are us, kr, es, gb, de, pl, etc.\n\n"
  read -p "${CAT} - Please enter the correct keyboard layout: " new_layout
  # Update the 'kb_layout=' line with the correct layout in the file
  awk -v new_layout="$new_layout" '/kb_layout/ {$0 = "  kb_layout=" new_layout} 1' config/hypr/configs/Settings.conf > temp.conf
  mv temp.conf config/hypr/configs/Settings.conf
fi
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
echo "You chose $resolution resolution for better Rofi appearance."

# Add your commands based on the resolution choice
if [ "$resolution" == "≤ 1080p" ]; then
    cp -r config/rofi/resolution/1080p/* config/rofi/
elif [ "$resolution" == "≥ 1440p" ]; then
    cp -r config/rofi/resolution/1440p/* config/rofi/
fi

### Copy Config Files ###
set -e # Exit immediately if a command exits with a non-zero status.

printf "${NOTE} - copying dotfiles\n"
  for DIR in btop cava dunst hypr kitty Kvantum qt5ct qt6ct rofi swappy swaylock wal waybar wlogout; do 
    DIRPATH=~/.config/$DIR
    if [ -d "$DIRPATH" ]; then 
      echo -e "${NOTE} - Config for $DIR found, attempting to back up."
      mv $DIRPATH $DIRPATH-back-up 2>&1 | tee -a "$LOG"
      echo -e "${NOTE} - Backed up $DIR to $DIRPATH-back-up."
    fi
  done

  for DIRw in wallpapers; do 
    DIRPATH=~/Pictures/$DIRw
    if [ -d "$DIRPATH" ]; then 
      echo -e "${NOTE} - wallpapers in $DIRw found, attempting to back up."
      mv $DIRPATH $DIRPATH-back-up 2>&1 | tee -a "$LOG"
      echo -e "${NOTE} - Backed up $DIRw to $DIRPATH-back-up."
    fi
  done

# Copying config files
printf " Copying config files...\n"
mkdir -p ~/.config
cp -r config/* ~/.config/ && { echo "${OK}Copy completed!"; } || { echo "${ERROR} Failed to copy config files."; exit 1; } 2>&1 | tee -a "$LOG"

# copying Wallpapers
mkdir -p ~/Pictures/wallpapers
cp -r wallpapers ~/Pictures/ && { echo "${OK}Copy completed!"; } || { echo "${ERROR} Failed to copy wallpapers."; exit 1; } 2>&1 | tee -a "$LOG"



  
# Set some files as executable
chmod +x ~/.config/hypr/scripts/* 2>&1 | tee -a "$LOG"

# Set executable for initial-boot.sh
chmod +x ~/.config/hypr/initial-boot.sh 2>&1 | tee -a "$LOG"

#printf "\n\n"
# adding user to input group
#printf " adding user to input group...\n"
#sudo gpasswd -a $(whoami) input 2>&1 | tee -a "$LOG"

#printf "\n\n"
# Additional wallpaper
echo "$(tput setaf 6) By default only a few wallpapers are copied...$(tput sgr0)"
read -n1 -rep "${CAT} Would you like to download additional wallpapers? (y/n)" WALL
sleep 1

if [[ $WALL =~ ^[Yy]$ ]]; then
  printf "${NOTE} Downloading additional wallpapers...\n"
  if git clone https://github.com/JaKooLit/Wallpaper-Bank.git 2>&1 | tee -a "$LOG"; then
    cp -R Wallpaper-Bank/wallpapers/* ~/Pictures/wallpapers/
    rm -rf Wallpaper-Bank # Remove cloned repository after copying wallpapers
  else
    echo "${ERROR} Downloading additional wallpapers failed" 2>&1 | tee -a "$LOG"
  fi
fi

# Initial Symlinks to avoid errors

# Detect machine type and set Waybar configurations accordingly, logging the output
if hostnamectl | grep -q 'Chassis: desktop'; then
    # Configurations for a desktop
    ln -sf "$HOME/.config/waybar/configs/Default [TOP]" "$HOME/.config/waybar/config" 2>&1 | tee -a "$LOG"
    rm -r "$HOME/.config/waybar/configs/Def[TOP]-Laptop" "$HOME/.config/waybar/configs/Def[Bottom]-Laptop" 2>&1 | tee -a "$LOG"
else
    # Configurations for a laptop or any system other than desktop
    ln -sf "$HOME/.config/waybar/configs/Def[TOP]-Laptop" "$HOME/.config/waybar/config" 2>&1 | tee -a "$LOG"
    rm -r "$HOME/.config/waybar/configs/Default [TOP]" "$HOME/.config/waybar/configs/Default [Bottom]" 2>&1 | tee -a "$LOG"
fi


# symlinks for waybar style
ln -sf "$HOME/.config/waybar/style/Golden Noir.css" "$HOME/.config/waybar/style.css" && \

# initialize pywal to avoid config error on hyprland
wal -i ~/Pictures/wallpapers/anime-girl-abyss.png 2>&1 | tee -a "$LOG"

#initial symlink for Pywal Dark and Light for Rofi Themes
ln -sf "$HOME/.cache/wal/colors-rofi-dark.rasi" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"

printf "\n\n"
printf "\n${OK} Copy Completed!\n\n\n"
printf "${ORANGE} ATTENTION!!!! \n"
printf "${ORANGE} YOU NEED to logout and re-login or reboot to avoid issues\n\n"
