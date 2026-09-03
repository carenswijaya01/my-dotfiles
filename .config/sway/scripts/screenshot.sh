#!/bin/bash

# ------------------------------------------------------------------
# Screenshot — flameshot GUI replacement on sway
# Select region (slurp) → grim → swappy (anotasi: coret, blur, teks, crop)
# → save ke ~/Pictures (Ctrl+S di swappy) / copy (Ctrl+C di swappy)
# Raw capture selalu di-copy ke clipboard dulu, jadi aman walau swappy
# ditutup tanpa save.
# ------------------------------------------------------------------
set -euo pipefail

AREA=$(slurp) || exit 0   # ESC cancels

DIR="$HOME/Pictures"
mkdir -p "$DIR"
FILE="$DIR/Screenshot-$(date +'%Y%m%d-%H%M%S').png"

if command -v swappy >/dev/null 2>&1; then
    # raw → clipboard (backup), lalu buka swappy editor dengan -o target save
    grim -g "$AREA" - | tee >(wl-copy > /dev/null) | swappy -f - -o "$FILE" || true
    if [ -f "$FILE" ]; then
        notify-send -a screenshot -t 2000 "Screenshot" "Saved: $(basename "$FILE")"
    fi
else
    # fallback tanpa swappy: langsung save + copy
    grim -g "$AREA" "$FILE"
    wl-copy < "$FILE"
    notify-send -a screenshot -t 2000 "Screenshot" "Saved & copied: $(basename "$FILE") (install swappy untuk anotasi)"
fi
