#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# Copied from Discord post. Thanks to @Zorg

# Get id of an active window
active_pid=$(hyprctl activewindow | grep -Eo 'pid: [0-9]+' | awk '{print $2}')

# Close active window
kill $active_pid
