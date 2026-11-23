# browser-theme

A small Chromium extension that makes web pages follow the dwl theme. It styles nothing by itself: it puts the colours of the active theme on every page as CSS variables, and userstyles (Stylus) use them.

## How it works

1. `dwl-theme apply` copies this extension to `~/.config/dwl-theme/browser/` and writes `theme.json` next to it.
2. The extension reads `theme.json` and sets the variables on `<html>` of every page.
3. An extension cannot watch a file, so the visible tab asks for a re-read every 3 seconds. Open tabs follow a theme change within that time, without a reload.

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

These are the same colours Obsidian and Vesktop get (`app_palette` in `bin/dwl-theme`).

## Writing a userstyle

Hang every rule on `:root[data-dwl-theme]`, so the site is untouched when the extension is off:

```css
:root[data-dwl-theme] body {
  background: var(--dwl-bg);
  color: var(--dwl-fg);
}
```

`examples/hackernews.user.css` is a complete one for Stylus.
To add it: Stylus → Manage → Write new style, then paste the whole file into the editor and save. Stylus reads the `@-moz-document` block and fills in the domain itself; the empty `example.com` section it leaves behind can be deleted.

## Limits

- Every site still needs its own userstyle; this only makes the colours live.
- The browser's own UI (tabs, address bar) is not themed.
- The variables are readable by the page's scripts, so a site could tell which theme is active.
- The variables arrive a moment after the page starts loading; a styled page can flash its own colours first.
