// Barın üç panel düğmesi: tema, bildirimler, güç. Bütün düzenler bunu kullanır.
import QtQuick

Grid {
    id: tray
    required property var sh
    required property string output
    property bool vertical: false
    property int cell: 28
    property color fg: sh.b.fg
    property color active: sh.b.accent

    columns: vertical ? 1 : 6
    spacing: vertical ? 4 : 0

    component Btn: Item {
        id: btn
        required property string kind
        required property string glyph
        property string badge: ""
        property bool alert: false // sorun var: simge vurgu renginde
        // "idle" panel açmaz: boşta kilitlemeyi açıp kapatır, kapalıyken vurgulu görünür
        readonly property bool open: kind === "idle" ? !tray.sh.idleEnabled
            : tray.sh.panelKind === kind && tray.sh.panelScreen === tray.output

        width: tray.vertical ? tray.cell : Math.max(tray.cell, row.implicitWidth + 14)
        height: tray.cell

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 4
            Text {
                text: btn.glyph
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: tray.sh.b.fontPx + 2
                color: btn.open || btn.alert ? tray.active : tray.fg
            }
            Text {
                visible: btn.badge !== "" && !tray.vertical
                text: btn.badge
                font.family: tray.sh.b.font
                font.pixelSize: tray.sh.b.fontPx - 1
                color: tray.active
            }
        }
        // dikey rayda sayı yerine küçük nokta
        Rectangle {
            visible: btn.badge !== "" && tray.vertical
            anchors { right: parent.right; top: parent.top; rightMargin: 3; topMargin: 3 }
            width: 5; height: 5; radius: 3
            color: tray.active
        }
        MouseArea {
            anchors.fill: parent
            onClicked: btn.kind === "idle" ? tray.sh.toggleIdle() : tray.sh.togglePanel(btn.kind, tray.output)
        }
    }

    Btn { kind: "idle"; glyph: "\u{F0176}" }
    Btn {
        kind: "drive"
        glyph: tray.sh.driveBad ? "\u{F09E0}" : tray.sh.driveBusy ? "\u{F063F}" : "\u{F0160}"
        alert: tray.sh.driveBad
    }
    Btn { kind: "send"; glyph: "\u{F09D5}"; alert: false; opacity: tray.sh.phone.reachable ? 1 : 0.55 }
    Btn { kind: "theme"; glyph: "\u{F03D8}" }
    Btn {
        kind: "notif"
        glyph: tray.sh.notifPaused ? "\u{F009B}" : "\u{F009A}"
        badge: tray.sh.notifCount > 0 ? String(tray.sh.notifCount) : ""
    }
    Btn { kind: "power"; glyph: "\u{F011}" }
}
