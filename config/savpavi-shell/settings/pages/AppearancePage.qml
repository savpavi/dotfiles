import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.services

Column {
    id: root

    readonly property string tool: Quickshell.env("HOME") + "/dotfiles/bin/dot-shell-theme"
    property var themes: []
    property var walls: []

    spacing: 12

    Process {
        id: themeList
        running: true
        command: [root.tool, "json"]
        stdout: StdioCollector { onStreamFinished: { try { root.themes = JSON.parse(text); } catch (e) {} } }
    }
    Process {
        id: wallList
        running: true
        command: [root.tool, "walls"]
        stdout: StdioCollector { onStreamFinished: { try { root.walls = JSON.parse(text); } catch (e) {} } }
    }
    Connections {
        target: Theme
        function onThemeIdChanged() { themeList.running = true; wallList.running = true; }
        function onWallpaperChanged() { wallList.running = true; }
    }

    Label { text: "Tema"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall }
    Label { width: parent.width; wrapMode: Text.WordWrap; elide: Text.ElideNone; color: Theme.fgDim; font.pixelSize: Theme.fontSmall
        text: "Tema; bar, kenarlıklar, imleç, duvar kağıdı ve uygulama renklerini (GTK, Qt, kitty, Zed, Vesktop, btop) birlikte değiştirir." }

    Grid {
        width: parent.width
        columns: 3
        spacing: 8

        Repeater {
            model: root.themes
            Rectangle {
                id: card
                required property var modelData
                width: (parent.width - 16) / 3
                height: 58
                radius: Theme.radius
                color: modelData.active ? Theme.primaryContainer : (cm.containsMouse ? Theme.bgHighest : Theme.bgHigh)
                border.width: modelData.active ? 2 : 0
                border.color: Theme.primary

                Row {
                    id: sw
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: -5
                    Repeater {
                        model: card.modelData.colors.slice(0, 4)
                        Rectangle {
                            required property string modelData
                            width: 16
                            height: 16
                            radius: 8
                            color: modelData
                            border.width: 1
                            border.color: Theme.bg
                        }
                    }
                }
                Column {
                    anchors.left: sw.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    Label { width: parent.width; text: card.modelData.title; font.weight: card.modelData.active ? Font.DemiBold : Font.Normal }
                    Label { width: parent.width; text: card.modelData.mode === "light" ? "açık" : "koyu"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall }
                }
                MouseArea {
                    id: cm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached([root.tool, "apply", card.modelData.id])
                }
            }
        }
    }

    Item { width: 1; height: 8 }
    Label { text: "Duvar kağıdı (aktif temanın)"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall }

    Grid {
        width: parent.width
        columns: 4
        spacing: 8

        Repeater {
            model: root.walls
            Rectangle {
                id: wc
                required property var modelData
                width: (parent.width - 24) / 4
                height: width * 9 / 16
                radius: Theme.radiusSmall
                color: Theme.bgHighest
                border.width: modelData.active ? 3 : (wm.containsMouse ? 1 : 0)
                border.color: Theme.primary
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: parent.border.width
                    source: "file://" + wc.modelData.path
                    sourceSize: Qt.size(360, 210)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                MouseArea {
                    id: wm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached([root.tool, "wall", String(wc.modelData.index)])
                }
            }
        }
    }

    Label {
        width: parent.width
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        color: Theme.fgDim
        font.pixelSize: Theme.fontSmall
        text: Theme.live ? "Bu temanın hareketli duvar kağıdı (Wallpaper Engine) açık; sabit duvar arkada bekler."
            : "Hareketli duvar kağıtları Steam Workshop indirmesi bitince temaya göre açılır."
    }
}
