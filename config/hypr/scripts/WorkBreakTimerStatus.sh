#!/bin/bash
# Work Break Timer - Waybar Status Display

TIMER_SCRIPT="$HOME/.config/hypr/scripts/WorkBreakTimer.py"
STATE_FILE="$HOME/.config/hypr/work-break-timer/state.json"

# Check if daemon is running
if ! pgrep -f "WorkBreakTimer.py" > /dev/null; then
    # Daemon not running, show inactive state
    echo '{"text": "⏲️", "tooltip": "Work Break Timer (Inactive)\nClick to start", "class": "inactive", "alt": "inactive"}'
    exit 0
fi

# Get status from daemon
if [[ -f "$STATE_FILE" ]]; then
    # Read state file (convert floats to ints)
    PAUSED=$(jq -r '.paused // false' "$STATE_FILE" 2>/dev/null)
    IN_BREAK=$(jq -r '.in_break // false' "$STATE_FILE" 2>/dev/null)
    BREAK_TYPE=$(jq -r '.break_type // "none"' "$STATE_FILE" 2>/dev/null)
    BREAK_END=$(jq -r '(.break_end // 0) | floor' "$STATE_FILE" 2>/dev/null)
    LAST_SHORT=$(jq -r '(.last_short_break // 0) | floor' "$STATE_FILE" 2>/dev/null)
    LAST_LONG=$(jq -r '(.last_long_break // 0) | floor' "$STATE_FILE" 2>/dev/null)
    SHORT_BREAKS=$(jq -r '.breaks_taken.short // 0' "$STATE_FILE" 2>/dev/null)
    LONG_BREAKS=$(jq -r '.breaks_taken.long // 0' "$STATE_FILE" 2>/dev/null)

    # Read config
    CONFIG_FILE="$HOME/.config/hypr/work-break-timer/config.json"
    SHORT_INTERVAL=$(jq -r '.timers.short_break_interval // 600' "$CONFIG_FILE" 2>/dev/null)
    LONG_INTERVAL=$(jq -r '.timers.long_break_interval // 3600' "$CONFIG_FILE" 2>/dev/null)

    NOW=$(date +%s)

    # Calculate status
    if [[ "$PAUSED" == "true" ]]; then
        TEXT="⏸️ Paused"
        CLASS="paused"
        ALT="paused"
        TOOLTIP="Work Break Timer (Paused)\n\nClick: Resume\nRight-click: Settings\n\nBreaks today: ${SHORT_BREAKS} short, ${LONG_BREAKS} long"
    elif [[ "$IN_BREAK" == "true" ]]; then
        REMAINING=$((BREAK_END - NOW))
        if [[ $REMAINING -lt 0 ]]; then
            REMAINING=0
        fi

        # Format remaining time
        if [[ $REMAINING -lt 60 ]]; then
            TIME_STR="${REMAINING}s"
        else
            MINS=$((REMAINING / 60))
            SECS=$((REMAINING % 60))
            TIME_STR=$(printf "%d:%02d" $MINS $SECS)
        fi

        if [[ "$BREAK_TYPE" == "short" ]]; then
            TEXT="⏸️ ${TIME_STR}"
            TOOLTIP="Short Break\n\nTime remaining: ${TIME_STR}\n\nPress ESC or 's' to skip"
            CLASS="break_short"
            ALT="break_short"
        else
            TEXT="☕ ${TIME_STR}"
            TOOLTIP="Long Break\n\nTime remaining: ${TIME_STR}\n\nPress ESC to skip\nPress 'p' to postpone"
            CLASS="break_long"
            ALT="break_long"
        fi
    else
        # Working - show time until next break
        TIME_SINCE_SHORT=$((NOW - LAST_SHORT))
        TIME_SINCE_LONG=$((NOW - LAST_LONG))

        TIME_UNTIL_SHORT=$((SHORT_INTERVAL - TIME_SINCE_SHORT))
        TIME_UNTIL_LONG=$((LONG_INTERVAL - TIME_SINCE_LONG))

        # Prevent negative values - clamp to 0
        if [[ $TIME_UNTIL_SHORT -lt 0 ]]; then
            TIME_UNTIL_SHORT=0
        fi
        if [[ $TIME_UNTIL_LONG -lt 0 ]]; then
            TIME_UNTIL_LONG=0
        fi

        # Determine next break
        if [[ $TIME_UNTIL_SHORT -le $TIME_UNTIL_LONG ]]; then
            NEXT_BREAK="short"
            TIME_UNTIL=$TIME_UNTIL_SHORT
        else
            NEXT_BREAK="long"
            TIME_UNTIL=$TIME_UNTIL_LONG
        fi

        # Format time until break (for display)
        if [[ $TIME_UNTIL -lt 60 ]]; then
            TIME_STR="${TIME_UNTIL}s"
        elif [[ $TIME_UNTIL -lt 3600 ]]; then
            MINS=$((TIME_UNTIL / 60))
            SECS=$((TIME_UNTIL % 60))
            TIME_STR=$(printf "%d:%02d" $MINS $SECS)
        else
            HOURS=$((TIME_UNTIL / 3600))
            MINS=$(((TIME_UNTIL % 3600) / 60))
            TIME_STR=$(printf "%d:%02d" $HOURS $MINS)
        fi

        # Format short break time (for tooltip)
        if [[ $TIME_UNTIL_SHORT -lt 60 ]]; then
            SHORT_TIME_STR="${TIME_UNTIL_SHORT}s"
        elif [[ $TIME_UNTIL_SHORT -lt 3600 ]]; then
            MINS=$((TIME_UNTIL_SHORT / 60))
            SECS=$((TIME_UNTIL_SHORT % 60))
            SHORT_TIME_STR=$(printf "%d:%02d" $MINS $SECS)
        else
            HOURS=$((TIME_UNTIL_SHORT / 3600))
            MINS=$(((TIME_UNTIL_SHORT % 3600) / 60))
            SHORT_TIME_STR=$(printf "%d:%02d" $HOURS $MINS)
        fi

        # Format long break time (for tooltip)
        if [[ $TIME_UNTIL_LONG -lt 60 ]]; then
            LONG_TIME_STR="${TIME_UNTIL_LONG}s"
        elif [[ $TIME_UNTIL_LONG -lt 3600 ]]; then
            MINS=$((TIME_UNTIL_LONG / 60))
            SECS=$((TIME_UNTIL_LONG % 60))
            LONG_TIME_STR=$(printf "%d:%02d" $MINS $SECS)
        else
            HOURS=$((TIME_UNTIL_LONG / 3600))
            MINS=$(((TIME_UNTIL_LONG % 3600) / 60))
            LONG_TIME_STR=$(printf "%d:%02d" $HOURS $MINS)
        fi

        if [[ "$NEXT_BREAK" == "short" ]]; then
            TEXT="🕐 ${TIME_STR}"
            BREAK_NAME="short break"
        else
            TEXT="🕐 ${TIME_STR}"
            BREAK_NAME="long break"
        fi

        CLASS="working"
        ALT="working"
        TOOLTIP="Work Break Timer\n\nNext: ${BREAK_NAME} in ${TIME_STR}\nShort break: ${SHORT_TIME_STR}\nLong break: ${LONG_TIME_STR}\n\nClick: Pause/Resume\nRight-click: Settings\n\nBreaks today: ${SHORT_BREAKS} short, ${LONG_BREAKS} long"
    fi

    # Output JSON for Waybar
    echo "{\"text\": \"${TEXT}\", \"tooltip\": \"${TOOLTIP}\", \"class\": \"${CLASS}\", \"alt\": \"${ALT}\"}"
else
    # State file not found
    echo '{"text": "⏲️ --:--", "tooltip": "Work Break Timer\n\nStarting...", "class": "starting", "alt": "starting"}'
fi
