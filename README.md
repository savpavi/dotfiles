# dotfiles

My Fedora 44 Wayland desktop: Hyprland with my own Quickshell shell, **savpavi-shell** (bar, launcher, notifications, lock screen, OSD, settings), DankMaterialShell kept as a fallback, a theme switcher that recolours the shell and a dozen apps at once, and a set of small desktop tools.

These are personal configs. Monitor names (`DP-1`, `DP-3`), paths and app choices fit my machine, so read before you copy.

## Layout

| Path | What it holds |
|---|---|
| `config/` | App configs, symlinked into `~/.config/<name>` by `dot-link` (Hyprland, savpavi-shell, DankMaterialShell, Kitty, Alacritty, Waybar, Rofi, SwayNC, btop, fastfetch, Starship, …) |
| `bin/` | `dot-*` helper scripts (add to `PATH`) |
| `themes/` | 22 colour themes adapted from Omarchy |
| `templates/` | `*.tpl` files rendered by `dot-theme`; `templates/apps/` app colour templates filled by `dot-shell-theme` |
| `tests/` | Unit tests for the helper scripts |
| `extras/` | Pieces installed by hand: Firefox Nord theme, `.desktop` launchers, MIME defaults, systemd user units, Thunar actions |
| `shell/` | Bash snippets for `~/.bashrc.d/` |
| `docs/` | Desktop tools, Hyprland cheatsheet (mostly in Turkish) |

## Install

```bash
git clone https://github.com/savpavi/dotfiles.git ~/dotfiles
~/dotfiles/bin/dot-link --dry-run   # see what would change
~/dotfiles/bin/dot-link             # back up existing configs, then symlink
export PATH="$HOME/dotfiles/bin:$PATH"
```

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

`dot-shell-theme` reads `config/savpavi-shell/themes/` (theme list + palettes) and writes the shell palette, Hyprland border colours and cursor, and app colours for GTK 3/4, Qt5/6ct, KDE, kitty, Vesktop/Vencord, Zed and btop from `templates/apps/`. With waywallen installed it also opens the theme's Wallpaper Engine wallpaper.

## Themes (dot-theme, older)

```bash
dot-theme list            # available themes, active one marked
dot-theme set gruvbox     # apply a theme
dot-theme next            # cycle
dot-theme menu            # pick with rofi
dot-theme reapply         # re-render the active theme
```

`dot-theme` renders `templates/` with the theme's `colors.toml` and writes the result for Kitty, Alacritty, btop, Rofi, SwayNC, wlogout, Hyprlock and Hyprland. It predates savpavi-shell, whose `dot-shell-theme` now drives the daily colours. Wallpapers are not stored here.

## Desktop tools

| Command | Does |
|---|---|
| `dot-shell <action>` | Shared shortcut actions (launcher, clipboard, lock, bar, volume, settings, themes…) routed to savpavi-shell or the DMS fallback; `dot-shell switch` toggles between them |
| `dot-shell-theme` | Themes for savpavi-shell and the apps (see above) |
| `dot-grab` | Download the focused Brave Origin tab or the clipboard link: video sites via yt-dlp, galleries via gallery-dl, unknown sites try both, then fall back to the direct file links found on the page (videos and archives first, otherwise images; saved under a folder named after the page title). Uses the browser's cookies and reports through notifications (Super+Shift+D tab, Super+Ctrl+D clipboard) |
| `dot-health` | Read-only desktop health report; never restarts or repairs anything |
| `dot-record` | Screen recording via Niri IPC + wf-recorder; the same command starts and stops |
| `dot-resolve [FILE…]` | Prepare a video for DaVinci Resolve: copy the video stream, PCM audio, write `<name>_resolve.mov` (Thunar action) |
| `dot-quicklook FILE` | Quick Look-style preview through GNOME Sushi; bound to Space in Thunar, pressing again closes it |
| `dot-send [FILE…]` | Send files to the paired phone over KDE Connect (file picker without arguments); bar widget `dotSend`: left click sends, right click opens LocalSend |
| `dot-drive <action>` | Google Drive mounted at `~/GoogleDrive` with rclone: `status` (JSON for the bar's Drive widget), `link FILE…` copies the Drive link without changing sharing, `share FILE…` creates a public link after confirming, `sync [NAME]` two-way folder sync with rclone bisync, `open`, `web`, `restart` (Thunar actions for link and share) |
| `dot-ocr` | Select a region, OCR it with Tesseract, copy the text |
| `dot-webapp Name https://url` | Create a Brave Origin web-app launcher (never overwrites) |
| `dot-keys` | Keybind sheet of savpavi-shell, read from the Hyprland Lua config and its comments (Super+K); `--text` prints it |
| `dot-askpass` | Zenity askpass helper for `sudo -A` |

`dot-send` needs `kdeconnect` and `zenity`. LocalSend runs hidden in the tray through `extras/systemd/localsend.service` (copy to `~/.config/systemd/user/`, then `systemctl --user enable --now localsend.service`).

`dot-drive` needs `rclone` with a remote named `gdrive:` (your own OAuth client: Desktop app, consent screen External and in production, Drive API enabled). The mount runs from `extras/systemd/rclone-gdrive.service` (copy to `~/.config/systemd/user/`, then `systemctl --user enable --now rclone-gdrive.service`); it exposes rclone's remote control on a socket in `$XDG_RUNTIME_DIR`, which `dot-drive` reads, and notifies when the mount stops unexpectedly.

Folder sync (like "back up folders from my computer" in Drive for Windows) is configured in `~/.config/dot-drive/sync.conf`, one `NAME<TAB>LOCAL<TAB>REMOTE` line per pair with optional filters in `NAME.filter`. The first run and any filter change do a `--resync` automatically; conflicts keep the newer copy and rename the other `.conflictN`. `extras/systemd/dot-drive-sync.{service,timer}` runs it every 10 minutes and `dot-drive-watch.service` (needs `inotify-tools`) triggers it 45 s after local changes settle.

`dot-quicklook` needs the `sushi` package. Append `extras/thunar/accels-quicklook.scm` to `~/.config/Thunar/accels.scm` while Thunar is closed to get the Space binding.

`dot-grab` needs `yt-dlp[default]` (for YouTube's JS challenge) and `gallery-dl`, e.g. via `uv tool install`. Extra gallery-dl domains can be listed one per line in `~/.config/dot-grab/gallery-domains`, outside the repo.

Run the tests with `python3 -m unittest discover -s tests`.

## Credits

- Theme system and colour schemes: [basecamp/omarchy](https://github.com/basecamp/omarchy), MIT © David Heinemeier Hansson (see `themes/UPSTREAM.md`).
- App colour templates: [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) matugen templates, MIT © Avenge Media LLC (see `templates/apps/LICENSE-dms`).
- Claude usage script: claudeUsage DMS plugin, MIT © Bogdan Velicu (`config/savpavi-shell/scripts/claude-usage.sh`).
