#!/usr/bin/env bash
# Reproduce this dotfiles setup on a fresh system.
#
#   ./install.sh              -- install fonts + stow configs
#   ./install.sh --packages   -- also apt-get install everything in
#                                 packages-ubuntu.txt, add the Microsoft Edge
#                                 apt repo + install it, configure default
#                                 apps (browser/file manager), and (on NVIDIA
#                                 machines) make the Sway session actually
#                                 launchable -- see configure_sway_session().
#
# Based on https://github.com/npranav7619/dotfiles (Sway/Catppuccin desktop),
# with app choices and extra keybindings ported from
# https://github.com/adithya-r-prabhu/bspwm (this repo's author's older
# X11/bspwm setup).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(kitty foot mako sway swaylock waybar wofi gtk)
FONT_DIR="$HOME/.local/share/fonts/Agave"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d%H%M%S)"
# Stale from an earlier version of this script -- see cleanup_stale_nvidia_modeset()
# below for why this is actively wrong on this machine and gets removed, not applied.
NVIDIA_MODESET_CONF="/etc/modprobe.d/zzz-nvidia-drm-nomodeset.conf"
SWAY_SESSION_DESKTOP="/usr/share/wayland-sessions/sway.desktop"

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

setup_gtk_theme() {
    # gtk-3.0/settings.ini (stowed by the "gtk" package) covers classic GTK3
    # apps, but GTK4/libadwaita apps (e.g. Nautilus 46+) mostly ignore custom
    # widget themes and instead read these via gsettings/dconf -- icon theme
    # is still respected there even though libadwaita ignores gtk-theme-name.
    if ! command -v gsettings >/dev/null; then
        echo "==> gsettings not found, skipping GTK icon-theme/dark-mode setup" >&2
        return
    fi
    echo "==> Setting icon theme (BigSur-dark) + dark color-scheme via gsettings"
    gsettings set org.gnome.desktop.interface icon-theme 'BigSur-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
}

enable_bluetooth() {
    if ! command -v systemctl >/dev/null; then
        return
    fi
    echo "==> Enabling bluetooth.service (for the Super+Shift+B / blueman-manager keybinding)"
    sudo systemctl enable --now bluetooth.service 2>/dev/null || true
}

cleanup_stale_nvidia_modeset() {
    # An earlier version of this script disabled nvidia-drm's modeset
    # (`options nvidia-drm modeset=0`), copied from npranav7619/dotfiles
    # where it fixes a *laptop* hybrid-GPU black-screen-at-boot race.
    #
    # On a desktop (this machine: Intel UHD 770 + NVIDIA T400, no internal
    # panel), that setting backfires: Ubuntu's GDM udev rule
    # (/usr/lib/udev/rules.d/61-gdm.rules) has a special-case that leaves
    # Wayland alone on hybrid-NVIDIA *laptops*, but on anything else it reads
    # nvidia-drm's modeset parameter, and if it's disabled, GDM concludes
    # Wayland can't work and runs `gdm-runtime-config set daemon
    # WaylandEnable false` -- which hides *every* Wayland session (including
    # Sway) from the login screen entirely. That's the actual reason Sway
    # wasn't showing up as a session option after the first install.
    #
    # The real problem (sway/wlroots hard-refusing to start on any detected
    # proprietary NVIDIA driver) is unrelated to modeset and is instead
    # handled by configure_sway_session()'s --unsupported-gpu flag below.
    if [ -f "$NVIDIA_MODESET_CONF" ]; then
        echo "==> Removing stale $NVIDIA_MODESET_CONF (was hiding Wayland/Sway from GDM)"
        sudo rm -f "$NVIDIA_MODESET_CONF"
        sudo update-initramfs -u
        echo "    Reboot required for GDM to re-detect Wayland as available."
    fi
}

configure_sway_session() {
    # sway (wlroots) hard-refuses to start if it detects the proprietary
    # NVIDIA driver is loaded at all, regardless of modeset, printing
    # "Proprietary Nvidia drivers are NOT supported" and exiting -- unless
    # launched with --unsupported-gpu. GDM's Exec= for the Sway session
    # doesn't include that flag by default, so it's added here.
    #
    # Only relevant on machines with an NVIDIA GPU; harmless no-op otherwise.
    if ! lspci 2>/dev/null | grep -qi nvidia; then
        return
    fi
    if [ ! -f "$SWAY_SESSION_DESKTOP" ]; then
        echo "==> $SWAY_SESSION_DESKTOP not found (sway package not installed?), skipping" >&2
        return
    fi
    if grep -q -- '--unsupported-gpu' "$SWAY_SESSION_DESKTOP"; then
        echo "==> Sway session already configured with --unsupported-gpu, skipping"
        return
    fi

    echo "==> Adding --unsupported-gpu to $SWAY_SESSION_DESKTOP's Exec line"
    echo "    NOTE: this file isn't a tracked dpkg conffile, so a future 'sway'"
    echo "    package upgrade/reinstall can silently reset it -- re-run"
    echo "    './install.sh --packages' afterwards if Sway stops launching."
    sudo sed -i 's/^Exec=sway$/Exec=sway --unsupported-gpu/' "$SWAY_SESSION_DESKTOP"
}

stow_packages() {
    echo "==> Linking dotfiles with stow"
    for pkg in "${PACKAGES[@]}"; do
        # Back up real (non-symlink) pre-existing files that would conflict
        # with stow. Checked in two places: one level inside .config/ (since
        # ~/.config itself is a real shared directory across all packages,
        # not something to move wholesale) and any other top-level dotfile/
        # dir the package ships directly under $HOME (e.g. gtk's .icons/.themes).
        if [ -d "$DOTFILES_DIR/$pkg/.config" ]; then
            for path in "$DOTFILES_DIR/$pkg/.config/"*; do
                [ -e "$path" ] || continue
                local name target
                name="$(basename "$path")"
                target="$HOME/.config/$name"
                if [ -e "$target" ] && [ ! -L "$target" ]; then
                    echo "    backing up existing $target -> $BACKUP_DIR/"
                    mkdir -p "$BACKUP_DIR"
                    mv "$target" "$BACKUP_DIR/"
                fi
            done
        fi
        for path in "$DOTFILES_DIR/$pkg/".*; do
            [ -e "$path" ] || continue
            local name target
            name="$(basename "$path")"
            case "$name" in
                .|..|.config) continue ;;
            esac
            target="$HOME/$name"
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
        setup_gtk_theme
        enable_bluetooth
        cleanup_stale_nvidia_modeset
        configure_sway_session
    fi

    stow_packages

    echo "==> Done"
    echo "    Linked: ${PACKAGES[*]}"
    [ -d "$BACKUP_DIR" ] && echo "    Backed up pre-existing configs to: $BACKUP_DIR"
    echo "    If you ran with --packages on an NVIDIA machine: reboot, then look for"
    echo "    'Sway' behind the gear/settings icon on the GDM login screen."
    echo "    Reload sway with \$mod+Shift+c (or 'swaymsg reload') to pick up changes."
}

main "$@"
