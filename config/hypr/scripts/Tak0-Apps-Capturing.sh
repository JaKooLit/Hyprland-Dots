##################################################################
#                                                                #   
#                                                                #
#             TAK_0'S Apps-Capturing-And-Deploying               #
#                                                                #
#                                                                #
#                                                                #
#    Script that allows you to capture all the windows on the    #
#       certain workspace and deploy that pack in future.        #
#                                                                #
#                                                                #
#                                                                #
#    For some unexplainable reason though the text prompt        #
#     does not work in wofi, so just for you to know - if there  # 
#        is an empty text line - it asks you for the name        #
#                                                                #
##################################################################



#!/usr/bin/env bash
# Captures running applications on one or all Hyprland workspaces and generates a deployment script

set -euo pipefail

# Configuration
CONFIG="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"
SCRIPTS_DIR="$(dirname "$CONFIG")"
DEPLOY_DIR="$SCRIPTS_DIR/deploy-scripts"
mkdir -p "$DEPLOY_DIR"

# Dependencies check
for cmd in hyprctl jq wofi; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is required but not installed." >&2
        exit 1
    fi
done

# 1) Ask which workspace(s) to capture
CAPTURE_ALL=$(printf "No\nYes" | wofi --dmenu --prompt="Capture all workspaces?" --lines=2)
if [[ "$CAPTURE_ALL" == "Yes" ]]; then
    mapfile -t WS_LIST < <(hyprctl workspaces -j | jq -r '.[].id' | sort -n)
else
    WS_SELECTION=$(hyprctl workspaces -j | jq -r '.[].id' | sort -n | wofi --dmenu --prompt="Select workspace to capture:" --lines=10)
    if [[ -z "$WS_SELECTION" ]]; then
        echo "No workspace selected, exiting."
        exit 0
    fi
    WS_LIST=("$WS_SELECTION")
fi

# Capture all clients upfront
ALL_CLIENTS=$(hyprctl clients -j)

# Build list of pid::workspace
CMDS=()
while read -r PID WS; do
    [[ -e "/proc/$PID/cmdline" ]] || continue
    CMDLINE=$(tr '\0' ' ' < "/proc/$PID/cmdline")
    [[ -n "$CMDLINE" ]] && CMDS+=("$CMDLINE::$WS")
done < <(echo "$ALL_CLIENTS" | jq -r '.[] | "\(.pid) \(.workspace.id)"')

# Filter to requested workspaces and dedupe
FILTERED=()
for ENTRY in "${CMDS[@]}"; do
    WS=${ENTRY##*::}
    if [[ "$CAPTURE_ALL" == "Yes" ]] || [[ " ${WS_LIST[*]} " == *"$WS"* ]]; then
        FILTERED+=("$ENTRY")
    fi
done
mapfile -t UNIQUE_ENTRIES < <(printf "%s\n" "${FILTERED[@]}" | awk '!seen[$0]++')

# 2) Prompt for script alias/name (fix: ensure default placeholder shown)
SCRIPT_ALIAS=$(wofi --dmenu --prompt="Enter script alias (or leave empty for random):" --lines=1 --width=500 --height=30 --hide-scroll --allow-markup --insensitive --no-custom)
if [[ -z "$SCRIPT_ALIAS" ]]; then
    RANDOM_NAME=$(tr -dc '0-9' </dev/urandom | fold -w6 | head -n1)
    SCRIPT_ALIAS="deploy_$RANDOM_NAME"
fi
SCRIPT_PATH="$DEPLOY_DIR/$SCRIPT_ALIAS.sh"

# Write the deploy script
{
    echo "#!/usr/bin/env bash"
    if [[ "$CAPTURE_ALL" == "Yes" ]]; then
        echo "# Deployment script for all workspaces"
    else
        echo "# Deployment script for workspace ${WS_LIST[*]}"
    fi
    for ENTRY in "${UNIQUE_ENTRIES[@]}"; do
        CMD=${ENTRY%%::*}
        WS=${ENTRY##*::}
        echo "( $CMD & ) && sleep 1 && hyprctl dispatch movetoworkspace $WS"
    done
} > "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

echo "Deployment script created at: $SCRIPT_PATH"

# 3) Prompt to add to Hyprland startup config
ADD_STARTUP=$(printf "No\nYes" | wofi --dmenu --prompt="Add script to Hyprland startup?" --lines=2)
if [[ "$ADD_STARTUP" == "Yes" ]]; then
    EXISTING=$(grep -E "exec-once = .*${SCRIPT_ALIAS}.sh" "$CONFIG" || true)
    if [[ -n "$EXISTING" ]]; then
        CHOICE=$(printf "Add\nOverride" | wofi --dmenu --prompt="Existing startup entries detected. Add or Override?" --lines=2)
        if [[ "$CHOICE" == "Override" ]]; then
            sed -i.bak "/exec-once = .*${SCRIPT_ALIAS}.sh/d" "$CONFIG"
        fi
    fi
    echo "exec-once = $SCRIPT_PATH" >> "$CONFIG"
    echo "Added to Hyprland startup: exec-once = $SCRIPT_PATH"
else
    echo "Skipped adding to Hyprland startup."
fi

# 4) Prompt to add a zsh alias for this script
ADD_ZSH_ALIAS=$(printf "No\nYes" | wofi --dmenu --prompt="Add zsh alias for this script?" --lines=2)
if [[ "$ADD_ZSH_ALIAS" == "Yes" ]]; then
    ALIAS_NAME=$(wofi --dmenu --prompt="Enter zsh alias name (or leave empty for script alias):" --lines=1 --width=500 --height=30 --hide-scroll --allow-markup --insensitive --no-custom)
    if [[ -z "$ALIAS_NAME" ]]; then
        ALIAS_NAME=$SCRIPT_ALIAS
    fi
    echo "alias $ALIAS_NAME='bash $SCRIPT_PATH'" >> "$HOME/.zshrc"
    echo "Added alias '$ALIAS_NAME' to ~/.zshrc"
else
    echo "Skipped adding zsh alias."
fi

echo "All done!"
