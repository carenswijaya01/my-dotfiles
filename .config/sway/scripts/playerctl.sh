#!/bin/bash

# ------------------------------------------------------------------
# playerctl widget for waybar — port of polybar/scripts/playerctl.sh
# Output uses pango markup (icon red #e55561, text default fg).
# Controls via waybar on-click: left=play-pause, middle=previous, right=next
# Icon = Nerd Font glyph via printf escape (tidak hilang saat file disimpan)
# ------------------------------------------------------------------

PLAYER_ICON=$(printf '\uf1bc')   # nf-fa-spotify
PLAY_ICON=$(printf '\uf04b')     # nf-fa-play
PAUSE_ICON=$(printf '\uf04c')    # nf-fa-pause

# Get song title / artist / status
title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)
status=$(playerctl status 2>/dev/null)

# Icon play saat paused (indikasi bisa di-resume), icon pause saat playing
if [ "$status" = "Paused" ]; then
    play_pause_icon=$PLAY_ICON
else
    play_pause_icon=$PAUSE_ICON
fi

# Tanpa title & artist → output kosong (modul hidden, seperti polybar)
if [ -z "$title" ] && [ -z "$artist" ]; then
    echo ""
    exit 0
fi

# Truncate 20 karakter (bash substring = char-aware, aman utk UTF-8)
printf "<span foreground='#e55561'>%s</span> %s - %s <span foreground='#e55561'>%s</span>\n" \
    "$PLAYER_ICON" "${title:0:20}" "${artist:0:20}" "$play_pause_icon"
