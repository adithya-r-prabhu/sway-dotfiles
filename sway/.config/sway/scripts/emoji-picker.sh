#!/usr/bin/env bash
# Emoji picker for Sway/wofi -- ported from the rofi version in
# adithya-r-prabhu/bspwm (.config/rofi/emoji/launcher.sh).
#
# Wayland has no reliable xdotool-style "type into the focused window", so
# unlike the X11/rofi original this always copies the chosen emoji to the
# clipboard (wl-copy) for you to paste (Ctrl+Shift+V in most apps).

set -euo pipefail

DATA_FILE="$(dirname "${BASH_SOURCE[0]}")/../emoji/emoji.md"

chosen=$(sed 's/U+.*//' "$DATA_FILE" | wofi --dmenu -i -p "Search emoji" | sed 's/ .*//')

[ -z "$chosen" ] && exit 0

printf '%s' "$chosen" | wl-copy
notify-send "Emoji copied" "'$chosen' copied to clipboard" 2>/dev/null || true
