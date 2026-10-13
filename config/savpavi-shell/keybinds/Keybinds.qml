import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common
import "../launcher/Search.js" as S

// Keybind cheat sheet (Super+K): read live from the Hyprland Lua config by
// scripts/keybinds.py. Type to filter, Esc closes.
PanelWindow {
    id: root

    property var binds: []
    property string filter: ""
    readonly property var cats: {
        const q = S.fold(filter);
        const groups = [];
        for (const b of binds) {
            if (q && !S.fold(b.desc + " " + b.keys.join(" ")).includes(q)) continue;
            let g = groups.find(x => x.name === b.cat);
            if (!g) groups.push(g = { name: b.cat, items: [] });
            g.items.push(b);
        }
        return groups;
    }

    function open() {
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        field.text = "";
        proc.running = true;
        visible = true;
        field.forceActiveFocus();
    }

    visible: false
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Qt.rgba(0, 0, 0, 0.45)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "savpavi-keybinds"

    Process {
        id: proc
        command: ["python3", Qt.resolvedUrl("../scripts/keybinds.py").toString().replace("file://", "")]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.binds = JSON.parse(text); } catch (e) { root.binds = []; }
            }
        }
    }

    MouseArea { anchors.fill: parent; onClicked: root.visible = false }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1180)
        height: Math.min(parent.height - 120, header.height + flick.contentHeight + 40)
        radius: Theme.radius + 6
        color: Theme.bg
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)

        MouseArea { anchors.fill: parent }

        Item {
            id: header
            x: 20
            y: 16
            width: parent.width - 40
            height: 40

            Label {
                id: title
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Kısayollar"
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 300
                height: 34
                radius: 17
                color: Theme.bgAlt

                Icon {
                    id: si
                    name: "search"
                    color: Theme.fgDim
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
                TextInput {
                    id: field
                    anchors.left: si.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fg
                    font.family: Theme.sans
                    font.pixelSize: Theme.fontSize
                    clip: true
                    onTextChanged: root.filter = text
                    Keys.onEscapePressed: root.visible = false
                    Label {
                        visible: field.text === ""
                        text: "Kısayol ya da tuş ara…"
                        color: Theme.fgDim
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        Flickable {
            id: flick
            x: 20
            anchors.top: header.bottom
            anchors.topMargin: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            width: parent.width - 40
            contentHeight: flow.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // Masonry-ish: three columns, each category card goes to the shortest column
            Row {
                id: flow
                width: parent.width
                spacing: 14

                Repeater {
                    model: 3
                    Column {
                        id: col
                        required property int index
                        width: (flow.width - 28) / 3
                        spacing: 14

                        Repeater {
                            model: {
                                // distribute by running row count
                                const cols = [[], [], []], h = [0, 0, 0];
                                for (const g of root.cats) {
                                    const i = h.indexOf(Math.min(...h));
                                    cols[i].push(g);
                                    h[i] += g.items.length + 2;
                                }
                                return cols[col.index];
                            }

                            Rectangle {
                                id: card
                                required property var modelData
                                width: col.width
                                height: inner.implicitHeight + 20
                                radius: Theme.radius
                                color: Theme.bgAlt

                                Column {
                                    id: inner
                                    x: 12
                                    y: 10
                                    width: parent.width - 24
                                    spacing: 6

                                    Label {
                                        text: card.modelData.name
                                        color: Theme.primary
                                        font.weight: Font.DemiBold
                                        bottomPadding: 2
                                    }

                                    Repeater {
                                        model: card.modelData.items
                                        Item {
                                            id: line
                                            required property var modelData
                                            width: inner.width
                                            height: Math.max(keyRow.height, desc.implicitHeight)

                                            Row {
                                                id: keyRow
                                                spacing: 3
                                                Repeater {
                                                    model: line.modelData.keys
                                                    Rectangle {
                                                        required property string modelData
                                                        width: Math.max(22, k.implicitWidth + 10)
                                                        height: 22
                                                        radius: 5
                                                        color: Theme.bgHighest
                                                        Label {
                                                            id: k
                                                            anchors.centerIn: parent
                                                            text: parent.modelData
                                                            font.family: Theme.mono
                                                            font.pixelSize: Theme.fontSmall
                                                        }
                                                    }
                                                }
                                            }

                                            Label {
                                                id: desc
                                                anchors.left: keyRow.right
                                                anchors.leftMargin: 10
                                                anchors.right: parent.right
                                                anchors.verticalCenter: keyRow.verticalCenter
                                                text: line.modelData.desc
                                                color: Theme.fgDim
                                                font.pixelSize: Theme.fontSmall
                                                wrapMode: Text.WordWrap
                                                elide: Text.ElideNone
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "keybinds"
        function toggle(): void { root.visible ? root.visible = false : root.open(); }
    }
}
