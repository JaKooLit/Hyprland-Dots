#!/usr/bin/env bash
# waybar-hover-toggle.sh
# Toggle waybar (SIGUSR1) when the cursor is near the bottom of the active monitor.
# Requirements: hyprctl, jq, pkill (or killall)
# Install: chmod +x ~/.local/bin/waybar-hover-toggle.sh

# --- user settings ---
BAR_HEIGHT=${BAR_HEIGHT:-50}  # height of your bottom bar

TRIGGER_ZONE=${TRIGGER_ZONE:-20}         # pixels from bottom to trigger show
POLL_INTERVAL=${POLL_INTERVAL:-0.12}     # how often to check cursor (sec)
MON_REFRESH_SEC=${MON_REFRESH_SEC:-2}    # refresh monitors JSON every N seconds
TOGGLE_CMD="kill -SIGUSR1 $(pgrep -f 'waybar -c /home/tak_0/.config/waybar/config-bottom.jsonc')"
  # command to toggle waybar
STATE_FILE=${STATE_FILE:-/tmp/waybar_hover_visible}
# ---------------------

# small helper
log() { printf '%s\n' "$*"; }

# Ensure prerequisites
command -v hyprctl >/dev/null 2>&1 || { log "hyprctl not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { log "jq not found"; exit 1; }

# Initialize: assume hidden if using start_hidden in config (recommended)
if [[ ! -f "$STATE_FILE" ]]; then
    echo 0 > "$STATE_FILE"
fi

# function: get cursor position (global layout coords)
# function: get cursor position (global layout coords)
get_cursor() {
    local out x y
    out=$(hyprctl cursorpos 2>/dev/null) || out=""
    # Expected format: "Cursor pos: 1234,567"
    x=$(echo "$out" | sed -E 's/[^0-9-]*(-?[0-9]+),.*/\1/')
    y=$(echo "$out" | sed -E 's/[^,]*,(-?[0-9]+)/\1/')
    # fallback if parsing fails
    if [[ -z "$x" || -z "$y" ]]; then
        echo "0 0"
    else
        echo "$x $y"
    fi
}

# function: refresh monitors JSON (cached for MON_REFRESH_SEC)
refresh_monitors() {
    MONS_JSON=$(hyprctl -j monitors 2>/dev/null) || MONS_JSON='[]'
    # create an array of compact objects
    mapfile -t MONS <<< "$(jq -c '.[]' <<<"$MONS_JSON" 2>/dev/null || echo '')"
}

refresh_monitors
last_refresh_ts=$(date +%s)

while true; do
    # maybe refresh monitor list every MON_REFRESH_SEC seconds
    now=$(date +%s)
    if (( now - last_refresh_ts >= MON_REFRESH_SEC )); then
        refresh_monitors
        last_refresh_ts=$now
    fi

    read -r CX CY <<< "$(get_cursor)"
    should_show=0
    found=0

    for m in "${MONS[@]}"; do
        # try multiple field names that hyprctl might use (geometry / at+size / x/y/w/h)
        mx=$(jq -r '.at.x // .geometry.x // .x // .pos.x // empty' <<<"$m")
        my=$(jq -r '.at.y // .geometry.y // .y // .pos.y // empty' <<<"$m")
        mw=$(jq -r '.size.w // .geometry.w // .w // .size.width // .width // empty' <<<"$m")
        mh=$(jq -r '.size.h // .geometry.h // .h // .size.height // .height // empty' <<<"$m")

        # if any missing, skip
        if [[ -z "$mx" || -z "$my" || -z "$mw" || -z "$mh" ]]; then
            continue
        fi

        # numeric math safe in bash
        if (( CX >= mx && CX < mx + mw && CY >= my && CY < my + mh )); then
            found=1
            bottom=$(( my + mh - 1 ))
            if (( CY >= bottom - TRIGGER_ZONE )); then
                should_show=1
            else
                should_show=0
            fi
            break
        fi
    done

    # fallback: if we couldn't find monitor that contains cursor, compare to primary/first monitor
    if (( found == 0 )); then
        # try jq on cached JSON
        mx=$(jq -r '.[0].at.x // .[0].geometry.x // .[0].x // 0' <<<"$MONS_JSON")
        my=$(jq -r '.[0].at.y // .[0].geometry.y // .[0].y // 0' <<<"$MONS_JSON")
        mw=$(jq -r '.[0].size.w // .[0].geometry.w // .[0].w // .[0].size.width // 0' <<<"$MONS_JSON")
        mh=$(jq -r '.[0].size.h // .[0].geometry.h // .[0].h // .[0].size.height // 0' <<<"$MONS_JSON")
        bottom=$(( my + mh - 1 ))
        if (( CY >= bottom - TRIGGER_ZONE )); then should_show=1; else should_show=0; fi
    fi

    current=$(cat "$STATE_FILE" 2>/dev/null || echo 0)

    if (( current == 0 )); then
    # Bar is hidden, check trigger zone
    if (( should_show == 1 )); then
        eval "$TOGGLE_CMD"
        echo 1 > "$STATE_FILE"
    fi
    else
    # Bar is shown, check if cursor is inside bar area
    bar_top=$(( bottom - BAR_HEIGHT ))
    if (( CY >= bar_top )); then
        # cursor is still inside bar → keep shown
        should_show=1
        else
        # cursor left bar → hide
        should_show=0
        fi

        if (( should_show == 0 )); then
        eval "$TOGGLE_CMD"
        echo 0 > "$STATE_FILE"
        fi
fi


    sleep "$POLL_INTERVAL"
done
