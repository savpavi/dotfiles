# browser-theme

A small Chromium extension that makes web pages follow the dwl theme. It puts the colours of the active theme on every page as CSS variables and applies the site styles in `styles/`, which use those variables. Stylus is not needed; the same variables are there for it if you prefer to write styles in Stylus.

## How it works

1. `dwl-theme apply` copies this extension to `~/.config/dwl-theme/browser/` and writes `theme.json` (the colours) and `styles.json` (the site styles, built from `styles/*.user.css`) next to it.
2. The extension reads both, sets the variables on `<html>` of every page and applies the style whose domain matches the page.
3. An extension cannot watch a file, so the visible tab asks for a re-read every 3 seconds. Open tabs follow a theme change, or an edited style, within that time, without a reload.

## Install

Apply any theme once so the folder exists, then in `brave://extensions` (or `chrome://extensions`) turn on Developer mode and choose Load unpacked → `~/.config/dwl-theme/browser`.

After a change to the extension's own files, apply a theme and press the reload button of the extension on that page.

## What a page gets

On `<html>`:

- `data-dwl-theme`: theme id, for example `kor`
- `data-dwl-scheme`: `dark` or `light`
- `--dwl-bg`, `--dwl-bg2`, `--dwl-bg3`, `--dwl-raised`, `--dwl-hover`, `--dwl-border`
- `--dwl-fg`, `--dwl-muted`, `--dwl-faint`
- `--dwl-accent`, `--dwl-on-accent`, `--dwl-accent2`, `--dwl-urgent`, `--dwl-sel`
- `--dwl-red`, `--dwl-green`, `--dwl-yellow`, `--dwl-blue`, `--dwl-magenta`, `--dwl-cyan`
- every colour again as components, for sites that build colours from parts: `--dwl-bg-rgb` (`18, 39, 56`), `--dwl-bg-channels` (`18 39 56`) and `--dwl-bg-hsl` (`207 51% 15%`)

These are the same colours Obsidian and Vesktop get (`app_palette` in `bin/dwl-theme`).

## Writing a style

A style is a `styles/<site>.user.css` file with one or more `@-moz-document domain("...") { ... }` blocks. Hang every rule on `:root[data-dwl-theme]`, so the site is untouched when the extension is off:

```css
:root[data-dwl-theme] body {
  background: var(--dwl-bg);
  color: var(--dwl-fg);
}
```

## Styles

`styles/` holds the userstyles written so far:

| File | Site | How it works |
| --- | --- | --- |
| `hackernews.user.css` | news.ycombinator.com | paints the elements directly |
| `github.user.css` | github.com | points Primer's `--bgColor-*`, `--fgColor-*`, `--borderColor-*` variables at the theme |
| `youtube.user.css` | youtube.com | points YouTube's colour variables at the theme; the video player keeps its own colours |
| `reddit.user.css` | reddit.com | points Reddit's `--color-*` variables at the theme |
| `eksisozluk.user.css` | eksisozluk.com | paints the elements directly |
| `claude.user.css` | claude.ai | points the `--cds-*` variables and the older HSL-component ones at the theme |
| `whatsapp.user.css` | web.whatsapp.com | points the `--WDS-*` design tokens at the theme |
| `google-calendar.user.css` | calendar.google.com | points the Material 3 `--gm3-sys-color-*` tokens at the theme; event colours stay |
| `instagram.user.css` | instagram.com | points the `--ig-*` variables (bare `r, g, b`) at the theme's `-rgb` variables |
| `facebook.user.css` | facebook.com | points Facebook's named variables (`--surface-background`, `--primary-text`, ...) at the theme |
| `hashtagbasketball.user.css` | hashtagbasketball.com | paints the surfaces directly; the green/red stat cells stay |
| `basketballmonster.user.css` | basketballmonster.com | points the site's `--color-*` variables at the theme; tier and heat colours stay |
| `yahoo-fantasy.user.css` | fantasysports.yahoo.com | paints the old fixed-colour layout directly, plus the few `--ys-colors-*` variables |
| `tailscale.user.css` | tailscale.com | points the console's named variables and its grey ramp (bare `r g b`) at the theme; dark mode only |
| `cloudflare.user.css` | dash.cloudflare.com | points the `--color-kumo-*` and `--text-color-kumo-*` tokens at the theme |

YouTube names most of its variables with build-generated hashes. `tools/youtube-tokens.js` regenerates that part of the style: run it in the DevTools console on youtube.com and replace the block between the "generated" markers.

The extension applies these itself. To use them in Stylus instead, import `~/.config/dwl-theme/stylus-import.json` (Stylus → Manage → Import), which `dwl-theme apply` rebuilds from `styles/` every time. Do not run both: the Stylus copies go stale when a style changes here.

## Limits

- Some sites set their variables from long selectors or on `<body>`; a style for such a site needs `!important` on its variable overrides (see `claude.user.css`).
- Dark Reader recolours pages on top of these styles. Turn it off for a site that has a style here.
- A style that follows a site's variables covers the main surfaces; a corner the site paints with a fixed colour keeps it until a rule is added.
- Every site still needs its own userstyle; this only makes the colours live.
- The browser's own UI (tabs, address bar) is not themed.
- The variables are readable by the page's scripts, so a site could tell which theme is active.
- The variables arrive a moment after the page starts loading; a styled page can flash its own colours first.
