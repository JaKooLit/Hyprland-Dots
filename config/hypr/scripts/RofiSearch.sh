# Opens rofi in dmenu mod and waits for input. Then pushes the input to the query of the URL.
#
echo "" | rofi -dmenu -p "Search:" | xargs -I{} xdg-open https://www.google.com/search?q={}
