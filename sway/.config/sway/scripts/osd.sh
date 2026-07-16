#!/usr/bin/env bash
# Small on-screen-display notification for volume/brightness/mic keys via
# mako. Uses the shared "x-canonical-private-synchronous" hint so repeated
# presses replace the previous popup instead of stacking new ones.
set -euo pipefail

mode="${1:?usage: osd.sh volume|brightness|mic}"

case "$mode" in
    volume)
        muted=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
        pct=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -1)
        [ "$muted" = "yes" ] && title="Muted" || title="Volume: ${pct}%"
        notify-send -h string:x-canonical-private-synchronous:osd-volume \
            -h int:value:"${pct:-0}" -t 1500 "$title"
        ;;
    brightness)
        pct=$(brightnessctl get -m | cut -d, -f4 | tr -d '%')
        notify-send -h string:x-canonical-private-synchronous:osd-brightness \
            -h int:value:"${pct:-0}" -t 1500 "Brightness: ${pct}%"
        ;;
    mic)
        muted=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
        [ "$muted" = "yes" ] && title="Mic muted" || title="Mic unmuted"
        notify-send -h string:x-canonical-private-synchronous:osd-mic -t 1500 "$title"
        ;;
    *)
        echo "unknown mode: $mode" >&2
        exit 1
        ;;
esac
