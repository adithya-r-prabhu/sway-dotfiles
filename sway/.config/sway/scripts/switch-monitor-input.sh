#!/usr/bin/env bash
# Switch the HP 327pf monitor to show THIS machine (Linux, DisplayPort-1).
#
# Design: each machine's script unconditionally selects ITS OWN input on the
# monitor (rather than trying to "toggle"). This avoids any state-reading
# race and matches the natural workflow with Deskflow: when you move focus
# to a machine (mouse crosses screen edge) and press Scroll Lock, that
# machine puts its own video on the monitor.
#
# VCP 0x60 (Input Source) codes for this monitor (from `ddcutil capabilities`):
#   0x01 = VGA-1
#   0x0f = DisplayPort-1   <- this machine
#   0x11 = HDMI-1          <- MacBook (via USB-C adapter)

set -euo pipefail

INPUT_CODE=0x0f

if ddcutil setvcp 60 "$INPUT_CODE" >/tmp/ddcutil-switch.log 2>&1; then
    notify-send -h string:x-canonical-private-synchronous:osd-monitor-input \
        -t 1500 "Monitor Input" "Switched to Linux (DisplayPort)"
else
    notify-send -u critical -t 3000 "Monitor Switch Failed" \
        "See /tmp/ddcutil-switch.log"
fi
