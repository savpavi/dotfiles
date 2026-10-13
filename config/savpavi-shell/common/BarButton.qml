import QtQuick

// Clickable bar segment: a soft highlight on hover/active, content laid out in a row.
Item {
    id: root

    default property alias content: row.data
    property bool active: false
    property int padding: 8
    property alias spacing: row.spacing
    readonly property alias hovered: mouse.containsMouse

    signal clicked(int button)
    signal scrolled(int delta)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Theme.barHeight - 8

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: root.active ? Theme.primaryContainer : Theme.bgHighest
        opacity: root.active ? 1 : (mouse.containsMouse ? 1 : 0)
        Behavior on opacity { NumberAnimation { duration: Theme.animMs } }
        Behavior on color { ColorAnimation { duration: Theme.animMs } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => root.clicked(e.button)
        onWheel: e => root.scrolled(e.angleDelta.y)
    }
}
