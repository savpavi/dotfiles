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
    property var lives: []
    property string liveQuery: ""

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
    Process {
        id: liveList
        running: true
        command: [root.tool, "lives", root.liveQuery]
        stdout: StdioCollector { onStreamFinished: { try { root.lives = JSON.parse(text); } catch (e) {} } }
    }
    // waits for typing to settle before searching the library
    Timer { id: liveSearch; interval: 300; onTriggered: { liveList.running = true; interval = 300; } }
    function setLive(id) {
        Quickshell.execDetached([tool, "live", id]);
        liveSearch.interval = 1500;  // waywallen needs a moment before the state file changes
        liveSearch.restart();
    }
    Connections {
        target: Theme
        function onThemeIdChanged() { themeList.running = true; wallList.running = true; liveList.running = true; }
        function onWallpaperChanged() { wallList.running = true; liveList.running = true; }
        function onLiveChanged() { liveList.running = true; }
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

    Item { width: 1; height: 8 }
    Label { text: "Hareketli duvar kağıdı (Wallpaper Engine)"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall }
    Label { width: parent.width; wrapMode: Text.WordWrap; elide: Text.ElideNone; color: Theme.fgDim; font.pixelSize: Theme.fontSmall
        text: "Boşken temanın hareketli duvarlarını gösterir; yazınca tüm Workshop kütüphanesinde arar. Sabit duvarı değiştirmek hareketli duvarı da temanın sırasına döndürür." }

    Row {
        width: parent.width
        spacing: 8

        Rectangle {
            width: parent.width - offBtn.width - 8
            height: 36
            radius: 18
            color: Theme.bgAlt
            Icon { id: si; name: "search"; color: Theme.fgDim; x: 12; anchors.verticalCenter: parent.verticalCenter }
            TextInput {
                anchors.left: si.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg
                font.family: Theme.sans
                font.pixelSize: Theme.fontSize
                clip: true
                onTextChanged: { root.liveQuery = text.trim(); liveSearch.restart(); }
                Label { visible: parent.text === ""; text: "Kütüphanede ara…"; color: Theme.fgDim; anchors.verticalCenter: parent.verticalCenter }
            }
        }
        BarButton {
            id: offBtn
            anchors.verticalCenter: parent.verticalCenter
            Icon { name: "hide_image"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Kapat"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: root.setLive("off")
        }
    }

    Grid {
        width: parent.width
        columns: 4
        spacing: 8

        Repeater {
            model: root.lives
            Rectangle {
                id: lc
                required property var modelData
                width: (parent.width - 24) / 4
                height: width * 9 / 16
                radius: Theme.radiusSmall
                color: Theme.bgHighest
                border.width: modelData.active ? 3 : (lm.containsMouse ? 1 : 0)
                border.color: Theme.primary
                clip: true
                opacity: modelData.item === null ? 0.5 : 1

                Image {
                    anchors.fill: parent
                    anchors.margins: parent.border.width
                    source: lc.modelData.preview ? "file://" + lc.modelData.preview : ""
                    sourceSize: Qt.size(360, 210)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: parent.border.width
                    height: lt.implicitHeight + 8
                    color: Qt.rgba(0, 0, 0, 0.55)
                    Label {
                        id: lt
                        x: 6
                        width: parent.width - 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: lc.modelData.item === null ? "İndirilmemiş · " + lc.modelData.title : lc.modelData.title
                        color: "white"
                        font.pixelSize: Theme.fontSmall
                    }
                }
                MouseArea {
                    id: lm
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: lc.modelData.item !== null
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setLive(lc.modelData.id)
                }
            }
        }
    }

    Label {
        visible: root.lives.length === 0
        width: parent.width
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        color: Theme.fgDim
        font.pixelSize: Theme.fontSmall
        text: root.liveQuery ? "Eşleşen hareketli duvar yok." : "Bu temaya hareketli duvar atanmamış."
    }
}
