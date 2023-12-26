#!/bin/sh

pkill swaync

sleep 0.3
swaync > /dev/null 2>&1 &