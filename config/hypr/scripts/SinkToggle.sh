#!/usr/bin/env bash

#// Credits to sl1ng for the orginal script. Rewritten by Vyle.
#// We will NOT USE set -e -u -o pipefail for this script - Avoids rewriting!

XDG_CONFIG_HOME="$HOME/.config"
swayIconDir="${XDG_CONFIG_HOME}/swaync/icons"

ctlcheck=("pactl" "jq" "notify-send")

#// Parse ctlcheck to declare the script to be available for us.
for i in "${!ctlcheck[@]}"; do
  if ! command -v "${ctlcheck[i]}" >/dev/null; then
    echo "${ctlcheck[i]} does not exist, require manual parsing!"
  fi
done

PID=$(hyprctl -j activewindow 2>/dev/null | jq -r '"\(.pid) \(.class) \(.title)"' || exit 1)

#// Read $PID
read -r __pid __class __title <<< "${PID}"

[[ -z "${__pid}" ]] && { echo -e "Could not resolve PID for focused window."; exit 1; }

#// Get process.id and application.name.
mapfile -t sink_ids < <(pactl -f json list sink-inputs 2>/dev/null | iconv -f utf-8 -t utf-8 -c  | jq -r --arg pid "${__pid}" --arg class "${__class}" --arg title "${__title}" '
.[] |
  select(
    (.properties["application.process.id"] == $pid)
    or
    (.properties["application.process.binary"] | ascii_downcase == ($class | ascii_downcase))
    or
    (.properties["application.name"] | ascii_downcase == ($class | ascii_downcase))
    or
    (.properties["media.name"] | ascii_downcase | contains($title | ascii_downcase))
    ) | .index'
)

# Let's parse!
idsJson=$(printf '%s\n' "${sink_ids[@]}" | jq -s 'map(tonumber)')

#// Verify the output of mute: "${want_mute}" from pactl -f.
want_mute=$(
  pactl -f json list sink-inputs | iconv -f utf-8 -t utf-8 -c | \
  jq -r --argjson ids "$idsJson" '
    [ .[] | select(.index as $i | $ids | index($i)) | .mute ] as $m |
    if all($m[]; . == true) then "no"
    else "yes"
    end
  '
)

if [[ ${#sink_ids[@]} -eq 0 ]]; then
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE}" ]]; then
    notify-send -a "t1" -r 91190 -t 1200 -i "${swayIconDir}/volume-low.png" "No sink input for the active_window: ${__class}"
    echo "No sink input for focused window: ${__class}"
    exit 0
  else
    echo "No sink input for focused active_window ${__class}"
    exit 1
  fi
fi

#// Toggle Mute/Unmute for the activewindow.
for id in "${sink_ids[@]}"; do
  pactl set-sink-input-mute "$id" "$want_mute"
done

if [[ "${want_mute}" == "no" ]]; then
  state_msg="Unmuted"
  swayIcon="${swayIconDir}/volume-high.png"
else
  state_msg="Muted"
  swayIcon="${swayIconDir}/volume-mute.png"
fi

notify-send -a "t2" -r 91190 -t 800 -i "${swayIcon}" "${state_msg} ${__class}" "$(pamixer --get-default-sink | awk -F '"' 'END{print $(NF - 1)}')"

