import QtQuick
import QtQuick.Effects
import Quickshell
import qs.common

// EB monogram, tinted with the theme accent. Opens the launcher.
BarButton {
    padding: 7

    Item {
        width: 18
        height: 18
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: logo
            anchors.fill: parent
            source: Qt.resolvedUrl("../assets/eb-logo.svg")
            sourceSize: Qt.size(36, 36)
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: logo
            colorization: 1
            colorizationColor: Theme.primary
        }
    }

    onClicked: Quickshell.execDetached(["qs", "-p", Qt.resolvedUrl("..").toString().replace("file://", ""), "ipc", "call", "launcher", "toggle"])
}
