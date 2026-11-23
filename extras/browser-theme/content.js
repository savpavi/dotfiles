// Sets the theme on <html>: --dwl-* custom properties plus data-dwl-theme (theme id)
// and data-dwl-scheme (dark | light). It styles nothing by itself; userstyles do.
const root = document.documentElement;
let names = [];

function apply(theme) {
  if (!theme || !theme.vars) return;
  for (const n of names) if (!(n in theme.vars)) root.style.removeProperty(n);
  names = Object.keys(theme.vars);
  for (const n of names) root.style.setProperty(n, theme.vars[n]);
  root.dataset.dwlTheme = theme.id;
  root.dataset.dwlScheme = theme.scheme;
}

chrome.storage.local.get("theme").then(({ theme }) => apply(theme));
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.theme) apply(changes.theme.newValue);
});

// Only the top frame of a visible tab asks the background to re-read theme.json.
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
