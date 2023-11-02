#!/bin/bash
sleep 1
pkill xdg-desktop-portal-hyprland
pkill xdg-desktop-portal-wlr
pkill xdg-desktop-portal-gnome
pkill xdg-desktop-portal
sleep 1
/usr/lib/xdg-desktop-portal-hyprland &
/usr/libexec/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal-hyprland &
/usr/libexec/xdg-desktop-portal &

