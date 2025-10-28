#!/usr/bin/env bash
# Compose merged Hyprland configs for Startup_Apps and WindowRules
set -euo pipefail

BASE_DIR="$HOME/.config/hypr"
BASE_CFG_DIR="$BASE_DIR/configs"
USER_DIR="$BASE_DIR/UserConfigs"
GEN_DIR="$BASE_DIR/generated"

mkdir -p "$GEN_DIR"

log() { printf "[compose] %s\n" "$*"; }

# Trim leading/trailing whitespace
trim() { sed -E 's/^\s+//;s/\s+$//'; }

# Normalize spaces in a directive line
normalize() { awk '{$1=$1;print}'; }

# Build merged Startup_Apps.conf
compose_startup_apps() {
  local base_file="$BASE_CFG_DIR/Startup_Apps.conf"
  local user_file="$USER_DIR/Startup_Apps.conf"
  local disable_file="$USER_DIR/Startup_Apps.disable"
  local out_file="$GEN_DIR/Startup_Apps.conf"

  : >"$out_file"

  # Header and variable lines come from base
  if [[ -f "$base_file" ]]; then
    # Copy all non exec-once lines (comments, blanks, variables, etc.)
    grep -Ev '^\s*exec-once\s*=' "$base_file" || true >>"$out_file"
  fi

  # Collect exec-once commands (the right side of '=')
  declare -A cmds=()

  if [[ -f "$base_file" ]]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^\s*exec-once\s*= ]] || continue
      cmd="${line#*=}"
      cmd="$(echo "$cmd" | trim)"
      cmds["$cmd"]=1
    done <"$base_file"
  fi

  if [[ -f "$user_file" ]]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^\s*exec-once\s*= ]] || continue
      cmd="${line#*=}"
      cmd="$(echo "$cmd" | trim)"
      cmds["$cmd"]=1
    done <"$user_file"
  fi

  # Apply disables (exact match of command string)
  if [[ -f "$disable_file" ]]; then
    while IFS= read -r d; do
      d="$(echo "$d" | trim)"
      [[ -z "$d" || "$d" =~ ^# ]] && continue
      unset 'cmds[$d]'
    done <"$disable_file"
  fi

  # Emit combined exec-once (stable sort)
  for k in "${!cmds[@]}"; do echo "$k"; done | sort -u | while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    printf "exec-once = %s\n" "$cmd" >>"$out_file"
  done

  log "Wrote $out_file"
}

# Build merged WindowRules.conf
compose_window_rules() {
  local base_file="$BASE_CFG_DIR/WindowRules.conf"
  local user_file="$USER_DIR/WindowRules.conf"
  local disable_file="$USER_DIR/WindowRules.disable"
  local out_file="$GEN_DIR/WindowRules.conf"

  : >"$out_file"
  echo "# Generated merged WindowRules" >>"$out_file"

  declare -A rules=()
  add_rules() {
    local f="$1"
    [[ -f "$f" ]] || return 0
    grep -E '^(windowrule|layerrule)\s*=' "$f" | trim | while IFS= read -r r; do
      rules["$r"]=1
    done
  }

  add_rules "$base_file"
  add_rules "$user_file"

  if [[ -f "$disable_file" ]]; then
    while IFS= read -r d; do
      d="$(echo "$d" | trim)"
      [[ -z "$d" || "$d" =~ ^# ]] && continue
      unset 'rules[$d]'
    done <"$disable_file"
  fi

  for r in "${!rules[@]}"; do echo "$r"; done | sort -u >>"$out_file"
  log "Wrote $out_file"
}

compose_startup_apps
compose_window_rules