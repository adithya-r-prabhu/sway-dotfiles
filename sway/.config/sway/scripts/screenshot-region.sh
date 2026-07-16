#!/usr/bin/env bash
# Region screenshot: select an area (slurp), save it to
# ~/Pictures/Screenshots/ AND copy it to the clipboard, with a mako
# notification when done. This replaces flameshot, which does not render
# any visible UI at all on this sway/wlroots setup (its Qt5 GUI has no
# wlr-layer-shell support) -- grim+slurp are the Wayland-native tools that
# are already proven to work reliably here.
set -euo pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

geometry=$(slurp) || exit 0
grim -g "$geometry" "$FILE"
wl-copy < "$FILE"
notify-send -i "$FILE" "Screenshot saved" "$FILE (also copied to clipboard)"
