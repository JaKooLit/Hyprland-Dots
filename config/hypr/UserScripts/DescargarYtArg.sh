#!/bin/bash

# Verifica si yt-dlp está instalado
if ! command -v yt-dlp &> /dev/null; then
    zennity --warning --text="yt-dlp no está instalado. Por favor, instálalo e intenta nuevamente." --timeout=5
    exit 1
fi

# Define las carpetas de destino usando xdg-user-dir
CARPETA_VIDEOS=$(xdg-user-dir VIDEOS)
CARPETA_MUSICA=$(xdg-user-dir MUSIC)
CARPETA_DESCARGAS_VIDEO="$CARPETA_VIDEOS/Descargas"

# Crea las carpetas si no existen
mkdir -p "$CARPETA_DESCARGAS_VIDEO"
mkdir -p "$CARPETA_MUSICA"

# Valida que se hayan pasado al menos dos argumentos
if [[ $# -lt 2 ]]; then
    echo "Uso: $0 -a|-v <URL>"
    echo "  -a  Descarga audio en formato MP3"
    echo "  -v  Descarga video en formato MP4"
    exit 1
fi

# Obtén la opción (-a o -v) y el URL
format_choice="$1"
video_url="$2"

# Valida que el usuario haya ingresado un URL
if [[ -z "$video_url" ]]; then
    zennity --warning --text="No ingresaste un URL válido. Saliendo..." --timeout=5
    exit 1
fi

# Procesa la opción elegida
case "$format_choice" in
    -v)
        echo "Descargando el mejor formato en MP4..."
        yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" -o "$CARPETA_DESCARGAS_VIDEO/%(title)s.%(ext)s" "$video_url"
        if [[ $? -eq 0 ]]; then
            echo "Descarga en MP4 completada con éxito. Guardado en: $CARPETA_DESCARGAS_VIDEO"
        else
            echo "Ocurrió un error durante la descarga en MP4."
        fi
        ;;
    -a)
        echo "Descargando y convirtiendo a MP3..."
        
        # Cambiar al directorio de música
        cd "$CARPETA_MUSICA" || { echo "No se pudo cambiar al directorio de música. Saliendo..."; exit 1; }

        # Descargar la miniatura como portada
        yt-dlp --skip-download --write-thumbnail -o "temp.%(ext)s" "$video_url"

        # Convertir la miniatura a jpg
        dwebp temp.webp -o temp.jpg

        # Descargar el archivo MP3
        yt-dlp -f "bestaudio" --extract-audio --audio-format mp3 -o "$CARPETA_MUSICA/temp.mp3" "$video_url"
        original=$(yt-dlp --get-title "$video_url")

        ffmpeg -i temp.mp3 -i temp.jpg -map 0 -map 1 -c copy -id3v2_version 3 "${original}.mp3"

        # Eliminar archivos temporales
        rm temp.jpg temp.mp3 temp.webp

        if [[ $? -eq 0 ]]; then
            zennity --info --text="Descarga en MP3 completada con éxito. Guardado en: $CARPETA_MUSICA" --timeout=5
        else
            echo "Ocurrió un error durante la descarga en MP3."
        fi
        ;;
    *)
        echo "Opción no válida. Usa -a para audio o -v para video."
        exit 1
        ;;
esac
