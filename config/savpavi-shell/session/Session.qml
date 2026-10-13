import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common

// Session menu over a dimmed focused monitor. Arrow keys / Tab move, Enter runs,
// letter keys jump (K kilitle, U uyku, O oturum, Y yeniden başlat, P kapat), Esc closes.
PanelWindow {
    id: root

    property int current: 0
    readonly property var entries: [
        { key: "K", icon: "lock", label: "Kilitle", cmd: ["dot-shell", "lock"] },
        { key: "U", icon: "bedtime", label: "Uyku", cmd: ["systemctl", "suspend"] },
        { key: "O", icon: "logout", label: "Oturumu kapat", cmd: ["uwsm", "stop"] },
        { key: "Y", icon: "restart_alt", label: "Yeniden başlat", cmd: ["systemctl", "reboot"] },
        { key: "P", icon: "power_settings_new", label: "Kapat", cmd: ["systemctl", "poweroff"] }
    ]

    function open() {
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        current = 0;
        visible = true;
        keys.forceActiveFocus();
    }

    function run(i) {
        visible = false;
        Quickshell.execDetached(entries[i].cmd);
    }

    visible: false
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Qt.rgba(0, 0, 0, 0.45)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "savpavi-session"

    MouseArea { anchors.fill: parent; onClicked: root.visible = false }

    Item {
        id: keys
        anchors.fill: parent
        Keys.onPressed: e => {
            const n = root.entries.length;
            if (e.key === Qt.Key_Escape) root.visible = false;
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down || e.key === Qt.Key_Tab) root.current = (root.current + 1) % n;
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) root.current = (root.current - 1 + n) % n;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) root.run(root.current);
            else {
                const i = root.entries.findIndex(x => x.key === e.text.toUpperCase());
                if (i >= 0) root.run(i);
            }
            e.accepted = true;
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 16

        Repeater {
            model: root.entries

            Rectangle {
                id: tile
                required property var modelData
                required property int index
                readonly property bool selected: index === root.current

                width: 132
                height: 132
                radius: Theme.radius + 8
                color: selected ? Theme.primary : (hover.containsMouse ? Theme.bgHighest : Theme.bg)
                border.width: 1
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                scale: selected ? 1.05 : 1
                Behavior on scale { NumberAnimation { duration: Theme.animMs } }
                Behavior on color { ColorAnimation { duration: Theme.animMs } }

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: tile.modelData.icon
                        size: 40
                        color: tile.selected ? Theme.onPrimary : Theme.fg
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.label
                        color: tile.selected ? Theme.onPrimary : Theme.fg
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.key
                        font.pixelSize: Theme.fontSmall
                        color: tile.selected ? Theme.onPrimary : Theme.fgDim
                    }
                }

                // Hover only tints the tile; it never moves the keyboard selection,
                // so Enter can't hit whatever the pointer happened to rest on.
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.run(tile.index)
                }
            }
        }
    }

    IpcHandler {
        target: "session"
        function toggle(): void { root.visible ? root.visible = false : root.open(); }
    }
}
