#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# for Semi-Manual upgrading your system.
# NOTE: requires rsync 

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

printf "\n%.0s" {1..1}  
echo -e "\e[35m
    ╦╔═┌─┐┌─┐╦    ╔╦╗┌─┐┌┬┐┌─┐
    ╠╩╗│ ││ │║     ║║│ │ │ └─┐ 2025
    ╩ ╩└─┘└─┘╩═╝  ═╩╝└─┘ ┴ └─┘ upgrade.sh
\e[0m"
printf "\n%.0s" {1..1}  

echo "${WARNING}A T T E N T I O N !${RESET}"
echo "${SKY_BLUE}This script is meant to manually upgrade your KooL Hyprland Dots${RESET}"
echo "${YELLOW}NOTE that you should edit this script and assign an Directory or Files exclusion${RESET}"
printf "\n%.0s" {1..1}
echo "${MAGENTA}If you are not sure what you are doing,ran the ${SKY_BLUE}copy.sh${RESET} ${MAGENTA}instead${RESET}"
printf "\n%.0s" {1..1}
read -p "${CAT} - Would you like to proceed (y/n): ${RESET}" proceed

if [ "$proceed" != "y" ]; then
    printf "\n%.0s" {1..1}
    echo "${INFO} Installation aborted. ${SKY_BLUE}No changes in your system.${RESET} ${YELLOW}Goodbye!${RESET}"
    printf "\n%.0s" {1..1}
    exit 1
fi

# Create Directory for Upgrade Logs
if [ ! -d Upgrade-Logs ]; then
    mkdir Upgrade-Logs
fi

LOG="Upgrade-Logs/upgrade-$(date +%d-%H%M%S)_upgrade_dotfiles.log"

# source and target versions
source_dir="config"
target_dir="$HOME/.config"

# Specify the update source directories, their corresponding target directories, and their exclusions
declare -A directories=(
    ["config/hypr/"]="$HOME/.config/hypr/"
    ["config/kitty/"]="$HOME/.config/kitty/"
    ["config/Kvantum/"]="$HOME/.config/Kvantum/"
    ["config/nvim/"]="$HOME/.config/nvim/"
    ["config/qt5ct/"]="$HOME/.config/qt5ct"
    ["config/qt6ct/"]="$HOME/.config/qt6ct/"
    ["config/rofi/"]="$HOME/.config/rofi/"
    ["config/swaync/"]="$HOME/.config/swaync/"
    ["config/waybar/"]="$HOME/.config/waybar/"
    ["config/cava/"]="$HOME/.config/cava/"
    ["config/ags/"]="$HOME/.config/ags/"
    ["config/fastfetch/"]="$HOME/.config/fastfetch/"
    ["config/wallust/"]="$HOME/.config/wallust/"
    ["config/wlogout/"]="$HOME/.config/wlogout/"
    # Add more directories to compare as needed
)

# Update the exclusion rules
declare -A exclusions=(
    ["config/hypr/"]="--exclude=UserConfigs/ --exclude=UserScripts/"
    ["config/waybar/"]="--exclude=config --exclude=style.css"
    ["config/rofi/"]="--exclude=.current_wallpaper"
    # Add more exclusions as needed
)

# Function to compare directories
compare_directories() {
    local source_dir="$1"
    local target_dir="$2"
    local exclusion="${exclusions[$source_dir]}"  # Get exclusions for the source directory

    # Perform dry-run comparison using rsync with exclusions
    diff=$(rsync -avn --delete "$source_dir" "$target_dir" $exclusion)
    echo "$diff"
}

# Function to create backup of target directory
create_backup() {
    local target_dir="$1"
    local backup_suffix="-b4-upgrade"
    local target_base=$(basename "$target_dir")
    local backup_dir="$HOME/.config/${target_base}${backup_suffix}"

    if [ -d "$backup_dir" ]; then
        echo "$NOTE Updating existing backup of the $target_dir..."
        rsync -av --delete "$target_dir" "$backup_dir"
        echo "$NOTE $backup_dir Backup updated successfully." 2>&1 | tee -a "$LOG"
    else
        echo "$NOTE Creating backup of the $target_dir..."
        rsync -av --exclude="${backup_suffix}" "$target_dir" "$backup_dir"/
        echo "$NOTE $backup_dir Backup created successfully." 2>&1 | tee -a "$LOG"
    fi
}

# Check if the version file exists in target directory, if not exit
target_version_file=$(find "$target_dir/hypr" -name 'v*' | sort -V | tail -n 1)
if [ -z "$target_version_file" ]; then
    echo "$ERROR Version number not found in ~/.config/hypr/" 2>&1 | tee -a "$LOG"
    echo "$ERROR Upgrade your dots first by running ./copy.sh" 2>&1 | tee -a "$LOG"
    exit 1
fi

# Get the stored version from the target directory
stored_version=$(basename "$target_version_file")

# Get the latest version from the source directory
source_version_file=$(find "$source_dir/hypr" -name 'v*' | sort -V | tail -n 1)
latest_version=$(basename "$source_version_file")

# Function to compare versions
version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

# Compare versions
if version_gt "$latest_version" "$stored_version"; then
    echo "$CAT newer version ($latest_version) is available. Do you want to upgrade? (Y/N)" 2>&1 | tee -a "$LOG"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        # Loop through directories for comparison
		for source_folder in "${!directories[@]}"; do
    	target_folder="${directories[$source_folder]}"
    	echo "$YELLOW Comparing directories: $source_folder and $target_folder" $RESET    
    	# Compare source and target folders
    	comparison=$(compare_directories "$source_folder" "$target_folder")
    	if [ -n "$comparison" ]; then
        echo "$NOTE Here are difference of $source_folder and $target_folder:"
        echo "$comparison"
        
        printf "\n%.0s" {1..2}
        
        # Prompt user for action
        echo "$CAT Do you want to copy files and folders from $source_folder to $target_folder? (Y/N)"
        read -r answer

        if [[ "$answer" =~ ^[Yy]$ ]]; then
            # Creating backup of the target folder
            create_backup "$target_folder"
            
            printf "\n%.0s" {1..2}
            # Copy differences from source folder to target folder
            rsync -av --delete ${exclusions[$source_folder]} "$source_folder" "$target_folder"
            echo "$NOTE Differences of "$target_folder" copied successfully." 2>&1 | tee -a "$LOG"
            printf "\n%.0s" {1..2}
        else
            	echo "$NOTE No changes were made for $target_folder" 2>&1 | tee -a "$LOG"
        	fi
    	else
        	echo "$OK No differences found between $source_folder and $target_folder" 2>&1 | tee -a "$LOG"
    	fi
		done
		printf "\n%.0s" {1..2}
        echo "$NOTE Files or Folders updated successfully to version $latest_version" 2>&1 | tee -a "$LOG"

        # Set some files as executable
        chmod +x "$HOME/.config/hypr/scripts/"* 2>&1 | tee -a "$LOG"
        chmod +x "$HOME/.config/hypr/UserScripts/"* 2>&1 | tee -a "$LOG"
        # Set executable for initial-boot.sh
        chmod +x "$HOME/.config/hypr/initial-boot.sh" 2>&1 | tee -a "$LOG"		
    else
        echo "$MAGENTA Upgrade declined. No files or folders changed" 2>&1 | tee -a "$LOG"
    fi
else
    echo "$OK 👌 No upgrade found. The installed version ${MAGENTA}($stored_version)${RESET} is up to date with the KooL Hyprland-Dots version ${YELLOW}($latest_version)${RESET}" 2>&1 | tee -a "$LOG"
fi

printf "\n%.0s" {1..3}
echo "$(tput bold)$(tput setaf 3)ATTENTION!!!! VERY IMPORTANT NOTICE!!!! $(tput sgr0)" 
echo "$(tput bold)$(tput setaf 7)If you updated waybar folder, and you have your own waybar layout and styles $(tput sgr0)"
echo "$(tput bold)$(tput setaf 7)Copy those files from the created backup ~/.config/waybar-b4-upgrade $(tput sgr0)"
echo "$(tput bold)$(tput setaf 7)Make sure to set your waybar and style before logout or reboot $(tput sgr0)"
echo "$(tput bold)$(tput setaf 7)SUPER CTRL B for Waybar Styles and SUPER ALT B for Waybar Layout $(tput sgr0)"
printf "\n%.0s" {1..3}
