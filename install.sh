#!/usr/bin/env bash
# Reproduce this dotfiles setup on a fresh system.
#
#   ./install.sh              -- install fonts + stow configs
#   ./install.sh --packages   -- also apt-get install everything in
#                                 packages-ubuntu.txt, add the Microsoft Edge
#                                 apt repo + install it, and configure
#                                 default apps (browser/file manager).
#
# Based on https://github.com/npranav7619/dotfiles (Sway/Catppuccin desktop),
# with app choices and extra keybindings ported from
# https://github.com/adithya-r-prabhu/bspwm (this repo's author's older
# X11/bspwm setup).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(kitty foot mako sway swaylock waybar wofi)
FONT_DIR="$HOME/.local/share/fonts/Agave"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d%H%M%S)"
# Prefixed zzz- so it sorts (and therefore wins) after the NVIDIA driver
# package's own modprobe.d files, which set modeset=1 by default and would
# otherwise silently override this. Ported from npranav7619/dotfiles.
NVIDIA_MODESET_CONF="/etc/modprobe.d/zzz-nvidia-drm-nomodeset.conf"

install_font() {
    if fc-list | grep -i "Agave Nerd Font Mono" >/dev/null; then
        echo "==> Agave Nerd Font already installed, skipping"
        return
    fi

    echo "==> Installing Agave Nerd Font"
    local tmp
    tmp="$(mktemp -d)"
    curl -fL -o "$tmp/Agave.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Agave.zip
    mkdir -p "$FONT_DIR"
    unzip -o -q "$tmp/Agave.zip" -d "$FONT_DIR"
    rm -rf "$tmp"
    fc-cache -f "$FONT_DIR" >/dev/null
}

install_packages() {
    if ! command -v apt-get >/dev/null; then
        echo "==> apt-get not found, skipping package install" >&2
        return
    fi
    echo "==> Installing packages from packages-ubuntu.txt"
    sudo apt-get update
    grep -v '^#' "$DOTFILES_DIR/packages-ubuntu.txt" | xargs sudo apt-get install -y
}

install_fastfetch() {
    if command -v fastfetch >/dev/null; then
        echo "==> fastfetch already installed, skipping"
        return
    fi
    echo "==> Installing fastfetch from its GitHub release (not in Ubuntu 24.04 repos)"
    local arch tmp url
    arch="$(dpkg --print-architecture)"
    tmp="$(mktemp -d)"
    url="$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest |
        grep -oP "\"browser_download_url\":\s*\"\K[^\"]+linux-${arch}\.deb" | head -1)"
    curl -fL -o "$tmp/fastfetch.deb" "$url"
    sudo apt-get install -y "$tmp/fastfetch.deb"
    rm -rf "$tmp"
}

install_microsoft_edge() {
    if command -v microsoft-edge >/dev/null; then
        echo "==> Microsoft Edge already installed, skipping"
        return
    fi
    if ! command -v apt-get >/dev/null; then
        echo "==> apt-get not found, skipping Microsoft Edge install" >&2
        return
    fi

    echo "==> Adding Microsoft Edge apt repo + installing microsoft-edge-stable"
    local tmp
    tmp="$(mktemp -d)"
    curl -fL -o "$tmp/microsoft.gpg" https://packages.microsoft.com/keys/microsoft.asc
    gpg --dearmor -o "$tmp/microsoft.gpg.dearmored" "$tmp/microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$tmp/microsoft.gpg.dearmored" \
        /etc/apt/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" |
        sudo tee /etc/apt/sources.list.d/microsoft-edge.list >/dev/null
    rm -rf "$tmp"
    sudo apt-get update
    sudo apt-get install -y microsoft-edge-stable
}

setup_default_apps() {
    echo "==> Setting default apps (browser: Microsoft Edge, file manager: Nautilus)"
    mkdir -p "$HOME/.config"
    if command -v xdg-mime >/dev/null; then
        xdg-mime default microsoft-edge.desktop x-scheme-handler/http || true
        xdg-mime default microsoft-edge.desktop x-scheme-handler/https || true
        xdg-mime default microsoft-edge.desktop text/html || true
        xdg-mime default org.gnome.Nautilus.desktop inode/directory || true
    fi
}

fix_hybrid_nvidia() {
    if ! command -v lspci >/dev/null; then
        return
    fi

    local gpus gpu_count nvidia_count
    gpus="$(lspci | grep -Ei 'vga compatible controller|3d controller|display controller' || true)"
    gpu_count=0
    nvidia_count=0
    [ -n "$gpus" ] && gpu_count="$(printf '%s\n' "$gpus" | grep -c .)"
    [ -n "$gpus" ] && nvidia_count="$(printf '%s\n' "$gpus" | grep -ic nvidia || true)"

    if [ "$nvidia_count" -eq 0 ] || [ "$gpu_count" -lt 2 ]; then
        # Not a hybrid NVIDIA + other-GPU system -- this fix would disable
        # the only display-capable GPU on an NVIDIA-only machine, so it
        # must never run unless there's a confirmed second GPU to fall back on.
        return
    fi

    echo "==> Hybrid NVIDIA + other-GPU system detected:"
    printf '%s\n' "$gpus" | sed 's/^/    /'

    if [ -f "$NVIDIA_MODESET_CONF" ] && grep -q "modeset=0" "$NVIDIA_MODESET_CONF"; then
        echo "==> nvidia-drm modeset=0 already configured, skipping"
        return
    fi

    echo "==> Disabling nvidia-drm modeset: with the proprietary NVIDIA driver, sway"
    echo "    (wlroots) refuses to start at all if it thinks NVIDIA might be the"
    echo "    display-driving GPU. This stops nvidia-drm from ever registering as a"
    echo "    KMS/display device, so Intel is always the one driving the display and"
    echo "    sway starts normally (NVIDIA still loads normally for compute/CUDA)."
    echo "options nvidia-drm modeset=0" | sudo tee "$NVIDIA_MODESET_CONF" >/dev/null
    sudo update-initramfs -u
    echo "    Applied. Takes effect on next boot."
}

stow_packages() {
    echo "==> Linking dotfiles with stow"
    for pkg in "${PACKAGES[@]}"; do
        for path in "$DOTFILES_DIR/$pkg/.config/"*; do
            local name target
            name="$(basename "$path")"
            target="$HOME/.config/$name"
            if [ -e "$target" ] && [ ! -L "$target" ]; then
                echo "    backing up existing $target -> $BACKUP_DIR/"
                mkdir -p "$BACKUP_DIR"
                mv "$target" "$BACKUP_DIR/"
            fi
        done
        stow -v -t "$HOME" -d "$DOTFILES_DIR" "$pkg"
    done
    chmod +x "$HOME/.config/sway/scripts/"*.sh 2>/dev/null || true
}

main() {
    install_font

    if [ "${1:-}" = "--packages" ]; then
        install_packages
        install_fastfetch
        install_microsoft_edge
        setup_default_apps
        fix_hybrid_nvidia
    fi

    stow_packages

    echo "==> Done"
    echo "    Linked: ${PACKAGES[*]}"
    [ -d "$BACKUP_DIR" ] && echo "    Backed up pre-existing configs to: $BACKUP_DIR"
    echo "    Log out and pick the 'Sway' session at the login screen to use it."
    echo "    Reload sway with \$mod+Shift+c (or 'swaymsg reload') to pick up changes."
}

main "$@"
