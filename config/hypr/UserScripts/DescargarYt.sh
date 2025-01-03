#!/bin/bash

# Verifica si yt-dlp está instalado
if ! command -v yt-dlp &> /dev/null
then
    echo "yt-dlp no está instalado. Por favor, instálalo e intenta nuevamente."
    exit 1
fi

# Define las carpetas de destino usando xdg-user-dir
CARPETA_VIDEOS=$(xdg-user-dir VIDEOS)
CARPETA_MUSICA=$(xdg-user-dir MUSIC)

# Define subcarpeta específica para descargas de video
CARPETA_DESCARGAS_VIDEO="$CARPETA_VIDEOS/Descargas"

# Crea las carpetas si no existen
mkdir -p "$CARPETA_DESCARGAS_VIDEO"
mkdir -p "$CARPETA_MUSICA"

# Pide al usuario un URL
read -p "Por favor, introduce el URL del video: " video_url

# Valida que el usuario haya ingresado un URL
if [[ -z "$video_url" ]]; then
    echo "No ingresaste un URL. Saliendo..."
    exit 1
fi

# Pregunta al usuario si desea MP4 o MP3
read -p "¿Deseas descargar en MP4 (video) o MP3 (audio)? Escribe 'mp4' o 'mp3': " format_choice

# Valida la elección del usuario y ejecuta yt-dlp con las opciones adecuadas
if [[ "$format_choice" == "mp4" ]]; then
    echo "Descargando el mejor formato en MP4..."
    yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" -o "$CARPETA_DESCARGAS_VIDEO/%(title)s.%(ext)s" "$video_url"
    if [[ $? -eq 0 ]]; then
        echo "Descarga en MP4 completada con éxito. Guardado en: $CARPETA_DESCARGAS_VIDEO"
    else
        echo "Ocurrió un error durante la descarga en MP4."
    fi
elif [[ "$format_choice" == "mp3" ]]; then
    echo "Descargando y convirtiendo a MP3..."

    #Cambiar al directorio de música
	cd "$CARPETA_MUSICA" || { echo "No se pudo cambiar al directorio de música. Saliendo..."; exit 1; }

	#Descargar la miniatura como portada
    yt-dlp --skip-download --write-thumbnail -o "temp.%(ext)s" "$video_url"

    #Convertir la miniatura a jpg
    dwebp temp.webp -o temp.jpg

    #Descargar el archivo mp3
    yt-dlp -f "bestaudio" --extract-audio --audio-format mp3 -o "$CARPETA_MUSICA/temp" "$video_url"
    original=$(yt-dlp --get-title "$video_url")

    ffmpeg -i temp.mp3 -i temp.jpg -map 0 -map 1 -c copy -id3v2_version 3 "${original}.mp3"

    #Eliminar archivos temporales
    rm temp.jpg rm temp.mp3 rm temp.webp

    if [[ $? -eq 0 ]]; then
        echo "Descarga en MP3 completada con éxito. Guardado en: $CARPETA_MUSICA"
    else
        echo "Ocurrió un error durante la descarga en MP3."
    fi
else
    echo "Opción no válida. Saliendo..."
    exit 1
fi

