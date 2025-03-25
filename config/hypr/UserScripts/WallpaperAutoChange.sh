#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# source https://wiki.archlinux.org/title/Hyprland#Using_a_script_to_change_wallpaper_every_X_minutes

# This script will randomly go through the files of a directory, setting it
# up as the wallpaper at regular intervals
#
# NOTE: this script uses bash (not POSIX shell) for the RANDOM variable

wallust_refresh=$HOME/.config/hypr/scripts/RefreshNoWaybar.sh

monitors=$(hyprctl monitors | awk '/^Monitor/{print $2}')

focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

if [[ $# -lt 1 ]] || [[ ! -d $1   ]]; then
	echo "Usage:
	$0 <dir containing images>"
	exit 1
fi

# Edit below to control the images transition
export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_TYPE=simple

# This controls (in seconds) when to switch to the next image
INTERVAL=900

while true; do
    while IFS= read -r focused_monitor; do
		random_file=$(find $1 -type f | shuf -n 1)
		echo "$random_file"
		swww img -o $focused_monitor "$random_file"
		$wallust_refresh
		# find "$1" \
		# 	| while read -r img; do
		# 		echo "$((RANDOM % 1000)):$img"
		# 	done \
		# 	| sort -n | cut -d':' -f2- \
		# 	| while read -r img; do
		 		
		# 		echo "$img"
		# 	done
		echo "$focused_monitor"
	done <<< "$monitors"
	sleep $INTERVAL
done
