#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Changing fan profiles on Asus laptops

notif="$HOME/.config/swaync/images/bell.png"

asusctl profile -n
msg=$(asusctl profile -p)
notify-send -u low -i "$notif" "$msg"
