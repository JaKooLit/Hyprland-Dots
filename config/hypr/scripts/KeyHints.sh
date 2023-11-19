#!/bin/bash

yad --width=1000 --height=1000 \
--center \
--title="Keybindings" \
--no-buttons \
--list \
--column=Key: \
--column=Description: \
--column=Command: \
--timeout=60 \
--timeout-indicator=bottom \
"ESC" "close this app" "" "=" "SUPER KEY" "(SUPER KEY)" \
" enter" "Terminal" "(kitty)" \
" or  D" "App Launcher" "(rofi)" \
" T" "Open File Manager" "(Thunar)" \
" Q or  Shift Q  " "close focused app" "(kill)" \
" Alt V" "Clipboard Manager" "(cliphist)" \
" W" "Choose wallpaper" "(swww)" \
"CTRL ALT W" "Random wallpaper" "(swww)" \
"CTRL W" "Choose waybar styles" "(waybar styles)" \
"ALT W" "Choose waybar layout" "(waybar layout)" \
"CTRL SHIFT W" "Reload Waybar and Dunst" "" \
" Print" "screenshot" "(grim)" \
" Shift Print" "screenshot region" "(grim + slurp)" \
" Shift S" "screenshot region" "(swappy)" \
"CTRL ALT P" "power-menu" "(wlogout)" \
"CTRL ALT L" "screen lock" "(swaylock)" \
"CTRL ALT Del" "Hyprland Exit" "(SAVE YOUR WORK!!!)" \
" F" "Fullscreen" "Toggles to full screen" \
" Spacebar" "Toggle Dwindle | Master Layout" "Hyprland Layout" \
" Shift F" "Toggle float" "single window" \
" ALT F" "Toggle all windows to float" "all windows" \
" SHIFT G" "Gamemode! All animations off" "" \
" H" "Launch this app" "" \
" E" "View or EDIT Keybinds, Settings, Monitor" "" \
"" "" "" \
"" "This window will auto-close in 60 secs" ""\


