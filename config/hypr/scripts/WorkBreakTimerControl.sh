#!/bin/bash
# Work Break Timer Control Script
# Handles user interactions: pause, skip, postpone, settings

ACTION="${1:-menu}"
TIMER_DAEMON="$HOME/.config/hypr/scripts/WorkBreakTimer.py"
CONFIG_DIR="$HOME/.config/hypr/work-break-timer"
CONFIG_FILE="$CONFIG_DIR/config.json"
STATE_FILE="$CONFIG_DIR/state.json"

# Check if daemon is running
is_daemon_running() {
    pgrep -f "WorkBreakTimer.py daemon" > /dev/null
}

# Start daemon
start_daemon() {
    if ! is_daemon_running; then
        python3 "$TIMER_DAEMON" daemon > /dev/null 2>&1 &
        notify-send "Work Break Timer" "Timer started" -i appointment-soon -u normal
        sleep 1
    fi
}

# Stop daemon
stop_daemon() {
    if is_daemon_running; then
        pkill -f "WorkBreakTimer.py daemon"
        notify-send "Work Break Timer" "Timer stopped" -i appointment-soon -u normal
    fi
}

# Toggle pause
toggle_pause() {
    if is_daemon_running; then
        touch "$CONFIG_DIR/pause.marker"
        sleep 0.5

        # Check if paused
        PAUSED=$(jq -r '.paused // false' "$STATE_FILE" 2>/dev/null)
        if [[ "$PAUSED" == "true" ]]; then
            notify-send "Work Break Timer" "Timer paused" -i appointment-soon -u normal
        else
            notify-send "Work Break Timer" "Timer resumed" -i appointment-soon -u normal
        fi
    else
        start_daemon
    fi
}

# Skip current break
skip_break() {
    if is_daemon_running; then
        touch "$CONFIG_DIR/skip.marker"
        pkill -f "BreakOverlay.sh"
        notify-send "Work Break Timer" "Break skipped" -i appointment-soon -u normal
    fi
}

# Postpone break
postpone_break() {
    if is_daemon_running; then
        touch "$CONFIG_DIR/postpone.marker"
        pkill -f "BreakOverlay.sh"
        notify-send "Work Break Timer" "Break postponed for 5 minutes" -i appointment-soon -u normal
    fi
}

# Open settings editor
open_settings() {
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        notify-send "Error" "jq is required for settings editor" -u critical
        xdg-open "$CONFIG_FILE"
        return
    fi

    # Create rofi menu for settings
    CURRENT_SHORT_INTERVAL=$(($(jq -r '.timers.short_break_interval' "$CONFIG_FILE") / 60))
    CURRENT_LONG_INTERVAL=$(($(jq -r '.timers.long_break_interval' "$CONFIG_FILE") / 60))
    CURRENT_SHORT_DURATION=$(jq -r '.timers.short_break_duration' "$CONFIG_FILE")
    CURRENT_LONG_DURATION=$(($(jq -r '.timers.long_break_duration' "$CONFIG_FILE") / 60))

    MENU="1. Short break interval (current: ${CURRENT_SHORT_INTERVAL} min)\n"
    MENU+="2. Long break interval (current: ${CURRENT_LONG_INTERVAL} min)\n"
    MENU+="3. Short break duration (current: ${CURRENT_SHORT_DURATION} sec)\n"
    MENU+="4. Long break duration (current: ${CURRENT_LONG_DURATION} min)\n"
    MENU+="5. Edit config file manually\n"
    MENU+="6. Reset to defaults\n"
    MENU+="7. View statistics"

    CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "Work Break Timer Settings" -i | cut -d. -f1)

    case "$CHOICE" in
        1)
            NEW_VAL=$(rofi -dmenu -p "Short break interval (minutes):" <<< "$CURRENT_SHORT_INTERVAL")
            if [[ -n "$NEW_VAL" && "$NEW_VAL" =~ ^[0-9]+$ ]]; then
                jq ".timers.short_break_interval = $((NEW_VAL * 60))" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
                mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                notify-send "Settings Updated" "Short break interval: ${NEW_VAL} minutes"
            fi
            ;;
        2)
            NEW_VAL=$(rofi -dmenu -p "Long break interval (minutes):" <<< "$CURRENT_LONG_INTERVAL")
            if [[ -n "$NEW_VAL" && "$NEW_VAL" =~ ^[0-9]+$ ]]; then
                jq ".timers.long_break_interval = $((NEW_VAL * 60))" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
                mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                notify-send "Settings Updated" "Long break interval: ${NEW_VAL} minutes"
            fi
            ;;
        3)
            NEW_VAL=$(rofi -dmenu -p "Short break duration (seconds):" <<< "$CURRENT_SHORT_DURATION")
            if [[ -n "$NEW_VAL" && "$NEW_VAL" =~ ^[0-9]+$ ]]; then
                jq ".timers.short_break_duration = $NEW_VAL" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
                mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                notify-send "Settings Updated" "Short break duration: ${NEW_VAL} seconds"
            fi
            ;;
        4)
            NEW_VAL=$(rofi -dmenu -p "Long break duration (minutes):" <<< "$CURRENT_LONG_DURATION")
            if [[ -n "$NEW_VAL" && "$NEW_VAL" =~ ^[0-9]+$ ]]; then
                jq ".timers.long_break_duration = $((NEW_VAL * 60))" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
                mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
                notify-send "Settings Updated" "Long break duration: ${NEW_VAL} minutes"
            fi
            ;;
        5)
            xdg-open "$CONFIG_FILE"
            ;;
        6)
            if rofi -dmenu -p "Reset to defaults? (yes/no):" <<< "no" | grep -qi "yes"; then
                cat > "$CONFIG_FILE" << 'EOF'
{
  "timers": {
    "short_break_interval": 600,
    "short_break_duration": 10,
    "long_break_interval": 3600,
    "long_break_duration": 600,
    "postpone_duration": 300
  },
  "notifications": {
    "enabled": true,
    "sound_enabled": false,
    "warning_before_break": 30
  },
  "overlay": {
    "dim_screen": true,
    "dim_opacity": 0.8,
    "show_skip_button": true,
    "show_postpone_button": true,
    "theme": "dark"
  },
  "behavior": {
    "auto_start": true,
    "reset_on_idle": true,
    "idle_threshold": 300,
    "strict_mode": false
  }
}
EOF
                notify-send "Settings Reset" "Configuration reset to defaults"
            fi
            ;;
        7)
            if [[ -f "$STATE_FILE" ]]; then
                SHORT_BREAKS=$(jq -r '.breaks_taken.short // 0' "$STATE_FILE")
                LONG_BREAKS=$(jq -r '.breaks_taken.long // 0' "$STATE_FILE")
                TOTAL_WORK=$(($(jq -r '.total_work_time // 0' "$STATE_FILE") / 60))

                STATS="Work Break Timer Statistics\n\n"
                STATS+="Short breaks taken: ${SHORT_BREAKS}\n"
                STATS+="Long breaks taken: ${LONG_BREAKS}\n"
                STATS+="Total breaks: $((SHORT_BREAKS + LONG_BREAKS))\n"
                STATS+="\nClick OK to close"

                notify-send "Statistics" "$STATS" -i appointment-soon -t 10000
            else
                notify-send "Statistics" "No statistics available yet" -i appointment-soon
            fi
            ;;
    esac
}

# Show interactive menu
show_menu() {
    if ! is_daemon_running; then
        MENU="▶️ Start timer\n"
        MENU+="⚙️ Settings"

        CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "Work Break Timer" -i)
    else
        PAUSED=$(jq -r '.paused // false' "$STATE_FILE" 2>/dev/null)
        IN_BREAK=$(jq -r '.in_break // false' "$STATE_FILE" 2>/dev/null)

        if [[ "$IN_BREAK" == "true" ]]; then
            MENU="⏭️ Skip break\n"
            MENU+="⏰ Postpone 5 min\n"
        elif [[ "$PAUSED" == "true" ]]; then
            MENU="▶️ Resume timer\n"
            MENU+="⏹️ Stop timer\n"
        else
            MENU="⏸️ Pause timer\n"
            MENU+="⏹️ Stop timer\n"
        fi

        MENU+="⚙️ Settings\n"
        MENU+="📊 Statistics"

        CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "Work Break Timer" -i)
    fi

    case "$CHOICE" in
        *"Start timer")
            start_daemon
            ;;
        *"Stop timer")
            stop_daemon
            ;;
        *"Pause timer")
            toggle_pause
            ;;
        *"Resume timer")
            toggle_pause
            ;;
        *"Skip break")
            skip_break
            ;;
        *"Postpone"*)
            postpone_break
            ;;
        *"Settings")
            open_settings
            ;;
        *"Statistics")
            open_settings "7"
            ;;
    esac
}

# Handle actions
case "$ACTION" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    toggle|pause)
        toggle_pause
        ;;
    skip)
        skip_break
        ;;
    postpone)
        postpone_break
        ;;
    settings)
        open_settings
        ;;
    menu)
        show_menu
        ;;
    *)
        echo "Usage: $0 {start|stop|toggle|skip|postpone|settings|menu}"
        echo ""
        echo "Actions:"
        echo "  start     - Start the timer daemon"
        echo "  stop      - Stop the timer daemon"
        echo "  toggle    - Toggle pause/resume"
        echo "  skip      - Skip current break"
        echo "  postpone  - Postpone break by 5 minutes"
        echo "  settings  - Open settings editor"
        echo "  menu      - Show interactive menu (default)"
        exit 1
        ;;
esac
