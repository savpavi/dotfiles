#!/usr/bin/env python3
"""Hyprland keybinds as JSON for the savpavi-shell keybind window.

Reads hl.bind(...) calls from the Lua config (~/.config/hypr/*.lua) and takes
each bind's description from its trailing `-- comment`; binds without a comment
are skipped. Prints [{"keys": [...], "desc": "...", "cat": "..."}, ...].
  keybinds.py          JSON
  keybinds.py --text   aligned plain text (terminal fallback)
"""
import json, re, sys
from pathlib import Path

HYPR = Path.home() / ".config/hypr"
FILES = ["hyprland.lua", "tiling.lua", "window-mode.lua", "user-binds.lua"]

NAMES = {
    "SUPER": "Super", "SHIFT": "Shift", "CTRL": "Ctrl", "CONTROL": "Ctrl", "ALT": "Alt",
    "SPACE": "Space", "space": "Space", "RETURN": "Enter", "Return": "Enter", "escape": "Esc",
    "TAB": "Tab", "comma": ",", "code:20": "-", "code:21": "=", "period": ".", "minus": "-", "equal": "=", "Print": "Print",
    "left": "←", "right": "→", "up": "↑", "down": "↓",
    "mouse:272": "Sol tık", "mouse:273": "Sağ tık", "mouse_down": "Tekerlek ↓", "mouse_up": "Tekerlek ↑",
    "XF86AudioRaiseVolume": "Ses +", "XF86AudioLowerVolume": "Ses −", "XF86AudioMute": "Ses kapat",
    "XF86AudioMicMute": "Mikrofon", "XF86MonBrightnessUp": "Parlaklık +", "XF86MonBrightnessDown": "Parlaklık −",
    "XF86AudioPlay": "Oynat", "XF86AudioPause": "Oynat", "XF86AudioNext": "Sonraki", "XF86AudioPrev": "Önceki",
}

# the description is the comment after the call's closing paren ("--clip" inside a
# command string must not count as a comment)
BIND = re.compile(r'hl\.bind\((?P<key>.+?),\s*(?P<action>.*\))\s*--\s*(?P<desc>[^\n]+)$')


def key_text(expr, mods):
    """Lua key expression -> 'SUPER + SHIFT + 1-9'."""
    expr = re.sub(r'\bmainMod\b', '"SUPER"', expr)
    expr = re.sub(r'code:"\s*\.\.\s*tostring\([^)]*\)', '1-5"', expr)  # group tab loop
    expr = re.sub(r'\.\.\s*(index|i)\b', '.. "1-9"', expr)   # for-loop binds
    parts = re.findall(r'"([^"]*)"', expr)
    if not parts:
        return None
    return "".join(parts)


def category(action, keys):
    a = action
    if "XF86" in keys:
        return "Medya ve donanım"
    if "dot-shell" in a or "dot-keys" in a or "dot-shell-theme" in a:
        return "Shell"
    if "exec_cmd" in a:
        return "Uygulamalar"
    if "group" in a:
        return "Gruplar"
    if "window." in a or "mouse:" in keys:
        return "Pencereler"
    if "workspace" in a or "1-9" in keys or "mouse_down" in keys or "mouse_up" in keys:
        return "Çalışma alanları"
    if "focus" in a or "function()" in a or "layout" in a:
        return "Pencereler"
    return "Diğer"


def parse():
    out = []
    for name in FILES:
        path = HYPR / name
        if not path.exists():
            continue
        for lineno, line in enumerate(path.read_text().splitlines(), 1):
            s = line.strip()
            if s.startswith("--") or "hl.bind(" not in s:
                continue
            m = BIND.search(s)
            if not m:
                continue
            keys = key_text(m.group("key"), None)
            if not keys:
                continue
            pretty = [NAMES.get(k.strip(), k.strip()) for k in keys.split("+")]
            # loop binds (1-9 / 1-5) are not editable from the settings window
            editable = "1-9" not in keys and "1-5" not in keys
            cat = "Özel kısayollar" if name == "user-binds.lua" else category(m.group("action"), keys)
            out.append({"keys": pretty, "desc": m.group("desc").strip(), "cat": cat, "raw": keys.replace(" ", ""),
                        "file": str(path.resolve()), "line": lineno, "editable": editable, "custom": name == "user-binds.lua"})
    order = ["Özel kısayollar", "Shell", "Uygulamalar", "Pencereler", "Çalışma alanları", "Gruplar", "Medya ve donanım", "Diğer"]
    out.sort(key=lambda b: order.index(b["cat"]))
    return out


if __name__ == "__main__":
    binds = parse()
    if "--text" in sys.argv:
        for b in binds:
            print(f"{' + '.join(b['keys']):<28}  {b['desc']:<55}  {b['cat']}")
    else:
        print(json.dumps(binds, ensure_ascii=False))
