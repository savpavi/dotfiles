// Düz şerit: Mürekkep ve Birim 01. Blok tag'ler, başlık, sağda durum hücreleri.
import QtQuick

Item {
    id: strip
    required property var sh
    required property string output
    required property var win

    readonly property var b: sh.b
    readonly property var st: sh.outputs[output] ?? null
    readonly property bool selected: st ? st.active === 1 : false
    readonly property int lineH: b.line ? 2 : 0
    readonly property int cellH: height - lineH

    component Cell: Text {
        color: strip.b.fg
        font.family: strip.b.font
        font.pixelSize: strip.b.fontPx
        height: strip.cellH
        verticalAlignment: Text.AlignVCenter
        leftPadding: 10
        rightPadding: 10
    }

    Rectangle {
        visible: strip.lineH > 0
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: strip.lineH
        color: strip.b.line || "transparent"
    }

    Row {
        id: left
        anchors.left: parent.left
        height: strip.cellH

        Repeater {
            model: strip.st ? strip.st.tags.length : 0

            Rectangle {
                id: tag
                required property int index
                readonly property var t: strip.st.tags[index]
                readonly property bool active: (t.s & 1) !== 0
                readonly property bool isUrgent: (t.s & 2) !== 0
                readonly property color ink: active ? (strip.selected ? strip.b.onAccent : strip.b.bg)
                    : t.c > 0 || isUrgent ? strip.b.fg : strip.b.faded

                visible: index < strip.sh.minTags || t.c > 0 || active
                width: visible ? strip.cellH + (strip.b.zeroPad ? 8 : 2) : 0
                height: strip.cellH
                color: active ? (strip.selected ? strip.b.accent : strip.b.fg)
                     : isUrgent ? strip.b.urgent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: strip.b.zeroPad ? String(tag.index + 1).padStart(2, "0") : tag.index + 1
                    font.family: strip.b.font
                    font.pixelSize: strip.b.fontPx
                    font.bold: tag.active
                    color: tag.ink
                }
                // dwm usulü doluluk işareti: sol üstte küçük kare
                Rectangle {
                    visible: tag.t.c > 0
                    x: 3; y: 3; width: 5; height: 5
                    color: tag.t.f ? tag.ink : "transparent"
                    border.width: 1
                    border.color: tag.ink
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: ev => strip.sh.view(strip.output, tag.index, ev.button === Qt.RightButton)
                }
            }
        }

        Cell {
            text: strip.st ? strip.st.layout : ""
            color: strip.b.line || strip.b.faded
            MouseArea {
                anchors.fill: parent
                onClicked: strip.sh.cycleLayout(strip.output, strip.st ? strip.st.layout : "")
            }
        }
    }

    Cell {
        anchors.left: left.right
        anchors.right: right.left
        leftPadding: 4
        elide: Text.ElideRight
        text: strip.st ? strip.st.title : ""
        color: strip.selected ? strip.b.title : strip.b.faded
    }

    Row {
        id: right
        anchors.right: parent.right
        height: strip.cellH

        Media { sh: strip.sh; height: strip.cellH; fg: strip.b.fg; dim: strip.b.faded }
        Cell {
            visible: strip.sh.hasSink
            text: strip.sh.muted ? "ses --" : "ses " + strip.sh.volume
            color: strip.sh.muted ? strip.b.faded : strip.b.fg
            MouseArea {
                anchors.fill: parent
                onClicked: strip.sh.toggleMute()
                onWheel: ev => strip.sh.nudgeVolume(ev.angleDelta.y > 0)
            }
        }
        Cell {
            text: "cpu " + strip.sh.cpu + "%"
            color: strip.sh.cpu >= 85 ? strip.b.accent : strip.b.fg
        }
        Cell {
            visible: strip.sh.claude5h >= 0
            text: "claude " + strip.sh.claudeText(" · ")
            color: strip.sh.claudeMax >= 80 ? strip.b.accent : strip.b.fg
            MouseArea {
                anchors.fill: parent
                onClicked: strip.sh.togglePanel("claude", strip.output)
            }
        }
        Cell {
            text: "ram " + strip.sh.ram + "%"
            color: strip.sh.ram >= 90 ? strip.b.accent : strip.b.fg
        }
        Cell {
            visible: strip.sh.kb !== ""
            text: strip.sh.kb
            color: strip.sh.kb === "tr" ? strip.b.fg : strip.b.accent
        }
        SysTray { win: strip.win; cell: strip.cellH }
        Tray { sh: strip.sh; output: strip.output; cell: strip.cellH }
        Rectangle {
            height: strip.cellH
            width: clockText.implicitWidth
            color: strip.b.clockBg
            Cell {
                id: clockText
                color: strip.b.clockFg
                text: strip.sh.clockText()
            }
        }
    }
}
