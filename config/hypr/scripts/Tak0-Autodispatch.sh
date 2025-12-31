#!/bin/bash
#
# ─────────────────────────────────────────────────────────────────────────────
# Tak0-Autodispatch.sh
# ─────────────────────────────────────────────────────────────────────────────
#
# 🇺🇦 УКРАЇНСЬКA
# -----------------------------------------------------------------------------
# Цей скрипт — це "розумний автодиспетчер" для Hyprland(особливо актуальний після того, як всі windowrules пішли по пизді після останнього апдейту, що ускладнює життя).
# Його задача — гарантовано закинути ВСІ вікна конкретного запуску
# (основне вікно + helper-и + Electron/Steam-дочірні процеси)
# на конкретний workspace, незалежно від:
#
#  • race conditions
#  • затримок створення вікон
#  • допоміжних процесів (steamwebhelper, gpu-process, renderer)
#  • Electron / Chromium / Steam chaos
#
# Типові юзкейси:
#  • Запуск Steam / Discord / браузерів без "window leakage"
#  • Гарантія, що спавняться НЕ на активному workspace
#  • Контроль вікон, які ігнорують static windowrules
#
# Запуск:
#   ./Tak0-Autodispatch.sh <workspace> [rule ...] -- <command>
#
# Приклади:
#   ./Tak0-Autodispatch.sh 5 "class:^(steam|steamwebhelper)$" -- steam
#   ./Tak0-Autodispatch.sh 7 "class:^(discord)$" -- discord
#
# ВАЖЛИВО:
#  • rules — тимчасові, вони існують тільки під час запуску
#  • нічого не ламає глобальну конфігурацію Hyprland
#
# -----------------------------------------------------------------------------
# 🇬🇧 ENGLISH
# -----------------------------------------------------------------------------
# This script is an "authoritative spawn dispatcher" for Hyprland.
# Its job is to FORCE all windows belonging to a single application launch
# (main window + helpers + Electron/Steam children)
# onto a specific workspace, regardless of:
#
#  • spawn race conditions
#  • delayed window creation
#  • detached helper processes
#  • Electron / Chromium / Steam insanity
#
# Typical use cases:
#  • Launch Steam / Discord / browsers without window leakage
#  • Ensure apps never spawn on the currently focused workspace
#  • Control applications that ignore static windowrules
#
# Invocation:
#   ./Tak0-Autodispatch.sh <workspace> [rule ...] -- <command>
#
# Important:
#  • rules are TEMPORARY and removed after launch
#  • global Hyprland config is not polluted
#
# ─────────────────────────────────────────────────────────────────────────────
#
# REQUIREMENTS:
#   - hyprctl   → control Hyprland at runtime
#   - jq        → parse JSON client list
#   - pgrep/ps  → process tree inspection
#

LOGFILE="$(dirname "$0")/dispatch.log"

# ─────────────────────────────────────────────────────────────────────────────
# 0️⃣ ARGUMENT PARSING
# ─────────────────────────────────────────────────────────────────────────────
#
# UA:
#   1-й аргумент  → target workspace
#   Далі          → capture rules (windowrulev2-compatible)
#   "--"          → роздільник
#   Після "--"    → команда запуску (НЕ shell-escaped автоматично)
#
# EN:
#   First arg     → target workspace
#   Then          → capture rules
#   "--"          → separator
#   After "--"    → command to execute
#

TARGET_WS="$1"
shift

CAPTURE_RULES=()
while [[ "$1" != "--" && -n "$1" ]]; do
    CAPTURE_RULES+=("$1")
    shift
done

shift # remove "--"

CMD="$*"

if [[ -z "$TARGET_WS" || -z "$CMD" ]]; then
    echo "Usage: $0 <workspace> [rule rule ...] -- <command>" >>"$LOGFILE"
    exit 1
fi

# UA:
#   Канонічне ім'я аплікації з команди.
#   Використовується для process-name match,
#   коли Electron / helpers відриваються від ROOT PID.
#
# EN:
#   Canonical application name extracted from command.
#   Used for process-name matching when helpers detach from ROOT PID.
#
APP_NAME="$(basename "$(echo "$CMD" | awk '{print $1}')")"

echo "=== Deploy '$CMD' → WS $TARGET_WS @ $(date) ===" >>"$LOGFILE"
echo "App gate name: $APP_NAME" >>"$LOGFILE"

# ─────────────────────────────────────────────────────────────────────────────
# 1️⃣ WAIT FOR HYPRLAND READINESS
# ─────────────────────────────────────────────────────────────────────────────
#
# UA:
#   Не всі автозапуски стартують після повної ініціалізації Hyprland.
#   Без цього hyprctl може тихо фейлитися.
#
# EN:
#   Some autostarts happen before Hyprland is fully ready.
#   Without this, hyprctl may silently fail.
#
for _ in {1..50}; do
    hyprctl -j monitors >/dev/null 2>&1 && break
    sleep 0.1
done

# ─────────────────────────────────────────────────────────────────────────────
# 2️⃣ TEMPORARY INITIAL CAPTURE
# ─────────────────────────────────────────────────────────────────────────────
#
# UA:
#   Це "ядерна опція".
#   Тимчасово ВСІ вікна (initialClass:.*) примусово
#   відправляються на target workspace.
#
#   Це рятує від:
#    • ultra-fast helpers
#    • gpu-process
#    • renderer spawn before supervision loop
#
# EN:
#   This is the nuclear option.
#   Temporarily forces ALL windows to the target workspace.
#   Prevents ultra-fast helpers from leaking.
#
echo "Applying temporary initialWorkspace capture (initialClass:.*)" >>"$LOGFILE"
hyprctl keyword windowrulev2 \
    "initialWorkspace $TARGET_WS silent, initialClass:.*" \
    >>"$LOGFILE" 2>&1

# ─────────────────────────────────────────────────────────────────────────────
# 2️⃣.0 OPTIONAL PRE-CAPTURE RULES
# ─────────────────────────────────────────────────────────────────────────────
#
# UA:
#   Додаткові class-based правила.
#   Не обовʼязкові, але покращують точність
#   (Steam, Discord, Electron forks).
#
# EN:
#   Optional class-based rules.
#   Improve reliability for Steam / Discord / Electron.
#
for RULE in "${CAPTURE_RULES[@]}"; do
    echo "Applying temporary capture rule: $RULE" >>"$LOGFILE"
    hyprctl keyword windowrulev2 \
        "initialWorkspace $TARGET_WS silent, $RULE" \
        >>"$LOGFILE" 2>&1
done

# ─────────────────────────────────────────────────────────────────────────────
# 3️⃣ APPLICATION LAUNCH
# ─────────────────────────────────────────────────────────────────────────────
#
# UA:
#   Запуск через bash -c дозволяє aliases, env, wrappers.
#   ROOT_PID — точка входу для process-tree matching.
#
# EN:
#   bash -c allows aliases, env vars, wrappers.
#   ROOT_PID is the root for process lineage matching.
#
bash -c "$CMD" &
ROOT_PID=$!
echo "Root PID: $ROOT_PID" >>"$LOGFILE"

# Даємо helper-вікнам зʼявитися
sleep 1.5

# Прибираємо глобальну пастку, щоб не ламати інші апки
echo "Releasing ultra-early wide capture" >>"$LOGFILE"
hyprctl keyword windowrulev2 "unset, initialClass:.*" >>"$LOGFILE" 2>&1

# ─────────────────────────────────────────────────────────────────────────────
# 4️⃣ SUPERVISION LOOP (AUTHORITATIVE PHASE)
# ─────────────────────────────────────────────────────────────────────────────
#
# UA:
#   Це головний мозок.
#   Loop:
#     • читає ВСІ клієнти Hyprland
#     • зіставляє PID, process-name, class
#     • гарантує, що кожне вікно опиниться у WS
#
# EN:
#   This is the brain.
#   The loop:
#     • reads all Hyprland clients
#     • matches PID lineage, process-name, class
#     • guarantees correct workspace placement
#

get_descendants() {
    local all=("$ROOT_PID")
    local changed=1

    while (( changed )); do
        changed=0
        for p in "${all[@]}"; do
            for c in $(pgrep -P "$p" 2>/dev/null); do
                if [[ ! " ${all[*]} " =~ " $c " ]]; then
                    all+=("$c")
                    changed=1
                fi
            done
        done
    done

    echo "${all[@]}"
}

pid_matches_app() {
    local pid="$1"
    local comm
    comm="$(ps -p "$pid" -o comm= 2>/dev/null)" || return 1
    [[ "$comm" == "$APP_NAME" || "$comm" == "$APP_NAME"* ]]
}

END_TIME=$((SECONDS + 20))
declare -A SEEN

while (( SECONDS < END_TIME )); do
    PIDS="$(get_descendants)"

    hyprctl clients -j | jq -r '.[] | "\(.pid) \(.address) \(.class)"' |
    while read -r PID ADDR CLASS; do

        MATCH=0

        # PID lineage
        for TPID in $PIDS; do
            [[ "$PID" == "$TPID" ]] && MATCH=1 && break
        done

        # Detached helpers
        pid_matches_app "$PID" && MATCH=1

        # Class fallback
        for RULE in "${CAPTURE_RULES[@]}"; do
            if [[ "$RULE" =~ class:\^\((.*)\)\$ ]]; then
                [[ "$CLASS" =~ ${BASH_REMATCH[1]} ]] && MATCH=1
            fi
        done

        if (( MATCH )) && [[ -z "${SEEN[$ADDR]}" ]]; then
            echo "Placing window $ADDR (pid $PID, class $CLASS) → WS $TARGET_WS" >>"$LOGFILE"
            hyprctl dispatch movetoworkspacesilent \
                "$TARGET_WS,address:$ADDR" >>"$LOGFILE" 2>&1
            SEEN[$ADDR]=1
        fi
    done

    sleep 0.01
done

# ─────────────────────────────────────────────────────────────────────────────
# 5️⃣ CLEANUP
# ─────────────────────────────────────────────────────────────────────────────
#
# UA:
#   Гарантоване прибирання ВСІХ тимчасових правил.
#   Ніякого windowrulev2-зомбі.
#
# EN:
#   Guaranteed cleanup of ALL temporary rules.
#
for RULE in "${CAPTURE_RULES[@]}"; do
    echo "Removing temporary capture rule: $RULE" >>"$LOGFILE"
    hyprctl keyword windowrulev2 "unset, $RULE" >>"$LOGFILE" 2>&1
done

echo "=== Deploy finished: '$CMD' ===" >>"$LOGFILE"
exit 0
