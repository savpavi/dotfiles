pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Tailscale state from `tailscale status --json`. Up/down works without sudo
// because savpavi is the tailscale operator.
Singleton {
    id: root

    property string state: ""        // Running, Stopped, NeedsLogin, ...
    property string ip: ""
    property string exitNode: ""
    property var peers: []           // [{ name, ip, online, os, exitNodeOption }]
    readonly property bool up: state === "Running"

    function refresh() {
        if (!status.running) status.running = true;
    }

    function setUp(on) {
        Quickshell.execDetached(["tailscale", on ? "up" : "down"]);
        later.restart();
    }

    function setExitNode(ip) {
        Quickshell.execDetached(["tailscale", "set", "--exit-node=" + ip]);
        later.restart();
    }

    Timer { interval: 15000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: later; interval: 2000; onTriggered: root.refresh() }

    Process {
        id: status
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.state = d.BackendState || "";
                    root.ip = (d.Self?.TailscaleIPs || [])[0] || "";
                    const list = [];
                    let exit = "";
                    for (const k in (d.Peer || {})) {
                        const p = d.Peer[k];
                        const name = (p.DNSName || p.HostName || "").split(".")[0];
                        if (p.ExitNode) exit = name;
                        list.push({ name, ip: (p.TailscaleIPs || [])[0] || "", online: !!p.Online, os: p.OS || "", exitNodeOption: !!p.ExitNodeOption });
                    }
                    list.sort((a, b) => (b.online - a.online) || a.name.localeCompare(b.name));
                    root.peers = list;
                    root.exitNode = exit;
                } catch (e) {
                    root.state = "";
                }
            }
        }
    }
}
