#!/usr/bin/env bash
#
while [[ true ]]; do
	result=$(
		cliphist list | rofi -dmenu \
			-kb-custom-1 "Control-Delete" \
			-config ~/.config/rofi/config-long.rasi
	)
	exit_state=$?
	if [[ $exit_state -eq 1 ]]; then
		exit
	fi
	case "$exit_state" in
	0)
		cliphist decode <<<$result | wl-copy
		exit
		;;
	10)
		cliphist delete <<<$result
		;;
	esac
done
