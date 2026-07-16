#!/usr/bin/env bash
# Power menu: lock / logout / suspend / restart / shutdown, picked via wofi.
# Suspend option added when this repo added an $mod+Shift+e sway keybinding
# for it (see sway/.config/sway/config) -- kept as the single power-menu
# script rather than duplicating one.
set -euo pipefail

icon_lock=$''
icon_logout=$''
icon_suspend=$'󰤄'
icon_restart=$''
icon_shutdown=$''

options="${icon_lock}  Lock\n${icon_logout}  Logout\n${icon_suspend}  Suspend\n${icon_restart}  Restart\n${icon_shutdown}  Shutdown"

chosen=$(echo -e "$options" | wofi --dmenu --prompt "Power" --width 300 --height 260 --cache-file /dev/null)

case "$chosen" in
    *Lock) exec swaylock -f ;;
    *Logout) exec swaymsg exit ;;
    *Suspend) exec systemctl suspend ;;
    *Restart) exec systemctl reboot ;;
    *Shutdown) exec systemctl poweroff ;;
esac
