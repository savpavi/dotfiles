// Yüzen adacıklar: Kor. Solda tag noktaları + başlık, ortada saat, sağda durum.
import QtQuick

Item {
    id: isl
    required property var sh
    required property string output

    readonly property var b: sh.b
    readonly property var st: sh.outputs[output] ?? null
    readonly property bool selected: st ? st.active === 1 : false
    readonly property int m: b.margin ?? 8
    readonly property int h: b.size

    component Pill: Rectangle {
        y: isl.m
        height: isl.h
        radius: isl.b.radius ?? isl.h / 2
        color: isl.b.bg
    }
    component Label: Text {
        color: isl.b.fg
        font.family: isl.b.font
        font.pixelSize: isl.b.fontPx
        verticalAlignment: Text.AlignVCenter
        height: isl.h
    }

    Pill {
        x: isl.m + 2
        width: leftRow.implicitWidth + 28
        Row {
            id: leftRow
            x: 14
            height: parent.height
            spacing: 8

            Repeater {
                model: isl.st ? isl.st.tags.length : 0

                Item {
                    id: tag
                    required property int index
                    readonly property var t: isl.st.tags[index]
                    readonly property bool active: (t.s & 1) !== 0
                    readonly property bool isUrgent: (t.s & 2) !== 0

                    visible: index < isl.sh.minTags || t.c > 0 || active
                    width: visible ? dot.width : 0
                    height: isl.h

                    Rectangle {
                        id: dot
                        anchors.verticalCenter: parent.verticalCenter
                        width: tag.active ? 26 : 10
                        height: 10
                        radius: 5
                        color: tag.active ? (isl.selected ? isl.b.accent : isl.b.fg)
                             : tag.isUrgent ? isl.b.urgent
                             : tag.t.c > 0 ? isl.b.faded : "transparent"
                        border.width: tag.t.c > 0 || tag.active || tag.isUrgent ? 0 : 1.5
                        border.color: isl.b.faded
                        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: ev => isl.sh.view(isl.output, tag.index, ev.button === Qt.RightButton)
                    }
                }
            }

            Label {
                visible: text !== ""
                leftPadding: 6
                width: Math.min(implicitWidth, 420)
                elide: Text.ElideRight
                text: isl.st ? isl.st.title : ""
                color: isl.selected ? isl.b.title : isl.b.faded
            }
        }
    }

    Pill {
        anchors.horizontalCenter: parent.horizontalCenter
        width: clock.implicitWidth + 32
        color: isl.b.clockBg
        Label {
            id: clock
            x: 16
            font.weight: Font.Medium
            color: isl.b.clockFg
            text: isl.sh.clockText()
        }
    }

    Pill {
        x: parent.width - width - isl.m - 2
        width: rightRow.implicitWidth + 32
        Row {
            id: rightRow
            x: 16
            height: parent.height
            spacing: 16

            Label {
                text: isl.st ? isl.st.layout : ""
                color: isl.b.faded
                font.family: "JetBrainsMono Nerd Font"
                MouseArea {
                    anchors.fill: parent
                    onClicked: isl.sh.cycleLayout(isl.output, isl.st ? isl.st.layout : "")
                }
            }
            Label {
                visible: isl.sh.hasSink
                text: isl.sh.muted ? "ses  –" : "ses  " + isl.sh.volume
                color: isl.sh.muted ? isl.b.faded : isl.b.fg
                MouseArea {
                    anchors.fill: parent
                    onClicked: isl.sh.toggleMute()
                    onWheel: ev => isl.sh.nudgeVolume(ev.angleDelta.y > 0)
                }
            }
            Label {
                text: "cpu  " + isl.sh.cpu + "%"
                color: isl.sh.cpu >= 85 ? isl.b.urgent : isl.b.accent
            }
            Label {
                visible: isl.sh.claude5h >= 0
                text: "claude  " + isl.sh.claudeText(" · ")
                color: isl.sh.claudeMax >= 80 ? isl.b.urgent : isl.b.fg
                MouseArea {
                    anchors.fill: parent
                    onClicked: isl.sh.togglePanel("claude", isl.output)
                }
            }
            Label {
                text: "ram  " + isl.sh.ram + "%"
                color: isl.sh.ram >= 90 ? isl.b.urgent : isl.b.accent
            }
            Tray { sh: isl.sh; output: isl.output; cell: isl.h }
        }
    }
}
