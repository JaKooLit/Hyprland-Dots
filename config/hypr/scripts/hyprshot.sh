#!/usr/bin/env bash

set -e

function Help() {
    cat <<EOF
Usage: hyprshot [options ..] [-m [mode] ..] -- [command]

Hyprshot is an utility to easily take screenshot in Hyprland using your mouse.

It allows taking screenshots of windows, regions and monitors which are saved to a folder of your choosing and copied to your clipboard.

Examples:
  capture a window                      \`hyprshot -m window\`
  capture active window to clipboard    \`hyprshot -m window -m active --clipboard-only\`
  capture selected monitor              \`hyprshot -m output -m DP-1\`

Options:
  -h, --help                show help message
  -m, --mode                one of: output, window, region, active, OUTPUT_NAME
  -o, --output-folder       directory in which to save screenshot
  -f, --filename            the file name of the resulting screenshot
  -D, --delay               how long to delay taking the screenshot after selection (seconds)
  -z, --freeze              freeze the screen on initialization
  -d, --debug               print debug information
  -s, --silent              don't send notification when screenshot is saved
  -r, --raw                 output raw image data to stdout
  -t, --notif-timeout       notification timeout in milliseconds (default 5000)
  --clipboard-only          copy screenshot to clipboard and don't save image in disk
  -- [command]              open screenshot with a command of your choosing. e.g. hyprshot -m window -- mirage

Modes:
  output        take screenshot of an entire monitor
  window        take screenshot of an open window
  region        take screenshot of selected region
  active        take screenshot of active window|output
                (you must use --mode again with the intended selection)
  OUTPUT_NAME   take screenshot of output with OUTPUT_NAME
                (you must use --mode again with the intended selection)
                (you can get this from \`hyprctl monitors\`)
EOF
}

function Print() {
    if [ $DEBUG -eq 0 ]; then
        return 0
    fi
    
    1>&2 printf "$@" 
}

function send_notification() {
    if [ $SILENT -eq 1 ]; then
        return 0
    fi

    local message=$([ $CLIPBOARD -eq 1 ] && \
        echo "Image copied to the clipboard" || \
        echo "Image saved in <i>${1}</i> and copied to the clipboard.")
    notify-send "Screenshot saved" \
                "${message}" \
                -t "$NOTIF_TIMEOUT" -i "${1}" -a Hyprshot
}

function trim() {
    Print "Geometry: %s\n" "${1}"
    local geometry="${1}"
    local xy_str=$(echo "${geometry}" | cut -d' ' -f1)
    local wh_str=$(echo "${geometry}" | cut -d' ' -f2)
    local x=`echo "${xy_str}" | cut -d',' -f1`
    local y=`echo "${xy_str}" | cut -d',' -f2`
    local width=`echo "${wh_str}" | cut -dx -f1`
    local height=`echo "${wh_str}" | cut -dx -f2`

    local max_width=`hyprctl monitors -j | jq -r '[.[] | if (.transform % 2 == 0) then (.x + .width) else (.x + .height) end] | max'`
    local max_height=`hyprctl monitors -j | jq -r '[.[] | if (.transform % 2 == 0) then (.y + .height) else (.y + .width) end] | max'`

    local min_x=`hyprctl monitors -j | jq -r '[.[] | (.x)] | min'`
    local min_y=`hyprctl monitors -j | jq -r '[.[] | (.y)] | min'`

    local cropped_x=$x
    local cropped_y=$y
    local cropped_width=$width
    local cropped_height=$height

    if ((x + width > max_width)); then
        cropped_width=$((max_width - x))
    fi
    if ((y + height > max_height)); then
        cropped_height=$((max_height - y))
    fi

    if ((x < min_x)); then
        cropped_x="$min_x"
        cropped_width=$((cropped_width + x - min_x))
    fi
    if ((y < min_y)); then
        cropped_y="$min_y"
        cropped_height=$((cropped_height + y - min_y))
    fi

    local cropped=`printf "%s,%s %sx%s\n" \
        "${cropped_x}" "${cropped_y}" \
        "${cropped_width}" "${cropped_height}"`
    Print "Crop: %s\n" "${cropped}"
    echo ${cropped}
}

function save_geometry() {
    local geometry="${1}"
    local output=""

    if [ $RAW -eq 1 ]; then
        grim -g "${geometry}" -
        return 0
    fi

    if [ $CLIPBOARD -eq 0 ]; then
        mkdir -p "$SAVEDIR"
        grim -g "${geometry}" "$SAVE_FULLPATH"
        output="$SAVE_FULLPATH"
        wl-copy --type image/png < "$output"
        [ -z "$COMMAND" ] || {
            "$COMMAND" "$output"
        }
    else
        wl-copy --type image/png < <(grim -g "${geometry}" -)
    fi

    send_notification $output
}

function checkRunning() {
    sleep 1
    while [[ 1 == 1 ]]; do
        if [[ $(pgrep slurp | wc -m) == 0 ]]; then
            pkill hyprpicker
            exit
        fi
    done
}

function begin_grab() {
    if [ $FREEZE -eq 1 ] && [ "$(command -v "hyprpicker")" ] >/dev/null 2>&1; then
        hyprpicker -r -z &
        sleep 0.2
        HYPRPICKER_PID=$!
    fi
    local option=$1
    case $option in
        output)
            if [ $CURRENT -eq 1 ]; then
                local geometry=`grab_active_output`
            elif [ -z $SELECTED_MONITOR ]; then
                local geometry=`grab_output`
            else
                local geometry=`grab_selected_output $SELECTED_MONITOR`
            fi
            ;;
        region)
            local geometry=`grab_region`
            ;;
        window)
            if [ $CURRENT -eq 1 ]; then
                local geometry=`grab_active_window`
            else
                local geometry=`grab_window`
            fi
	    geometry=`trim "${geometry}"`
            ;;
    esac
    if [ ${DELAY} -gt 0 ] 2>/dev/null; then
        sleep ${DELAY}
    fi
    save_geometry "${geometry}"
}

function grab_output() {
    slurp -or
}

function grab_active_output() {
    local active_workspace=`hyprctl -j activeworkspace`
    local monitors=`hyprctl -j monitors`
    Print "Monitors: %s\n" "$monitors"
    Print "Active workspace: %s\n" "$active_workspace"
    local current_monitor="$(echo $monitors | jq -r 'first(.[] | select(.activeWorkspace.id == '$(echo $active_workspace | jq -r '.id')'))')"
    Print "Current output: %s\n" "$current_monitor"
    echo $current_monitor | jq -r '"\(.x),\(.y) \(.width/.scale|round)x\(.height/.scale|round)"'
}

function grab_selected_output() {
    local monitor=`hyprctl -j monitors | jq -r '.[] | select(.name == "'$(echo $1)'")'`
    Print "Capturing: %s\n" "${1}"
    echo $monitor | jq -r '"\(.x),\(.y) \(.width/.scale|round)x\(.height/.scale|round)"'
}

function grab_region() {
    slurp -d
}

function grab_window() {
    local monitors=`hyprctl -j monitors`
    local clients=`hyprctl -j clients | jq -r '[.[] | select(.workspace.id | contains('$(echo $monitors | jq -r 'map(.activeWorkspace.id) | join(",")')'))]'`
    Print "Monitors: %s\n" "$monitors"
    Print "Clients: %s\n" "$clients"
    # Generate boxes for each visible window and send that to slurp
    # through stdin
    local boxes="$(echo $clients | jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.title)"' | cut -f1,2 -d' ')"
    Print "Boxes:\n%s\n" "$boxes"
    slurp -r <<< "$boxes"
}

function grab_active_window() {
    local active_window=`hyprctl -j activewindow`
    local box=$(echo $active_window | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | cut -f1,2 -d' ')
    Print "Box:\n%s\n" "$box"
    echo "$box"
}

function parse_mode() {
    local mode="${1}"

    case $mode in
        window | region | output)
            OPTION=$mode
            ;;
        active)
            CURRENT=1
            ;;
        *)
            hyprctl monitors -j | jq -re '.[] | select(.name == "'$(echo $mode)'")' &>/dev/null
            SELECTED_MONITOR=$mode
            ;;
    esac
}

function args() {
    local options=$(getopt -o hf:o:m:D:dszr:t: --long help,filename:,output-folder:,mode:,delay:,clipboard-only,debug,silent,freeze,raw,notif-timeout: -- "$@")
    eval set -- "$options"

    while true; do
        case "$1" in
            -h | --help)
                Help
                exit
                ;;
            -o | --output-folder)
                shift;
                SAVEDIR=$1
                ;;
            -f | --filename)
                shift;
                FILENAME=$1
                ;;
            -D | --delay)
		shift;
                DELAY=$1
                ;;
            -m | --mode)
                shift;
                parse_mode $1
                ;;
            --clipboard-only)
                CLIPBOARD=1
                ;;
            -d | --debug)
                DEBUG=1
                ;;
            -z | --freeze)
                FREEZE=1
                ;;
            -s | --silent)
                SILENT=1
                ;;
            -r | --raw)
                RAW=1
                ;;
            -t | --notif-timeout)
                shift;
                NOTIF_TIMEOUT=$1
                ;;
            --)
                shift # Skip -- argument
                COMMAND=${@:2}
                break;;
        esac
        shift
    done

    if [ -z $OPTION ]; then
        Print "A mode is required\n\nAvailable modes are:\n\toutput\n\tregion\n\twindow\n"
        exit 2
    fi
}

if [ -z $1 ]; then
    Help
    exit
fi

CLIPBOARD=0
DEBUG=0
SILENT=0
RAW=0
NOTIF_TIMEOUT=5000
CURRENT=0
FREEZE=0
[ -z "$XDG_PICTURES_DIR" ] && type xdg-user-dir &> /dev/null && XDG_PICTURES_DIR=$(xdg-user-dir PICTURES)
FILENAME="$(date +'%Y-%m-%d-%H%M%S_hyprshot.png')"
[ -z "$HYPRSHOT_DIR" ] && SAVEDIR=${XDG_PICTURES_DIR:=~} || SAVEDIR=${HYPRSHOT_DIR}

args $0 "$@"

SAVE_FULLPATH="$SAVEDIR/$FILENAME"
[ $CLIPBOARD -eq 0 ] && Print "Saving in: %s\n" "$SAVE_FULLPATH"
begin_grab $OPTION & checkRunning
