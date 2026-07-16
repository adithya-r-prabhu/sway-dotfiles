# sway-dotfiles

Minimal Sway desktop, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Base setup forked/adapted from [npranav7619/dotfiles](https://github.com/npranav7619/dotfiles)
(Sway + Catppuccin Mocha), with app choices and extra keybindings ported from
this account's older X11/bspwm setup,
[adithya-r-prabhu/bspwm](https://github.com/adithya-r-prabhu/bspwm)
(rofi/sxhkd behaviors rewritten for wofi/sway, since bspwm+rofi are X11-only
and this is a Wayland setup).

- **Theme:** Catppuccin Mocha / Gruvbox Dark / Nord / Dracula, cycle with `$mod+Shift+t` or the paint-brush icon in waybar.
- **Font:** [Agave Nerd Font](https://github.com/ryanoasis/nerd-fonts).
- **Icon theme / GTK theme:** BigSur-dark icons + Orchis-dark GTK theme (ported from adithya-r-prabhu/dotfiles' `.icons`/`.themes`), set for both GTK3 (`gtk-3.0/settings.ini`) and GTK4/libadwaita apps (`gsettings` -- see `setup_gtk_theme()` in install.sh). Alternates also included: BigSur (light), Orchis-dark-compact, Yaru-dark.
- **Wallpapers:** Pranav's originals plus extras from adithya-r-prabhu/arch-xfce-dotfiles, all pickable via `$mod+Shift+p` or waybar's wallpaper icon.
- **Terminals:** [kitty](https://sw.kovidgoyal.net/kitty/) (primary, `$mod+Return`) and [foot](https://codeberg.org/dnkl/foot) (secondary/lightweight, `$mod+Shift+Return`).
- **Browser:** Microsoft Edge (`$mod+w`, assigned to workspace 2).
- **File manager:** Nautilus (`$mod+n`).
- **Other apps:** sway (compositor), waybar (bar), mako (notifications), wofi (launcher), swaylock (lock screen), blueman (Bluetooth), CopyQ (clipboard history), fastfetch, neovim, tmux, htop.

### Why no flameshot?

flameshot is installed by neither this repo nor the bspwm one anymore -- it
was tried and dropped. Its Qt5 GUI has no `wlr-layer-shell` support, so on
this sway/wlroots setup it launches (no crash, no error) but renders
**nothing visible at all** -- confirmed by screenshotting mid-launch and
seeing an unchanged desktop. This is a known flameshot-on-wlroots limitation,
not a config issue. `Alt+s` now runs `screenshot-region.sh`
(grim+slurp+wl-copy+a mako notification) instead -- same core
"select a region, save it, copy it" behavior, fully Wayland-native and
already proven to work reliably here.

### Why no nitrogen?

[nitrogen](https://github.com/l3ib/nitrogen) (used for wallpapers in the old
X11 `bspwm` setup) is an **X11-only** tool -- it fundamentally cannot run on
Wayland/Sway. Its job here is done natively instead by `swaybg` (sets the
wallpaper, started automatically by sway's `output * bg ...` config line)
plus the wofi-based `wallpaper-picker.sh` (lets you pick one interactively
and persists the choice to the sway config) -- same end result, Wayland-native
tooling. Same story for anything else from the old X11 setups that doesn't
appear here (`picom`, `nitrogen`, `polybar`, `rofi`, `dunst`, `sxhkd`): they're
all X11-specific and have Wayland-native equivalents already in this repo
(sway's own compositing, swaybg, waybar, wofi, mako, sway's `bindsym`).

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
CopyQ, fastfetch, dev tools), add the Microsoft Edge apt repo, set
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

## Keybindings

`$mod` = Super/Windows key. Full source of truth is
`sway/.config/sway/config` (also viewable live with `$mod+F1`).

**Apps / basics**
| Binding | Action |
|---|---|
| `$mod+Return` | Open kitty (terminal) |
| `$mod+Shift+Return` | Open foot (lightweight secondary terminal) |
| `$mod+d` | App launcher (wofi) |
| `$mod+w` | Open Microsoft Edge |
| `$mod+n` | Open Nautilus (file manager) |
| `$mod+q` / `$mod+Shift+q` | Close focused window |
| `$mod+l` / `$mod+Escape` / `$mod+Ctrl+l` | Lock screen |
| `$mod+Shift+e` | Power menu (lock/logout/suspend/restart/shutdown) |
| `$mod+F1` | Keybinding cheat-sheet |
| `$mod+Ctrl+e` | Emoji picker (copies to clipboard) |
| `$mod+Shift+c` | Reload sway config |

**"Connecting" (network / Bluetooth) -- new**
| Binding | Action |
|---|---|
| `$mod+Shift+n` | Network menu: Wi-Fi scan/connect/disconnect, ethernet toggle |
| `$mod+Shift+b` | Bluetooth manager (blueman-manager: pair/connect/trust devices) |

**Look & feel -- new**
| Binding | Action |
|---|---|
| `$mod+Shift+t` | Cycle color theme (Catppuccin/Gruvbox/Nord/Dracula) |
| `$mod+Shift+p` | Wallpaper picker (thumbnails from `wallpapers/`) |
| `$mod+Shift+m` | Monitor layout tool (wdisplays) |

**Clipboard & screenshots**
| Binding | Action |
|---|---|
| `$mod+Ctrl+v` | Clipboard history (CopyQ, toggle show/hide) -- new |
| `Alt+s` | Screenshot a region, save to `~/Pictures/Screenshots/` + copy to clipboard (grim+slurp) -- new, replaces flameshot |
| `Print` | Full screenshot to `~/Pictures/Screenshots/` |
| `$mod+Shift+s` | Screenshot a selected region straight to clipboard only (grim+slurp) |

CopyQ's window is forced floating, centered, and fixed-size (never tiles).
**sway does not draw clickable close/minimize buttons on any window**
(unlike GNOME/Windows) -- the titlebar is just a label. To dismiss CopyQ:
press `$mod+Ctrl+v` again (same toggle), press `Escape` while it's focused
(CopyQ's own default), click anywhere outside it (auto-closes after 500ms,
`close_on_unfocus` is on by default), or `$mod+q` like any other
window. It keeps running in the background/tray either way -- that's by
design for a clipboard manager, not a bug.

**Media / brightness keys** (all show a mako popup now -- new)
| Binding | Action |
|---|---|
| `XF86AudioRaiseVolume` / `LowerVolume` / `Mute` | Volume up/down/mute |
| `XF86AudioMicMute` | Mic mute toggle |
| `XF86MonBrightnessUp` / `Down` | Brightness up/down |

**Moving around** (vim-style `h/j/k/l` = left/down/up/right, plus arrow keys)
| Binding | Action |
|---|---|
| `$mod+h/j/k/l` or arrows | Move focus |
| `$mod+Shift+h/j/k/l` or `Shift+`arrows | Move focused window |
| `$mod+1`..`$mod+0` | Switch to workspace 1-10 |
| `$mod+Shift+1`..`0` | Move window to workspace 1-10 |

**Layout**
| Binding | Action |
|---|---|
| `$mod+b` / `$mod+v` | Split horizontally / vertically |
| `$mod+s` / `$mod+Shift+w` | Stacking / tabbed layout |
| `$mod+e` | Toggle split layout |
| `$mod+f` | Fullscreen |
| `$mod+Shift+space` | Toggle floating |
| `$mod+space` | Toggle focus between tiling/floating |
| `$mod+a` | Focus parent container |
| `$mod+r` | Resize mode (then arrows/hjkl, Return/Escape to exit) |
| `$mod+minus` / `$mod+Shift+minus` | Show/send to scratchpad |

`$mod+q` and `$mod+w` match bspwm's un-shifted close-window/browser
bindings directly (bspwm had no sway-style layout commands competing for
those keys). Sway's own `layout tabbed`, which normally lives on plain
`$mod+w`, moved to `$mod+Shift+w` instead so it's still available.
`$mod+e` still means `layout toggle split` (sway default) since the
file-manager binding lives on `$mod+n` and never competed for it.

## Structure

Each top-level directory is a stow package mirroring `$HOME`, e.g.
`kitty/.config/kitty/kitty.conf` links to `~/.config/kitty/kitty.conf`. To
(re)link a single package by hand: `stow -v -t ~ kitty`.

## Wallpaper

Original wallpaper credits [walls-catppuccin-mocha](https://github.com/orangci/walls-catppuccin-mocha) (via npranav7619/dotfiles).
