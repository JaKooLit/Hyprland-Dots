#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# For Hyprlock
#pidof hyprlock || hyprlock -q 

# Ensure weather cache is up-to-date before locking (Waybar/lockscreen readers)
bash "$HOME/.secret/Hyprland-Dots/config/hypr/UserScripts/weatherWrap.sh" >/dev/null 2>&1

loginctl lock-session