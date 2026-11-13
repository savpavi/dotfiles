// Bardan açılan panel: tema seçici, bildirim merkezi ya da güç menüsü.
// Aynı anda yalnız biri açıktır; fare panelden çıkınca kendiliğinden kapanır.
import QtQuick
import Quickshell

PopupWindow {
    id: pop
    required property var sh
    required property var win
    required property string output
    property bool rail: false

    readonly property var m: sh.m
    readonly property string kind: sh.panelKind
    readonly property int pad: 10
    readonly property int rowH: 30
    property int armed: -1 // güç menüsünde onay bekleyen satır

    anchor.window: win
    anchor.rect.x: rail ? win.width + 6 : win.width - implicitWidth - 8
    anchor.rect.y: rail ? win.height - implicitHeight - 8 : win.height + 6
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right

    // Açıkken boyutu değişen popup bozuk çiziliyor (dwl/wlroots); bu yüzden içerik
    // her değiştiğinde popup kapanır, yeni boyutu alır ve yeniden açılır.
    readonly property bool wanted: kind !== "" && sh.panelScreen === output
    readonly property int wantW: kind === "notif" ? 380 : 260
    readonly property int wantH: body.implicitHeight + 2 * pad
    property bool settled: false
    property int w: 260
    property int h: 100

    visible: wanted && settled
    color: "transparent"
    implicitWidth: w
    implicitHeight: h

    function resettle() {
        if (wanted && settled && w === wantW && h === wantH)
            return;
        settled = false;
        settle.restart();
    }
    onWantedChanged: { armed = -1; Qt.callLater(resettle); }
    onKindChanged: { armed = -1; Qt.callLater(resettle); }
    onWantWChanged: Qt.callLater(resettle)
    onWantHChanged: Qt.callLater(resettle)
    Timer {
        id: settle
        interval: 40
        onTriggered: {
            pop.w = pop.wantW;
            pop.h = pop.wantH;
            pop.settled = pop.wanted;
        }
    }

    component Label: Text {
        color: pop.m.text
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        elide: Text.ElideRight
    }
    component Entry: Rectangle {
        id: entry
        property string text: ""
        property string hint: ""
        property bool marked: false
        property color swatch: "transparent"
        signal activated()

        width: body.width
        height: pop.rowH
        radius: Math.min(pop.m.radius, 8)
        color: hover.hovered ? pop.m.selBg : "transparent"

        Rectangle {
            id: sw
            visible: entry.swatch.a > 0
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            width: 10; height: 10
            color: entry.swatch
            border.width: 1
            border.color: hover.hovered ? pop.m.selText : pop.m.text
        }
        Label {
            anchors { left: sw.visible ? sw.right : parent.left; leftMargin: 8; right: tail.left; rightMargin: 6
                      verticalCenter: parent.verticalCenter }
            text: entry.text
            font.bold: entry.marked
            color: hover.hovered ? pop.m.selText : pop.m.text
        }
        Label {
            id: tail
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: entry.hint
            color: hover.hovered ? pop.m.selText : pop.m.match
        }
        HoverHandler { id: hover }
        TapHandler { onTapped: entry.activated() }
    }
    component Rule: Rectangle {
        width: body.width
        height: 1
        color: pop.m.border
        opacity: 0.5
    }

    Rectangle {
        anchors.fill: parent
        color: pop.m.bg
        border.width: pop.m.borderpx
        border.color: pop.m.border
        radius: pop.m.radius

        HoverHandler {
            id: inside
            onHoveredChanged: hovered ? leave.stop() : leave.restart()
        }
        Timer { id: leave; interval: 900; onTriggered: pop.sh.closePanel() }

        Column {
            id: body
            x: pop.pad
            y: pop.pad
            width: parent.width - 2 * pop.pad
            spacing: 2

            // --- Tema ---
            Repeater {
                model: pop.kind === "theme" ? pop.sh.themeData.themes : []
                Entry {
                    required property var modelData
                    text: modelData.name
                    marked: modelData.active
                    hint: modelData.active ? "etkin" : ""
                    swatch: modelData.accent
                    onActivated: pop.sh.applyTheme(modelData.id)
                }
            }
            Rule { visible: pop.kind === "theme" }
            Entry {
                visible: pop.kind === "theme"
                text: "Duvar kağıdı: sonraki"
                onActivated: pop.sh.wall("next")
            }
            Entry {
                visible: pop.kind === "theme"
                text: pop.sh.themeData.wallOff ? "Hareketli duvarı aç" : "Hareketli duvarı kapat"
                onActivated: pop.sh.wall("toggle")
            }

            // --- Bildirimler ---
            Item {
                visible: pop.kind === "notif"
                width: body.width
                height: pop.rowH
                Label {
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    text: "Bildirimler"
                    font.bold: true
                }
                Label {
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    text: pop.sh.notifs.length ? pop.sh.notifs.length + " kayıt" : ""
                    color: pop.m.match
                }
            }
            Repeater {
                model: pop.kind === "notif" ? pop.sh.notifs : []
                Rectangle {
                    id: note
                    required property var modelData
                    width: body.width
                    height: noteCol.implicitHeight + 12
                    radius: Math.min(pop.m.radius, 8)
                    color: noteHover.hovered ? pop.m.selBg : "transparent"

                    Column {
                        id: noteCol
                        x: 8; y: 6
                        width: parent.width - 16
                        spacing: 1
                        Label {
                            width: parent.width
                            text: note.modelData.summary
                            font.bold: true
                            color: noteHover.hovered ? pop.m.selText : pop.m.text
                        }
                        Label {
                            visible: text !== ""
                            width: parent.width
                            text: note.modelData.body
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            font.pixelSize: 12
                            color: noteHover.hovered ? pop.m.selText : pop.m.text
                            opacity: 0.8
                        }
                        Label {
                            width: parent.width
                            text: note.modelData.app
                            font.pixelSize: 11
                            color: noteHover.hovered ? pop.m.selText : pop.m.match
                        }
                    }
                    HoverHandler { id: noteHover }
                    TapHandler { onTapped: pop.sh.removeNotif(note.modelData.id) }
                }
            }
            Label {
                visible: pop.kind === "notif" && pop.sh.notifs.length === 0
                width: body.width
                height: pop.rowH
                leftPadding: 8
                verticalAlignment: Text.AlignVCenter
                text: "Bildirim yok"
                opacity: 0.6
            }
            Rule { visible: pop.kind === "notif" }
            Entry {
                visible: pop.kind === "notif"
                text: pop.sh.notifPaused ? "Sessiz modu kapat" : "Sessiz mod"
                hint: pop.sh.notifPaused ? "açık" : ""
                onActivated: pop.sh.toggleNotifPause()
            }
            Entry {
                visible: pop.kind === "notif" && pop.sh.notifs.length > 0
                text: "Tümünü temizle"
                onActivated: pop.sh.clearNotifs()
            }

            // --- Güç ---
            Repeater {
                model: pop.kind === "power" ? [
                    { label: "Oturumu kapat", cmd: ["pkill", "-TERM", "-x", "dwl"] },
                    { label: "Yeniden başlat", cmd: ["systemctl", "reboot"] },
                    { label: "Bilgisayarı kapat", cmd: ["systemctl", "poweroff"] }
                ] : []
                Entry {
                    required property var modelData
                    required property int index
                    text: pop.armed === index ? "Emin misin? Tekrar tıkla" : modelData.label
                    marked: pop.armed === index
                    onActivated: {
                        if (pop.armed === index)
                            Quickshell.execDetached(modelData.cmd);
                        else
                            pop.armed = index;
                    }
                }
            }
        }
    }
}
