#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# weather info using Python script with Open-Meteo APIs

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found in PATH" >&2
    exit 127
fi

python3 "$(dirname "$0")/Weather.py" "$@"
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
    echo "Failed to run Weather.py" >&2
fi
exit "$exit_code"