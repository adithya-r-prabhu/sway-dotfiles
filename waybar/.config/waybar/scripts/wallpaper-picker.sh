#!/usr/bin/env bash
# Wallpaper picker: pick an image from wallpapers/ via wofi thumbnails,
# apply it live and persist it in the sway config.
#
# wofi's dmenu image support uses colon-delimited "img:<path>" tags parsed by
# a recursive scan (see wofi's parse_images/get_img_data) that can only
# recognize a mode tag when it's the very first thing in the remaining
# string -- there's no way to reliably append a second "text:<label>" tag
# after an arbitrary file path, so each entry here is image-only (no
# caption). wofi echoes the raw "img:<path>" line back on selection.
set -euo pipefail

# -P resolves symlinks to the physical path -- this script is normally
# invoked via the stowed symlink at ~/.config/waybar/scripts/, and plain
# `pwd` would report that logical (unresolved) path instead, throwing off
# the fixed number of ".." hops below.
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd -P "$SCRIPT_DIR/../../../.." && pwd)"
WALLPAPER_DIR="$DOTFILES_DIR/wallpapers"
SWAY_CONFIG="$DOTFILES_DIR/sway/.config/sway/config"

generate_menu() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 |
    while IFS= read -r -d '' file; do
        printf 'img:%s\n' "$file"
    done
}

chosen=$(generate_menu | wofi --dmenu --allow-images --prompt "Wallpaper")

[ -z "$chosen" ] && exit 0

chosen_file="${chosen#img:}"
[ -f "$chosen_file" ] || exit 1

rel_path="~/dotfiles/wallpapers/$(basename "$chosen_file")"

# Persist to the sway config (idempotent single-line replace)
sed -i "s|^output \* bg .* fill\$|output * bg $rel_path fill|" "$SWAY_CONFIG"

# Apply live immediately
swaymsg output '*' bg "$chosen_file" fill
