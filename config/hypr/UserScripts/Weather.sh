#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# weather info from wttr. https://github.com/chubin/wttr.in
# Remember to add city 
# Function to get current city from IP address with fallback

# Get your current location with your IP adress 
get_current_city() {
    local city
    
    # First try: ipinfo.io
    local location_data=$(curl -fsS "https://ipinfo.io/json" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$location_data" ]; then
        city=$(echo "$location_data" | grep -o '"city"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
        if [ -n "$city" ]; then
            echo "$city"
            return 0
        fi
    fi
    
    # Fallback: ipapi.co
    city=$(curl -fsS "https://ipapi.co/json" 2>/dev/null | grep -o '"city"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    if [ -n "$city" ]; then
        echo "$city"
        return 0
    fi
    
    # Last resort: ipwho.is
    city=$(curl -fsS "https://ipwho.is/" 2>/dev/null | grep -o '"city"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    if [ -n "$city" ]; then
        echo "$city"
        return 0
    fi
    
    # If all fail
    echo "Unknown" >&2
    return 1
}

city=$(get_current_city)

# If city is empty, that means the IP check failed, which means, we should use manual setting 
if [ -z "$city" ] || [ "$city" = "Unknown" ]; then
    # SET YOUR MANUAL CITY HERE
    city=" "  # ← Change this to your preferred city
    echo "Using manual city: $city" >&2
fi

# URL-encode city for safe use in URLs
encoded_city="$city"
if command -v python3 >/dev/null 2>&1; then
    encoded_city=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$city")
elif command -v jq >/dev/null 2>&1; then
    encoded_city=$(printf '%s' "$city" | jq -sRr @uri)
else
    # Minimal fallback: encode a few common special characters
    encoded_city=$(printf '%s' "$city" | sed -e 's/ /%20/g' -e 's/&/%26/g' -e 's/?/%3F/g' -e 's/#/%23/g')
fi


cachedir="$HOME/.cache/rbn"
# Include city and arg in cache key so changing city invalidates old cache
cache_key="${city}_${1}"
# Sanitize cache key to avoid problematic characters in filename
safe_key=$(printf '%s' "$cache_key" | tr -c '[:alnum:]_-' '_')
cachefile=${0##*/}-$safe_key

if [ ! -d "$cachedir" ]; then
    mkdir -p "$cachedir"
fi

if [ ! -f "$cachedir/$cachefile" ]; then
    touch "$cachedir/$cachefile"
fi

# Save current IFS
SAVEIFS=$IFS
# Change IFS to new line.
IFS=$'\n'

file="$cachedir/$cachefile"
# Portable file mtime retrieval (GNU/BSD):
# - GNU: stat -c %Y <file>
# - BSD/macOS: stat -f %m <file>
mtime=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo 0)
now=$(date +%s)
cacheage=$(( now - mtime ))
if [ $cacheage -gt 1740 ] || [ ! -s "$cachedir/$cachefile" ]; then
    # Prefer structured format for reliable parsing (3 lines: location, condition, temperature)
    mapfile -t sdata < <(curl -fsS "https://wttr.in/${encoded_city}?format=%25l%0A%25C%0A%25t&lang=en" 2>/dev/null || true)
    if [ ${#sdata[@]} -ge 3 ]; then
        printf "%s\n" "${sdata[0]}" > "$cachedir/$cachefile"
        printf "%s\n" "${sdata[1]}" >> "$cachedir/$cachefile"
        printf "%s\n" "${sdata[2]}" >> "$cachedir/$cachefile"
    else
        # Try fetching each field separately if combined format is flaky
        loc=$(curl -fsS "https://wttr.in/${encoded_city}?format=%25l&lang=en" 2>/dev/null || true)
        cond_only=$(curl -fsS "https://wttr.in/${encoded_city}?format=%25C&lang=en" 2>/dev/null || true)
        temp_only=$(curl -fsS "https://wttr.in/${encoded_city}?format=%25t" 2>/dev/null || true)
        if [ -n "$loc" ] && [ -n "$cond_only" ] && [ -n "$temp_only" ]; then
            printf "%s\n" "$loc" > "$cachedir/$cachefile"
            printf "%s\n" "$cond_only" >> "$cachedir/$cachefile"
            printf "%s\n" "$temp_only" >> "$cachedir/$cachefile"
        else
        # Fallback: try ASCII output and extract best-effort fields
        url="https://en.wttr.in/${encoded_city}?1"
        mapfile -t data < <(curl -fsS "$url" 2>/dev/null || true)
        if [ ${#data[@]} -ge 3 ] && ! echo "${data[0]}" | grep -qi 'not found\|unknown location'; then
            loc=$(echo "${data[0]}" | sed -E 's/^.*: *//')
            # Attempt to pull condition and temperature hints from nearby lines
            cond=$(echo "${data[2]}" | sed -E 's/^.{0,15}//; s/^\s+//')
            temp=$(printf "%s\n" "${data[@]}" | grep -Eo '\+?-?[0-9]+(\([^)]+\))? ?°?[CF]' | head -n1)
            # Only write if we have at least location and something else meaningful
            if [ -n "$loc" ] && { [ -n "$cond" ] || [ -n "$temp" ]; }; then
                printf "%s\n" "$loc" > "$cachedir/$cachefile"
                printf "%s\n" "${cond:-Unknown}" >> "$cachedir/$cachefile"
                printf "%s\n" "${temp:-N/A}" >> "$cachedir/$cachefile"
            fi
        fi
        fi
    fi
fi

# Read cache robustly (line-wise)
mapfile -t weather < "$cachedir/$cachefile"

# If cache is still empty or invalid, emit a single error JSON and exit to avoid double-prints
if [ ${#weather[@]} -lt 3 ] || ! echo "${weather[2]}" | grep -qE '[-+0-9].*°'; then
    # Last-chance: try live structured fetch and populate cache and runtime weather
    mapfile -t sdata < <(curl -fsS "https://wttr.in/${encoded_city}?format=%25l%0A%25C%0A%25t&lang=en" 2>/dev/null || true)
    if [ ${#sdata[@]} -ge 3 ]; then
        weather=("${sdata[@]}")
        printf "%s\n" "${sdata[0]}" > "$cachedir/$cachefile"
        printf "%s\n" "${sdata[1]}" >> "$cachedir/$cachefile"
        printf "%s\n" "${sdata[2]}" >> "$cachedir/$cachefile"
    else
        loc=$(curl -fsS "https://wttr.in/${encoded_city}?format=%25l&lang=en" 2>/dev/null || true)
        cond_only=$(curl -fsS "https://wttr.in/${encoded_city}?format=%25C&lang=en" 2>/dev/null || true)
        temp_only=$(curl -fsS "https://wttr.in/${encoded_city}?format=%25t" 2>/dev/null || true)
        if [ -n "$loc" ] && [ -n "$cond_only" ] && [ -n "$temp_only" ]; then
            weather=("$loc" "$cond_only" "$temp_only")
            printf "%s\n" "$loc" > "$cachedir/$cachefile"
            printf "%s\n" "$cond_only" >> "$cachedir/$cachefile"
            printf "%s\n" "$temp_only" >> "$cachedir/$cachefile"
        else
            echo -e "{\"text\":\"\uf06a\", \"alt\":\"\", \"tooltip\":\": \"}"
            exit 1
        fi
    fi
fi

# Restore IFSClear
IFS=$SAVEIFS

temperature=$(echo "${weather[2]}" | sed -E 's/([[:digit:]]+)\.\./\1 to /g')

#echo ${weather[1]##*,}

# https://fontawesome.com/icons?s=solid&c=weather
# Normalize condition string for matching
cond_key=$(echo "${weather[1]##*,}" | tr '[:upper:]' '[:lower:]' | sed -E 's/^\s+//; s/\s+$//')
case "$cond_key" in
"clear" | "sunny")
    condition=""
    ;;
"partly cloudy")
    condition="󰖕"
    ;;
"cloudy")
    condition=""
    ;;
"overcast")
    condition=""
    ;;
"fog" | "freezing fog")
    condition=""
    ;;
"patchy rain possible" | "patchy light drizzle" | "light drizzle" | "patchy light rain" | "light rain" | "light rain shower" | "mist" | "rain" | "patchy rain nearby")
    condition="󰼳"
    ;;
"moderate rain at times" | "moderate rain" | "heavy rain at times" | "heavy rain" | "moderate or heavy rain shower" | "torrential rain shower" | "rain shower")
    condition=""
    ;;
"patchy snow possible" | "patchy sleet possible" | "patchy freezing drizzle possible" | "freezing drizzle" | "heavy freezing drizzle" | "light freezing rain" | "moderate or heavy freezing rain" | "light sleet" | "ice pellets" | "light sleet showers" | "moderate or heavy sleet showers")
    condition="󰼴"
    ;;
"blowing snow" | "moderate or heavy sleet" | "patchy light snow" | "light snow" | "light snow showers")
    condition="󰙿"
    ;;
"blizzard" | "patchy moderate snow" | "moderate snow" | "patchy heavy snow" | "heavy snow" | "moderate or heavy snow with thunder" | "moderate or heavy snow showers")
    condition=""
    ;;
"thundery outbreaks possible" | "patchy light rain with thunder" | "moderate or heavy rain with thunder" | "patchy light snow with thunder")
    condition=""
    ;;
*)
    condition=""
    ;;
esac

# If still unknown, try substring heuristics to pick a reasonable icon
if [ "$condition" = "" ]; then
    if echo "$cond_key" | grep -q "rain\|drizzle\|shower"; then
        condition="󰼳"
    elif echo "$cond_key" | grep -q "heavy rain\|torrential"; then
        condition=""
    elif echo "$cond_key" | grep -q "snow"; then
        condition="󰙿"
    elif echo "$cond_key" | grep -q "sleet\|freezing\|ice"; then
        condition="󰼴"
    elif echo "$cond_key" | grep -q "thunder"; then
        condition=""
    elif echo "$cond_key" | grep -q "overcast"; then
        condition=""
    elif echo "$cond_key" | grep -q "cloud"; then
        condition=""
    elif echo "$cond_key" | grep -q "sunny\|clear"; then
        condition=""
    fi
fi

#echo $temp $condition

# Ensure temperature has a value; if empty, keep whatever is in weather[2] or N/A
if [ -z "$temperature" ]; then
    temperature="${weather[2]:-N/A}"
fi

cond_disp=$(echo "${weather[1]}" | sed -E 's/^\s+//; s/\s+$//')

# Escape strings for safe JSON embedding (escape backslashes and double quotes)
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/\"/\\\"/g'
}

text_json=$(json_escape "$temperature $condition")
alt_json=$(json_escape "${weather[0]}")
tooltip_json=$(json_escape "${weather[0]}: $temperature $cond_disp")

printf '{"text":"%s", "alt":"%s", "tooltip":"%s"}\n' "$text_json" "$alt_json" "$tooltip_json"

# Write a two-line cache with an actual newline between lines
printf ' %s  \n%s %s\n' "$temperature" "$condition" "${weather[1]}" > "$HOME/.cache/.weather_cache"
