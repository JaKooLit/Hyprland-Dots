#!/bin/bash
# USAGE / ІНСТРУКЦІЯ:
# 1) Run from terminal:
#    ./dispatch.sh <application_command> <target_workspace_number>
#    Example:
#    ./dispatch.sh discord 2
#
# 2) Call from Hyprland config (in hyprland.conf file):
#    exec-once = /path/to/dispatch.sh <application_command> <target_workspace_number>
#
# Logs are saved in dispatch.log file next to the script.
# If the window doesn't appear or is dispatched incorrectly — info will be there.
#
# Notes:
# - Script waits about ~9 seconds (30 iterations of 0.3 sec) for window to appear.
# - Uses hyprctl and jq, so these tools must be installed.
#
# USAGE / ІНСТРУКЦІЯ:
# 1) Запуск з терміналу:
#    ./dispatch.sh <application_command> <target_workspace_number>
#    Наприклад:
#    ./dispatch.sh discord 2
#
# 2) Виклик з конфігурації Hyprland (у файлі hyprland.conf):
#    exec-once = /path/to/dispatch.sh <application_command> <target_workspace_number>
#
# Логи зберігаються у файлі dispatch.log поруч зі скриптом.
# Якщо вікно не з'явилось або неправильно диспатчилось — інформація там.
#
# Примітки:
# - Скрипт чекає до ~9 секунд (30 ітерацій по 0.3 сек) поки вікно з'явиться.
# - Використовує hyprctl і jq, тому ці інструменти мають бути встановлені.

LOGFILE="$(dirname "$0")/dispatch.log"
# Log file path located next to the script.
# Файл логів розташований поруч зі скриптом.

APP=$1
# The application command or window class to launch or match.
# Команда для запуску аплікації або клас вікна для пошуку.

TARGET_WORKSPACE=$2
# The target workspace number where the window should be moved.
# Цільовий номер воркспейсу, куди потрібно перемістити вікно.

# Check if required arguments are provided.
# Перевірка наявності необхідних параметрів.
if [[ -z "$APP" || -z "$TARGET_WORKSPACE" ]]; then
    echo "Usage: $0 <application_command> <target_workspace_number>" >> "$LOGFILE" 2>&1
    exit 1
fi

echo "Starting dispatch of '$APP' to workspace $TARGET_WORKSPACE at $(date)" >> "$LOGFILE"
# Starting the dispatch process and logging the event.
# Початок процесу диспатчу, запис у лог.

# Avoid early workspace focus issues by switching workspace first.
# Уникаємо проблем з раннім фокусом, спочатку переключаємо воркспейс.
hyprctl dispatch workspace "$TARGET_WORKSPACE" >> "$LOGFILE" 2>&1
sleep 0.4

# Launch the application in the background and disown it.
# Запускаємо аплікацію у фоновому режимі та відв’язуємо від терміналу.
$APP & disown
pid=$!

echo "Launched '$APP' with PID $pid" >> "$LOGFILE"
# Log the launched process ID.
# Лог процесу запуску з PID.

# Wait for the application window to appear (matching window class).
# Чекаємо появи вікна аплікації (за класом вікна).
for i in {1..30}; do
    win=$(hyprctl clients -j | jq -r --arg APP "$APP" '
        .[] | select(.class | test($APP;"i")) | .address' 2>>"$LOGFILE")

    if [[ -n "$win" ]]; then
        echo "Found window $win for app '$APP', moving to workspace $TARGET_WORKSPACE" >> "$LOGFILE"
        # Move the window to the target workspace.
        # Переміщаємо вікно на цільовий воркспейс.
        hyprctl dispatch movetoworkspace "$TARGET_WORKSPACE,address:$win" >> "$LOGFILE" 2>&1
        exit 0
    fi
    sleep 0.3
done

echo "ERROR: Window for '$APP' was NOT found or dispatched properly to workspace $TARGET_WORKSPACE at $(date)" >> "$LOGFILE"
# Log error if window was not found or dispatched correctly.
# Запис помилки, якщо вікно не знайдено або неправильно диспатчено.
exit 1
