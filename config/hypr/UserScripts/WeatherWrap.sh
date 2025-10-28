#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Weather entrypoint: prefer Python (Open‑Meteo), fallback to legacy Bash (wttr.in)

SCRIPT_DIR="$(dirname "$0")"
PY_SCRIPT="$SCRIPT_DIR/Weather.py"
BASH_FALLBACK="$SCRIPT_DIR/Weather.sh"

run_fallback() {
    if [ -f "$BASH_FALLBACK" ]; then
        # Invoke via bash to avoid requiring +x and ensure consistent shell
        bash "$BASH_FALLBACK" "$@"
        return $?
    else
        echo "Weather fallback not found: $BASH_FALLBACK" >&2
        return 127
    fi
}

if command -v python3 >/dev/null 2>&1; then
    python3 "$PY_SCRIPT" "$@"
    exit_code=$?
    if [ "$exit_code" -eq 0 ]; then
        exit 0
    fi
    echo "Weather.py failed with code $exit_code — falling back to Weather.sh" >&2
    run_fallback "$@"
    exit $?
else
    echo "python3 not found in PATH — falling back to Weather.sh" >&2
    run_fallback "$@"
    exit $?
fi