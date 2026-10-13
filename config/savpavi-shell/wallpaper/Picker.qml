import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common

// Wallpaper picker for the active theme: a thumbnail grid. Arrow keys move,
// Enter applies (dot-shell-theme wall N, which also picks the theme's live
// wallpaper), Esc closes.
PanelWindow {
    id: root

    readonly property string tool: Quickshell.env("HOME") + "/dotfiles/bin/dot-shell-theme"
    property var walls: []
    property int current: 0
    readonly property int columns: 4

    function open() {
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        list.running = true;
        visible = true;
        grid.forceActiveFocus();
    }

    function apply(i) {
        visible = false;
        Quickshell.execDetached([tool, "wall", String(walls[i].index)]);
    }

    visible: false
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Qt.rgba(0, 0, 0, 0.45)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "savpavi-wallpapers"

    Process {
        id: list
        command: [root.tool, "walls"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.walls = JSON.parse(text);
                    root.current = Math.max(0, root.walls.findIndex(w => w.active));
                } catch (e) {
                    root.walls = [];
                }
            }
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.visible = false }

    Rectangle {
        anchors.centerIn: parent
        width: grid.width + 32
        height: grid.height + title.height + 44
        radius: Theme.radius + 6
        color: Theme.bg
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)

        MouseArea { anchors.fill: parent }

        Label {
            id: title
            x: 16
            y: 14
            text: "Duvar kağıtları  ·  " + root.walls.length
            font.weight: Font.DemiBold
        }

        GridView {
            id: grid
            x: 16
            anchors.top: title.bottom
            anchors.topMargin: 12
            width: root.columns * cellWidth
            height: Math.min(3, Math.ceil(root.walls.length / root.columns)) * cellHeight
            cellWidth: 232
            cellHeight: 140
            clip: true
            model: root.walls
            currentIndex: root.current
            boundsBehavior: Flickable.StopAtBounds
            focus: true

            Keys.onPressed: e => {
                const n = root.walls.length;
                if (e.key === Qt.Key_Escape) root.visible = false;
                else if (e.key === Qt.Key_Right) root.current = Math.min(n - 1, root.current + 1);
                else if (e.key === Qt.Key_Left) root.current = Math.max(0, root.current - 1);
                else if (e.key === Qt.Key_Down) root.current = Math.min(n - 1, root.current + root.columns);
                else if (e.key === Qt.Key_Up) root.current = Math.max(0, root.current - root.columns);
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.apply(root.current);
                e.accepted = true;
            }

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Theme.radiusSmall + 2
                    color: Theme.bgHighest
                    border.width: cell.index === root.current ? 3 : 0
                    border.color: Theme.primary
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        source: "file://" + cell.modelData.path
                        sourceSize: Qt.size(448, 260)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Rectangle {
                        visible: cell.modelData.active
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        width: 22
                        height: 22
                        radius: 11
                        color: Theme.primary
                        Icon { anchors.centerIn: parent; name: "check"; size: 16; color: Theme.onPrimary }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = cell.index
                    onClicked: root.apply(cell.index)
                }
            }
        }
    }

    IpcHandler {
        target: "wallpapers"
        function toggle(): void { root.visible ? root.visible = false : root.open(); }
    }
}
