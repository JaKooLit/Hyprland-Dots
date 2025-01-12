# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Modified Script for Google Search
# Original Submitted by https://github.com/LeventKaanOguz

# Opens rofi in dmenu mod and waits for input. Then pushes the input to the query of the URL.

rofi_config="$HOME/.config/rofi/config-search.rasi"
    
# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    #exit 0
fi

# Open rofi with a dmenu and pass the selected item to xdg-open for Google search
echo "" | rofi -dmenu -config "$rofi_config" -p "Search:" | xargs -I{} xdg-open "https://www.google.com/search?q={}"

