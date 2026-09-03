#!/bin/bash

# ------------------------------------------------------------------
# Power menu — klik ikon 󰐥 di waybar
# Utama: wlogout (overlay icon besar, layout OneDark di ~/.config/wlogout)
# Fallback: fuzzel dmenu (kalau wlogout belum terpasang)
# ------------------------------------------------------------------

if command -v wlogout >/dev/null 2>&1; then
    exec wlogout -b 3
fi

choice=$(printf 'lock\nreboot\npoweroff\nlogout' | fuzzel --dmenu -p ':') || exit 0
[ -n "$choice" ] || exit 0

case "$choice" in
    lock)     swaylock -f -c 1f2329 ;;
    reboot)   systemctl reboot ;;
    poweroff) systemctl poweroff ;;
    logout)   swaymsg exit ;;
esac
