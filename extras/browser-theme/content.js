// Sets the theme on <html>: --dwl-* custom properties plus data-dwl-theme (theme id)
// and data-dwl-scheme (dark | light), then applies the site style for this host, if
// styles/ has one. Without a site style the page only gets the variables.
const root = document.documentElement;
let names = [];

function applyTheme(theme) {
  if (!theme || !theme.vars) return;
  for (const n of names) if (!(n in theme.vars)) root.style.removeProperty(n);
  names = Object.keys(theme.vars);
  for (const n of names) root.style.setProperty(n, theme.vars[n]);
  root.dataset.dwlTheme = theme.id;
  root.dataset.dwlScheme = theme.scheme;
}

// A constructed stylesheet instead of a <style> element: the page's Content Security
// Policy cannot block it, and the page's own scripts do not find it in the DOM.
const sheet = new CSSStyleSheet();
let adopted = false;

function applyStyles(styles) {
  const host = location.hostname;
  const css = (styles || [])
    .filter((s) => s.domains.some((d) => host === d || host.endsWith("." + d)))
    .map((s) => s.code)
    .join("\n");
  sheet.replaceSync(css);
  if (css && !adopted) {
    document.adoptedStyleSheets = [...document.adoptedStyleSheets, sheet];
    adopted = true;
  }
}

chrome.storage.local.get(["theme", "styles"]).then(({ theme, styles }) => {
  applyTheme(theme);
  applyStyles(styles);
});
chrome.storage.onChanged.addListener((changes, area) => {
  if (area !== "local") return;
  if (changes.theme) applyTheme(changes.theme.newValue);
  if (changes.styles) applyStyles(changes.styles.newValue);
});

// Only the top frame of a visible tab asks the background to re-read the files.
if (window === window.top) {
  let timer = 0;
  const ask = () => {
    if (document.visibilityState !== "visible") return;
    try {
      chrome.runtime.sendMessage("sync").catch(() => {});
    } catch (e) {
      clearInterval(timer); // the extension was reloaded; this copy is orphaned
    }
  };
  ask();
  document.addEventListener("visibilitychange", ask);
  timer = setInterval(ask, 3000);
}
