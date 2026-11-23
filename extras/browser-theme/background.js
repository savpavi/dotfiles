// dwl-theme writes theme.json (colours) and styles.json (the site styles) next to this
// file. An extension cannot watch a file, so the visible tab asks for a check every few
// seconds; the result goes to storage, and storage.onChanged carries it to every open tab.
async function syncFile(file, rawKey, key) {
  try {
    const res = await fetch(chrome.runtime.getURL(file), { cache: "no-store" });
    const raw = await res.text();
    const old = await chrome.storage.local.get(rawKey);
    if (raw !== old[rawKey]) await chrome.storage.local.set({ [rawKey]: raw, [key]: JSON.parse(raw) });
  } catch (e) {
    // missing or half-written: keep the last good copy
  }
}

function sync() {
  syncFile("theme.json", "raw", "theme");
  syncFile("styles.json", "rawStyles", "styles");
}

chrome.runtime.onInstalled.addListener(sync);
chrome.runtime.onStartup.addListener(sync);
chrome.runtime.onMessage.addListener((msg) => {
  if (msg === "sync") sync();
});
