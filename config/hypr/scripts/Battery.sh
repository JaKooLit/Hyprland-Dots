#!/bin/bash

for i in {0..3}; do
  if [ -f /sys/class/power_supply/BAT$i/capacity ]; then
    battery_level=$(cat /sys/class/power_supply/BAT$i/status)
    battery_capacity=$(cat /sys/class/power_supply/BAT$i/capacity)
    echo "Battery: $battery_capacity% ($battery_level)"
  fi
done
