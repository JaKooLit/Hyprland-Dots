#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Smooth border cycling effect using Wallust palette or full rainbow

# Possible values: "wallust_random", "rainbow", "gradient_flow"
EFFECT_TYPE="gradient_flow"

WALLUST_COLORS_SOURCE="$HOME/.config/hypr/wallust/wallust-hyprland.conf"

WALLUST_COLORS=()

# ---------- LOAD WALLUST COLORS ----------
if [[ "$EFFECT_TYPE" == "wallust_random" || "$EFFECT_TYPE" == "gradient_flow" ]]; then
    mapfile -t WALLUST_COLORS < <(
        grep -E '^\$color[0-9]+' "$WALLUST_COLORS_SOURCE" \
        | awk -F'rgb\\(|\\)' '{print "0xff"$2}'
    )

    if (( ${#WALLUST_COLORS[@]} == 0 )); then
        echo "ERROR: wallust mode enabled but no colors loaded" >&2
        exit 1
    fi
fi

# ---------- RANDOM WALLUST COLORS ----------
function wallust_random() {
    echo "${WALLUST_COLORS[RANDOM % ${#WALLUST_COLORS[@]}]}"
}

# ---------- RAINBOW COLORS ----------
function random_hex() {
    random_hex=("0xff$(openssl rand -hex 3)")
    echo $random_hex
}

# ---------- FLOW MODE ----------
BASE_COLOR="${WALLUST_COLORS[10]}"
GRAD1_COLOR="${WALLUST_COLORS[14]}"
GRAD2_COLOR="${WALLUST_COLORS[13]}"
GLOW_COLOR="${WALLUST_COLORS[15]}"

MAX_POS=10
GLOW_POS=0

function gradient_flow_color() {
    local pos=$1
    local d=$(( pos - GLOW_POS ))

    # wrap distance (-9..9)
    if (( d >  MAX_POS/2 )); then d=$((d - MAX_POS)); fi
    if (( d < -MAX_POS/2 )); then d=$((d + MAX_POS)); fi

    case "${d#-}" in
        0) echo "$GLOW_COLOR" ;;
        1) echo "$GRAD1_COLOR" ;;
        2) echo "$GRAD2_COLOR" ;;
        *) echo "$BASE_COLOR" ;;
    esac

    if (( pos == MAX_POS - 1 )); then
        GLOW_POS=$(( (GLOW_POS + 1) % MAX_POS ))
    fi
}

# ---------- Main function ---------- 

function get_color() {
    if [[ "$EFFECT_TYPE" == "wallust_random" && ${#WALLUST_COLORS[@]} -gt 0 ]]; then
        wallust_random
    elif [[ "$EFFECT_TYPE" == "gradient_flow" && ${#WALLUST_COLORS[@]} -gt 0 ]]; then
        gradient_flow_color $1
    else
        random_hex
    fi
}

# border effect for ACTIVE window
hyprctl keyword general:col.active_border $(get_color 0) $(get_color 1) $(get_color 2) $(get_color 3) $(get_color 4) $(get_color 5) $(get_color 6) $(get_color 7) $(get_color 8) $(get_color 9) 270deg

# border effect for INACTIVE windows
#hyprctl keyword general:col.inactive_border $(get_color 0) $(get_color 1) $(get_color 2) $(get_color 3) $(get_color 4) $(get_color 5) $(get_color 6) $(get_color 7) $(get_color 8) $(get_color 9) 270deg