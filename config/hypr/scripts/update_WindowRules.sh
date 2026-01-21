#!/usr/bin/env bash
# Script to update WindowRules config if Hyprland version is >= 0.53

CONFIGS_DIR="$HOME/.config/hypr/configs"
TARGET_FILE="$CONFIGS_DIR/WindowRules.conf"
V3_FILE="$CONFIGS_DIR/WindowRules-config-v3.conf"

if [[ ! -f "$V3_FILE" ]]; then
  echo "Error: Source configuration file not found: $V3_FILE"
  exit 1
fi

get_hyprland_version() {
  local ver="0.0.0"
  local raw_ver=""

  if command -v hyprctl &>/dev/null; then
    raw_ver=$(hyprctl version 2>/dev/null | grep "Tag:" | cut -d 'v' -f2)
  fi

  if [ -z "$raw_ver" ] && command -v Hyprland &>/dev/null; then
    raw_ver=$(Hyprland --version 2>/dev/null | grep "Tag:" | cut -d 'v' -f2 | awk '{print $1}')
  fi

  if [ -n "$raw_ver" ]; then
    ver=$(echo "$raw_ver" | grep -oE '^[0-9]+\.[0-9]+(\.[0-9]+)?')
  fi

  if [ -z "$ver" ]; then
    echo "0.0.0"
  else
    echo "$ver"
  fi
}

VERSION=$(get_hyprland_version)
REQUIRED_VER="0.53"

# Check if version >= REQUIRED_VER
SMALLEST=$(printf '%s\n' "$REQUIRED_VER" "$VERSION" | sort -V | head -n1)

if [ "$SMALLEST" = "$REQUIRED_VER" ]; then
  echo "Version $VERSION >= $REQUIRED_VER. Updating WindowRules config..."
  # Backup existing config if it exists
  if [ -f "$TARGET_FILE" ]; then
    echo "Backing up existing WindowRules.conf to WindowRules.conf.bak"
    mv "$TARGET_FILE" "$TARGET_FILE.bak"
  fi
  cp "$V3_FILE" "$TARGET_FILE"

  if command -v hyprctl &>/dev/null; then
    if hyprctl instances &>/dev/null; then
      echo "Reloading Hyprland..."
      hyprctl reload
    fi
  fi
else
  echo "Version $VERSION < $REQUIRED_VER. No update needed."
fi

