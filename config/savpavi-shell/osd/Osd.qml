import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.common

// Volume / mic OSD: a small pill at the bottom of the focused monitor. It reacts
// to the default devices themselves, so keys, the control centre, pavucontrol or
// wpctl all show it.
PanelWindow {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    property string kind: "sink"          // which device the pill is showing
    property bool armed: false            // ignore the burst of changes at startup

    function show(k) {
        if (!armed) return;
        kind = k;
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        visible = true;
        hide.restart();
    }

    PwObjectTracker { objects: [root.sink, root.source] }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.show("sink"); }
        function onMutedChanged() { root.show("sink"); }
    }
    Connections {
        target: root.source?.audio ?? null
        function onMutedChanged() { root.show("source"); }
    }

    Timer { interval: 1500; running: true; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1400; onTriggered: root.visible = false }

    readonly property PwNode node: kind === "sink" ? sink : source
    readonly property bool muted: node?.audio?.muted ?? false
    readonly property real volume: node?.audio?.volume ?? 0

    visible: false
    anchors.bottom: true
    margins.bottom: 80
    implicitWidth: 300
    implicitHeight: 48
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "savpavi-osd"
    // no input: the pill must never steal clicks
    mask: Region {}

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.bg
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.25)

        Icon {
            id: ic
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            size: 22
            name: root.kind === "sink"
                ? (root.muted || root.volume === 0 ? "volume_off" : root.volume < 0.4 ? "volume_down" : "volume_up")
                : (root.muted ? "mic_off" : "mic")
            color: root.muted ? Theme.fgDim : Theme.primary
        }

        Rectangle {
            id: track
            anchors.left: ic.right
            anchors.leftMargin: 12
            anchors.right: pct.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: Theme.bgHighest

            Rectangle {
                width: parent.width * Math.min(1, root.muted ? 0 : root.volume)
                height: parent.height
                radius: 3
                color: Theme.primary
                Behavior on width { NumberAnimation { duration: 90 } }
            }
        }

        Label {
            id: pct
            width: 40
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: root.muted ? "kapalı" : Math.round(root.volume * 100) + "%"
            font.pixelSize: Theme.fontSmall
            color: Theme.fgDim
        }
    }
}
