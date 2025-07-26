##################################################################
#                                                                #   
#                                                                #
#                  TAK_0'S Per-Window-Switch                     #
#                                                                #
#                                                                #
#                                                                #
#  Just a little script that I made to switch keyboard layouts   #
#       per-window instead of global switching for the more      #
#                 smooth and comfortable workflow.               #  
#                                                                #
##################################################################








# This is for changing kb_layouts. Set kb_layouts in 

MAP_FILE="$HOME/.cache/kb_layout_per_window"
CFG_FILE="$HOME/.config/hypr/UserConfigs/UserSettings.conf"
ICON="$HOME/.config/swaync/images/ja.png"
SCRIPT_NAME="$(basename "$0")"

# Ensure map file exists
touch "$MAP_FILE"

# Read layouts from config
if ! grep -q 'kb_layout' "$CFG_FILE"; then
  echo "Error: cannot find kb_layout in $CFG_FILE" >&2
  exit 1
fi
kb_layouts=($(grep 'kb_layout' "$CFG_FILE" | cut -d '=' -f2 | tr -d '[:space:]' | tr ',' ' '))
count=${#kb_layouts[@]}

# Get current active window ID
get_win() {
  hyprctl activewindow -j | jq -r '.address // .id'
}

# Get available keyboards
get_keyboards() {
  hyprctl devices -j | jq -r '.keyboards[].name'
}

# Save window-specific layout
save_map() {
  local W=$1 L=$2
  grep -v "^${W}:" "$MAP_FILE" > "$MAP_FILE.tmp"
  echo "${W}:${L}" >> "$MAP_FILE.tmp"
  mv "$MAP_FILE.tmp" "$MAP_FILE"
}

# Load layout for window (fallback to default)
load_map() {
  local W=$1
  local E
  E=$(grep "^${W}:" "$MAP_FILE")
  [[ -n "$E" ]] && echo "${E#*:}" || echo "${kb_layouts[0]}"
}

# Switch layout for all keyboards to layout index
do_switch() {
  local IDX=$1
  for kb in $(get_keyboards); do
    hyprctl switchxkblayout "$kb" "$IDX" 2>/dev/null
  done
}

# Toggle layout for current window only
cmd_toggle() {
  local W=$(get_win)
  [[ -z "$W" ]] && return
  local CUR=$(load_map "$W")
  local i NEXT
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$CUR" ]]; then
      i=$idx
      break
    fi
  done
  NEXT=$(( (i+1) % count ))
  do_switch "$NEXT"
  save_map "$W" "${kb_layouts[NEXT]}"
  notify-send -u low -i "$ICON" "kb_layout: ${kb_layouts[NEXT]}"
}

# Restore layout on focus
cmd_restore() {
  local W=$(get_win)
  [[ -z "$W" ]] && return
  local LAY=$(load_map "$W")
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$LAY" ]]; then
      do_switch "$idx"
      break
    fi
  done
}

# Listen to focus events and restore window-specific layouts
subscribe() {
  local SOCKET2="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  [[ -S "$SOCKET2" ]] || { echo "Error: Hyprland socket not found." >&2; exit 1; }

  socat -u UNIX-CONNECT:"$SOCKET2" - | while read -r line; do
    [[ "$line" =~ ^activewindow ]] && cmd_restore
  done
}

# Ensure only one listener
if ! pgrep -f "$SCRIPT_NAME.*--listener" >/dev/null; then
  subscribe --listener &
fi

# CLI
case "$1" in
  toggle|"") cmd_toggle ;;
  *) echo "Usage: $SCRIPT_NAME [toggle]" >&2; exit 1 ;;
esac
