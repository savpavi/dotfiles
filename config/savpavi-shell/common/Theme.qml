pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Palette comes from dot-shell-theme: state file -> active theme id + mode ->
// ~/.local/share/savpavi-shell/themes/<id>.json. Both files are watched, so a
// theme switch recolours the shell live.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property string themeId: ""
    property string mode: "dark"
    property var pal: ({})
    property string wallpaper: ""
    property bool live: false          // waywallen draws a live wallpaper on top

    readonly property color bg: pal.surface ?? "#2E3440"
    readonly property color bgAlt: pal.surfaceContainer ?? "#363e4c"
    readonly property color bgHigh: pal.surfaceContainerHigh ?? "#3d4555"
    readonly property color bgHighest: pal.surfaceContainerHighest ?? "#434C5E"
    readonly property color fg: pal.surfaceText ?? "#D8DEE9"
    readonly property color fgDim: Qt.rgba(fg.r, fg.g, fg.b, 0.6)
    readonly property color primary: pal.primary ?? "#81A1C1"
    readonly property color onPrimary: pal.primaryText ?? "#000000"
    readonly property color primaryContainer: pal.primaryContainer ?? "#4f6074"
    readonly property color secondary: pal.secondary ?? "#88C0D0"
    readonly property color outline: pal.outline ?? "#8c929d"
    readonly property color error: pal.error ?? "#BF616A"
    readonly property color warning: pal.warning ?? "#EBCB8B"

    readonly property string sans: "Inter"
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string icons: "Material Symbols Rounded"
    readonly property int fontSize: 13
    readonly property int fontSmall: 11
    readonly property int iconSize: 17

    readonly property int barHeight: 32
    readonly property int barMargin: 8
    readonly property int radius: 12
    readonly property int radiusSmall: 8
    readonly property int spacing: 6
    readonly property int animMs: 160

    FileView {
        path: root.home + "/.local/state/savpavi-shell/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.mode = s.mode || "dark";
                root.themeId = s.id || "";
                root.wallpaper = s.wallpaper || "";
                root.live = !!s.live;
            } catch (e) {
                console.warn("Theme: state unreadable:", e);
            }
        }
    }

    FileView {
        id: themeFile
        path: root.themeId ? root.home + "/.local/share/savpavi-shell/themes/" + root.themeId + ".json" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyPalette()
    }

    onModeChanged: applyPalette()

    function applyPalette() {
        try {
            const t = JSON.parse(themeFile.text());
            root.pal = t[root.mode] || t.dark || {};
        } catch (e) {
            // file not loaded yet
        }
    }
}
