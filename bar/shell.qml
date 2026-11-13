// dwl için Quickshell bar. Görünüm ~/.local/state/dwl-theme/theme.json'dan gelir
// (bin/dwl-theme üretir); dosya değişince bar yeniden başlatılmadan güncellenir.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland

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
    property var wm: ({ root: "#ECE6D9" })

    // Boşta kalınca: önce kilit, sonra ekranları kapat (ikincisi wlopm kuruluysa çalışır)
    readonly property int idleLockSec: 600
    readonly property int idleScreenOffSec: 900
    property bool idleEnabled: true // bardaki fincan düğmesi kapatır ("uyanık kal")
    function toggleIdle() {
        idleEnabled = !idleEnabled;
        Quickshell.execDetached(["notify-send", "-t", "3000", "Boşta kilit",
            idleEnabled ? "Açık: 10 dk'da kilitler, 15 dk'da ekranı kapatır"
                        : "Kapalı: ekran açık kalır, kilitlenmez"]);
    }
    function lockNow() { closePanel(); lock.lock(); }

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
        if (kind === "drive") drivePoll.running = true;
        if (kind === "net") netPoll.running = true;
        if (kind === "send") phonePoll.running = true;
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
    property int ram: 0
    // Çalan parça: önce çalan oynatıcı, yoksa ilk oynatıcı
    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? (ps.length > 0 ? ps[0] : null);
    }
    // Klavye düzeni: dwl etkin düzeni $XDG_RUNTIME_DIR/dwl-kblayout dosyasına yazar
    property string kb: ""
    // Ağ: { type: "ethernet"|"wifi"|"", name, ip, tailscale }
    property var net: ({ type: "", name: "", ip: "", tailscale: "" })
    // Claude kullanım limiti: dotfiles'taki claude-usage.sh, önbelleği Hyprland barıyla ortak
    // (uç nokta sık sorulunca 429 veriyor; script 150 sn içinde önbelleği yeniden kullanır).
    property var claude: null // { five_hour: {used_percentage, resets_at}, seven_day: {...} }
    readonly property int claude5h: claude && claude.five_hour ? claude.five_hour.used_percentage : -1
    readonly property int claude7d: claude && claude.seven_day ? claude.seven_day.used_percentage : -1
    readonly property int claudeMax: Math.max(claude5h, claude7d)
    // barda: "58% · 50%" (5 saatlik · haftalık); haftalık yoksa yalnız ilki
    function claudeText(sep) {
        return claude5h + "%" + (claude7d >= 0 ? sep + claude7d + "%" : "");
    }
    function resetText(block) {
        if (!block || !block.resets_at)
            return "";
        const d = new Date(block.resets_at * 1000);
        const sameDay = d.toDateString() === new Date().toDateString();
        return Qt.locale("tr_TR").toString(d, sameDay ? "HH:mm" : "ddd HH:mm");
    }
    // Google Drive (dot-drive) ve telefona gönderme (dot-send) durumları
    readonly property string dotBin: Quickshell.env("HOME") + "/dotfiles/bin/"
    property var drive: ({ active: false, mounted: false, uploading: 0, queued: 0, errored: 0, lastError: "", syncs: [] })
    property var phone: ({ reachable: false, device: "", paired: false, localsend: false })
    readonly property bool driveBusy: drive.uploading > 0 || drive.queued > 0
        || drive.syncs.some(s => s.state === "running")
    readonly property bool driveBad: !drive.active || !drive.mounted || drive.errored > 0
        || drive.syncs.some(s => s.state === "error")
    function driveCmd(args) { driveRun.command = [dotBin + "dot-drive"].concat(args); driveRun.running = true; }
    function sendCmd(args) { closePanel(); Quickshell.execDetached([dotBin + "dot-send"].concat(args)); }
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
                root.wm = t.wm;
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
        id: drivePoll
        command: [root.dotBin + "dot-drive", "status"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.drive = JSON.parse(text); } catch (e) {} }
        }
    }
    Process { id: driveRun; onExited: drivePoll.running = true }

    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/dwl-kblayout"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.kb = text().trim()
    }
    Process {
        id: netPoll
        command: ["sh", "-c",
            "nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null | grep -E '^(ethernet|wifi):connected' | head -n1; echo; "
            + "ip -4 -o addr show scope global 2>/dev/null | grep -vE 'tailscale|virbr|docker|br-' | awk '{print $4}' | head -n1; echo; "
            + "tailscale status --json 2>/dev/null | sed -n 's/.*\"BackendState\": *\"\\([^\"]*\\)\".*/\\1/p' | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n").map(x => x.trim()).filter(x => x !== "");
                const conn = (l.find(x => /^(ethernet|wifi):connected/.test(x)) ?? "").split(":");
                root.net = {
                    type: conn[0] ?? "",
                    name: conn.slice(2).join(":"),
                    ip: l.find(x => /^\d+\.\d+\.\d+\.\d+\//.test(x)) ?? "",
                    tailscale: l.find(x => /^(Running|Stopped|NeedsLogin|Starting|NoState)$/.test(x)) ?? ""
                };
            }
        }
    }
    Timer {
        interval: 10000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: netPoll.running = true
    }

    Process {
        id: claudePoll
        command: ["sh", "-c", "CACHE_FILE=\"${XDG_CACHE_HOME:-$HOME/.cache}/savpavi-shell/claude-usage.json\" "
            + "exec \"$HOME/dotfiles/config/savpavi-shell/scripts/claude-usage.sh\""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (d && d.five_hour) root.claude = d;
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 300000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: claudePoll.running = true
    }
    Process {
        id: phonePoll
        command: [root.dotBin + "dot-send", "status"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.phone = JSON.parse(text); } catch (e) {} }
        }
    }
    Timer {
        interval: 15000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { drivePoll.running = true; phonePoll.running = true; }
    }

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

    Lock { id: lock; sh: root }
    IpcHandler {
        target: "lock"
        function lock(): void { root.lockNow(); }
    }
    IdleMonitor {
        enabled: root.idleEnabled
        timeout: root.idleLockSec
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lockNow()
    }
    IdleMonitor {
        enabled: root.idleEnabled
        timeout: root.idleScreenOffSec
        respectInhibitors: true
        onIsIdleChanged: Quickshell.execDetached(["sh", "-c",
            "command -v wlopm >/dev/null && wlopm " + (isIdle ? "--off" : "--on") + " '*'"])
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
    FileView { id: mem; path: "/proc/meminfo"; blockLoading: true }
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

            mem.reload();
            const mi = {};
            for (const l of mem.text().split("\n")) {
                const p = l.split(/[:\s]+/);
                mi[p[0]] = Number(p[1]);
            }
            if (mi.MemTotal > 0)
                root.ram = Math.round(100 * (mi.MemTotal - mi.MemAvailable) / mi.MemTotal);
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
            Component { id: strip; Strip { sh: root; output: modelData.name; win: topBar } }
            Component { id: islands; Islands { sh: root; output: modelData.name; win: topBar } }
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
                sourceComponent: Rail { sh: root; output: modelData.name; win: railBar }
            }
            Panel { sh: root; win: railBar; output: railBar.modelData.name; rail: true }
        }
    }
}
