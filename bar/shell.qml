// dwl için Quickshell bar. Görünüm ~/.local/state/dwl-theme/theme.json'dan gelir
// (bin/dwl-theme üretir); dosya değişince bar yeniden başlatılmadan güncellenir.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    // Tema dosyası yoksa kullanılan varsayılan (Mürekkep).
    readonly property var fallbackBar: ({
        layout: "strip", size: 26, font: "JetBrainsMono Nerd Font", fontPx: 13,
        bg: "#1B1A17", fg: "#ECE6D9", faded: "#8A857A", accent: "#D2452D", onAccent: "#FFFFFF",
        urgent: "#2B4C7E", title: "#ECE6D9", line: "", clockBg: "#ECE6D9", clockFg: "#1B1A17",
        clockFormat: "ddd d MMM HH:mm", zeroPad: false
    })
    property var b: fallbackBar
    readonly property var fallbackMenu: ({
        bg: "#ECE6D9", text: "#1B1A17", match: "#D2452D", selBg: "#1B1A17", selText: "#ECE6D9",
        border: "#1B1A17", borderpx: 2, radius: 0
    })
    property var m: fallbackMenu

    // Açık panel: "" | "theme" | "notif" | "power", ve hangi ekranın barında
    property string panelKind: ""
    property string panelScreen: ""
    property var themeData: ({ current: "", wallOff: false, themes: [] })
    property var notifs: []
    property int notifCount: 0
    property bool notifPaused: false
    readonly property string themeBin: Quickshell.shellDir + "/../bin/dwl-theme"

    function togglePanel(kind, screen) {
        if (panelKind === kind && panelScreen === screen) {
            closePanel();
            return;
        }
        panelKind = kind;
        panelScreen = screen;
        if (kind === "theme") themeList.running = true;
        if (kind === "notif") notifHistory.running = true;
    }
    function closePanel() { panelKind = ""; }
    function applyTheme(id) { themeRun.command = [themeBin, "apply", id]; themeRun.running = true; }
    function wall(cmd) { themeRun.command = [themeBin, "wall", cmd]; themeRun.running = true; }
    function removeNotif(id) { notifRun.command = ["dunstctl", "history-rm", String(id)]; notifRun.running = true; }
    function clearNotifs() { notifRun.command = ["dunstctl", "history-clear"]; notifRun.running = true; }
    function toggleNotifPause() { notifRun.command = ["dunstctl", "set-paused", "toggle"]; notifRun.running = true; }
    readonly property int minTags: 5 // boş olsa da her zaman görünen tag sayısı

    readonly property string ipc: Quickshell.shellDir + "/ipc/dwl-bar-ipc"
    readonly property string stateDir:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/dwl-theme"

    // output adı -> dwl-bar-ipc'nin son JSON satırı
    property var outputs: ({})
    property int cpu: 0
    property var cpuPrev: null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasSink: sink !== null && sink.audio !== null
    readonly property bool muted: hasSink && sink.audio.muted
    readonly property int volume: hasSink ? Math.round(sink.audio.volume * 100) : 0
    readonly property date now: clock.date

    function view(output, index, toggle) {
        Quickshell.execDetached([ipc, toggle ? "toggle" : "view", output, String(1 << index)]);
    }
    function cycleLayout(output, symbol) {
        // 0 = tile, 2 = monocle
        Quickshell.execDetached([ipc, "layout", output, symbol === "[]=" ? "2" : "0"]);
    }
    function toggleMute() { if (hasSink) sink.audio.muted = !sink.audio.muted; }
    function nudgeVolume(up) {
        if (hasSink)
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (up ? 0.05 : -0.05)));
    }
    function clockText() { return Qt.locale("tr_TR").toString(now, b.clockFormat); }

    FileView {
        id: themeFile
        path: root.stateDir + "/theme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const t = JSON.parse(text());
                root.b = Object.assign({}, root.fallbackBar, t.bar);
                root.m = Object.assign({}, root.fallbackMenu, t.menu);
            } catch (e) {
                console.warn("theme.json okunamadı:", e);
            }
        }
    }

    Process {
        id: themeList
        command: [root.themeBin, "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.themeData = JSON.parse(text); } catch (e) { console.warn("tema listesi:", e); }
            }
        }
    }
    Process { id: themeRun; onExited: themeList.running = true }

    Process {
        id: notifHistory
        command: ["dunstctl", "history"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rows = JSON.parse(text).data[0] || [];
                    root.notifs = rows.slice(0, 8).map(n => ({
                        id: n.id.data,
                        summary: n.summary.data,
                        body: (n.body.data || "").replace(/<[^>]*>/g, ""),
                        app: n.appname.data
                    }));
                } catch (e) {
                    root.notifs = [];
                }
            }
        }
    }
    Process {
        id: notifRun
        onExited: { notifHistory.running = true; notifPoll.running = true; }
    }
    Process {
        id: notifPoll
        command: ["sh", "-c", "dunstctl count history; dunstctl is-paused"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                root.notifCount = parseInt(l[0]) || 0;
                root.notifPaused = l[1] === "true";
            }
        }
    }
    Timer {
        interval: 4000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: notifPoll.running = true
    }

    // Kısayoldan/terminalden panel açmak için: quickshell ipc -p <bar> call panel toggle theme|notif|power
    IpcHandler {
        target: "panel"
        function toggle(kind: string): void {
            let screen = "";
            for (const name in root.outputs)
                if (root.outputs[name].active === 1) screen = name;
            if (screen !== "") root.togglePanel(kind, screen);
        }
        function close(): void { root.closePanel(); }
    }

    // Oturum açılışında etkin temanın hareketli duvarını başlat
    Component.onCompleted: Quickshell.execDetached([themeBin, "wall", "show"])

    Process {
        id: watcher
        command: [root.ipc]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const o = JSON.parse(line);
                    const next = Object.assign({}, root.outputs);
                    next[o.output] = o;
                    root.outputs = next;
                } catch (e) {
                    console.warn("dwl-bar-ipc:", line);
                }
            }
        }
        onExited: restart.start()
    }
    Timer { id: restart; interval: 2000; onTriggered: watcher.running = true }

    FileView { id: stat; path: "/proc/stat"; blockLoading: true }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            stat.reload();
            const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4];
            const total = f.reduce((a, b) => a + b, 0);
            if (root.cpuPrev && total > root.cpuPrev.total)
                root.cpu = Math.round(100 * (1 - (idle - root.cpuPrev.idle) / (total - root.cpuPrev.total)));
            root.cpuPrev = { idle: idle, total: total };
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    // Üstte duran düzenler: strip (düz şerit) ve islands (yüzen adacıklar)
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: topBar
            required property var modelData
            screen: modelData
            visible: root.b.layout !== "rail"
            anchors { top: true; left: true; right: true }
            implicitHeight: root.b.size + (root.b.layout === "islands" ? (root.b.margin ?? 0) : 0)
            color: root.b.layout === "islands" ? "transparent" : root.b.bg

            Loader {
                anchors.fill: parent
                sourceComponent: root.b.layout === "islands" ? islands : strip
            }
            Component { id: strip; Strip { sh: root; output: modelData.name } }
            Component { id: islands; Islands { sh: root; output: modelData.name } }
            Panel { sh: root; win: topBar; output: topBar.modelData.name }
        }
    }

    // Solda dikey ray
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: railBar
            required property var modelData
            screen: modelData
            visible: root.b.layout === "rail"
            anchors { top: true; left: true; bottom: true }
            implicitWidth: root.b.size
            color: root.b.bg

            Loader {
                anchors.fill: parent
                active: parent.visible
                sourceComponent: Rail { sh: root; output: modelData.name }
            }
            Panel { sh: root; win: railBar; output: railBar.modelData.name; rail: true }
        }
    }
}
