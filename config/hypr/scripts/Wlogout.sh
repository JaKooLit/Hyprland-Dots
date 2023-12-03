#!/bin/bash

# If you have 1440p, better to use this
#wlogout --protocol layer-shell -b 5 -T 600 -B 600 &

# for 1080p
wlogout --protocol layer-shell -b 5 -T 450 -B 450 &


# Capture the PID of the wlogout process
wlogout_pid=$!

# Wait for up to 30 seconds for wlogout to exit gracefully
timeout 30s tail --pid $wlogout_pid -f /dev/null

# If wlogout is still running after the timeout, forcefully kill it
if ps -p $wlogout_pid > /dev/null; then
  kill -KILL $wlogout_pid
fi
