# dotfiles

My Arch Linux Wayland desktop: Hyprland with my own Quickshell shell, **savpavi-shell** (bar, launcher, notifications, lock screen, OSD, settings), a theme switcher that recolours the shell and a dozen apps at once, and a set of small desktop tools.

These are personal configs. Monitor names (`DP-1`, `DP-3`), paths and app choices fit my machine, so read before you copy.

## Layout

| Path | What it holds |
|---|---|
| `config/` | App configs, symlinked into `~/.config/<name>` by `dot-link` (Hyprland, savpavi-shell, Alacritty, btop, fastfetch, Starship) |
| `bin/` | `dot-*` helper scripts (add to `PATH`) |
| `themes/` | Omarchy colour schemes and backgrounds, kept as a wallpaper source (the `dot-theme` switcher that used them was removed in November 2026) |
| `templates/` | `templates/apps/`: app colour templates filled by `dot-shell-theme` |
| `tests/` | Unit tests for the helper scripts |
| `extras/` | Pieces installed by hand: Firefox Nord theme, `.desktop` launchers, MIME defaults, systemd user units, Dolphin service menus |
| `shell/` | Bash snippets for `~/.bashrc.d/` |
| `docs/` | Desktop tools, Hyprland cheatsheet (mostly in Turkish) |

## Install

```bash
git clone https://github.com/savpavi/dotfiles.git ~/dotfiles
~/dotfiles/bin/dot-link --dry-run   # see what would change
~/dotfiles/bin/dot-link             # back up existing configs, then symlink
export PATH="$HOME/dotfiles/bin:$PATH"
```

On a fresh Arch install (after `archinstall`, as the normal user) `install/arch/install.sh` installs the packages in `install/arch/{pacman,aur,flatpak}.txt`, runs `dot-link` and enables the services. Stages are idempotent and can be named individually; `--dry-run` prints what would happen. The `disks` and `home` stages (fstab entries for my `/srv` disks, home restore from my backup) are opt-in and specific to my machine. VFIO and Looking Glass are not covered.

`dot-link` moves anything already in `~/.config` to `~/.local/share/dotfiles-backup/<date>/` before linking. `dot-link --unlink` removes the links and copies the repo content back.

## savpavi-shell

`config/savpavi-shell/` is a [Quickshell](https://quickshell.org) shell run as the user unit `savpavi-shell.service` (`qs -p ~/dotfiles/config/savpavi-shell`):

- floating bar: workspaces, focused window, media with a cava visualiser, weather (open-meteo), tray, CPU/RAM, Claude usage, Tailscale, phone send, notifications, quick settings, clock with calendar, power menu
- launcher (Alt+Space): apps, `/` file names via `dsearch`, `dig ` file contents via DigUp, clipboard history via `cliphist` (Super+X)
- notification daemon and centre, lock screen (PAM), volume OSD, session menu, wallpaper layer and picker, keybind sheet (Super+K)
- settings window (Super+Alt+S): theme and wallpaper, window gaps/borders, bar widgets, notifications, displays (with a 15-second revert), sound, keyboard repeat and a key tester, default apps, shortcut editor, power and idle lock, system info

Hyprland values the settings window changes live in `config/hypr/settings.json` → `settings.lua` and `user-binds.json` → `user-binds.lua`; each change is checked with `Hyprland --verify-config` and rolled back if it fails. Shell preferences are kept in `~/.config/savpavi-shell/settings.json`.

```bash
dot-shell-theme pick        # choose one of the 15 themes (fuzzel)
dot-shell-theme apply dwm-nord
dot-shell-theme wall        # next wallpaper of the active theme
```

`dot-shell-theme` reads `config/savpavi-shell/themes/` (theme list + palettes) and writes the shell palette, Hyprland border colours and cursor, and app colours for GTK 3/4, Qt5/6ct, KDE, Alacritty, Vesktop/Vencord and btop from `templates/apps/`. For KDE apps such as Dolphin it also sets `[UiSettings] ColorScheme` in `~/.config/kdeglobals`: outside Plasma they only load a colour scheme that is selected by name and otherwise fall back to Breeze, ignoring the qt6ct palette. Running KDE apps pick up a theme change after a restart. With waywallen installed it also opens the theme's Wallpaper Engine wallpaper.

## Desktop tools

| Command | Does |
|---|---|
| `dot-shell <action>` | Shared shortcut actions (launcher, clipboard, lock, bar, volume, settings, themes…) sent to savpavi-shell over Quickshell IPC |
| `dot-shell-theme` | Themes for savpavi-shell and the apps (see above) |
| `dot-grab` | Download the focused Brave Origin tab or the clipboard link: video sites via yt-dlp, galleries via gallery-dl, unknown sites try both, then fall back to the direct file links found on the page (videos and archives first, otherwise images; saved under a folder named after the page title). Uses the browser's cookies and reports through notifications (Super+Shift+D tab, Super+Ctrl+D clipboard) |
| `dot-health` | *Legacy, Niri-only:* read-only desktop health report from the Niri setup (checks `niri validate`, Niri IPC); never restarts or repairs anything. Not updated for Hyprland |
| `dot-record` | *Legacy, Niri-only:* screen recording via Niri IPC + wf-recorder; the same command starts and stops. Does not work under Hyprland |
| `dot-resolve [FILE…]` | Prepare a video for DaVinci Resolve: copy the video stream, PCM audio, write `<name>_resolve.mov` |
| `dot-quicklook FILE` | Quick Look-style preview through GNOME Sushi; available from the Dolphin service menu |
| `dot-send [FILE…]` | Send files to the paired phone over KDE Connect (file picker without arguments); the bars have a button for it |
| `dot-drive <action>` | Google Drive mounted at `~/GoogleDrive` with rclone: `status` (JSON for the bar's Drive widget), `link FILE…` copies the Drive link without changing sharing, `share FILE…` creates a public link after confirming, `sync [NAME]` two-way folder sync with rclone bisync, `open`, `web`, `restart` (Dolphin actions for link and share) |
| `dot-fm <action> FILE…` | Helper behind the Dolphin service menus in `extras/dolphin/`: video (MP4, MP3, lossless audio, GIF, lossless trim), PDF (merge, split, compress), duplicate finder (report only), find/replace rename with preview, which mergerfs disk holds a file, copy path/name/`file://` URI, open a terminal or Neovim in Alacritty. Outputs go next to the original under a new name; nothing is overwritten |
| `dot-ocr` | Select a region, OCR it with Tesseract, copy the text |
| `dot-webapp Name https://url` | Create a Brave Origin web-app launcher (never overwrites) |
| `dot-keys` | Keybind sheet of savpavi-shell, read from the Hyprland Lua config and its comments (Super+K); `--text` prints it |
| `dot-spin [-s arch\|donut] [-t SEC] [--fetch]` | Spinning ASCII art: an extruded Arch logo in Arch blue (default) or a Nord-coloured donut; Ctrl+C or `q` quits. `--fetch` prints it next to fastfetch's info and keeps it spinning in the background at that screen spot; a zsh `preexec` hook stops it at the first command (also Ctrl+L, terminal resize, shell exit), since scrolling would move it. About 10% of one core while spinning |
| `dot-wallfx <pick\|map\|warm\|install>` | Maps for savpavi-shell's wallpaper transition (`wallpaper/WallFx.qml` + `shaders/wallfx.frag`): `sketch` draws the subject's outline with a pen, hatches it in and lets the rest bleed outwards; `spread` (no subject found) bleeds in from a few points. `install` sets up the cut-out (rembg in its own venv, about 900 MB); without it every wallpaper gets `spread`. `warm` precomputes the theme wallpapers |
| `dot-askpass` | Zenity askpass helper for `sudo -A` |

`dot-send` needs `kdeconnect` and `zenity`. LocalSend runs hidden in the tray through `extras/systemd/localsend.service` (copy to `~/.config/systemd/user/`, then `systemctl --user enable --now localsend.service`).

`dot-drive` needs `rclone` with a remote named `gdrive:` (your own OAuth client: Desktop app, consent screen External and in production, Drive API enabled). The mount runs from `extras/systemd/rclone-gdrive.service` (copy to `~/.config/systemd/user/`, then `systemctl --user enable --now rclone-gdrive.service`); it exposes rclone's remote control on a socket in `$XDG_RUNTIME_DIR`, which `dot-drive` reads, and notifies when the mount stops unexpectedly.

Folder sync (like "back up folders from my computer" in Drive for Windows) is configured in `~/.config/dot-drive/sync.conf`, one `NAME<TAB>LOCAL<TAB>REMOTE` line per pair with optional filters in `NAME.filter`. The first run and any filter change do a `--resync` automatically; conflicts keep the newer copy and rename the other `.conflictN`. `extras/systemd/dot-drive-sync.{service,timer}` runs it every 10 minutes and `dot-drive-watch.service` (needs `inotify-tools`) triggers it 45 s after local changes settle.

`dot-fm` needs `ffmpeg`, `poppler`, `ghostscript`, `zenity`, `wl-clipboard`, `attr` and `alacritty`.

`dot-quicklook` needs the `sushi` package.

`dot-wallfx` needs `python-numpy`, `python-pillow` and, for `install`, `uv`; rebuilding the shader needs `qsb` from `qt6-shadertools`.

`dot-grab` needs `yt-dlp[default]` (for YouTube's JS challenge) and `gallery-dl`, e.g. via `uv tool install`. Extra gallery-dl domains can be listed one per line in `~/.config/dot-grab/gallery-domains`, outside the repo.

Run the tests with `python3 -m unittest discover -s tests`.

## Credits

- Colour schemes and backgrounds in `themes/`: [basecamp/omarchy](https://github.com/basecamp/omarchy), MIT © David Heinemeier Hansson (see `themes/UPSTREAM.md`).
- App colour templates: [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) matugen templates, MIT © Avenge Media LLC (see `templates/apps/LICENSE-dms`).
- Claude usage script: claudeUsage DMS plugin, MIT © Bogdan Velicu (`config/savpavi-shell/scripts/claude-usage.sh`).
