#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Dropdown Terminal Usage: ./dropdown.sh [foot|kitty]

TERMINAL="$1"
SPECIAL_WS="special:scratchpad"

# Validate input and set CLASS and CMD
case "$TERMINAL" in
    foot)
        CLASS="foot-dropterminal"
        TERMINAL_CMD="foot --app-id $CLASS"
        ;;
    kitty)
        CLASS="kitty-dropterminal"
        TERMINAL_CMD="kitty --class $CLASS"
        ;;
    *)
        echo "Invalid or missing terminal argument. Usage: $0 [foot|kitty]"
        exit 1
        ;;
esac

# Get the current workspace
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

# Function to check if terminal exists
terminal_exists() {
    hyprctl clients -j | jq -e --arg CLASS "$CLASS" 'any(.[]; .class == $CLASS)' >/dev/null 2>&1
}

# Function to check if terminal is in special workspace
terminal_in_special() {
    hyprctl clients -j | jq -e --arg CLASS "$CLASS" 'any(.[]; .class == $CLASS and .workspace.name == "special:scratchpad")' >/dev/null 2>&1
}

# Function to get terminal address
get_terminal_address() {
    hyprctl clients -j | jq -r --arg CLASS "$CLASS" '.[] | select(.class == $CLASS) | .address'
}

if terminal_exists; then
    TERMINAL_ADDR=$(get_terminal_address)

    if terminal_in_special; then
        echo "Bringing terminal to workspace $CURRENT_WS and pinning"
        hyprctl dispatch movetoworkspace "$CURRENT_WS,address:$TERMINAL_ADDR"
        hyprctl dispatch pin "address:$TERMINAL_ADDR"
        hyprctl dispatch focuswindow "address:$TERMINAL_ADDR"
    else
        echo "Unpinning and hiding terminal to special workspace"
        hyprctl dispatch pin "address:$TERMINAL_ADDR"  # Unpin (toggle)
        sleep 0.1
        hyprctl dispatch movetoworkspacesilent "$SPECIAL_WS,address:$TERMINAL_ADDR"
    fi
else
    echo "Creating new dropdown terminal with command: $TERMINAL_CMD"
    hyprctl dispatch exec "[float; move 25% 5%; size 50% 50%] $TERMINAL_CMD"
    sleep 0.5
    if terminal_exists; then
        TERMINAL_ADDR=$(get_terminal_address)
        hyprctl dispatch pin "address:$TERMINAL_ADDR"
        hyprctl dispatch focuswindow "address:$TERMINAL_ADDR"
    fi
fi
