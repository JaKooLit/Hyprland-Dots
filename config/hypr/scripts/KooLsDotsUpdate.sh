#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# simple bash script to check if KooL Hyprland Dots update is available by comparing local version and github version
# it utilizes curl and also has a default time of 60s if users dont do anything
# will only ran once you logged into your system. It will not continously pinging the KooL github

# Local Paths
local_dir="$HOME/.config/hypr"
iDIR="$HOME/.config/swaync/images/ja.png"
local_version=$(ls $local_dir/v* 2>/dev/null | sort -V | tail -n 1 | sed 's/.*v\(.*\)/\1/')
notification_timeout="60s"
KooL_Dots_DIR="$HOME/Hyprland-Dots"

# exit if cannot find local version
if [ -z "$local_version" ]; then
  exit 1
fi

# KooL's Dots GitHub URL 
branch="main"
github_url="https://github.com/JaKooLit/Hyprland-Dots/tree/$branch/config/hypr/"

# Fetch the latest version from GitHub directly
github_version=$(curl -s $github_url | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | sort -V | tail -n 1 | sed 's/v//')

# Exit if we can't find the GitHub version
if [ -z "$github_version" ]; then
  exit 1
fi

# Compare the local version with the GitHub version
if [ "$(echo -e "$github_version\n$local_version" | sort -V | tail -n 1)" = "$github_version" ]; then
  notify_cmd_base="notify-send -t 10000 -A action1=Update -A action2=NO -h string:x-canonical-private-synchronous:shot-notify"
  notify_cmd_shot="${notify_cmd_base} -i $iDIR"

  response=$(timeout $notification_timeout $notify_cmd_shot "KooL Hyprland" "Update available! Update now?")
  # exit when timeout reached
  if [ $? -eq 124 ]; then
    exit 0
  fi

  case "$response" in
    "action1")  
      if [ -d $KooL_Dots_DIR ]; then
        kitty -e bash -c "
          cd $KooL_Dots_DIR &&
          git stash &&
          git pull &&
          ./copy.sh
        "
      else
        kitty -e bash -c "
          git clone --depth=1 https://github.com/JaKooLit/Hyprland-Dots.git $KooL_Dots_DIR &&
          cd $KooL_Dots_DIR &&
          chmod +x copy.sh &&
          ./copy.sh
        "
      fi
      ;;
    "action2")
      exit 0
      ;;
  esac
else
  exit 0
fi
