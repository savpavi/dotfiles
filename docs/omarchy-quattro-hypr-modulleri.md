# Omarchy quattro (v4) — Hyprland Lua modülleri

Karar vermek için çıkarıldı. Kaynak: `basecamp/omarchy`, `quattro` dalı, `default/hypr/`.
Senin `~/.config/hypr/hyprland.lua` ile **aynı format** (Hyprland Lua config, `hl.*` API'si).

Her modülün başında **taşınabilirlik notu** var:

- **TEMİZ** — sadece `hl.*` çağırıyor, doğrudan kopyalanabilir
- **KARIŞIK** — bir kısmı temiz, bir kısmı `omarchy-*` script'i çağırıyor
- **BAĞIMLI** — omarchy altyapısı olmadan çalışmaz

---

## `looknfeel.lua` — KARIŞIK (125 satır)

> omarchy bağımlılıkları: `omarchy-restart-shell `

```lua
-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

local active_border_color = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }
local inactive_border_color = "rgba(595959aa)"

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,

    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },

    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 0,

    shadow = {
      enabled = false,
    },

    blur = {
      enabled = false,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },

    groupbar = {
      font_size = 12,
      font_family = "monospace",
      font_weight_active = "ultraheavy",
      font_weight_inactive = "normal",
      indicator_height = 1,
      indicator_gap = 5,
      height = 22,
      gaps_in = 5,
      gaps_out = 0,
      text_color = "rgb(ffffff)",
      text_color_inactive = "rgba(ffffff90)",
      col = {
        active = "rgba(00000040)",
        inactive = "rgba(00000020)",
      },
      gradients = true,
      gradient_rounding = 0,
      gradient_round_only_edges = false,
    },
  },

  animations = {
    enabled = true,
  },
})

-- Default animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = false })

hl.config({
  dwindle = {
    preserve_split = true,
    force_split = 2,
  },

  scrolling = {
    column_width = 0.49,
  },

  master = {
    new_status = "master",
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    disable_scale_notification = true,
    focus_on_activate = true,
    anr_missed_pings = 3,
    on_focus_under_fullscreen = 1,
    initial_workspace_tracking = 0,
    -- Let a fresh shell re-acquire the session lock after the lock client
    -- died, so omarchy-restart-shell can recover the LOCK failsafe.
    allow_session_lock_restore = true,
  },

  cursor = {
    hide_on_key_press = true,
    warp_on_change_workspace = 1,
  },

  binds = {
    hide_special_on_workspace_change = true,
  },
})
```

## `input.lua` — KARIŞIK (79 satır)

> omarchy bağımlılıkları: `omarchy `

```lua
-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

local function read_vconsole()
  local values = {}
  local file = io.open("/etc/vconsole.conf", "r")
  if not file then
    return values
  end

  for line in file:lines() do
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if key and value then
      value = value:gsub("%s+#.*$", "")
      value = value:gsub('^"(.*)"$', "%1")
      value = value:gsub("^'(.*)'$", "%1")
      values[key] = value
    end
  end

  file:close()
  return values
end

-- Layouts that can't type Latin letters. Keep in sync with the list in
-- etc/mkinitcpio.conf.d/omarchy_hooks.conf.
local non_latin_layouts =
  " af am ara bd bg by et ge gr il in iq ir kg kh kz la lk mk mm mn mv np rs ru sy th tj ua "

local vconsole = read_vconsole()

local kb_layout = vconsole.XKBLAYOUT or "us"
local kb_variant = vconsole.XKBVARIANT or ""
-- CapsLock is the compose key, so Caps Lock itself has to live somewhere else.
-- Both Shifts together is the usual home for it, but it's easy to hit by
-- accident while typing. The _cancel variant sets Caps Lock the same way and
-- releases it on the next lone Shift, so a misfire clears itself.
local kb_options = "compose:caps,shift:both_capslock_cancel"

-- Hyprland resolves keybindings against the first entry in kb_layout, not the
-- layout that's currently active, so Omarchy's Latin-keysym bindings (SUPER + W
-- and friends) only fire when a Latin layout leads. Installing with a non-Latin
-- one would otherwise leave the desktop unusable.
if non_latin_layouts:find(" " .. kb_layout:match("^[^,]*") .. " ", 1, true) then
  kb_layout = "us," .. kb_layout
  kb_variant = "," .. kb_variant
  -- Reach the original layout with Left Alt + Right Alt.
  kb_options = kb_options .. ",grp:alts_toggle"
end

hl.config({
  input = {
    kb_layout = kb_layout,
    kb_variant = kb_variant,
    kb_model = "",
    kb_options = kb_options,
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,

    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    touchpad = {
      natural_scroll = false,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },

  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

-- Scroll nicely in the terminal.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })
```

## `windows.lua` — TEMİZ (25 satır)

```lua
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

o.window(".*", { suppress_event = "maximize" })

-- Tag all windows for default opacity (apps can override with -default-opacity tag).
o.window(".*", { tag = "+default-opacity" })

-- Fix some dragging issues with XWayland.
o.window(
  {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  { no_focus = true }
)

-- App-specific tweaks (may remove default-opacity tag).
require("default.hypr.apps")

-- Apply default opacity after apps have had a chance to opt out.
o.window({ tag = "default-opacity" }, { opacity = "0.985 0.96" })
```

## `envs.lua` — KARIŞIK (49 satır)

> omarchy bağımlılıkları: `omarchy `

```lua
local paths = require("default.hypr.paths")
local require_optional = require("default.hypr.require_optional")

-- GUM environment variables for styling purposes.
require_optional.module("omarchy.current.theme.gum_env")

-- Cursor size.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Force all apps to use Wayland.
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Allow better support for screen sharing (Google Meet, Discord, etc).
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Use XCompose file.
hl.env("XCOMPOSEFILE", paths.home .. "/.XCompose")

-- hyprctl setenv doesn't reach keybind dispatcher env; use hl.env.
hl.env("OMARCHY_PATH", paths.omarchy_path)

local bin_dir = paths.omarchy_path .. "/bin"
local kept = {}
for entry in (os.getenv("PATH") or "/usr/local/bin:/usr/bin"):gmatch("[^:]+") do
  if entry ~= bin_dir then table.insert(kept, entry) end
end
table.insert(kept, 1, bin_dir)
hl.env("PATH", table.concat(kept, ":"))

-- Hardware-specific environment.
require("default.hypr.nvidia")

hl.config({
  xwayland = {
    force_zero_scaling = true,
  },

  ecosystem = {
    no_update_news = true,
  },
})
```

## `autostart.lua` — KARIŞIK (14 satır)

> omarchy bağımlılıkları: `omarchy-hook omarchy-hyprland-monitor-watch omarchy-launch-shell omarchy-powerprofiles-init omarchy-provision-first-run `

```lua
hl.on("hyprland.start", function()
  -- Slow app launch fix -- set systemd vars before starting session services.
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  hl.exec_cmd("omarchy-launch-shell")
  hl.exec_cmd("omarchy-provision-first-run")
  hl.exec_cmd("omarchy-powerprofiles-init")
  hl.exec_cmd(o.launch("omarchy-hyprland-monitor-watch"))
  hl.exec_cmd(o.launch("udiskie --automount --no-notify --no-tray"))

  -- Run post-boot hooks after startup config has loaded.
  hl.exec_cmd("sleep 2 && omarchy-hook post-boot")
end)
```

---

# Keybinding modülleri

## `bindings/applications.lua` — BAĞIMLI (34 satır, 12 satırda omarchy çağrısı)

> omarchy bağımlılıkları: `omarchy `

```lua
-- Essential application bindings.
o.bind("SUPER + RETURN", "Terminal", { omarchy = "terminal" })
o.bind("SUPER + SHIFT + RETURN", "Browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + F", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { omarchy = "nautilus-cwd" })
o.bind("SUPER + SHIFT + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", { omarchy = "browser --private" })
o.bind("SUPER + SHIFT + N", "Editor", { omarchy = "editor" })

if o.preinstalled_bindings_enabled() then
  -- Bindings for preinstalled Omarchy applications, TUIs, and web apps.
  o.bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })
  o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
  o.bind("SUPER + SHIFT + M", "Music", { omarchy = "spotify" })
  o.bind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })
  o.bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
  o.bind("SUPER + SHIFT + G", "Signal", { omarchy = "signal" })
  o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
  o.bind("SUPER + SHIFT + W", "Omawrite", { launch = "omawrite" })
  o.bind("SUPER + SHIFT + SLASH", "Passwords", { omarchy = "1password" })

  o.bind("SUPER + SHIFT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
  o.bind("SUPER + SHIFT + ALT + A", "Grok", { webapp = "https://grok.com" })
  o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })
  o.bind("SUPER + SHIFT + E", "Email", { webapp = "https://app.hey.com" })
  o.bind("SUPER + SHIFT + ALT + E", "New email", { webapp = "https://app.hey.com/messages/new?display=standalone&new_window=true" })
  o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
  o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
  o.bind( "SUPER + SHIFT + CTRL + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
  o.bind("SUPER + SHIFT + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
  o.bind("SUPER + SHIFT + S", "Google Maps", { webapp = "https://maps.google.com/", focus = true })
  o.bind("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })
  o.bind("SUPER + SHIFT + ALT + X", "X Post", { webapp = "https://x.com/compose/post" })
end
```

## `bindings/tiling.lua` — KARIŞIK (97 satır, 8 satırda omarchy çağrısı)

> omarchy bağımlılıkları: `omarchy-hyprland-monitor-scaling omarchy-hyprland-window-close-all omarchy-hyprland-window-pop omarchy-hyprland-window-tiled-fullscreen-toggle omarchy-hyprland-window-width omarchy-hyprland-workspace-layout-toggle `

```lua
o.bind("SUPER + W", "Close window", hl.dsp.window.close())
o.bind("CTRL + ALT + DELETE", "Close all windows", "omarchy-hyprland-window-close-all")

o.bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())
o.bind("SUPER + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
o.bind("SUPER + CTRL + F", "Tiled full screen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
o.bind("SUPER + ALT + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + O", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")
o.bind("SUPER + ALT + Home", "Save window width", "omarchy-hyprland-window-width save")
o.bind("SUPER + Home", "Restore window width", "omarchy-hyprland-window-width restore")
o.bind("SUPER + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

o.bind("SUPER + LEFT", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + UP", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + DOWN", "Focus on below window", hl.dsp.focus({ direction = "d" }))

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end

o.bind("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
o.bind("SUPER + grave", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + grave", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

o.bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))

o.bind("SUPER + SHIFT + ALT + LEFT", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + ALT + RIGHT", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
o.bind("SUPER + SHIFT + ALT + UP", "Move workspace to up monitor", hl.dsp.workspace.move({ monitor = "u" }))
o.bind("SUPER + SHIFT + ALT + DOWN", "Move workspace to down monitor", hl.dsp.workspace.move({ monitor = "d" }))

o.bind("SUPER + SHIFT + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + SHIFT + UP", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + DOWN", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

o.bind("ALT + TAB", "Focus on next window", hl.dsp.window.cycle_next())
o.bind("ALT + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))
o.bind("ALT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())
o.bind("ALT + SHIFT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())

o.bind("CTRL + ALT + TAB", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))
o.bind("CTRL + ALT + SHIFT + TAB", "Focus on previous monitor", hl.dsp.focus({ monitor = "-1" }))

o.bind("SUPER + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("SUPER + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
o.bind("SUPER + SHIFT + code:20", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("SUPER + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

o.bind("SUPER + ALT + code:20", "Expand window left a little", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
o.bind("SUPER + ALT + code:21", "Shrink window left a little", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
o.bind("SUPER + SHIFT + ALT + code:20", "Shrink window up a little", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
o.bind("SUPER + SHIFT + ALT + code:21", "Expand window down a little", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))

o.bind("SUPER + CTRL + code:20", "Expand window left a lot", hl.dsp.window.resize({ x = -300, y = 0, relative = true }))
o.bind("SUPER + CTRL + code:21", "Shrink window left a lot", hl.dsp.window.resize({ x = 300, y = 0, relative = true }))
o.bind("SUPER + CTRL + SHIFT + code:20", "Shrink window up a lot", hl.dsp.window.resize({ x = 0, y = -300, relative = true }))
o.bind("SUPER + CTRL + SHIFT + code:21", "Expand window down a lot", hl.dsp.window.resize({ x = 0, y = 300, relative = true }))

o.bind("SUPER + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "e-1" }))

o.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
o.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

o.bind("SUPER + G", "Toggle window grouping", hl.dsp.group.toggle())
o.bind("SUPER + ALT + G", "Move active window out of group", hl.dsp.window.move({ out_of_group = true }))

o.bind("SUPER + ALT + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
o.bind("SUPER + ALT + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
o.bind("SUPER + ALT + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
o.bind("SUPER + ALT + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))

o.bind("SUPER + ALT + TAB", "Next window in group", hl.dsp.group.next())
o.bind("SUPER + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())

o.bind("SUPER + CTRL + LEFT", "Move grouped window focus left", hl.dsp.group.prev())
o.bind("SUPER + CTRL + RIGHT", "Move grouped window focus right", hl.dsp.group.next())

o.bind("SUPER + ALT + mouse_down", "Next window in group", hl.dsp.group.next())
o.bind("SUPER + ALT + mouse_up", "Previous window in group", hl.dsp.group.prev())

for index = 1, 5 do
  o.bind("SUPER + ALT + code:" .. tostring(index + 9), "Switch to group window " .. index, hl.dsp.group.active({ index = index }))
end

o.bind("SUPER + SLASH", "Monitor scaling up", "omarchy-hyprland-monitor-scaling up")
o.bind("SUPER + ALT + SLASH", "Monitor scaling down", "omarchy-hyprland-monitor-scaling down")
```

## `bindings/media.lua` — BAĞIMLI (34 satır, 26 satırda omarchy çağrısı)

> omarchy bağımlılıkları: `omarchy-audio-input-mute omarchy-audio-output-switch omarchy-audio-output-volume omarchy-audio-source-switch omarchy-brightness-display omarchy-brightness-keyboard omarchy-shell omarchy-toggle-touchpad `

```lua
-- Volume, brightness, keyboard backlight, and touchpad controls.
o.bind("XF86AudioRaiseVolume", "Volume up", "omarchy-audio-output-volume raise", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "omarchy-audio-output-volume lower", { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", "omarchy-audio-output-volume mute-toggle", { locked = true })
o.bind("XF86AudioMicMute", "Mute microphone", "omarchy-audio-input-mute", { locked = true })
o.bind("XF86MonBrightnessUp", "Brightness up", "omarchy-brightness-display +5%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", "omarchy-brightness-display 5%-", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", "omarchy-brightness-display 100%", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", "omarchy-brightness-display 1%", { locked = true, repeating = true })
o.bind("XF86KbdBrightnessUp", "Keyboard brightness up", "omarchy-brightness-keyboard up", { locked = true, repeating = true })
o.bind("XF86KbdBrightnessDown", "Keyboard brightness down", "omarchy-brightness-keyboard down", { locked = true, repeating = true })
o.bind("XF86KbdLightOnOff", "Keyboard backlight cycle", "omarchy-brightness-keyboard cycle", { locked = true })
o.bind_toggle("XF86TouchpadToggle", "Toggle touchpad", "touchpad", { locked = true })
o.bind("XF86TouchpadOn", "Enable touchpad", "omarchy-toggle-touchpad on", { locked = true })
o.bind("XF86TouchpadOff", "Disable touchpad", "omarchy-toggle-touchpad off", { locked = true })

-- Precise volume and brightness controls.
o.bind("ALT + XF86AudioRaiseVolume", "Volume up precise", "omarchy-audio-output-volume +1", { locked = true, repeating = true })
o.bind("ALT + XF86AudioLowerVolume", "Volume down precise", "omarchy-audio-output-volume -1", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", "omarchy-brightness-display +1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", "omarchy-brightness-display 1%-", { locked = true, repeating = true })

-- Media controls.
o.bind("XF86AudioNext", "Next track", "omarchy-shell media next", { locked = true })
o.bind("ALT + XF86AudioPlay", "Next track", "omarchy-shell media next", { locked = true })
o.bind("XF86AudioPause", "Pause", "omarchy-shell media playPause", { locked = true })
o.bind("XF86AudioPlay", "Play", "omarchy-shell media playPause", { locked = true })
o.bind("XF86AudioPrev", "Previous track", "omarchy-shell media previous", { locked = true })
o.bind("ALT + SHIFT + XF86AudioPlay", "Previous track", "omarchy-shell media previous", { locked = true })
o.bind("XF86Eject", "Eject media", "eject", { locked = true })

o.bind("SHIFT + XF86AudioMute", "Switch audio output", "omarchy-audio-output-switch", { locked = true })
o.bind("SHIFT + XF86AudioPause", "Switch media source", "omarchy-audio-source-switch", { locked = true })
o.bind("SHIFT + XF86AudioPlay", "Switch media source", "omarchy-audio-source-switch", { locked = true })
```

## `bindings/clipboard.lua` — KARIŞIK (48 satır, 1 satırda omarchy çağrısı)

> omarchy bağımlılıkları: `omarchy omarchy-shell `

```lua
-- Send with explicit mods to the focused surface by omitting the window target,
-- so universal clipboard shortcuts reach both normal windows and focused
-- layer-shell surfaces such as Omarchy panels. A virtual keyboard (wtype) won't
-- do: the physically held SUPER merges into the injected chord at the seat.
-- The down/up split works around Hyprland send_shortcut sometimes leaving
-- synthetic key state stuck/repeating.
-- https://github.com/hyprwm/Hyprland/discussions/14099
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- Lean on the terminal tag from default/hypr/apps/terminals.lua so there's one
-- definition of what counts as a terminal. Dynamic tags carry a trailing "*".
local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
  return function()
    if active_window_is_terminal() then
      send_shortcut_once(terminal_mods, terminal_key)()
    else
      send_shortcut_once(default_mods, default_key)()
    end
  end
end

o.bind("SUPER + C", "Universal copy", universal_clipboard_shortcut("CTRL", "C", "CTRL", "Insert"))
o.bind("SUPER + V", "Universal paste", universal_clipboard_shortcut("CTRL", "V", "SHIFT", "Insert"))
o.bind("SUPER + X", "Universal cut", send_shortcut_once("CTRL", "X"))
o.bind("SUPER + CTRL + V", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")
```

## `bindings/utilities.lua` — BAĞIMLI (126 satır, 53 satırda omarchy çağrısı)

> omarchy bağımlılıkları: `omarchy omarchy-agent omarchy-capture-region omarchy-capture-screenrecording omarchy-capture-screenshot omarchy-capture-text omarchy-capture-webcam-resize omarchy-hyprland-monitor-clamshell omarchy-hyprland-monitor-internal omarchy-hyprland-monitor-internal-mirror omarchy-hyprland-window-gaps-toggle omarchy-hyprland-window-single-square-aspect-toggle omarchy-hyprland-window-transparency-toggle omarchy-menu omarchy-menu-herdr-keybindings omarchy-menu-keybindings omarchy-menu-tmux-keybindings omarchy-notification-battery omarchy-notification-time omarchy-notification-weather omarchy-reminder omarchy-shell omarchy-system-lid-close omarchy-system-lock omarchy-transcode `

```lua
o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle")
o.bind("SUPER + ALT + SPACE", "Apps menu", "omarchy-menu toggle apps")
o.bind("SUPER + CTRL + E", "Emojis", "omarchy-shell shell toggle omarchy.emojis")
o.bind("SUPER + CTRL + C", "Capture menu", "omarchy-menu toggle capture")
o.bind("SUPER + CTRL + O", "Toggle menu", "omarchy-menu toggle toggle")
o.bind("SUPER + CTRL + H", "Hardware menu", "omarchy-menu toggle hardware")
o.bind("SUPER + SHIFT + code:201", "Omarchy menu", "omarchy-menu toggle root")
o.bind("SUPER + ESCAPE", "System menu", "omarchy-menu toggle system")
o.bind("XF86PowerOff", "Power menu", "omarchy-menu toggle system", { locked = true })
o.bind("SUPER + K", "Keybindings", "omarchy-menu-keybindings")
o.bind("SUPER + ALT + K", "Tmux keybindings", "omarchy-menu-tmux-keybindings")
o.bind("SUPER + CTRL + K", "Herdr keybindings", "omarchy-menu-herdr-keybindings")
o.bind("SUPER + CTRL + Q", "Calculator", "omacalc")
o.bind("XF86Calculator", "Calculator", "omacalc")

o.bind_toggle("SUPER + SHIFT + SPACE", "Toggle top bar", "bar")
o.bind("SUPER + CTRL + SPACE", "Background switcher", "omarchy-menu toggle background")
o.bind("SUPER + SHIFT + CTRL + SPACE", "Theme menu", "omarchy-menu toggle theme")
o.bind("SUPER + BACKSPACE", "Toggle window transparency", "omarchy-hyprland-window-transparency-toggle")
o.bind("SUPER + SHIFT + BACKSPACE", "Toggle window gaps", "omarchy-hyprland-window-gaps-toggle")
o.bind("SUPER + CTRL + BACKSPACE", "Toggle single-window square aspect", "omarchy-hyprland-window-single-square-aspect-toggle")

-- xkbcommon names the comma keysym "comma"; the upper-case "COMMA" does not match.
o.bind("SUPER + comma", "Dismiss last notification", "omarchy-shell notifications dismissOne")
o.bind("SUPER + SHIFT + comma", "Dismiss all notifications", "omarchy-shell notifications dismissAll")
o.bind_toggle("SUPER + CTRL + comma", "Toggle silencing notifications", "notification-silencing")
o.bind("SUPER + ALT + comma", "Invoke last notification", "omarchy-shell notifications invokeLast")
o.bind("SUPER + SHIFT + ALT + comma", "Open notification history", "omarchy-shell notifications showHistory")

o.bind_toggle("SUPER + CTRL + I", "Toggle locking on idle", "idle")
o.bind_toggle("SUPER + CTRL + N", "Toggle nightlight", "nightlight")
o.bind("SUPER + CTRL + Delete", "Toggle laptop display", "omarchy-hyprland-monitor-internal toggle")
o.bind("SUPER + CTRL + ALT + Delete", "Toggle laptop display mirroring", "omarchy-hyprland-monitor-internal-mirror toggle")
o.bind("switch:on:Lid Switch", nil, "omarchy-system-lid-close", { locked = true })
o.bind("switch:off:Lid Switch", nil, "omarchy-hyprland-monitor-clamshell", { locked = true })

o.bind("PRINT", "Screenshot", "omarchy-capture-screenshot")
o.bind("ALT + PRINT", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + ALT + code:34", "Make webcam overlay smaller", "omarchy-capture-webcam-resize smaller")
o.bind("SUPER + ALT + code:35", "Make webcam overlay larger", "omarchy-capture-webcam-resize larger")
o.bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind("SUPER + CTRL + PRINT", "Extract text (OCR) from screenshot", "omarchy-capture-text")

-- Keyboard control for the slurp region picker (see omarchy-capture-region).
-- The binds live exactly as long as a selection layer is on screen (slurp
-- opens one per monitor), so they cannot leak or get stuck.
-- Unbinding by key would take a same-key binding out of the user's own config
-- with it, so each handle is kept and removed individually.
local selection_layers = 0
local selection_binds = {}

hl.on("layer.opened", function(layer)
  if layer.namespace == "selection" then
    selection_layers = selection_layers + 1
    if selection_layers == 1 then
      selection_binds = {
        hl.bind("RETURN", hl.dsp.exec_cmd("omarchy-capture-region --take-window"), { description = "Capture highlighted window" }),
        hl.bind("CTRL + RETURN", hl.dsp.exec_cmd("omarchy-capture-region --take-fullscreen"), { description = "Capture entire screen" }),
        hl.bind("TAB", hl.dsp.exec_cmd("omarchy-capture-region --select-window next"), { description = "Select next window to capture" }),
        hl.bind("CTRL + TAB", hl.dsp.exec_cmd("omarchy-capture-region --select-window prev"), { description = "Select previous window to capture" }),
      }
      for _, direction in ipairs({ "left", "right", "up", "down" }) do
        table.insert(
          selection_binds,
          hl.bind(direction:upper(), hl.dsp.exec_cmd("omarchy-capture-region --select-window " .. direction), { description = "Select window to capture" })
        )
      end
    end
  end
end)

hl.on("layer.closed", function(layer)
  if layer.namespace == "selection" and selection_layers > 0 then
    selection_layers = selection_layers - 1
    if selection_layers == 0 then
      for _, keybind in ipairs(selection_binds) do
        keybind:unbind()
      end
      selection_binds = {}
    end
  end
end)

o.bind("SUPER + CTRL + S", "Share", "omarchy-menu toggle share")

o.bind("SUPER + CTRL + PERIOD", "Transcode", "omarchy-transcode")

o.bind("SUPER + CTRL + R", "Set reminder", "omarchy-menu toggle reminder-set")
o.bind("SUPER + CTRL + ALT + R", "Show reminders", "omarchy-reminder show")
o.bind("SUPER + SHIFT + CTRL + R", "Clear reminders", "omarchy-reminder clear")

o.bind("SUPER + CTRL + ALT + T", "Show time", "omarchy-notification-time")
o.bind("SUPER + CTRL + ALT + B", "Show battery remaining", "omarchy-notification-battery")
o.bind("SUPER + CTRL + ALT + W", "Toggle weather", "omarchy-notification-weather")

o.bind("SUPER + SHIFT + CTRL + A", "Agent", "omarchy-agent --pick")
o.bind("SUPER + CTRL + A", "Audio", "omarchy-shell shell toggle omarchy.audio")
o.bind("SUPER + CTRL + B", "Bluetooth", "omarchy-shell shell toggle omarchy.bluetooth")
o.bind("SUPER + CTRL + D", "Display", "omarchy-shell shell toggle omarchy.monitor")
o.bind("SUPER + CTRL + ALT + D", "Calendar", "omarchy-shell shell toggle omarchy.clock")
o.bind("SUPER + CTRL + W", "Network", "omarchy-shell shell toggle omarchy.network")
o.bind("SUPER + CTRL + P", "Power", "omarchy-shell shell toggle omarchy.power")
o.bind("SUPER + CTRL + T", "Activity", { tui = "btop" })

-- The letters above name a panel; the numbers count them. 1 is the leftmost
-- panel in the bar's right section, and a widget with no panel of its own (the
-- tray) is not counted, so the number matches the icon a user would point at.
-- A bar with fewer panels than this leaves the tail of the range doing nothing.
for panel = 1, 9 do
  o.bind(
    "SUPER + CTRL + code:" .. tostring(panel + 9),
    "Bar panel " .. panel,
    "omarchy-shell -q shell togglePanelAt right " .. panel
  )
end

o.bind("SUPER + CTRL + Z", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)

o.bind("SUPER + CTRL + ALT + Z", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)

o.bind("SUPER + CTRL + L", "Lock system", "omarchy-system-lock")
```

## `bindings/voxtype.lua` — TEMİZ (5 satır, 0 satırda omarchy çağrısı)

```lua
if o.cmd_present("voxtype") then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "voxtype record toggle")
  o.bind("F9", "Start dictation (push-to-talk)", "voxtype record start")
  o.bind("F9", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })
end
```

---

## `helpers.lua` — omarchy'nin `o.*` yardımcı API'si

Yukarıdaki modüllerdeki `o.bind(...)`, `o.app(...)` çağrıları buradan geliyor.
Bindings modüllerinden herhangi birini alacaksan bu da gerekir.

```lua
-- Shared helpers for Hyprland Lua configuration.

o = o or {}

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

o.shell_quote = shell_quote

local function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end

  return false
end

-- Hyprland reaps its own children, so os.execute() can't retrieve an exit status
-- from inside the compositor. Read a marker off stdout instead.
function o.shell_succeeds(command)
  -- Subshell, so the redirection covers every command rather than binding to
  -- the last one and letting an earlier one write its own OK into the pipe.
  local pipe = io.popen("( " .. command .. " ) >/dev/null 2>&1 && echo OK")
  if not pipe then
    return false
  end

  local output = pipe:read("*a") or ""
  pipe:close()

  return output:find("OK", 1, true) ~= nil
end

function o.cmd_present(command)
  if command:find("/", 1, true) then
    return file_exists(command)
  end

  local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
  for directory in (path .. ":"):gmatch("([^:]*):") do
    if file_exists((directory ~= "" and directory or ".") .. "/" .. command) then
      return true
    end
  end

  return false
end

function o.cmd_missing(command)
  return not o.cmd_present(command)
end

local function command_from(value, description)
  if type(value) ~= "table" then
    return value
  end

  if value.omarchy then
    return "omarchy-launch-" .. value.omarchy
  elseif value.focus and value.launch then
    return o.launch_sole(value.focus, value.launch)
  elseif value.launch then
    return o.launch(value.launch)
  elseif value.webapp then
    if value.focus then
      return o.launch_webapp_sole(description, value.webapp)
    else
      return o.launch_webapp(value.webapp)
    end
  elseif value.tui then
    if value.focus then
      return "omarchy-launch-or-focus-tui " .. shell_quote(value.tui)
    else
      return "omarchy-launch-tui " .. shell_quote(value.tui)
    end
  end

  return value
end

function o.preinstalled_bindings_enabled()
  if _G.omarchy_preinstalled_bindings ~= nil then
    return _G.omarchy_preinstalled_bindings == true
  end

  return not file_exists((os.getenv("HOME") or "") .. "/.local/state/omarchy/preinstalls-removed")
end

function o.bind(keys, description, dispatcher, options)
  local opts = options or {}

  if description then
    opts.description = description
  end

  dispatcher = command_from(dispatcher, description)

  if type(dispatcher) == "string" then
    dispatcher = hl.dsp.exec_cmd(dispatcher)
  end

  hl.bind(keys, dispatcher, opts)
end

function o.launch(command)
  return "uwsm-app -- " .. command
end

function o.exec_on_start(command)
  hl.on("hyprland.start", function()
    hl.exec_cmd(command)
  end)
end

function o.launch_on_start(command)
  o.exec_on_start(o.launch(command))
end

function o.launch_webapp(url)
  return "omarchy-launch-webapp " .. shell_quote(url)
end

function o.launch_webapp_sole(name, url)
  return "omarchy-launch-or-focus-webapp " .. shell_quote(name) .. " " .. shell_quote(url)
end

function o.launch_sole(match, command)
  return "omarchy-launch-or-focus " .. shell_quote(match) .. " " .. shell_quote(o.launch(command))
end

function o.bind_toggle(keys, description, toggle, options)
  o.bind(keys, description, "omarchy-toggle-" .. toggle, options)
end

function o.notify(message)
  return "notify-send -u low " .. shell_quote(message)
end

function o.window(match, rules)
  rules.match = rules.match or {}

  if type(match) == "string" then
    rules.match.class = match
  else
    for key, value in pairs(match) do
      rules.match[key] = value
    end
  end

  hl.window_rule(rules)
end
```
