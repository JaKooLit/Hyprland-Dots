#!/bin/bash

STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [ "${STATE}" == "2" ]; then
  hyprctl keyword decoration:blur:size 3
	hyprctl keyword decoration:blur:passes 1
  notify-send "Less blur"
else
  hyprctl keyword decoration:blur:size 7.8
	hyprctl keyword decoration:blur:passes 2
  notify-send "Normal blur"
fi
