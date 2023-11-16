#!/bin/bash

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
WARN="$(tput setaf 166)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
ORANGE=$(tput setaf 166)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

printf "${NOTE} Checking for existing Hyprland-Dots.tar.gz...\n"

# Check if Hyprland-Dots.tar.gz exists
if [ -f Hyprland-Dots.tar.gz ]; then
  printf "${NOTE} Hyprland-Dots.tar.gz found.\n"

  # Get the version from the existing tarball filename
  existing_version=$(echo Hyprland-Dots.tar.gz | grep -oP 'v\d+\.\d+\.\d+' | sed 's/v//')

  # Fetch the tag_name for the latest release using the GitHub API
  latest_version=$(curl -s https://api.github.com/repos/JaKooLit/Hyprland-Dots/releases/latest | grep "tag_name" | cut -d '"' -f 4 | sed 's/v//')

  # Check if versions match
  if [ "$existing_version" = "$latest_version" ]; then
    echo -e "${OK} Hyprland-Dots.tar.gz is up-to-date with the latest release ($latest_version)."
    
    # Sleep for 10 seconds before exiting
    printf "${NOTE} No update found. Sleeping for 10 seconds...\n"
    sleep 10
    exit 0
  else
    echo -e "${WARN} Hyprland-Dots.tar.gz is outdated (Existing version: $existing_version, Latest version: $latest_version)."
    read -p "Do you want to upgrade to the latest version? (y/n): " upgrade_choice
    if [ "$upgrade_choice" = "y" ]; then
      echo -e "${NOTE} Proceeding to download the latest release."
      rm -f Hyprland-Dots.tar.gz
      printf "${WARN} Removed existing Hyprland-Dots.tar.gz.\n"
    else
      echo -e "${NOTE} User chose not to upgrade. Exiting..."
      exit 0
    fi
  fi
fi

printf "${NOTE} Downloading the latest Hyprland source code release...\n"

# Fetch the tarball URL for the latest release using the GitHub API
latest_tarball_url=$(curl -s https://api.github.com/repos/JaKooLit/Hyprland-Dots/releases/latest | grep "tarball_url" | cut -d '"' -f 4)

# Check if the URL is obtained successfully
if [ -z "$latest_tarball_url" ]; then
  echo -e "${ERROR} Unable to fetch the tarball URL for the latest release."
  exit 1
fi

# Extract the direct download URL from the tarball URL
download_url=$(echo "$latest_tarball_url" | sed 's/{\/tarball\/.*}//')

# Get the filename from the URL
file_name=$(basename "$download_url")

# Download the latest release source code tarball to the current directory
if curl -LOk "$download_url"; then
  mv "$file_name" Hyprland-Dots.tar.gz  # Rename the downloaded file if needed

  # Extract the contents of the tarball
  tar -xzf Hyprland-Dots.tar.gz

  # Rename the extracted directory to JaKooLit-Hyprland-Dots
  mv JaKooLit-Hyprland-Dots-* JaKooLit-Hyprland-Dots

  cd "JaKooLit-Hyprland-Dots" || exit 1

  # Set execute permission for copy.sh and execute it
  chmod +x copy.sh
  ./copy.sh 2>&1 | tee -a "../install-$(date +'%d-%H%M%S')_dots.log"

  echo -e "${OK} Latest source code release downloaded, extracted, and processed successfully."
else
  echo -e "${ERROR} Failed to download the latest source code release."
  exit 1
fi
