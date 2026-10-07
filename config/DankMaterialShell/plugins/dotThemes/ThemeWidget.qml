import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Bar'da aktif tema; tıklayınca 15 DWM temasının listesi.
// Veri ve uygulama: ~/dotfiles/bin/dot-dms-theme (json / apply / wall).
PluginComponent {
    id: root

    layerNamespacePlugin: "dot-themes"

    readonly property string tool: Quickshell.env("HOME") + "/dotfiles/bin/dot-dms-theme"
    property var themes: []
    readonly property var active: themes.find(t => t.active) || null

    function refresh() {
        if (!listProc.running)
            listProc.running = true;
    }

    function applyTheme(id) {
        Quickshell.execDetached([tool, "apply", id]);
        refreshTimer.restart();
    }

    Process {
        id: listProc
        command: [root.tool, "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.themes = JSON.parse(text);
                } catch (e) {
                    console.warn("dotThemes: json okunamadı:", e);
                }
            }
        }
    }

    // apply arka planda imleci de ayarlıyor; birkaç saniye sonra durumu tazele
    Timer {
        id: refreshTimer
        interval: 2500
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "palette"
                size: Theme.iconSize - 6
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.active ? root.active.title : "Tema"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "palette"
            size: Theme.iconSize - 6
            color: Theme.primary
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "Temalar"
            detailsText: "Palet, duvar kağıdı ve imleç birlikte değişir"
            showCloseButton: true

            Component.onCompleted: root.refresh()

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - popout.headerHeight - popout.detailsHeight - Theme.spacingXL

                DankListView {
                    anchors.fill: parent
                    clip: true
                    spacing: Theme.spacingXS
                    model: root.themes

                    delegate: StyledRect {
                        required property var modelData
                        width: ListView.view.width
                        height: 52
                        radius: Theme.cornerRadius
                        color: modelData.active ? Theme.primaryContainer : (rowMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                        // palet önizlemesi
                        Row {
                            id: swatches
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: -6

                            Repeater {
                                model: modelData.colors
                                Rectangle {
                                    required property string modelData
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: modelData
                                    border.width: 1
                                    border.color: Theme.outline
                                }
                            }
                        }

                        Column {
                            anchors.left: swatches.right
                            anchors.leftMargin: Theme.spacingM
                            anchors.right: check.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                text: modelData.title + (modelData.mode === "light" ? "  ·  açık" : "")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: modelData.active ? Font.Bold : Font.Normal
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            StyledText {
                                text: modelData.cursor
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        DankIcon {
                            id: check
                            name: "check"
                            size: Theme.iconSize - 4
                            color: Theme.primary
                            visible: modelData.active
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.applyTheme(modelData.id);
                                popout.closePopout();
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 380
    popoutHeight: 620
}
