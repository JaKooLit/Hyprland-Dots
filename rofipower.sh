#!/usr/bin/env bash

# Swayconfig
SWAYCONFIG="$HOME/.config/swaylock/config"

# CMDs
uptime="`uptime -p | sed -e 's/up //g'`"
host=`hostnamectl hostname`

# Options
shutdown=''
reboot=''
lock=''
suspend=''
logout=''

# Rofi CMD
rofi_cmd() {
	rofi -dmenu -p " $USER@$host" -mesg " Uptime: $uptime" -theme ~/.config/rofi/config-powermenu.rasi
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\0meta\x1fl\n$suspend\0meta\x1fu\n$logout\0meta\x1fe\n$reboot\0meta\x1fr\n$shutdown\0meta\x1fs" | rofi_cmd
}

# Execute Command
run_cmd() {
	if [[ $1 == '--shutdown' ]]; then
		systemctl poweroff
	elif [[ $1 == '--reboot' ]]; then
		systemctl reboot
	elif [[ $1 == '--suspend' ]]; then
		systemctl suspend
	elif [[ $1 == '--logout' ]]; then
		hyprctl dispatch exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    $shutdown)
		run_cmd --shutdown
        ;;
    $reboot)
		run_cmd --reboot
        ;;
    $hibernate)
		run_cmd --hibernate
        ;;
    $lock)
        sleep 0.5s; swaylock --config ${SWAYCONFIG} & disown
        ;;
    $suspend)
		run_cmd --suspend
        ;;
    $logout)
		run_cmd --logout
        ;;
esac