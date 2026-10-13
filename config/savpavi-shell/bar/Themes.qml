import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Active theme name; dropdown lists the 15 themes with palette swatches.
// Data and applying: ~/dotfiles/bin/dot-shell-theme (json / apply).
BarButton {
    id: root

    readonly property string tool: Quickshell.env("HOME") + "/dotfiles/bin/dot-shell-theme"
    property var themes: []
    readonly property var current: themes.find(t => t.active) ?? null

    function refresh() {
        if (!list.running) list.running = true;
    }

    Icon { name: "palette"; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
    Label { text: root.current?.title ?? "Tema"; anchors.verticalCenter: parent.verticalCenter }

    onClicked: dd.toggle()

    Process {
        id: list
        command: [root.tool, "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.themes = JSON.parse(text); } catch (e) { console.warn("Themes:", e); }
            }
        }
    }

    // The active theme changes when the palette does; re-read the list then
    Connections {
        target: Theme
        function onThemeIdChanged() { root.refresh(); }
    }

    Component.onCompleted: refresh()

    Dropdown {
        id: dd
        anchorItem: root
        contentWidth: 300

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: root.themes

                Rectangle {
                    id: row
                    required property var modelData
                    width: parent.width
                    height: 40
                    radius: Theme.radiusSmall
                    color: modelData.active ? Theme.primaryContainer : (mouse.containsMouse ? Theme.bgHighest : "transparent")

                    Row {
                        id: swatches
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: -5
                        Repeater {
                            model: row.modelData.colors
                            Rectangle {
                                required property string modelData
                                width: 18
                                height: 18
                                radius: 9
                                color: modelData
                                border.width: 1
                                border.color: Theme.bg
                            }
                        }
                    }

                    Label {
                        anchors.left: swatches.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.title + (row.modelData.mode === "light" ? "  ·  açık" : "")
                        font.weight: row.modelData.active ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached([root.tool, "apply", row.modelData.id]);
                            dd.close();
                        }
                    }
                }
            }
        }
    }
}
