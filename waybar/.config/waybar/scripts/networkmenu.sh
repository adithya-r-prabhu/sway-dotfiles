#!/usr/bin/env bash
# Network menu: manage ethernet + Wi-Fi (connect/disconnect/toggle), picked via wofi.
set -euo pipefail

icon_wifi=$''
icon_lock=$''
icon_refresh=$''
icon_power=$''
icon_check=$''
icon_x=$''

MAP_SEP=$'\x1f'

notify() { notify-send "Network" "$1"; }

wifi_iface() {
    nmcli -t -f DEVICE,TYPE device status | awk -F: '$2 == "wifi" { print $1; exit }'
}

has_wifi_device() {
    nmcli -t -f TYPE device status | grep -qx wifi
}

wifi_connected() {
    local iface state
    iface=$(wifi_iface)
    [[ -z "$iface" ]] && return 1
    state=$(nmcli -t -f GENERAL.STATE device show "$iface" 2>/dev/null | cut -d: -f2) || return 1
    [[ "$state" == 100* ]]
}

ethernet_ifaces() {
    nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$2 == "ethernet" && $3 == "connected" { print $1 }'
}

list_ethernet_lines() {
    local map_file="$1" eth ip row
    while read -r eth; do
        [[ -z "$eth" ]] && continue
        ip=$(nmcli -g IP4.ADDRESS device show "$eth" 2>/dev/null | head -1)
        echo "${icon_check}  ${eth}: ${ip:-connected}"
        row="${icon_x}  Disconnect ${eth}"
        printf "%s${MAP_SEP}%s${MAP_SEP}%s${MAP_SEP}%s\n" "$row" "$eth" "" "ethernet" >> "$map_file"
        echo "$row"
    done < <(ethernet_ifaces)
}

list_network_lines() {
    local map_file="$1" raw
    raw=$(nmcli -t -e no -f IN-USE,SIGNAL,SECURITY,BARS,SSID device wifi list --rescan yes 2>/dev/null \
        | awk -F: '$5 != ""' | sort -t: -k2,2 -rn | awk -F: '!seen[$5]++') || true
    [[ -z "$raw" ]] && return 0

    local inuse signal security bars ssid icon lock row
    while IFS=: read -r inuse signal security bars ssid; do
        [[ -z "$ssid" ]] && continue
        icon="$icon_wifi"
        [[ "$inuse" == "*" ]] && icon="$icon_check"
        lock=""
        [[ -n "$security" && "$security" != "--" ]] && lock="  ${icon_lock}"
        row="${icon}  ${bars}${lock}  ${ssid} (${signal}%)"
        printf "%s${MAP_SEP}%s${MAP_SEP}%s${MAP_SEP}%s\n" "$row" "$ssid" "$security" "wifi" >> "$map_file"
        echo "$row"
    done <<< "$raw"
}

build_menu() {
    local map_file="$1"
    list_ethernet_lines "$map_file"

    has_wifi_device || return 0

    local radio_state
    radio_state=$(nmcli radio wifi)

    if [[ "$radio_state" != "enabled" ]]; then
        echo "${icon_power}  Turn Wi-Fi On"
        return 0
    fi

    echo "${icon_power}  Turn Wi-Fi Off"
    echo "${icon_refresh}  Rescan"
    wifi_connected && echo "${icon_x}  Disconnect Wi-Fi"

    list_network_lines "$map_file"
}

prompt_password() {
    wofi --dmenu --password --prompt "Password: $1" --width 380 --height 100 --cache-file /dev/null < /dev/null
}

already_saved() {
    nmcli -t -f NAME connection show | grep -qxF "$1"
}

do_connect() {
    local ssid="$1" security="$2" output attempt pw

    if already_saved "$ssid"; then
        if output=$(nmcli connection up id "$ssid" 2>&1); then
            notify "Connected to $ssid"
        else
            notify "Failed to connect to $ssid"
        fi
        return
    fi

    if [[ -z "$security" || "$security" == "--" ]]; then
        if output=$(nmcli device wifi connect "$ssid" 2>&1); then
            notify "Connected to $ssid"
        else
            notify "Failed to connect to $ssid"
        fi
        return
    fi

    for attempt in 1 2 3; do
        pw=$(prompt_password "$ssid") || return 0
        if output=$(nmcli device wifi connect "$ssid" password "$pw" 2>&1); then
            notify "Connected to $ssid"
            return
        fi
        nmcli connection delete "$ssid" >/dev/null 2>&1 || true
        notify "Wrong password for $ssid (attempt $attempt/3)"
    done
    notify "Failed to connect to $ssid"
}

toggle_wifi() {
    if [[ "$(nmcli radio wifi)" == "enabled" ]]; then
        nmcli radio wifi off
        notify "Wi-Fi turned off"
    else
        nmcli radio wifi on
        notify "Wi-Fi turned on"
    fi
}

disconnect_wifi() {
    local iface
    iface=$(wifi_iface)
    nmcli device disconnect "$iface"
    notify "Wi-Fi disconnected"
}

map_file=$(mktemp)
trap 'rm -f "$map_file"' EXIT

menu=$(build_menu "$map_file")
chosen=$(echo "$menu" | wofi --dmenu --prompt "Network" --width 380 --height 400 --cache-file /dev/null)

case "$chosen" in
    "") exit 0 ;;
    *"Turn Wi-Fi"*) toggle_wifi ;;
    *"Rescan") exec "$0" ;;
    *"Disconnect Wi-Fi") disconnect_wifi ;;
    *)
        row_data=$(awk -F"$MAP_SEP" -v r="$chosen" '$1 == r { print; exit }' "$map_file")
        [[ -z "$row_data" ]] && exit 0
        IFS="$MAP_SEP" read -r _ target extra kind <<< "$row_data"
        if [[ "$kind" == "ethernet" ]]; then
            nmcli device disconnect "$target"
            notify "Ethernet disconnected"
        else
            do_connect "$target" "$extra"
        fi
        ;;
esac
