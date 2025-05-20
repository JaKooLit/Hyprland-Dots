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

set -euo pipefail  # Strict error handling: exit on error, unset variables, and pipeline failure

# Configuration
CONFIG="$HOME/.config/hypr/UserConfigs/Startup_Apps.conf"  # Path to user startup config
SCRIPTS_DIR="$(dirname "$CONFIG")"  # Directory containing the config
DEPLOY_DIR="$SCRIPTS_DIR/deploy-scripts"  # Directory to store generated deployment scripts
mkdir -p "$DEPLOY_DIR"  # Ensure deployment directory exists

# Print debug info
echo "[DEBUG] CONFIG=$CONFIG"
echo "[DEBUG] SCRIPTS_DIR=$SCRIPTS_DIR"
echo "[DEBUG] DEPLOY_DIR=$DEPLOY_DIR"

# Dependencies check
echo "[DEBUG] Checking dependencies..."
for cmd in hyprctl jq wofi; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is required but not installed." >&2
        exit 1
    fi
    echo "[DEBUG] Found dependency: $cmd"
done

# Prompt user whether to capture all workspaces or select one
echo "[DEBUG] Prompting for capture mode (all or one workspace)..."
CAPTURE_ALL=$(printf "No\nYes" | wofi --dmenu --prompt="Capture all workspaces?" --lines=2)
echo "[DEBUG] CAPTURE_ALL=$CAPTURE_ALL"

if [[ "$CAPTURE_ALL" == "Yes" ]]; then
    # Get list of all workspace IDs if user wants to capture all
    echo "[DEBUG] Fetching all workspace IDs..."
    mapfile -t WS_LIST < <(hyprctl workspaces -j | jq -r '.[].id' | sort -n)
else
    # Prompt user to select a single workspace
    echo "[DEBUG] Prompting user to select a workspace..."
    WS_SELECTION=$(hyprctl workspaces -j | jq -r '.[].id' | sort -n | wofi --dmenu --prompt="Select workspace to capture:" --lines=10)
    echo "[DEBUG] WS_SELECTION=$WS_SELECTION"
    if [[ -z "$WS_SELECTION" ]]; then
        echo "No workspace selected, exiting."
        exit 0
    fi
    WS_LIST=("$WS_SELECTION")
fi

echo "[DEBUG] Workspaces to capture: ${WS_LIST[*]}"

# Get all current clients (windows)
echo "[DEBUG] Capturing all clients..."
ALL_CLIENTS=$(hyprctl clients -j)
echo "[DEBUG] Raw clients JSON captured."

# Parse clients' PIDs and workspace IDs
CMDS=()
echo "[DEBUG] Parsing clients for PID and workspace..."
while read -r PID WS; do
    echo "[DEBUG] Processing PID=$PID, WS=$WS"
    [[ -e "/proc/$PID/cmdline" ]] || { echo "[DEBUG] Skipping nonexistent PID=$PID"; continue; }  # Skip if process doesn't exist
    CMDLINE=$(tr '\0' ' ' < "/proc/$PID/cmdline")  # Read command line
    echo "[DEBUG] CMDLINE=$CMDLINE"
    [[ -n "$CMDLINE" ]] && CMDS+=("$CMDLINE::$WS")
    echo "[DEBUG] Recorded command: $CMDLINE on workspace $WS"
done < <(echo "$ALL_CLIENTS" | jq -r '.[] | "\(.pid) \(.workspace.id)"')

# Filter entries by selected workspaces and deduplicate
FILTERED=()
echo "[DEBUG] Filtering clients by selected workspaces..."
for ENTRY in "${CMDS[@]}"; do
    WS=${ENTRY##*::}  # Extract workspace ID from the entry
    echo "[DEBUG] Checking ENTRY=$ENTRY for workspace match"
    if [[ "$CAPTURE_ALL" == "Yes" ]] || [[ " ${WS_LIST[*]} " == *"$WS"* ]]; then
        FILTERED+=("$ENTRY")
        echo "[DEBUG] Added to FILTERED: $ENTRY"
    fi

done

# Remove duplicates
mapfile -t UNIQUE_ENTRIES < <(printf "%s\n" "${FILTERED[@]}" | awk '!seen[$0]++')
echo "[DEBUG] Unique entries count: ${#UNIQUE_ENTRIES[@]}"

# Prompt for script alias/name
echo "[DEBUG] Prompting for script alias..."
SCRIPT_ALIAS=$(wofi --dmenu --prompt="Enter script alias (or leave empty for random):" --lines=1 --width=500 --height=30 --hide-scroll --allow-markup --insensitive --no-custom)
echo "[DEBUG] SCRIPT_ALIAS before fallback: $SCRIPT_ALIAS"
if [[ -z "$SCRIPT_ALIAS" ]]; then
    # Generate a random name if user doesn't input one
    RANDOM_NAME=$(tr -dc '0-9' </dev/urandom | fold -w6 | head -n1)
    SCRIPT_ALIAS="deploy_$RANDOM_NAME"
    echo "[DEBUG] Generated random alias: $SCRIPT_ALIAS"
fi
SCRIPT_PATH="$DEPLOY_DIR/$SCRIPT_ALIAS.sh"
echo "[DEBUG] SCRIPT_PATH=$SCRIPT_PATH"

# Write the deployment script
echo "[DEBUG] Writing deployment script..."
{
    echo "#!/usr/bin/env bash"
    if [[ "$CAPTURE_ALL" == "Yes" ]]; then
        echo "# Deployment script for all workspaces"
    else
        echo "# Deployment script for workspace ${WS_LIST[*]}"
    fi
    for ENTRY in "${UNIQUE_ENTRIES[@]}"; do
        CMD=${ENTRY%%::*}  # Extract command
        WS=${ENTRY##*::}   # Extract workspace
        echo "( $CMD & ) && sleep 1 && hyprctl dispatch movetoworkspace $WS"
    done
} > "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
echo "[DEBUG] Script written and made executable."

echo "Deployment script created at: $SCRIPT_PATH"

# Prompt to add the script to Hyprland startup config
echo "[DEBUG] Prompting to add script to Hyprland startup config..."
ADD_STARTUP=$(printf "No\nYes" | wofi --dmenu --prompt="Add script to Hyprland startup?" --lines=2)
echo "[DEBUG] ADD_STARTUP=$ADD_STARTUP"
if [[ "$ADD_STARTUP" == "Yes" ]]; then
    echo "[DEBUG] Checking if script already exists in config..."
    EXISTING=$(grep -E "exec-once = .*${SCRIPT_ALIAS}.sh" "$CONFIG" || true)
    if [[ -n "$EXISTING" ]]; then
        # Let user choose whether to override or add another entry
        echo "[DEBUG] Existing entry detected: $EXISTING"
        CHOICE=$(printf "Add\nOverride" | wofi --dmenu --prompt="Existing startup entries detected. Add or Override?" --lines=2)
        echo "[DEBUG] Override choice: $CHOICE"
        if [[ "$CHOICE" == "Override" ]]; then
            sed -i.bak "/exec-once = .*${SCRIPT_ALIAS}.sh/d" "$CONFIG"
            echo "[DEBUG] Removed existing entry."
        fi
    fi
    echo "exec-once = $SCRIPT_PATH" >> "$CONFIG"
    echo "Added to Hyprland startup: exec-once = $SCRIPT_PATH"
else
    echo "Skipped adding to Hyprland startup."
fi

# Prompt to add zsh alias
echo "[DEBUG] Prompting to add zsh alias..."
ADD_ZSH_ALIAS=$(printf "No\nYes" | wofi --dmenu --prompt="Add zsh alias for this script?" --lines=2)
echo "[DEBUG] ADD_ZSH_ALIAS=$ADD_ZSH_ALIAS"
if [[ "$ADD_ZSH_ALIAS" == "Yes" ]]; then
    # Prompt for alias name
    ALIAS_NAME=$(wofi --dmenu --prompt="Enter zsh alias name (or leave empty for script alias):" --lines=1 --width=500 --height=30 --hide-scroll --allow-markup --insensitive --no-custom)
    echo "[DEBUG] ALIAS_NAME before fallback: $ALIAS_NAME"
    if [[ -z "$ALIAS_NAME" ]]; then
        ALIAS_NAME=$SCRIPT_ALIAS
        echo "[DEBUG] Defaulting alias to script alias: $ALIAS_NAME"
    fi
    echo "alias $ALIAS_NAME='bash $SCRIPT_PATH'" >> "$HOME/.zshrc"
    echo "Added alias '$ALIAS_NAME' to ~/.zshrc"
else
    echo "Skipped adding zsh alias."
fi

echo "All done!"
