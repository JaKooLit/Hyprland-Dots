#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Dropdown Terminal 
# Usage: ./dropdown.sh [-d] <terminal_command>
# Example: ./dropdown.sh foot
#          ./dropdown.sh -d foot (with debug output)
#          ./dropdown.sh "kitty -e zsh"
#          ./dropdown.sh "alacritty --working-directory /home/user"

DEBUG=false
SPECIAL_WS="special:scratchpad"
ADDR_FILE="/tmp/dropdown_terminal_addr"

# Parse arguments
if [ "$1" = "-d" ]; then
    DEBUG=true
    shift
fi

TERMINAL_CMD="$1"

# Debug echo function
debug_echo() {
    if [ "$DEBUG" = true ]; then
        echo "$@"
    fi
}

# Validate input
if [ -z "$TERMINAL_CMD" ]; then
    echo "Missing terminal command. Usage: $0 [-d] <terminal_command>"
    echo "Examples:"
    echo "  $0 foot"
    echo "  $0 -d foot (with debug output)"
    echo "  $0 'kitty -e zsh'"
    echo "  $0 'alacritty --working-directory /home/user'"
    exit 1
fi

# Get the current workspace
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

# Function to get stored terminal address
get_terminal_address() {
    if [ -f "$ADDR_FILE" ] && [ -s "$ADDR_FILE" ]; then
        cat "$ADDR_FILE"
    fi
}

# Function to check if terminal exists
terminal_exists() {
    local addr=$(get_terminal_address)
    if [ -n "$addr" ]; then
        hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR)' >/dev/null 2>&1
    else
        return 1
    fi
}

# Function to check if terminal is in special workspace
terminal_in_special() {
    local addr=$(get_terminal_address)
    if [ -n "$addr" ]; then
        hyprctl clients -j | jq -e --arg ADDR "$addr" 'any(.[]; .address == $ADDR and .workspace.name == "special:scratchpad")' >/dev/null 2>&1
    else
        return 1
    fi
}

# Function to spawn terminal and capture its address
spawn_terminal() {
    debug_echo "Creating new dropdown terminal with command: $TERMINAL_CMD"
    
    # Get window count and list before spawning
    local windows_before=$(hyprctl clients -j)
    local count_before=$(echo "$windows_before" | jq 'length')
    
    # Launch terminal with rules applied from the start
    hyprctl dispatch exec "[float; move 25% 5%; size 50% 50%; pin] $TERMINAL_CMD"
    
    # Wait for window to appear
    sleep 1
    
    # Get windows after spawning
    local windows_after=$(hyprctl clients -j)
    local count_after=$(echo "$windows_after" | jq 'length')
    
    if [ "$count_after" -gt "$count_before" ]; then
        # Find the new window by comparing before/after lists
        local new_addr=$(comm -13 \
            <(echo "$windows_before" | jq -r '.[].address' | sort) \
            <(echo "$windows_after" | jq -r '.[].address' | sort) \
            | head -1)
        
        if [ -n "$new_addr" ] && [ "$new_addr" != "null" ]; then
            # Store the address
            echo "$new_addr" > "$ADDR_FILE"
            debug_echo "Terminal created with address: $new_addr"
            return 0
        fi
    fi
    
    # Fallback: try to find by the most recently mapped window
    local new_addr=$(hyprctl clients -j | jq -r 'sort_by(.focusHistoryID) | .[-1] | .address')
    
    if [ -n "$new_addr" ] && [ "$new_addr" != "null" ]; then
        echo "$new_addr" > "$ADDR_FILE"
        debug_echo "Terminal created with address: $new_addr (fallback method)"
        return 0
    fi
    
    debug_echo "Failed to get terminal address"
    return 1
}

# Main logic
if terminal_exists; then
    TERMINAL_ADDR=$(get_terminal_address)
    debug_echo "Found existing terminal: $TERMINAL_ADDR"

    if terminal_in_special; then
        debug_echo "Bringing terminal to workspace $CURRENT_WS and pinning"
        hyprctl dispatch movetoworkspace "$CURRENT_WS,address:$TERMINAL_ADDR"
        hyprctl dispatch pin "address:$TERMINAL_ADDR"
        hyprctl dispatch focuswindow "address:$TERMINAL_ADDR"
    else
        debug_echo "Unpinning and hiding terminal to special workspace"
        hyprctl dispatch pin "address:$TERMINAL_ADDR"  # Unpin (toggle)
        sleep 0.1
        hyprctl dispatch movetoworkspacesilent "$SPECIAL_WS,address:$TERMINAL_ADDR"
    fi
else
    debug_echo "No existing terminal found, creating new one"
    if spawn_terminal; then
        TERMINAL_ADDR=$(get_terminal_address)
        if [ -n "$TERMINAL_ADDR" ]; then
            hyprctl dispatch focuswindow "address:$TERMINAL_ADDR"
        fi
    else
        echo "Failed to create terminal"
        exit 1
    fi
fi