#!/usr/bin/env bash
# USAGE:
# 1) Run from terminal:
#    ./dispatch.sh <application_command> <target_workspace_number>
#    Example:
#    ./dispatch.sh discord 2
#
# 2) Call from Hyprland config (in hyprland.conf file):
#    exec-once = /path/to/dispatch.sh <application_command> <target_workspace_number>
#
# Logs are saved in dispatch.log file next to the script.
# If the window doesn't appear or is dispatched incorrectly — info will be there.
#
# Notes:
# - Script waits about ~9 seconds (30 iterations of 0.3 sec) for window to appear.
# - Uses hyprctl and jq, so these tools must be installed.

LOGFILE="$(dirname "$0")/dispatch.log"
# Log file path located next to the script.

APP=$1
# The application command or window class to launch or match.

TARGET_WORKSPACE=$2
# The target workspace number where the window should be moved.

# Check if required arguments are provided.
if [[ -z "$APP" || -z "$TARGET_WORKSPACE" ]]; then
  echo "Usage: $0 <application_command> <target_workspace_number>" >>"$LOGFILE" 2>&1
  exit 1
fi

echo "Starting dispatch of '$APP' to workspace $TARGET_WORKSPACE at $(date)" >>"$LOGFILE"
# Starting the dispatch process and logging the event.
# Avoid early workspace focus issues by switching workspace first.
hyprctl dispatch workspace "$TARGET_WORKSPACE" >>"$LOGFILE" 2>&1
sleep 0.4

# Launch the application in the background and disown it.
$APP &
disown
pid=$!

echo "Launched '$APP' with PID $pid" >>"$LOGFILE"
# Log the launched process ID.
# Wait for the application window to appear (matching window class).
for i in {1..30}; do
  win=$(hyprctl clients -j | jq -r --arg APP "$APP" '
        .[] | select(.class | test($APP;"i")) | .address' 2>>"$LOGFILE")

  if [[ -n "$win" ]]; then
    echo "Found window $win for app '$APP', moving to workspace $TARGET_WORKSPACE" >>"$LOGFILE"
    # Move the window to the target workspace.
    hyprctl dispatch movetoworkspace "$TARGET_WORKSPACE,address:$win" >>"$LOGFILE" 2>&1
    exit 0
  fi
  sleep 0.3
done

echo "ERROR: Window for '$APP' was NOT found or dispatched properly to workspace $TARGET_WORKSPACE at $(date)" >>"$LOGFILE"
# Log error if window was not found or dispatched correctly.
exit 1
