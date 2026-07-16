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

### NVIDIA machines: Sway missing from the login screen, or won't start

On a machine with the proprietary NVIDIA driver, two separate problems show up:

1. **"Sway" doesn't appear as a session option at all** (behind GDM's
   gear/settings icon). Ubuntu's GDM has a udev rule
   (`/usr/lib/udev/rules.d/61-gdm.rules`) that disables Wayland *entirely*
   whenever `nvidia-drm`'s `modeset` parameter is off -- **except** on
   detected hybrid-GPU *laptops*, which it leaves alone. On a desktop (no
   internal panel), disabling modeset -- e.g. via the common
   `options nvidia-drm modeset=0` fix for hybrid-laptop black-screen-at-boot
   issues -- backfires and hides every Wayland session. `./install.sh
   --packages` removes any such stale modeset override
   (`cleanup_stale_nvidia_modeset`) so GDM keeps Wayland/Sway listed
   (**takes effect on next reboot**).
2. **Sway exits immediately with `Proprietary Nvidia drivers are NOT
   supported`** if you do select it. This check is independent of modeset --
   it fires whenever any proprietary NVIDIA driver is loaded at all. The fix
   is the `--unsupported-gpu` flag, which `./install.sh --packages` bakes
   into `/usr/share/wayland-sessions/sway.desktop`'s `Exec=` line
   (`configure_sway_session`). Note that file isn't a tracked dpkg conffile,
   so a future `sway` package upgrade can silently reset it -- re-run
   `./install.sh --packages` if Sway stops launching after an update.

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
