#!/bin/bash
## Files

iDIR="$HOME/.config/dunst/icons"

notification(){
  notify-send -h string:x-canonical-private-synchronous:sys-notify -u normal -i "$iDIR/music.png" "Playing now: " "$@" 
}

menu(){
printf "1. Lofi Girl\n"
printf "2. 96.3 Easy Rock - FM Radio\n"
printf "3. Ghibli Music (Instrumental)\n"
printf "4. Top Youtube Music 2023\n"
printf "5. Chillhop\n"
printf "6. SmoothChill\n"
printf "7. Relaxing Music\n"
printf "8. Youtube Remix\n"
printf "9. Korean Drama OST"
}
main() {
choice=$(menu | rofi -dmenu -config ~/.config/rofi/config-rofi-Beats.rasi | cut -d. -f1)

case $choice in
1)
	notification "Lofi Girl ☕️🎶";
    mpv "https://play.streamafrica.net/lofiradio"
    return
    ;;
2)
   	notification "96.3 Easy Rock 📻🎶";
   	mpv "https://radio-stations-philippines.com/easy-rock"
   	return
	;; 
3)
  	notification "Ghibli Music 🎻🎶";
   	mpv --shuffle --vid=no "https://youtube.com/playlist?list=PLNi74S754EXbrzw-IzVhpeAaMISNrzfUy&si=rqnXCZU5xoFhxfOl"
   	return
   	;;
4)
   	notification "Top Youtube Music 2023 ☕️🎶";
   	mpv --shuffle --vid=no "https://youtube.com/playlist?list=PLDIoUOhQQPlXr63I_vwF9GD8sAKh77dWU&si=y7qNeEVFNgA-XxKy"
   	return
   	;;
5)
  	notification "Chillhop ☕️🎶";
  	mpv "http://stream.zeno.fm/fyn8eh3h5f8uv"
  	return
  	;;
6)
  	notification "SmoothChill ☕️🎶";
  	mpv "https://media-ssl.musicradio.com/SmoothChill"
  	return
  	;;
7)
  	notification "Relaxing Music ☕️🎶";
  	mpv --shuffle --vid=no "https://youtube.com/playlist?list=PLMIbmfP_9vb8BCxRoraJpoo4q1yMFg4CE"
  	return
	;;
8)
  	notification "Youtube Remix 📻🎶";
  	mpv --shuffle  --vid=no "https://youtube.com/playlist?list=PLeqTkIUlrZXlSNn3tcXAa-zbo95j0iN-0"
  	return
  	;;
9)
  	notification "Korean Drama OST 📻🎶";
  	mpv --shuffle  --vid=no "https://youtube.com/playlist?list=PLUge_o9AIFp4HuA-A3e3ZqENh63LuRRlQ"
  	return
	;;
esac
}

pkill -f http && notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i "$iDIR/music.png" "Online Music stopped" || main
