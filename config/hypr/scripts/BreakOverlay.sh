#!/bin/bash
# Break Overlay - Simple fullscreen break notification

BREAK_TYPE="$1"
DURATION="$2"

if [[ -z "$BREAK_TYPE" || -z "$DURATION" ]]; then
    echo "Usage: $0 <break_type> <duration_seconds>"
    exit 1
fi

CONFIG_DIR="$HOME/.config/hypr/work-break-timer"

# Break type specific settings
if [[ "$BREAK_TYPE" == "short" ]]; then
    TITLE="⏰ Short Break Time"
    MESSAGE="Take a quick break. Look away from the screen!"
    ICON="⏸️"
    BG_COLOR="#1e1e2e"
    FG_COLOR="#89dceb"
else
    TITLE="☕ Long Break Time"
    MESSAGE="Time for a break! Stand up, stretch, and rest your eyes."
    ICON="🧘"
    BG_COLOR="#1e1e2e"
    FG_COLOR="#a6e3a1"
fi

# Create a temp script to avoid heredoc quote hell
TEMP_SCRIPT=$(mktemp /tmp/break-overlay-XXXXXX.sh)
cat > "$TEMP_SCRIPT" << 'SCRIPT_END'
#!/bin/bash

# Disable terminal echo
stty -echo

# Clear screen
clear

# Get terminal size
COLS=$(tput cols)
LINES=$(tput lines)

# Center text function
center_text() {
    local text="$1"
    local text_length=${#text}
    local padding=$(( (COLS - text_length) / 2 ))
    printf "%${padding}s%s\n" "" "$text"
}

# Draw the break screen (once, on first call)
draw_static_screen() {
    clear

    # Add vertical spacing
    for i in $(seq 1 $((LINES / 4))); do echo ""; done

    # Icon
    center_text "$ICON"
    echo ""
    echo ""

    # Title
    center_text "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    center_text "$TITLE"
    echo ""
    center_text "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo ""

    # Message
    center_text "$MESSAGE"
    echo ""
    echo ""
    echo ""
}

# Update only the countdown and progress bar
update_countdown() {
    local remaining=$1

    # Ensure remaining is not negative
    if [[ $remaining -lt 0 ]]; then
        remaining=0
    fi

    # Calculate line positions
    local countdown_line=$((LINES / 4 + 12))
    local progress_line=$((countdown_line + 3))

    # Format countdown
    if [[ $remaining -lt 60 ]]; then
        TIME_STR="${remaining}s"
    else
        MINS=$((remaining / 60))
        SECS=$((remaining % 60))
        TIME_STR=$(printf "%d:%02d" $MINS $SECS)
    fi

    # Update countdown (move cursor to line, clear line, print)
    tput cup $countdown_line 0
    tput el
    center_text "⏱  $TIME_STR  ⏱"

    # Update progress bar
    tput cup $progress_line 0
    tput el
    local bar_width=40
    local progress=$(( (DURATION - remaining) * bar_width / DURATION ))

    # Ensure progress doesn't exceed 100%
    if [[ $progress -gt $bar_width ]]; then
        progress=$bar_width
    fi

    local bar_text="["
    for i in $(seq 1 $bar_width); do
        if [[ $i -le $progress ]]; then
            bar_text+="█"
        else
            bar_text+="░"
        fi
    done
    bar_text+="]"
    center_text "$bar_text"
}

# Draw instructions at bottom (once)
draw_instructions() {
    local instr_line=$((LINES / 4 + 18))
    tput cup $instr_line 0
    echo ""
    echo ""
    center_text "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    center_text "Press ESC or S to skip | Press P to postpone"
    center_text "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    center_text "💡 Regular breaks improve focus and reduce eye strain"
}

# Draw static elements once
draw_static_screen
draw_instructions

# Hide cursor
tput civis

# Countdown loop
for i in $(seq $DURATION -1 0); do
    update_countdown $i

    # Check for skip/postpone markers
    if [[ -f "$CONFIG_DIR/skip.marker" ]]; then
        rm -f "$CONFIG_DIR/skip.marker"
        clear
        center_text "Break skipped!"
        sleep 1
        exit 0
    fi

    if [[ -f "$CONFIG_DIR/postpone.marker" ]]; then
        rm -f "$CONFIG_DIR/postpone.marker"
        clear
        center_text "Break postponed for 5 minutes"
        sleep 1
        exit 0
    fi

    # Non-blocking key check
    read -t 1 -n 1 key
    if [[ $? -eq 0 ]]; then
        # Check for s or S
        if [[ "$key" == "s" || "$key" == "S" ]]; then
            clear
            center_text "Break skipped!"
            sleep 1
            tput cnorm
            exit 0
        # Check for p or P
        elif [[ "$key" == "p" || "$key" == "P" ]]; then
            touch "$CONFIG_DIR/postpone.marker"
            clear
            center_text "Break postponed for 5 minutes"
            sleep 1
            tput cnorm
            exit 0
        fi
    fi
done

# Show cursor again
tput cnorm

# Break complete
clear
for i in $(seq 1 $((LINES / 3))); do echo ""; done
center_text "✅ Break complete! Back to work."
center_text ""
center_text "Stay focused and productive!"
sleep 2

# Restore terminal
stty echo
SCRIPT_END

# Add variables to script
sed -i "1a\\
DURATION=$DURATION\\
TITLE='$TITLE'\\
MESSAGE='$MESSAGE'\\
ICON='$ICON'\\
CONFIG_DIR='$CONFIG_DIR'\\
" "$TEMP_SCRIPT"

# Run the script
kitty --class "break-overlay-fullscreen" \
      --title "Work Break Timer" \
      --override font_size=20 \
      --override background="$BG_COLOR" \
      --override foreground="$FG_COLOR" \
      --override window_padding_width=40 \
      -e bash "$TEMP_SCRIPT" &

OVERLAY_PID=$!

# Store current workspace to lock it
CURRENT_WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.id')

# Set window rules before window is created
hyprctl keyword windowrulev2 'immediate, class:(break-overlay-fullscreen)' 2>/dev/null
hyprctl keyword windowrulev2 'fullscreen, class:(break-overlay-fullscreen)' 2>/dev/null
hyprctl keyword windowrulev2 "workspace $CURRENT_WORKSPACE, class:(break-overlay-fullscreen)" 2>/dev/null

# Hide Waybar during break
pkill -SIGUSR1 waybar 2>/dev/null

# Wait for kitty to start
sleep 0.8

# Get the window address and manually force fullscreen
for i in {1..5}; do
    WINDOW_ADDRESS=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class == "break-overlay-fullscreen") | .address' 2>/dev/null | head -1)
    if [[ -n "$WINDOW_ADDRESS" ]]; then
        break
    fi
    sleep 0.2
done

if [[ -n "$WINDOW_ADDRESS" ]]; then
    # Focus the window
    hyprctl dispatch focuswindow address:$WINDOW_ADDRESS 2>/dev/null
    sleep 0.2

    # Toggle fullscreen (mode 1 = real fullscreen, hides bars)
    hyprctl dispatch fullscreen 1 2>/dev/null
    sleep 0.1

    # Pin on top
    hyprctl dispatch pin 2>/dev/null
fi

# Cleanup function
cleanup_break() {
    # Show Waybar again
    pkill -SIGUSR1 waybar 2>/dev/null

    # Cleanup marker files
    rm -f "$CONFIG_DIR/skip.marker" "$CONFIG_DIR/postpone.marker" 2>/dev/null
}

# Monitor for skip/postpone markers and enforce workspace lock
while ps -p $OVERLAY_PID > /dev/null 2>&1; do
    # Check if user switched workspace - force them back
    ACTIVE_WORKSPACE=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id')
    if [[ "$ACTIVE_WORKSPACE" != "$CURRENT_WORKSPACE" ]]; then
        # User switched workspace - force back to break workspace
        hyprctl dispatch workspace "$CURRENT_WORKSPACE" 2>/dev/null
        # Refocus the break window
        if [[ -n "$WINDOW_ADDRESS" ]]; then
            hyprctl dispatch focuswindow address:$WINDOW_ADDRESS 2>/dev/null
        fi
    fi

    # Check for skip/postpone markers
    if [[ -f "$CONFIG_DIR/skip.marker" ]]; then
        rm -f "$CONFIG_DIR/skip.marker"
        pkill -P $OVERLAY_PID 2>/dev/null
        kill $OVERLAY_PID 2>/dev/null
        cleanup_break
        exit 0
    fi

    if [[ -f "$CONFIG_DIR/postpone.marker" ]]; then
        rm -f "$CONFIG_DIR/postpone.marker"
        pkill -P $OVERLAY_PID 2>/dev/null
        kill $OVERLAY_PID 2>/dev/null
        cleanup_break
        exit 0
    fi

    sleep 0.1
done

# Cleanup when break ends normally
cleanup_break
