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

## Styles

`styles/` holds the userstyles written so far:

| File | Site | How it works |
| --- | --- | --- |
| `hackernews.user.css` | news.ycombinator.com | paints the elements directly |
| `github.user.css` | github.com | points Primer's `--bgColor-*`, `--fgColor-*`, `--borderColor-*` variables at the theme |
| `youtube.user.css` | youtube.com | points YouTube's colour variables at the theme; the video player keeps its own colours |
| `reddit.user.css` | reddit.com | points Reddit's `--color-*` variables at the theme |
| `eksisozluk.user.css` | eksisozluk.com | paints the elements directly |

YouTube names most of its variables with build-generated hashes. `tools/youtube-tokens.js` regenerates that part of the style: run it in the DevTools console on youtube.com and replace the block between the "generated" markers.

To add them all at once: Stylus → Manage → Import (in the Backup section) and pick `~/.config/dwl-theme/stylus-import.json`. `dwl-theme apply` rebuilds that file from `styles/` every time, so after a style changes here, apply a theme and import again.

To add a single one by hand: Stylus → Manage → Write new style, then paste the whole file into the editor and save. Stylus reads the `@-moz-document` block and fills in the domain itself; the empty `example.com` section it leaves behind can be deleted.

## Limits

- Dark Reader recolours pages on top of these styles. Turn it off for a site that has a style here.
- A style that follows a site's variables covers the main surfaces; a corner the site paints with a fixed colour keeps it until a rule is added.
- Every site still needs its own userstyle; this only makes the colours live.
- The browser's own UI (tabs, address bar) is not themed.
- The variables are readable by the page's scripts, so a site could tell which theme is active.
- The variables arrive a moment after the page starts loading; a styled page can flash its own colours first.
