#!/bin/bash

# ------------------------------------------------------------------
# Temperature widget for waybar — polybar parity
# Dynamic k10temp hwmon detection (same as polybar launch.sh), warn >= 60°C red
# ------------------------------------------------------------------

for d in /sys/class/hwmon/hwmon*; do
    [ "$(cat "$d/name" 2>/dev/null)" = "k10temp" ] || continue

    temp=$(( $(cat "$d/temp1_input") / 1000 ))

    if [ "$temp" -ge 60 ]; then
        echo "<span foreground='#e55561'>󰔏 ${temp}°C</span>"
    else
        echo "<span foreground='#e55561'>󰔏 </span>${temp}°C"
    fi
    exit 0
done

# no k10temp found → empty output (module hidden)
echo ""
