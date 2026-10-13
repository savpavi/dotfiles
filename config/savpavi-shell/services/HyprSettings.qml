pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Front for scripts/hypr-settings.py: current values + queued changes.
// Each change is verified by the script (Hyprland --verify-config) and rolled
// back there on failure; the error text lands in `lastError`.
Singleton {
    id: root

    property var data: null
    property string lastError: ""
    property bool busy: runner.running
    property var queue: []

    readonly property string script: Qt.resolvedUrl("../scripts/hypr-settings.py").toString().replace("file://", "")

    function refresh() {
        if (!getter.running) getter.running = true;
    }

    function call(args) {
        queue = [...queue, args];
        next();
    }

    function next() {
        if (runner.running || queue.length === 0) return;
        const [head, ...rest] = queue;
        queue = rest;
        runner.command = ["python3", script, ...head];
        runner.running = true;
    }

    function setLayout(key, value) { call(["set-layout", key + "=" + value]); }
    function setInput(key, value) { call(["set-input", key + "=" + value]); }
    function setMonitors(list) { call(["set-monitors", JSON.stringify(list)]); }
    function bindSet(file, line, key) { call(["bind-set", file, String(line), key]); }
    function bindAdd(key, name, cmd) { call(["bind-add", key, name, cmd]); }
    function bindRemove(index) { call(["bind-remove", String(index)]); }
    function idleSet(seconds) { call(["idle-set", String(seconds)]); }

    signal applied

    Process {
        id: getter
        command: ["python3", root.script, "get"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.data = JSON.parse(text); } catch (e) {} }
        }
    }

    Process {
        id: runner
        stderr: StdioCollector { id: err }
        onExited: code => {
            root.lastError = code === 0 ? "" : err.text.trim();
            root.applied();
            root.refresh();
            root.next();
        }
    }
}
