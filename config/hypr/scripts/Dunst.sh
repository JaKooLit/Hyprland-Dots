#!/usr/bin/env bash

CONFIG="$HOME/.config/dunst/dunstrc"

if [[ ! $(pidof dunst) ]]; then
	dunst -conf ${CONFIG}
fi
