import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common

// Workspaces of this bar's monitor. Dispatches use the Lua syntax (hyprland.lua config).
// The active one stretches into an accent pill.
Row {
    id: root

    required property ShellScreen screen
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(w => w.id > 0 && w.monitor?.name === screen.name)
        .sort((a, b) => a.id - b.id)

    spacing: 4

    Repeater {
        model: root.workspaces

        Rectangle {
            id: dot
            required property var modelData
            readonly property bool current: modelData.active

            anchors.verticalCenter: parent.verticalCenter
            width: current ? 30 : 20
            height: 20
            radius: 10
            color: current ? Theme.primary : (mouse.containsMouse ? Theme.bgHighest : "transparent")

            Behavior on width { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.animMs } }

            Label {
                anchors.centerIn: parent
                // Names look like "1-ASUS" / "1-LG"; show the number only
                text: dot.modelData.name.split("-")[0]
                font.pixelSize: Theme.fontSmall
                font.weight: dot.current ? Font.Bold : Font.Normal
                color: dot.current ? Theme.onPrimary : Theme.fg
                // empty workspaces fade back
                opacity: dot.current || dot.modelData.toplevels.values.length > 0 ? 1 : 0.4
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + dot.modelData.id + " })")
            }
        }
    }

    // Scroll anywhere on the strip to step through workspaces on this monitor
    WheelHandler {
        onWheel: e => Hyprland.dispatch('hl.dsp.focus({ workspace = "' + (e.angleDelta.y > 0 ? "m-1" : "m+1") + '" })')
    }
}
