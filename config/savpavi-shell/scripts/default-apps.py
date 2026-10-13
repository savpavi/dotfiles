#!/usr/bin/env python3
"""Default applications for the savpavi-shell settings window.

  list               JSON: [{id, name, icon, current, apps: [{id, name, icon}]}]
  set CATEGORY APP   make APP (desktop id, e.g. org.gnome.Loupe.desktop) the default
                     for every MIME type of CATEGORY (xdg-mime; browser also via xdg-settings)
"""
import configparser, json, os, subprocess as sp, sys
from pathlib import Path

CATEGORIES = [
    ("browser", "Web tarayıcı", "public", ["x-scheme-handler/http", "x-scheme-handler/https", "text/html"]),
    ("files", "Dosya yöneticisi", "folder", ["inode/directory"]),
    ("terminal", "Terminal", "terminal", ["x-scheme-handler/terminal"]),
    ("mail", "E-posta", "mail", ["x-scheme-handler/mailto"]),
    ("image", "Görseller", "image", ["image/png", "image/jpeg", "image/webp", "image/gif", "image/avif"]),
    ("video", "Video", "movie", ["video/mp4", "video/x-matroska", "video/webm", "video/quicktime"]),
    ("music", "Müzik", "music_note", ["audio/mpeg", "audio/flac", "audio/ogg", "audio/x-wav"]),
    ("pdf", "PDF", "picture_as_pdf", ["application/pdf"]),
    ("text", "Metin düzenleyici", "edit_note", ["text/plain", "text/markdown"]),
    ("archive", "Arşivler", "folder_zip", ["application/zip", "application/x-tar", "application/x-7z-compressed"]),
]

DIRS = [Path.home() / ".local/share/applications",
        Path.home() / ".local/share/flatpak/exports/share/applications",
        Path("/var/lib/flatpak/exports/share/applications"),
        Path("/usr/share/applications")]


def entries():
    seen = {}
    for d in DIRS:
        if not d.is_dir():
            continue
        for f in d.glob("*.desktop"):
            if f.name in seen:
                continue
            cp = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                cp.read(f, encoding="utf-8")
                e = cp["Desktop Entry"]
            except Exception:
                continue
            if e.get("NoDisplay", "false") == "true" or e.get("Hidden", "false") == "true":
                continue
            name = e.get("Name[tr]") or e.get("Name") or f.stem
            mimes = [m for m in e.get("MimeType", "").split(";") if m]
            seen[f.name] = {"id": f.name, "name": name, "icon": e.get("Icon", ""), "mimes": mimes,
                            "terminal": "TerminalEmulator" in e.get("Categories", "")}
    return seen


def current(mime):
    r = sp.run(["xdg-mime", "query", "default", mime], capture_output=True, text=True)
    return r.stdout.strip()


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    apps = entries()
    if cmd == "list":
        out = []
        for cid, name, icon, mimes in CATEGORIES:
            if cid == "terminal":
                cands = [a for a in apps.values() if a["terminal"]]
            else:
                cands = [a for a in apps.values() if set(a["mimes"]) & set(mimes)]
            cur = current(mimes[0])
            if cur and cur not in {a["id"] for a in cands} and cur in apps:
                cands.append(apps[cur])
            cands.sort(key=lambda a: a["name"].lower())
            out.append({"id": cid, "name": name, "icon": icon, "current": cur,
                        "apps": [{"id": a["id"], "name": a["name"], "icon": a["icon"]} for a in cands]})
        print(json.dumps(out, ensure_ascii=False))
    elif cmd == "set":
        cid, app = sys.argv[2], sys.argv[3]
        cat = next(c for c in CATEGORIES if c[0] == cid)
        for mime in cat[3]:
            sp.run(["xdg-mime", "default", app, mime], check=True)
        if cid == "browser":
            sp.run(["xdg-settings", "set", "default-web-browser", app], capture_output=True)
        print(current(cat[3][0]))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
