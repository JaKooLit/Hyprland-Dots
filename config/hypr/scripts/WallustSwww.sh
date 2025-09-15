#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Wallust Colors for current wallpaper

# Define the path to the swww cache directory
cache_dir="$HOME/.cache/swww/"

# Get a list of monitor outputs
monitor_outputs=($(ls "$cache_dir"))

# Initialize a flag to determine if the ln command was executed
ln_success=false

# Get current focused monitor
current_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')
echo $current_monitor
# Construct the full path to the cache file
cache_file="$cache_dir$current_monitor"
echo $cache_file
# Check if the cache file exists for the current monitor output
if [ -f "$cache_file" ]; then
  # Get the wallpaper path from the cache file
  wallpaper_path=$(grep -v 'Lanczos3' "$cache_file" | head -n 1)
  # Fallback: If the specified wallpaper path doesn't point to a valid file,
  # it likely means the cache file is in a binary format. As a workaround,
  # try extracting readable strings from the cache and use the first relevant line as the wallpaper path.
  if [[ ! -f "$wallpaper_path" ]]; then
    echo "[WARN] Binary file format detected, attempting to parse strings..."
    wallpaper_path=$(strings "$cache_file" | grep -v 'Lanczos3' | head -n 1)
  fi
  echo $wallpaper_path
  # symlink the wallpaper to the location Rofi can access
  if ln -sf "$wallpaper_path" "$HOME/.config/rofi/.current_wallpaper"; then
    ln_success=true # Set the flag to true upon successful execution
  fi
  # copy the wallpaper for wallpaper effects
  cp -r "$wallpaper_path" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
fi

# Check the flag before executing further commands
if [ "$ln_success" = true ]; then
  # execute wallust
  echo 'about to execute wallust'
  # execute wallust skipping tty and terminal changes
  wallust run "$wallpaper_path" -s &
fi
