# sway-dotfiles

Minimal Sway desktop, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Base setup forked/adapted from [npranav7619/dotfiles](https://github.com/npranav7619/dotfiles)
(Sway + Catppuccin Mocha), with app choices and extra keybindings ported from
this account's older X11/bspwm setup,
[adithya-r-prabhu/bspwm](https://github.com/adithya-r-prabhu/bspwm)
(rofi/sxhkd behaviors rewritten for wofi/sway, since bspwm+rofi are X11-only
and this is a Wayland setup).

- **Theme:** Catppuccin Mocha by default, click the paint-brush icon in waybar to cycle through Catppuccin Mocha / Gruvbox Dark / Nord / Dracula.
- **Font:** [Agave Nerd Font](https://github.com/ryanoasis/nerd-fonts).
- **Terminals:** [kitty](https://sw.kovidgoyal.net/kitty/) (primary, `$mod+Return`) and [foot](https://codeberg.org/dnkl/foot) (secondary/lightweight, `$mod+Shift+Return`).
- **Browser:** Microsoft Edge (`$mod+Shift+w`, assigned to workspace 2).
- **File manager:** Nautilus (`$mod+n`).
- **Other apps:** sway (compositor), waybar (bar), mako (notifications), wofi (launcher), swaylock (lock screen), flameshot (screenshot GUI, `Alt+s`), fastfetch, neovim, tmux, htop.

## Usage

```
git clone https://github.com/adithya-r-prabhu/sway-dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

This installs the Agave Nerd Font (if not already present) and symlinks each
package's config into `~/.config` via `stow`. Any pre-existing real config
files get moved to `~/.config-backup-<timestamp>/` first, so nothing is lost.

To also install the full package list (sway ecosystem, kitty/foot, Nautilus,
flameshot, fastfetch, dev tools), add the Microsoft Edge apt repo, set
default apps (browser/file manager), and apply the hybrid-NVIDIA fix if
needed:

```
./install.sh --packages
```

### Hybrid NVIDIA laptops/desktops: sway refuses to start

On a hybrid-GPU machine (NVIDIA + Intel/AMD) with the proprietary NVIDIA
driver, sway (wlroots) refuses to start at all -- it hard-exits with
`Proprietary Nvidia drivers are NOT supported`. `./install.sh --packages`
detects this via `lspci` and disables `nvidia-drm`'s modeset capability
(`/etc/modprobe.d/zzz-nvidia-drm-nomodeset.conf`), so Intel/AMD always drives
the display and NVIDIA stays available for compute/CUDA only. **Takes effect
on next reboot.** This is a no-op on non-hybrid systems and skips itself if
already applied.

## Extra keybindings (beyond Pranav's base set)

| Binding | Action |
|---|---|
| `$mod+Shift+Return` | Open foot (secondary terminal) |
| `$mod+Shift+w` | Open Microsoft Edge |
| `$mod+n` | Open Nautilus (file manager) |
| `$mod+Shift+e` | Power menu (lock/logout/suspend/reboot/shutdown) |
| `$mod+F1` | Keybinding cheat-sheet |
| `$mod+Ctrl+e` | Emoji picker (copies to clipboard) |
| `Alt+s` | Screenshot GUI (flameshot) |

See `sway/.config/sway/config` for the full list (workspaces, moving/resizing
windows, media/brightness keys, screenshots via grim+slurp, etc. -- all
inherited from Pranav's base config).

## Structure

Each top-level directory is a stow package mirroring `$HOME`, e.g.
`kitty/.config/kitty/kitty.conf` links to `~/.config/kitty/kitty.conf`. To
(re)link a single package by hand: `stow -v -t ~ kitty`.

## Wallpaper

Original wallpaper credits [walls-catppuccin-mocha](https://github.com/orangci/walls-catppuccin-mocha) (via npranav7619/dotfiles).
