.pragma library

// Qt key event -> Hyprland bind syntax ("SUPER + SHIFT + K").
// Keys without a stable name (Turkish letters, OEM keys on compact keyboards)
// fall back to "code:N" (XKB keycode = evdev + 8), which Hyprland accepts.

const NAMES = {
    0x01000000: "escape", 0x01000001: "TAB", 0x01000002: "TAB", 0x01000003: "BackSpace",
    0x01000004: "RETURN", 0x01000005: "KP_Enter", 0x01000006: "Insert", 0x01000007: "Delete",
    0x01000008: "Pause", 0x01000009: "Print", 0x01000010: "Home", 0x01000011: "End",
    0x01000012: "left", 0x01000013: "up", 0x01000014: "right", 0x01000015: "down",
    0x01000016: "Prior", 0x01000017: "Next", 0x20: "SPACE",
    0x2c: "comma", 0x2e: "period", 0x2d: "minus", 0x3d: "equal", 0x2f: "slash", 0x5c: "backslash",
    0x3b: "semicolon", 0x27: "apostrophe", 0x60: "grave", 0x5b: "bracketleft", 0x5d: "bracketright",
    0x1000070: "XF86AudioRaiseVolume", 0x1000072: "XF86AudioLowerVolume", 0x1000071: "XF86AudioMute",
    0x1000080: "XF86AudioPlay", 0x1000083: "XF86AudioNext", 0x1000082: "XF86AudioPrev",
};

const MODIFIER_KEYS = [0x01000020, 0x01000021, 0x01000022, 0x01000023, 0x01000053, 0x01000054, 0x01001103];

function isModifier(key) {
    return MODIFIER_KEYS.indexOf(key) >= 0;
}

function keyName(key, scanCode) {
    if (key >= 0x41 && key <= 0x5a) return String.fromCharCode(key);       // A-Z
    if (key >= 0x30 && key <= 0x39) return String.fromCharCode(key);       // 0-9
    if (key >= 0x01000030 && key <= 0x01000047) return "F" + (key - 0x01000030 + 1);
    if (NAMES[key] !== undefined) return NAMES[key];
    return "code:" + scanCode;
}

function mods(m) {
    const out = [];
    if (m & 0x10000000) out.push("SUPER");     // Qt.MetaModifier
    if (m & 0x04000000) out.push("CTRL");      // Qt.ControlModifier
    if (m & 0x08000000) out.push("ALT");       // Qt.AltModifier
    if (m & 0x02000000) out.push("SHIFT");     // Qt.ShiftModifier
    return out;
}

// returns "" while only modifiers are held
function combo(event) {
    if (isModifier(event.key)) return "";
    return mods(event.modifiers).concat([keyName(event.key, event.nativeScanCode)]).join(" + ");
}

function normalize(s) {
    return s.replace(/\s+/g, "").toUpperCase();
}
