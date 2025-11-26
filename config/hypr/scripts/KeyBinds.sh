#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# searchable enabled keybinds using rofi (supports bindd descriptions)

# kill yad to not interfere with this binds
pkill yad || true

# check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

# define the config files
keybinds_conf="$HOME/.config/hypr/configs/Keybinds.conf"
user_keybinds_conf="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
laptop_conf="$HOME/.config/hypr/UserConfigs/Laptops.conf"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg='☣️ NOTE ☣️: Clicking with Mouse or Pressing ENTER will have NO function'

# collect raw bind lines (strip end-of-line comments) from available files
files=("$keybinds_conf" "$user_keybinds_conf")
[[ -f "$laptop_conf" ]] && files+=("$laptop_conf")

# Parse binds/unbinds from files, detect overrides, and keep unique effective binds
declare -A binding_map        # combo -> bind line (effective)
declare -A source_map         # combo -> source file
declare -A user_bind_map      # combo -> user bind line
declare -A unbound_user       # combo -> 1 if explicitly unbound in user file
declare -A seen_any_bind      # combo -> 1 if any bind seen (for iteration)
declare -A default_seen       # combo -> 1 if default bind exists
declare -a missing_unbind_suggestions_arr

normalize_combo() { echo "$1" | sed -E 's/[[:space:]]//g'; }

extract_combo() {
  # arg: a bind/unbind line; returns "mods,key" via echo
  local s="$1"
  s="$(echo "$s" | sed -E 's/[[:space:]]+#.*$//')"
  if [[ "$s" =~ = ]]; then
    local rhs="${s#*=}"
    local mods="$(echo "$rhs" | awk -F',' '{gsub(/^[ \t]+|[ \t]+$/,"",$1); print $1}')"
    local key="$(echo "$rhs"  | awk -F',' '{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}')"
    echo "${mods},${key}"
  fi
}

for file in "${files[@]}"; do
  [[ ! -f "$file" ]] && continue
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    if [[ "$line" =~ ^[[:space:]]*bind[a-z]*[[:space:]]*= ]]; then
      combo_raw="$(extract_combo "$line")"
      [[ -z "$combo_raw" ]] && continue
      combo="$(normalize_combo "$combo_raw")"
      seen_any_bind["$combo"]=1

      if [[ "$file" != "$user_keybinds_conf" ]]; then
        default_seen["$combo"]=1
      fi

      # prefer user bind, else first seen
      if [[ -z "${source_map[$combo]}" ]]; then
        binding_map["$combo"]="$line"
        source_map["$combo"]="$file"
      fi
      if [[ "$file" == "$user_keybinds_conf" ]]; then
        user_bind_map["$combo"]="$line"
        binding_map["$combo"]="$line"
        source_map["$combo"]="$file"
      fi

    elif [[ "$line" =~ ^[[:space:]]*unbind[[:space:]]*= ]]; then
      combo_raw="$(extract_combo "$line")"
      [[ -z "$combo_raw" ]] && continue
      combo="$(normalize_combo "$combo_raw")"
      if [[ "$file" == "$user_keybinds_conf" ]]; then
        unbound_user["$combo"]=1
      fi
    fi
  done < "$file"
done

# Build raw_keybinds for display and collect missing unbind suggestions
raw_keybinds=""
for combo in "${!seen_any_bind[@]}"; do
  eff_line="${binding_map[$combo]}"
  src="${source_map[$combo]}"
  [[ -z "$eff_line" ]] && continue
  raw_keybinds+="$eff_line"$'\n'

  # If user overrides a default but didn't unbind in user file, suggest unbind
  if [[ "$src" == "$user_keybinds_conf" && -n "${default_seen[$combo]}" && -z "${unbound_user[$combo]}" ]]; then
    suggest="$(echo "$eff_line" | sed -E 's/^[[:space:]]*bind[a-z]*/unbind/')"
    missing_unbind_suggestions_arr+=("$suggest")
  fi
done

# If there are missing unbinds, write suggestions to a temp file and note in message
if (( ${#missing_unbind_suggestions_arr[@]} > 0 )); then
  suggestions_file="$(mktemp -t hypr-unbind-suggestions.XXXX.conf)"
  printf '%s\n' "${missing_unbind_suggestions_arr[@]}" > "$suggestions_file"
  msg="$msg | Overrides missing unbind: ${#missing_unbind_suggestions_arr[@]} (suggestions: $suggestions_file)"
fi

# check for any keybinds to display
if [[ -z "$raw_keybinds" ]]; then
    echo "no keybinds found."
    exit 1
fi

# transform into a readable list: MODS+KEY — DESCRIPTION (for bindd) or DISPATCHER [PARAMS] (for bind)
display_keybinds=$(echo "$raw_keybinds" | awk -F'=' '
  function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
  /^[[:space:]]*bind/ {
    binder=$1; gsub(/[ \t]/, "", binder);
    hasdesc = (index(binder, "d")>0);

    rhs=$2; rhs=trim(rhs);
    n=split(rhs, a, /[ \t]*,[ \t]*/);

    mods=trim(a[1]); key=(n>=2?trim(a[2]):"");
    desc=""; dispatcher=""; params="";

    if (hasdesc) {
      desc=(n>=3?trim(a[3]):"");
      dispatcher=(n>=4?trim(a[4]):"");
      start=5;
    } else {
      dispatcher=(n>=3?trim(a[3]):"");
      start=4;
    }

    for(i=start;i<=n;i++){ if(length(a[i])){ p=trim(a[i]); if(p!="") params = (params?params", ":"") p } }

    gsub(/\$mainMod/,"SUPER",mods);
    gsub(/[ \t]+/,"+",mods);

    combo = (mods && key) ? mods "+" key : (key?key:mods);

    if (hasdesc && desc != "") {
      print combo, " — ", desc;
    } else {
      if (dispatcher != "" && params != "")
        print combo, " — ", dispatcher, " ", params;
      else if (dispatcher != "")
        print combo, " — ", dispatcher;
      else
        print combo;
    }
  }
')

# use rofi to display the keybinds
printf '%s\n' "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"
