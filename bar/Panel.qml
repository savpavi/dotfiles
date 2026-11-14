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
    readonly property int wantW: kind === "notif" ? 380 : kind === "drive" || kind === "send" || kind === "net" ? 320 : 260
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

            // --- Claude kullanımı ---
            Item {
                visible: pop.kind === "claude"
                width: body.width
                height: pop.rowH
                Label {
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    text: "Claude kullanımı"
                    font.bold: true
                }
            }
            Repeater {
                model: pop.kind === "claude" && pop.sh.claude ? [
                    { label: "5 saatlik", block: pop.sh.claude.five_hour },
                    { label: "7 günlük", block: pop.sh.claude.seven_day }
                ].filter(r => r.block) : []
                Item {
                    id: lim
                    required property var modelData
                    width: body.width
                    height: 46
                    Label {
                        id: limName
                        x: 8; y: 4
                        text: lim.modelData.label
                    }
                    Label {
                        anchors { right: parent.right; rightMargin: 8 }
                        y: 4
                        text: "%" + lim.modelData.block.used_percentage
                        font.bold: true
                        color: lim.modelData.block.used_percentage >= 80 ? pop.m.match : pop.m.text
                    }
                    Rectangle {
                        x: 8; y: 25
                        width: parent.width - 16; height: 4
                        color: "transparent"
                        border.width: 1
                        border.color: pop.m.border
                        Rectangle {
                            width: parent.width * Math.min(100, lim.modelData.block.used_percentage) / 100
                            height: parent.height
                            color: lim.modelData.block.used_percentage >= 80 ? pop.m.match : pop.m.text
                        }
                    }
                    Label {
                        x: 8; y: 31
                        font.pixelSize: 11
                        opacity: 0.7
                        text: "sıfırlanma: " + pop.sh.resetText(lim.modelData.block)
                    }
                }
            }
            Label {
                visible: pop.kind === "claude" && !pop.sh.claude
                width: body.width
                height: pop.rowH
                leftPadding: 8
                verticalAlignment: Text.AlignVCenter
                text: "Veri alınamadı"
                opacity: 0.6
            }

            // --- Ağ ---
            Item {
                visible: pop.kind === "net"
                width: body.width
                height: pop.rowH
                Label {
                    anchors { left: parent.left; leftMargin: 8; right: netState.left; rightMargin: 6
                              verticalCenter: parent.verticalCenter }
                    text: pop.sh.net.name !== "" ? pop.sh.net.name : "Ağ"
                    font.bold: true
                }
                Label {
                    id: netState
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    color: pop.m.match
                    text: pop.sh.net.type === "ethernet" ? "kablolu" : pop.sh.net.type === "wifi" ? "kablosuz" : "bağlı değil"
                }
            }
            Repeater {
                model: pop.kind === "net" ? [
                    { k: "IP", v: pop.sh.net.ip !== "" ? pop.sh.net.ip : "yok" },
                    { k: "Tailscale", v: pop.sh.net.tailscale === "Running" ? "açık"
                        : pop.sh.net.tailscale === "" ? "bilinmiyor" : "kapalı" }
                ] : []
                Item {
                    id: netRow
                    required property var modelData
                    width: body.width
                    height: 24
                    Label {
                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        text: netRow.modelData.k
                        font.pixelSize: 12
                        opacity: 0.8
                    }
                    Label {
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        text: netRow.modelData.v
                        font.pixelSize: 12
                    }
                }
            }

            // --- Google Drive ---
            Item {
                visible: pop.kind === "drive"
                width: body.width
                height: pop.rowH
                Label {
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    text: "Google Drive"
                    font.bold: true
                }
                Label {
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    color: pop.m.match
                    text: !pop.sh.drive.active ? "kapalı"
                        : !pop.sh.drive.mounted ? "bağlı değil"
                        : pop.sh.drive.errored > 0 ? pop.sh.drive.errored + " hata"
                        : pop.sh.drive.uploading + pop.sh.drive.queued > 0
                            ? (pop.sh.drive.uploading + pop.sh.drive.queued) + " yükleniyor"
                        : "güncel"
                }
            }
            Repeater {
                model: pop.kind === "drive" ? pop.sh.drive.syncs : []
                Item {
                    id: syncRow
                    required property var modelData
                    width: body.width
                    height: 24
                    Label {
                        anchors { left: parent.left; leftMargin: 8; right: syncState.left; rightMargin: 6
                                  verticalCenter: parent.verticalCenter }
                        text: "senkron: " + syncRow.modelData.name
                        font.pixelSize: 12
                        opacity: 0.8
                    }
                    Label {
                        id: syncState
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        font.pixelSize: 12
                        color: pop.m.match
                        text: syncRow.modelData.state === "running" ? "sürüyor"
                            : syncRow.modelData.state === "error" ? "hata"
                            : syncRow.modelData.lastOk
                                ? Qt.formatTime(new Date(syncRow.modelData.lastOk * 1000), "HH:mm") + " tamam"
                            : syncRow.modelData.state
                    }
                }
            }
            Label {
                visible: pop.kind === "drive" && pop.sh.drive.lastError !== ""
                width: body.width
                leftPadding: 8
                rightPadding: 8
                wrapMode: Text.Wrap
                maximumLineCount: 3
                font.pixelSize: 12
                text: pop.sh.drive.lastError
                color: pop.m.match
            }
            Rule { visible: pop.kind === "drive" }
            Entry {
                visible: pop.kind === "drive"
                text: "Klasörü aç"
                onActivated: { pop.sh.closePanel(); pop.sh.driveCmd(["open"]); }
            }
            Entry {
                visible: pop.kind === "drive"
                text: "Web'de aç"
                onActivated: { pop.sh.closePanel(); pop.sh.driveCmd(["web"]); }
            }
            Entry {
                visible: pop.kind === "drive"
                text: "Şimdi senkronla"
                onActivated: pop.sh.driveCmd(["sync"])
            }
            Entry {
                visible: pop.kind === "drive"
                text: "Bağlantıyı yenile"
                onActivated: pop.sh.driveCmd(["restart"])
            }

            // --- Telefona gönder ---
            Item {
                visible: pop.kind === "send"
                width: body.width
                height: pop.rowH
                Label {
                    anchors { left: parent.left; leftMargin: 8; right: phoneState.left; rightMargin: 6
                              verticalCenter: parent.verticalCenter }
                    text: pop.sh.phone.device !== "" ? pop.sh.phone.device : "Telefon"
                    font.bold: true
                }
                Label {
                    id: phoneState
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    color: pop.m.match
                    text: pop.sh.phone.reachable ? "bağlı" : pop.sh.phone.paired ? "ulaşılamıyor" : "eşleşmemiş"
                }
            }
            Rule { visible: pop.kind === "send" }
            Entry {
                visible: pop.kind === "send"
                text: "Dosya gönder (KDE Connect)"
                onActivated: pop.sh.sendCmd([])
            }
            Entry {
                visible: pop.kind === "send"
                text: "LocalSend'i aç"
                onActivated: pop.sh.sendCmd(["localsend"])
            }

            // --- Güç ---
            Entry {
                visible: pop.kind === "power"
                text: "Kilitle"
                onActivated: pop.sh.lockNow()
            }
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
                        if (pop.armed === index) {
                            pop.sh.closePanel();
                            Quickshell.execDetached(modelData.cmd);
                        }
                        else
                            pop.armed = index;
                    }
                }
            }
        }
    }
}
