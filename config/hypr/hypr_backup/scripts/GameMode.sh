#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Game Mode. Turning off all animations

notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

# location to store pre-gamemode settings so we can restore them without a full reload
STATE_FILE="$HOME/.cache/hypr/gamemode_state"

save_state() {
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "animations:enabled=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')" > "$STATE_FILE"
    echo "decoration:shadow:enabled=$(hyprctl getoption decoration:shadow:enabled | awk 'NR==1{print $2}')" >> "$STATE_FILE"
    echo "decoration:blur:enabled=$(hyprctl getoption decoration:blur:enabled | awk 'NR==1{print $2}')" >> "$STATE_FILE"
    echo "general:gaps_in=$(hyprctl getoption general:gaps_in | awk 'NR==1{print $2}')" >> "$STATE_FILE"
    echo "general:gaps_out=$(hyprctl getoption general:gaps_out | awk 'NR==1{print $2}')" >> "$STATE_FILE"
    echo "general:border_size=$(hyprctl getoption general:border_size | awk 'NR==1{print $2}')" >> "$STATE_FILE"
    echo "decoration:rounding=$(hyprctl getoption decoration:rounding | awk 'NR==1{print $2}')" >> "$STATE_FILE"
}

restore_state() {
    if [ -f "$STATE_FILE" ]; then
        while IFS='=' read -r key val; do
            [ -z "$key" ] && continue
            # apply saved value; ignore errors and continue
            hyprctl keyword "$key" "$val" >/dev/null 2>&1 || true
        done < "$STATE_FILE"
        rm -f "$STATE_FILE"
    else
        # Fallback conservative defaults if state not available
        hyprctl keyword animations:enabled 1 >/dev/null 2>&1 || true
        hyprctl keyword decoration:shadow:enabled 1 >/dev/null 2>&1 || true
        hyprctl keyword decoration:blur:enabled 1 >/dev/null 2>&1 || true
        hyprctl keyword general:gaps_in 10 >/dev/null 2>&1 || true
        hyprctl keyword general:gaps_out 10 >/dev/null 2>&1 || true
        hyprctl keyword general:border_size 1 >/dev/null 2>&1 || true
        hyprctl keyword decoration:rounding 6 >/dev/null 2>&1 || true
    fi
}

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    # Save current options so we can restore them without reloading Hyprland
    save_state
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"

    hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
    swww kill 
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
    exit
else
    swww-daemon --format xrgb && swww img "$HOME/.config/rofi/.current_wallpaper" &
    sleep 0.1
    ${SCRIPTSDIR}/WallustSwww.sh
    sleep 0.5
    # restore previously saved options instead of doing a full reload which can disrupt keybinds
    restore_state
    ${SCRIPTSDIR}/Refresh.sh	 
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
    exit
fi
