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
                root.b = Object.assign({}, root.fallbackBar, JSON.parse(text()).bar);
            } catch (e) {
                console.warn("theme.json okunamadı:", e);
            }
        }
    }

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
        }
    }

    // Solda dikey ray
    Variants {
        model: Quickshell.screens

        PanelWindow {
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
        }
    }
}
