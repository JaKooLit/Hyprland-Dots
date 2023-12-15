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

printf "\n%.0s" {1..3}

# additional wallpapers
echo "$(tput setaf 6) By default only a few wallpapers are copied...$(tput sgr0)"
printf "\n%.0s" {1..2}

while true; do
    read -rp "${CAT} Would you like to download additional wallpapers? (y/n)" WALL
    case $WALL in
        [Yy])
            echo "${NOTE} Downloading additional wallpapers..."
            if git clone https://github.com/JaKooLit/Wallpaper-Bank.git 2>&1 | tee -a "$LOG"; then
                if cp -R Wallpaper-Bank/wallpapers/* ~/Pictures/wallpapers/; then 2>&1 | tee -a "$LOG"
                    rm -rf Wallpaper-Bank 2>&1 | tee -a "$LOG" # Remove cloned repository after copying wallpapers
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

printf "\n%.0s" {1..3}

# Detect machine type and set Waybar configurations accordingly, logging the output
if hostnamectl | grep -q 'Chassis: desktop'; then
    # Configurations for a desktop
    ln -sf "$HOME/.config/waybar/configs/Default [TOP]" "$HOME/.config/waybar/config" 2>&1 | tee -a "$LOG"
    rm -r "$HOME/.config/waybar/configs/Default [TOP]-Laptop" "$HOME/.config/waybar/configs/Default [Bottom]-Laptop" 2>&1 | tee -a "$LOG"
else
    # Configurations for a laptop or any system other than desktop
    ln -sf "$HOME/.config/waybar/configs/Default [TOP]-Laptop" "$HOME/.config/waybar/config" 2>&1 | tee -a "$LOG"
    rm -r "$HOME/.config/waybar/configs/Default [TOP]" "$HOME/.config/waybar/configs/Default [Bottom]" 2>&1 | tee -a "$LOG"
fi


# symlinks for waybar style
ln -sf "$HOME/.config/waybar/style/Golden Noir.css" "$HOME/.config/waybar/style.css" && \

# initialize pywal to avoid config error on hyprland
wal -i ~/Pictures/wallpapers/anime-girl-abyss.png 2>&1 | tee -a "$LOG"

#initial symlink for Pywal Dark and Light for Rofi Themes
ln -sf "$HOME/.cache/wal/colors-rofi-dark.rasi" "$HOME/.config/rofi/pywal-color/pywal-theme.rasi"

printf "\n%.0s" {1..2}
printf "\n${OK} Copy Completed!\n\n\n"
printf "${ORANGE} ATTENTION!!!! \n"
printf "${ORANGE} YOU NEED to logout and re-login or reboot to avoid issues\n\n"
