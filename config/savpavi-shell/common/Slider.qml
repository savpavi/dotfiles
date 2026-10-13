import QtQuick

// Horizontal slider with an icon. value is 0..1; emits moved(v) while dragging or scrolling.
Item {
    id: root

    property real value: 0
    property string icon
    property bool muted: false

    signal moved(real v)
    signal iconClicked

    implicitHeight: 36

    Icon {
        id: ic
        name: root.icon
        size: 20
        color: root.muted ? Theme.fgDim : Theme.fg
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.iconClicked() }
    }

    Item {
        id: track
        anchors.left: ic.right
        anchors.leftMargin: 12
        anchors.right: pct.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 22

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.bgHighest
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(6, parent.width * Math.min(1, root.value))
            height: 6
            radius: 3
            color: root.muted ? Theme.fgDim : Theme.primary
        }
        Rectangle {
            x: Math.max(0, Math.min(parent.width - width, parent.width * Math.min(1, root.value) - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: root.muted ? Theme.fgDim : Theme.primary
            border.width: 3
            border.color: Theme.bg
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function set(x) { root.moved(Math.max(0, Math.min(1, x / width))); }
            onPressed: e => set(e.x)
            onPositionChanged: e => { if (pressed) set(e.x); }
            onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    Label {
        id: pct
        width: 36
        horizontalAlignment: Text.AlignRight
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.value * 100) + "%"
        font.pixelSize: Theme.fontSmall
        color: Theme.fgDim
    }
}
