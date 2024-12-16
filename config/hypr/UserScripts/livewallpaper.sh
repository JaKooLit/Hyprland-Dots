#!/bin/bash

# Log output to a file
exec >>~/script_log.txt 2>&1
echo "Script run at: $(date)"

# Define paths for the default wallpaper and the video
DEFAULT_WALLPAPER="$HOME/.config/rofi/.current_wallpaper"
VIDEO_PATH="$HOME/Pictures/wallpapers/livewallpaper/catgirl.mp4"

# Function to restore the wallpaper
restore_wallpaper() {
  echo "Restoring normal wallpaper..."
  swww-daemon &
  swww img "$DEFAULT_WALLPAPER"
}

# Check if mpvpaper is already running
if pgrep mpvpaper >/dev/null; then
  echo "mpvpaper is running. Stopping mpvpaper and restoring normal wallpaper..."

  # Kill mpvpaper forcefully
  pkill -9 mpvpaper
  sleep 1 # Wait for a second to ensure it has stopped
  restore_wallpaper

else
  echo "mpvpaper is not running. Stopping swww-daemon if it's running..."

  # Stop swww-daemon if running
  if pgrep swww-daemon >/dev/null; then
    echo "Stopping swww-daemon..."
    pkill -9 swww-daemon
    sleep 1 # Wait for a second to ensure it has stopped
  else
    echo "swww-daemon is not running."
  fi

  # Check if the video file exists before trying to run mpvpaper
  if [[ -f "$VIDEO_PATH" ]]; then
    # Run mpvpaper in the background without hardware acceleration
    echo "Running mpvpaper without hardware acceleration..."
    mpvpaper -o "--no-config --hwdec=no --loop-playlist" '*' "$VIDEO_PATH" & # Add & to run it in the background
  else
    echo "Error: Video file does not exist at $VIDEO_PATH."
  fi
fi
