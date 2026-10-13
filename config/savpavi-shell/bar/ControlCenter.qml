import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.common
import qs.services

// Quick settings: network, Bluetooth, power profile, keep-awake tiles; output and
// mic volume with device pickers; Bluetooth devices.
BarButton {
    id: root
    padding: 6

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property BluetoothAdapter bt: Bluetooth.defaultAdapter
    readonly property var btDevices: Bluetooth.devices.values.filter(d => d.paired || d.connected)
        .sort((a, b) => b.connected - a.connected)

    property string net: ""          // connection name
    property string netType: ""      // ethernet / wifi
    property string expanded: ""     // which device list is open: "sink" / "source" / ""

    // volume / mute need bound nodes
    PwObjectTracker { objects: [root.sink, root.source] }

    Icon { name: "tune"; anchors.verticalCenter: parent.verticalCenter }

    onClicked: dd.toggle()
    onScrolled: delta => { if (root.sink?.audio) root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + (delta > 0 ? 0.05 : -0.05))); }

    function nodeName(n) {
        return n?.nickname || n?.description || n?.name || "—";
    }

    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.net = "";
                for (const l of text.split("\n")) {
                    const [type, state, ...name] = l.split(":");
                    if ((type === "ethernet" || type === "wifi") && state === "connected") {
                        root.netType = type;
                        root.net = name.join(":");
                        break;
                    }
                }
            }
        }
    }

    Dropdown {
        id: dd
        anchorItem: root
        contentWidth: 360
        onVisibleChanged: { if (visible) netProc.running = true; else root.expanded = ""; }

        Column {
            width: parent.width
            spacing: 10

            Grid {
                width: parent.width
                columns: 2
                spacing: 8

                Tile {
                    width: (parent.width - 8) / 2
                    icon: root.netType === "wifi" ? "wifi" : root.net ? "lan" : "signal_disconnected"
                    title: root.netType === "wifi" ? "Wi-Fi" : "Ağ"
                    detail: root.net || "Bağlı değil"
                    on: root.net !== ""
                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                }

                Tile {
                    width: (parent.width - 8) / 2
                    icon: "bluetooth"
                    title: "Bluetooth"
                    detail: !root.bt ? "Yok" : !root.bt.enabled ? "Kapalı" : (root.btDevices.find(d => d.connected)?.name ?? "Açık")
                    on: root.bt?.enabled ?? false
                    onClicked: if (root.bt) root.bt.enabled = !root.bt.enabled
                }

                Tile {
                    width: (parent.width - 8) / 2
                    icon: PowerProfiles.profile === PowerProfile.Performance ? "bolt" : PowerProfiles.profile === PowerProfile.PowerSaver ? "eco" : "balance"
                    title: "Güç profili"
                    detail: PowerProfiles.profile === PowerProfile.Performance ? "Performans" : PowerProfiles.profile === PowerProfile.PowerSaver ? "Tasarruf" : "Dengeli"
                    on: PowerProfiles.profile !== PowerProfile.Balanced
                    onClicked: {
                        const order = [PowerProfile.Balanced, PowerProfile.Performance, PowerProfile.PowerSaver];
                        const next = order[(order.indexOf(PowerProfiles.profile) + 1) % order.length];
                        if (next !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile) PowerProfiles.profile = next;
                        else PowerProfiles.profile = PowerProfile.PowerSaver;
                    }
                }

                Tile {
                    width: (parent.width - 8) / 2
                    icon: "coffee"
                    title: "Uyanık kal"
                    detail: ShellState.idleInhibit ? "Açık" : "Kapalı"
                    on: ShellState.idleInhibit
                    onClicked: ShellState.idleInhibit = !ShellState.idleInhibit
                }
            }

            // Output
            Column {
                width: parent.width
                spacing: 2

                Slider {
                    width: parent.width
                    icon: root.sink?.audio?.muted ? "volume_off" : "volume_up"
                    muted: root.sink?.audio?.muted ?? false
                    value: root.sink?.audio?.volume ?? 0
                    onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v; }
                    onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
                }
                MenuItem {
                    icon: "speaker"
                    text: root.nodeName(root.sink)
                    detail: root.sinks.length > 1 ? (root.expanded === "sink" ? "▴" : "▾") : ""
                    onClicked: root.expanded = root.expanded === "sink" ? "" : "sink"
                }
                Repeater {
                    model: root.expanded === "sink" ? root.sinks : []
                    MenuItem {
                        required property PwNode modelData
                        text: root.nodeName(modelData)
                        checked: modelData === root.sink
                        onClicked: { Pipewire.preferredDefaultAudioSink = modelData; root.expanded = ""; }
                    }
                }
            }

            // Input
            Column {
                width: parent.width
                spacing: 2
                visible: root.source !== null

                Slider {
                    width: parent.width
                    icon: root.source?.audio?.muted ? "mic_off" : "mic"
                    muted: root.source?.audio?.muted ?? false
                    value: root.source?.audio?.volume ?? 0
                    onMoved: v => { if (root.source?.audio) root.source.audio.volume = v; }
                    onIconClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
                }
                MenuItem {
                    icon: "settings_voice"
                    text: root.nodeName(root.source)
                    detail: root.sources.length > 1 ? (root.expanded === "source" ? "▴" : "▾") : ""
                    onClicked: root.expanded = root.expanded === "source" ? "" : "source"
                }
                Repeater {
                    model: root.expanded === "source" ? root.sources : []
                    MenuItem {
                        required property PwNode modelData
                        text: root.nodeName(modelData)
                        checked: modelData === root.source
                        onClicked: { Pipewire.preferredDefaultAudioSource = modelData; root.expanded = ""; }
                    }
                }
            }

            // Bluetooth devices
            Column {
                width: parent.width
                spacing: 2
                visible: (root.bt?.enabled ?? false) && root.btDevices.length > 0

                Label { text: "Bluetooth cihazları"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall; leftPadding: 10 }
                Repeater {
                    model: root.bt?.enabled ? root.btDevices : []
                    MenuItem {
                        required property BluetoothDevice modelData
                        icon: modelData.icon?.includes("headset") || modelData.icon?.includes("audio") ? "headphones" : modelData.icon?.includes("phone") ? "smartphone" : "bluetooth"
                        text: modelData.name
                        detail: modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%  bağlı" : "bağlı") : ""
                        checked: modelData.connected
                        onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                    }
                }
            }
        }
    }
}
