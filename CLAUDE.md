# Working in this repo

This repo is the whole dwl desktop: the compositor (`dwl/`, a git subtree), the Quickshell bar (`bar/`), themes (`themes/`), scripts (`bin/dwl-*`, `bin/dot-*`), the login screen (`sddm/`) and the installers (`install/`). `README.md` explains how the parts fit together and `docs/dwl.md` lists the patches in the C source. Read those before changing structure.

The running session uses this checkout directly (`DWL_HOME`). Saving a file under `bar/` reloads the live bar, and `dwl-theme apply` recolours the real desktop. Treat edits here as edits to a live system.

## Rules

- The repo is public. Commit messages, the README and docs are in English. Never commit private paths, personal data, tokens, or names of private sites; machine-local choices live outside the repo (for example `~/.config/dwl-theme/walls.json`).
- Commit and push only when asked. Never rewrite history or force-push.
- A new `dot-*` tool gets a row in the README "Desktop tools" table.
- The desktop is dwl only. The Hyprland and savpavi-shell side was removed on purpose; do not restore it or keep things compatible with it.
- `dwl/` stays on the v0.9 release. Do not pull upstream `main` or propose an upgrade unless asked; `docs/dwl.md` records why.
- After changing `dwl/dwl.c` or `dwl/config.h` the owner runs `install/dwl.sh derle kur` (needs a password) and logs in again. Say so instead of trying to install.
- Units in `extras/systemd/` are copied to `~/.config/systemd/user`, not linked. When one changes, the installed copy must be updated too.

## Checks

```bash
tests/themes.sh                         # every theme in a headless dwl session
python3 -m unittest discover -s tests   # the dot-* tools
dwl-theme check                         # validate the theme files
shellcheck -S warning bin/<script>
/usr/lib/qt6/bin/qmllint bar/<file>.qml # only syntax errors matter
```

- `/usr/bin/qmllint` on this machine is a different program that prints nothing. Use the Qt 6 path above. Quickshell types make qmllint report many "unqualified access" warnings; they are noise.
- `tests/themes.sh` proves nothing crashed and no QML error was logged. It does not look at pixels, so do not report a visual change as verified from it.

## Trying things without touching the real session

- Nested or headless dwl must run with `DWL_NESTED=1` and `DWL_HOME` set to this checkout. Without `DWL_NESTED` the autostart script runs again, takes over the real session's polkit agent and kills it when the test ends.
- Headless: `DWL_NESTED=1 DWL_HOME=$PWD WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 dwl -s "<command>"`. Add `XDG_STATE_HOME=<tmp>` and `DWL_THEME_NO_WALL=1` so theme state and the wallpaper stay untouched.
- `QT_QPA_PLATFORM=offscreen` falls back to the software renderer and `ShaderEffect` renders black; use headless dwl for shader work. Recompile shaders with `/usr/lib/qt6/bin/qsb`.
- A nested dwl window that is not visible produces no frames and `grim` waits forever: always `timeout 3 grim`.
- Do not take screenshots of the host session. Capture only from the nested or headless one.

## Traps

- OpenRGB: never start an `openrgb` client or the GUI while the server is still detecting devices (about 12 s after start). A client that connects during detection makes the server misread the hardware. `bin/dot-rgb` waits on the journal for that reason; keep it that way.
- `pkill -f <pattern>` in a shell command also matches the shell running it. Use `pkill -x`, or the `[c]laude` bracket form.
- A popup that changes size while open is drawn broken under dwl; `bar/Panel.qml` closes and reopens instead. Keep that pattern for new panels.
- The session started by SDDM does not have `~/.local/bin` in `PATH`; scripts that need tools from there add it themselves.
