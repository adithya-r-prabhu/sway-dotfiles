#!/usr/bin/env bash
# Keybinding cheat-sheet for Sway/wofi -- ported from adithya-r-prabhu/bspwm's
# .config/bspwm/scripts/keybindings_rofi.sh (which parsed sxhkd's
# comment-then-binding format). Sway's config keeps everything on one
# `bindsym ...` line instead, so this greps those directly rather than
# trying to match the sxhkd comment/binding pairing.

set -euo pipefail

CONFIG="$HOME/.config/sway/config"

grep -E '^\s*bindsym' "$CONFIG" |
    sed -E 's/^\s*bindsym\s+(--locked\s+)?//' |
    sed -E "s/\\\$mod/Super/g; s/\\\$term\b/kitty/; s/\\\$menu\b/wofi --show drun/" |
    awk '{key=$1; $1=""; printf "%-28s %s\n", key, $0}' |
    wofi --dmenu -i -p "Keybindings" --width 900 --height 600 >/dev/null
