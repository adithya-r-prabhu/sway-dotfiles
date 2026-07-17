# sway-dotfiles
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/984096a5-798a-46c5-9a7e-1b1287449425" />

Minimal Sway (Wayland) desktop for Ubuntu, managed with [GNU Stow](https://www.gnu.org/software/stow/).
Base setup from [npranav7619/dotfiles](https://github.com/npranav7619/dotfiles), with
app choices/keybindings ported from this account's old X11 setup,
[adithya-r-prabhu/bspwm](https://github.com/adithya-r-prabhu/bspwm).

## What's included

- **Theme:** Catppuccin Mocha / Gruvbox / Nord / Dracula -- cycle with `$mod+Shift+t`
- **Icons/GTK theme:** BigSur-dark + Orchis-dark (alternates: BigSur, Orchis-dark-compact, Yaru-dark)
- **Wallpapers:** picker via `$mod+Shift+p`
- **Terminals:** kitty (`$mod+Return`), foot (`$mod+Shift+Return`)
- **Browser:** Microsoft Edge (`$mod+w`) · **Files:** Nautilus (`$mod+n`)
- **Clipboard history:** CopyQ (`$mod+Ctrl+v`) · **Bluetooth:** blueman (`$mod+Shift+b`)
- **Screenshots:** grim+slurp (`Alt+s` region+save+clipboard, `Print` full, `$mod+Shift+s` region-to-clipboard)
- waybar, mako, wofi, swaylock, fastfetch, neovim, tmux, htop

## Install

```
git clone https://github.com/adithya-r-prabhu/sway-dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh              # font + stow configs only
./install.sh --packages    # + apt packages, Edge repo, default apps, GTK theme,
                           #   Bluetooth, and NVIDIA/GDM fixes (see below)
```

Pre-existing real configs get backed up to `~/.config-backup-<timestamp>/` first.

**On an NVIDIA machine**, `--packages` also fixes two Sway/GDM issues: Wayland
sessions missing entirely from the GDM login screen, and Sway refusing to
start on proprietary NVIDIA drivers. See comments in `install.sh`
(`cleanup_stale_nvidia_modeset`, `configure_sway_session`) for details --
re-run `--packages` if Sway ever stops appearing/launching after a driver or
`sway` package update.

## Keybindings

`$mod` = Super key. Full source of truth: `sway/.config/sway/config`, or view live with `$mod+F1`.

| Binding | Action |
|---|---|
| `$mod+Return` / `$mod+Shift+Return` | Terminal: kitty / foot |
| `$mod+d` | App launcher |
| `$mod+w` | Browser (Edge) |
| `$mod+n` | File manager (Nautilus) |
| `$mod+q` | Close window |
| `$mod+l` | Lock screen |
| `$mod+Shift+e` | Power menu |
| `$mod+Ctrl+e` | Emoji picker |
| `$mod+Ctrl+v` | Clipboard history (CopyQ) |
| `$mod+F1` | Keybinding cheat-sheet |
| `$mod+Shift+n` | Network menu (Wi-Fi/ethernet) |
| `$mod+Shift+b` | Bluetooth manager |
| `$mod+Shift+t` | Cycle color theme |
| `$mod+Shift+p` | Wallpaper picker |
| `$mod+Shift+m` | Monitor layout (wdisplays) |
| `Scroll Lock` | Switch shared monitor's input to this machine (DDC/CI via ddcutil) |
| `Alt+s` | Screenshot region -> save + clipboard |
| `Print` / `$mod+Shift+s` | Screenshot full / region to clipboard |
| `$mod+1..0` / `$mod+Shift+1..0` | Switch / move to workspace 1-10 |
| `$mod+hjkl` or arrows | Move focus (`Shift+` to move window) |
| `$mod+b` / `v` / `s` / `Shift+w` | Split horiz/vert, stacking, tabbed layout |
| `$mod+e` | Toggle split layout |
| `$mod+f` | Fullscreen |
| `$mod+Shift+space` / `$mod+space` | Toggle floating / focus tiling-floating |
| `$mod+r` | Resize mode |
| `$mod+Shift+c` | Reload config |

CopyQ and any floating window has no clickable close button (sway doesn't
draw one) -- dismiss with `Escape`, the same shortcut that opened it, or `$mod+q`.

## Structure

Each top-level directory is a stow package mirroring `$HOME`, e.g.
`kitty/.config/kitty/kitty.conf` links to `~/.config/kitty/kitty.conf`.
Relink one package by hand: `stow -v -t ~ kitty`.

## Notes

- **No nitrogen/picom/polybar/rofi/dunst/sxhkd** (from the old X11 bspwm
  setup): all X11-only, replaced here by their Wayland-native equivalents
  already in this repo (swaybg+wallpaper-picker, sway compositing, waybar,
  wofi, mako, sway `bindsym`).
- **No flameshot**: its Qt5 GUI doesn't render at all under Sway (no
  `wlr-layer-shell` support) -- replaced by the `Alt+s` grim+slurp script.
- Wallpaper credit: [walls-catppuccin-mocha](https://github.com/orangci/walls-catppuccin-mocha).
