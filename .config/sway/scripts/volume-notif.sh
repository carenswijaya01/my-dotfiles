#!/bin/bash

# ------------------------------------------------------------------
# Function Key Control Wrapper Script for Volume & Brightness
# Works with sxhkd, acpid, or similar hotkey daemons.
# ------------------------------------------------------------------

set -euo pipefail

# --- Configuration ---
VOLUME_STEP=5
BRIGHTNESS_STEP=5
MSG_TAG_VOLUME="volume_control"
MSG_TAG_BRIGHTNESS="brightness_control"

# --- Helpers ---
get_volume() {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]{1,3}(?=%)' | head -1
}

get_mute() {
    pactl get-sink-mute @DEFAULT_SINK@ | grep -Po '(?<=Mute: )(yes|no)'
}

get_brightness() {
    brightnessctl g
}

get_max_brightness() {
    brightnessctl m
}

# --- Notifications ---
notify_volume() {
    local volume mute icon
    volume=$(get_volume)
    mute=$(get_mute)

    if [[ "$mute" == "yes" || "$volume" -eq 0 ]]; then
        icon="󰸈 "  # muted
    elif [[ "$volume" -lt 30 ]]; then
        icon="󰕿 "  # low
    elif [[ "$volume" -lt 70 ]]; then
        icon="󰖀 "  # medium
    elif [[ "$volume" -gt 100 ]]; then
        icon="󱄡 "  # boosted
    else
        icon="󰕾 "  # high
    fi

    dunstify -a "changeVolume" -u low -i none -h string:x-dunst-stack-tag:"$MSG_TAG_VOLUME" \
        -h int:value:"$volume" "$icon Volume: ${volume}%"
}

notify_brightness() {
    local brightness max_brightness percentage icon
    brightness=$(get_brightness)
    max_brightness=$(get_max_brightness)
    percentage=$((brightness * 100 / max_brightness))
    icon="󰃠 "  # sun icon

    dunstify -a "changeBrightness" -u low -i none -h string:x-dunst-stack-tag:"$MSG_TAG_BRIGHTNESS" \
        -h int:value:"$percentage" "$icon Brightness: ${percentage}%"
}

# --- Volume Controls ---
volume_up() {
    pactl set-sink-mute @DEFAULT_SINK@ 0
    pactl set-sink-volume @DEFAULT_SINK@ +${VOLUME_STEP}%
    notify_volume
}

volume_down() {
    pactl set-sink-volume @DEFAULT_SINK@ -${VOLUME_STEP}%
    notify_volume
}

volume_mute() {
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    notify_volume
}

# --- Brightness Controls ---
brightness_up() {
    brightnessctl set +${BRIGHTNESS_STEP}% >/dev/null
    notify_brightness
}

brightness_down() {
    brightnessctl set ${BRIGHTNESS_STEP}%- >/dev/null
    notify_brightness
}

# --- Main Logic ---
case "${1:-}" in
    volume_up) volume_up ;;
    volume_down) volume_down ;;
    volume_mute) volume_mute ;;
    brightness_up) brightness_up ;;
    brightness_down) brightness_down ;;
    *)
        echo "Usage: $0 {volume_up|volume_down|volume_mute|brightness_up|brightness_down}"
        exit 1
        ;;
esac
