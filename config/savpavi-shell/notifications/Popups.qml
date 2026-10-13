import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common
import qs.services

// Notification popups, top right of the focused monitor, under the bar.
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Notifs.popups.length > 0
    anchors { top: true; right: true }
    margins { top: Theme.barHeight + Theme.barMargin * 2; right: Theme.barMargin }
    implicitWidth: 380
    implicitHeight: stack.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "savpavi-notifications"

    Column {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.popups
            NotificationCard {
                required property var modelData
                notif: modelData
                popup: true
                onExpired: Notifs.dismissPopup(modelData)
            }
        }
    }
}
