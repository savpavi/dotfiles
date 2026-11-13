// Solda dikey ray: Fener. Üstte tag'ler, ortada dikey başlık, altta durum ve saat.
import QtQuick

Item {
    id: rail
    required property var sh
    required property string output

    readonly property var b: sh.b
    readonly property var st: sh.outputs[output] ?? null
    readonly property bool selected: st ? st.active === 1 : false
    readonly property int cell: width - 16

    component Label: Text {
        color: rail.b.fg
        font.family: rail.b.font
        font.pixelSize: rail.b.fontPx
        horizontalAlignment: Text.AlignHCenter
        width: rail.width
    }

    Rectangle {
        visible: !!rail.b.line
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
        width: 1
        color: rail.b.line || "transparent"
    }

    Column {
        id: top
        anchors.top: parent.top
        anchors.topMargin: 8
        width: parent.width
        spacing: 4

        Repeater {
            model: rail.st ? rail.st.tags.length : 0

            Item {
                id: tag
                required property int index
                readonly property var t: rail.st.tags[index]
                readonly property bool active: (t.s & 1) !== 0
                readonly property bool isUrgent: (t.s & 2) !== 0

                visible: index < rail.sh.minTags || t.c > 0 || active
                width: rail.width
                height: visible ? rail.cell : 0

                Rectangle {
                    anchors.centerIn: parent
                    width: rail.cell; height: rail.cell
                    radius: 4
                    color: tag.active ? (rail.selected ? rail.b.accent : rail.b.fg)
                         : tag.isUrgent ? rail.b.urgent : "transparent"
                }
                Text {
                    anchors.centerIn: parent
                    text: tag.index + 1
                    font.family: rail.b.font
                    font.pixelSize: rail.b.fontPx
                    font.bold: tag.active
                    color: tag.active || tag.isUrgent ? rail.b.onAccent
                         : tag.t.c > 0 ? rail.b.fg : rail.b.faded
                }
                // dolu tag: sağ kenarda ince işaret
                Rectangle {
                    visible: tag.t.c > 0 && !tag.active
                    anchors { right: parent.right; rightMargin: 3; verticalCenter: parent.verticalCenter }
                    width: 2; height: 8
                    color: rail.b.accent
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: ev => rail.sh.view(rail.output, tag.index, ev.button === Qt.RightButton)
                }
            }
        }

        Label {
            topPadding: 6
            text: rail.st ? rail.st.layout : ""
            color: rail.b.faded
            font.pixelSize: rail.b.fontPx - 2
            MouseArea {
                anchors.fill: parent
                onClicked: rail.sh.cycleLayout(rail.output, rail.st ? rail.st.layout : "")
            }
        }
    }

    // Pencere başlığı, aşağıdan yukarı okunur
    Item {
        anchors { top: top.bottom; bottom: bottom.top; topMargin: 12; bottomMargin: 12 }
        width: parent.width
        clip: true
        Text {
            anchors.centerIn: parent
            rotation: -90
            width: parent.height
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: rail.st ? rail.st.title : ""
            color: rail.selected ? rail.b.title : rail.b.faded
            font.family: rail.b.font
            font.pixelSize: rail.b.fontPx - 1
        }
    }

    Column {
        id: bottom
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: parent.width
        spacing: 10

        Label {
            visible: rail.sh.hasSink
            text: rail.sh.muted ? "ses\n--" : "ses\n" + rail.sh.volume
            lineHeight: 0.95
            font.pixelSize: rail.b.fontPx - 2
            color: rail.sh.muted ? rail.b.faded : rail.b.title
            MouseArea {
                anchors.fill: parent
                onClicked: rail.sh.toggleMute()
                onWheel: ev => rail.sh.nudgeVolume(ev.angleDelta.y > 0)
            }
        }
        Label {
            text: "cpu\n" + rail.sh.cpu
            lineHeight: 0.95
            font.pixelSize: rail.b.fontPx - 2
            color: rail.sh.cpu >= 85 ? rail.b.urgent : rail.b.title
        }
        Label {
            visible: rail.sh.claude5h >= 0
            text: "cl\n" + rail.sh.claude5h + (rail.sh.claude7d >= 0 ? "\n" + rail.sh.claude7d : "")
            lineHeight: 0.95
            font.pixelSize: rail.b.fontPx - 2
            color: rail.sh.claudeMax >= 80 ? rail.b.urgent : rail.b.title
            MouseArea {
                anchors.fill: parent
                onClicked: rail.sh.togglePanel("claude", rail.output)
            }
        }
        Label {
            text: "ram\n" + rail.sh.ram
            lineHeight: 0.95
            font.pixelSize: rail.b.fontPx - 2
            color: rail.sh.ram >= 90 ? rail.b.urgent : rail.b.title
        }
        Tray {
            sh: rail.sh; output: rail.output; vertical: true
            cell: rail.cell
            anchors.horizontalCenter: parent.horizontalCenter
            fg: rail.b.title
        }
        Label {
            text: rail.sh.clockText()
            lineHeight: 0.95
            font.bold: true
            color: rail.b.clockFg
        }
    }
}
