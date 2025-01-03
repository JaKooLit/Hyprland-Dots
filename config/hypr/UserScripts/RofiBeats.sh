##!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
## For Rofi Beats to play online Music or Locally save media files
#
## Directory local music folder
#mDIR="$HOME/Música/"
#
## Directory for icons
#iDIR="$HOME/.config/swaync/icons"
#
## Online Stations. Edit as required
#declare -A online_music=(
##  ["Radio - Lofi Girl 🎧🎶"]="https://play.streamafrica.net/lofiradio"
##  ["Radio - Chillhop 🎧🎶"]="http://stream.zeno.fm/fyn8eh3h5f8uv"
##  ["FM - Easy Rock 96.3 📻🎶"]="https://radio-stations-philippines.com/easy-rock"
##  ["FM - Love Radio 90.7 📻🎶"]="https://radio-stations-philippines.com/love"
##  ["FM - WRock - CEBU 96.3 📻🎶"]="https://onlineradio.ph/126-96-3-wrock.html"
##  ["FM - Fresh Philippines 📻🎶"]="https://onlineradio.ph/553-fresh-fm.html"
##  ["YT - Wish 107.5 YT Pinoy HipHop 📻🎶"]="https://youtube.com/playlist?list=PLkrzfEDjeYJnmgMYwCKid4XIFqUKBVWEs&si=vahW_noh4UDJ5d37"
##  ["YT - Top Youtube Music 2023 📹🎶"]="https://youtube.com/playlist?list=PLDIoUOhQQPlXr63I_vwF9GD8sAKh77dWU&si=y7qNeEVFNgA-XxKy"
##  ["YT - Wish 107.5 YT Wishclusives 📹🎶"]="https://youtube.com/playlist?list=PLkrzfEDjeYJn5B22H9HOWP3Kxxs-DkPSM&si=d_Ld2OKhGvpH48WO"
##  ["YT - Relaxing Music 📹🎶"]="https://youtube.com/playlist?list=PLMIbmfP_9vb8BCxRoraJpoo4q1yMFg4CE"
##  ["YT - Youtube Remix 📹🎶"]="https://youtube.com/playlist?list=PLeqTkIUlrZXlSNn3tcXAa-zbo95j0iN-0"
##  ["YT - Korean Drama OST 📹🎶"]="https://youtube.com/playlist?list=PLUge_o9AIFp4HuA-A3e3ZqENh63LuRRlQ"
##  ["YT - AfroBeatz 2024 📹🎶"]="https://www.youtube.com/watch?v=7uB-Eh9XVZQ"
##  ["YT - Relaxing Piano Jazz Music 🎹🎶"]="https://youtu.be/85UEqRat6E4?si=jXQL1Yp2VP_G6NSn"
#)
#
## Populate local_music array with files from music directory and subdirectories
#populate_local_music() {
#  local_music=()
#  filenames=()
#  while IFS= read -r file; do
#    local_music+=("$file")
#    filenames+=("$(basename "$file")")
#  done < <(find "$mDIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.mp4" \))
#}
#
## Function for displaying notifications
#notification() {
#  notify-send -u normal -i "$iDIR/music.png" "Playing: $@"
#}
#
## Main function for playing local music
#play_local_music() {
#  populate_local_music
#
#  # Prompt the user to select a song
#  choice=$(printf "%s\n" "${filenames[@]}" | rofi -i -dmenu -config ~/.config/rofi/config-rofi-Beats.rasi -p "Local Music")
#
#  if [ -z "$choice" ]; then
#    exit 1
#  fi
#
#  # Find the corresponding file path based on user's choice and set that to play the song then continue on the list
#  for (( i=0; i<"${#filenames[@]}"; ++i )); do
#    if [ "${filenames[$i]}" = "$choice" ]; then
#		
#	    notification "$choice"
#
#      # Play the selected local music file using mpv
#      mpv --playlist-start="$i" --loop-playlist --vid=no  "${local_music[@]}"
#
#      break
#    fi
#  done
#}
#
## Main function for shuffling local music
shuffle_local_music() {
  notification "Shuffle local music"
  Play music in $mDIR on shuffle
  mpv --shuffle --loop-playlist --vid=no "$mDIR"
}

##Mostrar las opciones del menu de música
#control_choice=
#
#
## Main function for playing online music
#play_online_music() {
#  choice=$(printf "%s\n" "${!online_music[@]}" | rofi -i -dmenu -config ~/.config/rofi/config-rofi-Beats.rasi -p "Online Music")
#
#  if [ -z "$choice" ]; then
#    exit 1
#  fi
#
#  link="${online_music[$choice]}"
#
#  notification "$choice"
#  
#  # Play the selected online music using mpv
#  mpv --shuffle --vid=no "$link"
#}
#
## Check if an online music process is running and send a notification, otherwise run the main function
#pkill mpv && notify-send -u low -i "$iDIR/music.png" "Music stopped" || {
#
## Prompt the user to choose between local and online music
#user_choice=$(printf "Play from Online Stations\nPlay from Music Folder\nShuffle Play from Music Folder" | rofi -dmenu -config ~/.config/rofi/config-rofi-Beats-menu.rasi -p "Select music source")
#
#  case "$user_choice" in
#    "Play from Music Folder")
#      play_local_music
#      ;;
#    "Play from Online Stations")
#      play_online_music
#      ;;
#    "Shuffle Play from Music Folder")
#      shuffle_local_music
#      ;;
#    *)
#      echo "Invalid choice"
#      ;;
#  esac
#}

#Arriba esta el antiguo archivo

#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For Rofi Beats to play online Music or Locally save media files

# Directorio local de música
mDIR="$HOME/Música"

# Directorio para iconos
iDIR="$HOME/.config/swaync/icons"

# Estaciones en línea. Edita según sea necesario
declare -A online_music=(
  ["Mi Música - YT 🎧🎶"]="https://www.youtube.com/playlist?list=PLeqcVFKSqY8-0_y5uEUnmF4Ypwyq7agXX"
  ["80s Hits"]="https://www.youtube.com/playlist?list=PLmXxqSJJq-yXrCPGIT2gn8b34JjOrl4Xf"
  ["All time hits"]="https://www.youtube.com/playlist?list=PLmXxqSJJq-yXrCPGIT2gn8b34JjOrl4Xf"
  ["Ultimate gaming music"]="https://www.youtube.com/playlist?list=PL37UZ2QfPUvz3k5mZNFZmjhLNTT-M5-Oa"
  ["Lofi Girl"]="https://www.youtube.com/watch?v=jfKfPfyJRdk"
  ["Lofi Girl Sleep/Chill Music"]="https://www.youtube.com/watch?v=28KRPhVzCus"
  ["The Fat Rat Songs"]="https://www.youtube.com/watch?v=jXkroZadSMA&list=PL37UZ2QfPUvwZOg7P6Jt7s1or0uFINQjc"
  ["YT - Top Youtube Music 2024 📹🎶"]="https://youtube.com/playlist?list=PLDIoUOhQQPlXr63I_vwF9GD8sAKh77dWU&si=y7qNeEVFNgA-XxKy"
  ["YT - Relaxing Music 📹🎶"]="https://youtube.com/playlist?list=PLMIbmfP_9vb8BCxRoraJpoo4q1yMFg4CE"

)

# Función para mostrar notificaciones
notification() {
  notify-send -u normal -i "$iDIR/music.png" "Reproduciendo: $@"
}

# Verificar si mpv está reproduciendo música
is_playing() {
  pgrep -x "mpv" > /dev/null
}

# Mostrar opciones de control de música
music_control_menu() {
  control_choice=$(printf "Pausar\nReanudar\nDetener" | rofi -dmenu -config ~/.config/rofi/config-rofi-Beats-menu.rasi -p "Control de Música")
  case "$control_choice" in
    "Pausar")
      playerctl pause
      notify-send -u low -i "$iDIR/music.png" "Música pausada"
      ;;
    "Reanudar")
      playerctl play
      notify-send -u low -i "$iDIR/music.png" "Música reanudada"
      ;;
    "Detener")
      playerctl stop
      notify-send -u low -i "$iDIR/music.png" "Música detenida"
      ;;
    *)
      echo "Opción no válida"
      ;;
  esac
}

# Función principal para reproducir música local
play_local_music() {
  local_music=()
  filenames=()
  
  while IFS= read -r file; do
    local_music+=("$file")
    filenames+=("$(basename "$file")")
  done < <(find "$mDIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.mp4" \))

  # Preguntar al usuario qué canción seleccionar
  choice=$(printf "%s\n" "${filenames[@]}" | rofi -i -dmenu -config ~/.config/rofi/config-rofi-Beats.rasi -p "Música Local")

  if [ -z "$choice" ]; then
    exit 1
  fi

  # Encontrar la ruta del archivo basado en la elección del usuario
  for (( i=0; i<"${#filenames[@]}"; ++i )); do
    if [ "${filenames[$i]}" = "$choice" ]; then
      notification "$choice"
      # Reproducir la canción seleccionada usando mpv
      mpv --input-ipc-server=/tmp/mpvsocket --playlist-start="$i" --loop-playlist --vid=no "${local_music[@]}"
      break
    fi
  done
}

# Función principal para reproducir música en línea
play_online_music() {
  choice=$(printf "%s\n" "${!online_music[@]}" | rofi -i -dmenu -config ~/.config/rofi/config-rofi-Beats.rasi -p "Música en Línea")

  if [ -z "$choice" ]; then
    exit 1
  fi

  link="${online_music[$choice]}"

  notification "$choice"
  # Reproducir la música en línea seleccionada usando mpv
  mpv --input-ipc-server=/tmp/mpvsocket --vid=no "$link"
}

descargar_cancion_YT() {
  cd ~/.config/hypr/UserScripts
  url=$(zenity --entry --title="Introduce el URL" --text="Por favor, introduce el URL del video a descargar:")
  ./DescargarYtArg.sh -a "$url"
}

# Comprobar si hay un proceso de música en ejecución
if is_playing; then
  music_control_menu
else
  # Mostrar menú para elegir entre música local o en línea
  user_choice=$(printf "Reproducir música online\nReproducir música desde la carpeta música\nShuffle de la carpeta música\nDescargar una canción de YT" | rofi -dmenu -config ~/.config/rofi/config-rofi-Beats-menu.rasi -p "Selecciona desde donde reproducir")

  case "$user_choice" in
    "Reproducir música desde la carpeta música")
      play_local_music
      ;;
    "Reproducir música online")
      play_online_music
      ;;
    "Shuffle de la carpeta música")
      # Implementar función shuffle aquí si es necesario
      shuffle_local_music
      ;;
    "Descargar una canción de YT")
      descargar_cancion_YT
      ;;
    *)
      echo "Opción no válida"
      ;;
  esac
fi

