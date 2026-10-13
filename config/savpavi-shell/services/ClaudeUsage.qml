pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Claude Code 5-hour and weekly limits, via scripts/claude-usage.sh (reads the
// local OAuth token, writes a JSON cache that this file watches).
Singleton {
    id: root

    property var fiveHour: null     // { used_percentage, resets_at }
    property var sevenDay: null
    property int capturedAt: 0
    property bool failed: false
    property int now: Math.floor(Date.now() / 1000)
    readonly property bool ready: fiveHour !== null || sevenDay !== null

    readonly property string cache: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/savpavi-shell/claude-usage.json"
    readonly property string script: Qt.resolvedUrl("../scripts/claude-usage.sh").toString().replace("file://", "")

    function countdown(reset) {
        const s = reset - now;
        if (!reset || s <= 0) return "şimdi";
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
        if (d > 0) return d + "g " + h + "s";
        if (h > 0) return h + "s " + m + "dk";
        return Math.max(1, m) + "dk";
    }

    function refresh() {
        if (!fetch.running) fetch.running = true;
    }

    Timer { interval: 300000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = Math.floor(Date.now() / 1000) }

    Process {
        id: fetch
        command: ["sh", root.script]
        environment: ({ CACHE_FILE: root.cache })
        onExited: code => root.failed = code !== 0
    }

    FileView {
        path: root.cache
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const o = JSON.parse(text());
                root.capturedAt = o.captured_at || 0;
                root.fiveHour = o.five_hour || null;
                root.sevenDay = o.seven_day || null;
            } catch (e) {
                console.warn("ClaudeUsage: bad cache:", e);
            }
        }
    }
}
