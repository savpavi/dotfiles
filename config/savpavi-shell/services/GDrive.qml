pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Google Drive mount (rclone-gdrive.service) state from `dot-drive status`.
// Also notifies when an upload burst finishes or a file fails to upload;
// an unexpected mount stop is reported by the unit's ExecStopPost instead.
Singleton {
    id: root

    readonly property string tool: Quickshell.env("HOME") + "/dotfiles/bin/dot-drive"

    property bool ready: false
    property bool active: false
    property bool mounted: false
    property int uploading: 0
    property int queued: 0
    property int errored: 0
    property bool outOfSpace: false
    property real cacheBytes: 0
    property real cacheMax: 0
    property var transferring: []
    property string lastError: ""
    property var syncs: []           // [{ name, state: running|ok|error, resync, error, conflicts, lastOk }]
    readonly property int pending: uploading + queued
    readonly property bool syncing: syncs.some(s => s.state === "running")
    readonly property bool syncFailed: syncs.some(s => s.state === "error")
    readonly property bool busy: pending > 0

    // upload burst tracking for the "done" notification
    property var burstNames: ({})
    property real burstStart: 0

    function refresh() {
        if (!status.running) status.running = true;
    }

    function run(args) {
        Quickshell.execDetached([tool].concat(args));
        later.restart();
    }

    function notify(urgency, title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Google Drive", "-i", "folder-google-drive", "-u", urgency, title, body]);
    }

    function apply(d) {
        const wasBusy = busy;
        const prevErrored = errored;
        const prevOut = outOfSpace;

        active = d.active; mounted = d.mounted;
        uploading = d.uploading; queued = d.queued; errored = d.errored;
        outOfSpace = d.outOfSpace; cacheBytes = d.cacheBytes; cacheMax = d.cacheMax;
        transferring = d.transferring; lastError = d.lastError;
        syncs = d.syncs || [];

        if (!ready) { ready = true; return; }

        if (busy) {
            if (!wasBusy) { burstNames = {}; burstStart = Date.now(); }
            const names = burstNames;
            for (const n of transferring) names[n] = true;
            burstNames = names;
        } else if (wasBusy) {
            // short saves stay quiet; only longer or multi-file uploads report
            const count = Object.keys(burstNames).length;
            if (errored <= prevErrored && (count >= 3 || Date.now() - burstStart >= 20000))
                notify("normal", "Drive'a yüklendi", count > 1 ? count + " dosya" : (Object.keys(burstNames)[0] || "Yükleme tamamlandı"));
        }

        if (errored > prevErrored)
            notify("critical", "Drive yükleme hatası", (errored - prevErrored) + " dosya yüklenemedi" + (lastError ? "\n" + lastError : ""));
        if (outOfSpace && !prevOut)
            notify("critical", "Drive önbelleği dolu", "Yerel disk alanı yetersiz, yüklemeler bekliyor.");
    }

    Timer {
        interval: root.busy || root.syncing ? 3000 : 15000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Timer { id: later; interval: 2500; onTriggered: root.refresh() }

    Process {
        id: status
        command: [root.tool, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.apply(JSON.parse(text)); } catch (e) {}
            }
        }
    }
}
