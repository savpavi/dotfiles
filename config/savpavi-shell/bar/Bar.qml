import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

// Floating single-piece top bar, one per screen.
PanelWindow {
    id: bar

    required property ShellScreen modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    margins { top: Theme.barMargin; left: Theme.barMargin; right: Theme.barMargin }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "savpavi-bar"

    IdleInhibitor {
        window: bar
        enabled: ShellState.idleInhibit
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.18)
        Behavior on color { ColorAnimation { duration: Theme.animMs } }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacing

            LauncherButton {}
            Themes {}
            Workspaces { screen: bar.modelData; anchors.verticalCenter: parent.verticalCenter }
            FocusedWindow { screen: bar.modelData; anchors.verticalCenter: parent.verticalCenter }
        }

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacing

            Media {}
            WeatherWidget {}
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Tray { anchors.verticalCenter: parent.verticalCenter }
            SendButton { visible: ShellState.settings.showSend }
            DriveWidget {}

            BarButton {
                padding: 6
                Icon { name: "content_paste"; anchors.verticalCenter: parent.verticalCenter }
                onClicked: Quickshell.execDetached(["dot-shell", "clipboard"])
            }

            Stats { visible: ShellState.settings.showStats }
            ClaudeWidget { visible: ShellState.settings.showClaude }
            TailscaleWidget {}

            BarButton {
                padding: 6
                Icon {
                    name: ShellState.idleInhibit ? "coffee" : "bedtime"
                    filled: ShellState.idleInhibit
                    color: ShellState.idleInhibit ? Theme.primary : Theme.fgDim
                    anchors.verticalCenter: parent.verticalCenter
                }
                onClicked: ShellState.idleInhibit = !ShellState.idleInhibit
            }

            NotificationButton {}

            ControlCenter {}

            Clock {}
            PowerButton {}
        }
    }
}
