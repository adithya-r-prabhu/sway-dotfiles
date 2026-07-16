#!/usr/bin/env bash
# Clipboard history picker (cliphist + wofi). Requires the cliphist store
# daemons started in sway config (`wl-paste --watch cliphist store`).
set -euo pipefail

chosen=$(cliphist list | wofi --dmenu -i -p "Clipboard history")
[ -z "$chosen" ] && exit 0

printf '%s' "$chosen" | cliphist decode | wl-copy
