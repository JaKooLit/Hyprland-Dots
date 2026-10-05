#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Wallpaper daemon compatibility helper.
#
# swww has been unmaintained and was replaced by its successor awww
# (https://codeberg.org/LGFae/awww). Distributions renamed the package
# accordingly (e.g. Arch extra/awww Provides/Replaces swww) and ship
# awww/awww-daemon binaries instead of swww/swww-daemon.
#
# Source this file to detect the available daemon and get:
#   WWW_CMD          - client binary (awww or swww)
#   WWW_DAEMON       - daemon binary (awww-daemon or swww-daemon)
#   WWW_DAEMON_ARGS  - required daemon arguments
#   WWW_CACHE_DIR    - wallpaper cache directory
#   www_start_daemon - start the daemon unless it is already running
#
# Executed directly as `WallpaperDaemon.sh start [image ...]` it starts
# the daemon (and optionally sets wallpaper images) - intended for
# exec-once in Startup_Apps.conf.

if command -v awww >/dev/null 2>&1; then
  WWW_CMD="awww"
  WWW_DAEMON="awww-daemon"
  WWW_CACHE_DIR="$HOME/.cache/awww"
  WWW_DAEMON_ARGS=()
else
  WWW_CMD="swww"
  WWW_DAEMON="swww-daemon"
  WWW_CACHE_DIR="$HOME/.cache/swww"
  WWW_DAEMON_ARGS=(--format xrgb)
fi

# Start the wallpaper daemon unless it is already answering queries
www_start_daemon() {
  "$WWW_CMD" query >/dev/null 2>&1 && return 0
  "$WWW_DAEMON" "${WWW_DAEMON_ARGS[@]}" >/dev/null 2>&1 &
  # give the daemon a moment to accept connections
  for _ in {1..20}; do
    "$WWW_CMD" query >/dev/null 2>&1 && return 0
    sleep 0.1
  done
  return 1
}

# Only run the exec-once entry point when invoked directly (not when sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ "${1:-}" == "start" ]]; then
    shift
    www_start_daemon || exit 1
    for _img in "$@"; do
      [[ -f "$_img" ]] && "$WWW_CMD" img "$_img"
    done
  fi
fi
