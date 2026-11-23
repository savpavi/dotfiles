// dwl-theme writes theme.json next to this file. An extension cannot watch a file,
// so the visible tab asks for a check every few seconds; the result goes to
// storage, and storage.onChanged carries it to every open tab at once.
async function sync() {
  try {
    const res = await fetch(chrome.runtime.getURL("theme.json"), { cache: "no-store" });
    const raw = await res.text();
    const old = await chrome.storage.local.get("raw");
    if (raw !== old.raw) await chrome.storage.local.set({ raw, theme: JSON.parse(raw) });
  } catch (e) {
    // theme.json missing or half-written: keep the last good theme
  }
}

chrome.runtime.onInstalled.addListener(sync);
chrome.runtime.onStartup.addListener(sync);
chrome.runtime.onMessage.addListener((msg) => {
  if (msg === "sync") sync();
});
