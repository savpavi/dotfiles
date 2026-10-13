import QtQuick
import Quickshell
import qs.common
import qs.services

// CPU and RAM usage. Click opens a process monitor.
BarButton {
    spacing: 10

    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Icon { name: "memory"; color: SystemStats.cpu > 0.85 ? Theme.error : Theme.fgDim; anchors.verticalCenter: parent.verticalCenter }
        Label { text: Math.round(SystemStats.cpu * 100) + "%"; font.family: Theme.mono; font.pixelSize: Theme.fontSmall; anchors.verticalCenter: parent.verticalCenter }
    }

    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Icon { name: "memory_alt"; color: SystemStats.mem > 0.85 ? Theme.error : Theme.fgDim; anchors.verticalCenter: parent.verticalCenter }
        Label { text: Math.round(SystemStats.mem * 100) + "%"; font.family: Theme.mono; font.pixelSize: Theme.fontSmall; anchors.verticalCenter: parent.verticalCenter }
    }

    onClicked: Quickshell.execDetached(["kitty", "--class", "btop", "btop"])
}
