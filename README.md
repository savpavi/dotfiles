# dotfiles

My Fedora 44 Wayland desktop: Hyprland with DankMaterialShell as the daily driver (Noctalia kept as a fallback), a Niri configuration kept alongside it, a theme switcher that recolours a dozen apps at once, and a set of small desktop tools.

These are personal configs. Monitor names (`DP-1`, `DP-3`), paths and app choices fit my machine, so read before you copy.

## Layout

| Path | What it holds |
|---|---|
| `config/` | App configs, symlinked into `~/.config/<name>` by `dot-link` (Hyprland, Niri, DankMaterialShell, Kitty, Alacritty, Waybar, Rofi, SwayNC, btop, fastfetch, Starship, …) |
| `bin/` | `dot-*` helper scripts (add to `PATH`) |
| `themes/` | 22 colour themes adapted from Omarchy |
| `templates/` | `*.tpl` files rendered per theme |
| `lib/`, `tests/` | Python modules behind the desktop tools, with unit tests |
| `extras/` | Pieces installed by hand: Noctalia snippets, Firefox Nord theme, `.desktop` launchers, systemd user units, Thunar actions, presenter overlay |
| `shell/` | Bash snippets for `~/.bashrc.d/` |
| `docs/` | Niri guide, desktop tools, Hyprland cheatsheet (mostly in Turkish) |

## Install

```bash
git clone https://github.com/savpavi/dotfiles.git ~/dotfiles
~/dotfiles/bin/dot-link --dry-run   # see what would change
~/dotfiles/bin/dot-link             # back up existing configs, then symlink
export PATH="$HOME/dotfiles/bin:$PATH"
```

`dot-link` moves anything already in `~/.config` to `~/.local/share/dotfiles-backup/<date>/` before linking. `dot-link --unlink` removes the links and copies the repo content back.

## Themes

```bash
dot-theme list            # available themes, active one marked
dot-theme set gruvbox     # apply a theme
dot-theme next            # cycle
dot-theme menu            # pick with rofi
dot-theme reapply         # re-render the active theme
```

`dot-theme` renders `templates/` with the theme's `colors.toml` and writes the result for Kitty, Alacritty, btop, Rofi, SwayNC, wlogout, Hyprlock and Hyprland. It does not touch Niri; Niri colours come from Noctalia templates (see `docs/desktop-tools.md`). Wallpapers are not stored here.

## Desktop tools

| Command | Does |
|---|---|
| `dot-shell <action>` | Shared shortcut actions (launcher, clipboard, lock, bar, volume, themes…) routed to whichever shell is running; `dot-shell switch` toggles DMS ↔ Noctalia |
| `dot-dms-theme` | Port the Noctalia theme-switcher themes to DankMaterialShell; `pick` chooses and applies one |
| `dot-grab` | Download the focused Zen tab or the clipboard link: video sites via yt-dlp, galleries via gallery-dl, unknown sites try both. Uses the browser's cookies and reports through notifications (Super+Shift+D tab, Super+Ctrl+D clipboard) |
| `dot-settings` | GTK settings centre (built for the Niri session) |
| `dot-desktop` | Noctalia service/backup indicators and tool menus |
| `dot-health` | Read-only desktop health report; never restarts or repairs anything |
| `dot-record` | Screen recording via Niri IPC + wf-recorder; the same command starts and stops |
| `dot-presenter` | Toggle a drawing/spotlight overlay on the focused monitor |
| `dot-quicklook FILE` | Quick Look-style preview through GNOME Sushi; bound to Space in Thunar, pressing again closes it |
| `dot-ocr` | Select a region, OCR it with Tesseract, copy the text |
| `dot-webapp Name https://url` | Create a Brave web-app launcher (never overwrites) |
| `dot-keys` | Searchable keybinding list |
| `dot-askpass` | Zenity askpass helper for `sudo -A` |

`dot-quicklook` needs the `sushi` package. Append `extras/thunar/accels-quicklook.scm` to `~/.config/Thunar/accels.scm` while Thunar is closed to get the Space binding.

`dot-grab` needs `yt-dlp[default]` (for YouTube's JS challenge) and `gallery-dl`, e.g. via `uv tool install`. Extra gallery-dl domains can be listed one per line in `~/.config/dot-grab/gallery-domains`, outside the repo.

Run the tests with `python3 -m unittest discover -s tests`.

## Credits

- Theme system and colour schemes: [basecamp/omarchy](https://github.com/basecamp/omarchy), MIT © David Heinemeier Hansson (see `themes/UPSTREAM.md`).
- Presenter overlay components: [andreas-bylund/presenter-overlay](https://github.com/andreas-bylund/presenter-overlay), MIT (see `extras/presenter/LICENSE.upstream`).
