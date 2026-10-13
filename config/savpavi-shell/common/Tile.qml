import QtQuick

// Quick-settings tile: icon + title + state line; accent fill when on.
Rectangle {
    id: root

    property string icon
    property string title
    property string detail
    property bool on: false

    signal clicked(int button)

    height: 54
    radius: Theme.radius
    color: on ? Theme.primary : (mouse.containsMouse ? Theme.bgHighest : Theme.bgHigh)
    Behavior on color { ColorAnimation { duration: Theme.animMs } }

    Icon {
        id: ic
        name: root.icon
        size: 20
        filled: root.on
        color: root.on ? Theme.onPrimary : Theme.fg
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    Column {
        anchors.left: ic.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        Label {
            width: parent.width
            text: root.title
            font.weight: Font.DemiBold
            color: root.on ? Theme.onPrimary : Theme.fg
        }
        Label {
            width: parent.width
            visible: text !== ""
            text: root.detail
            font.pixelSize: Theme.fontSmall
            color: root.on ? Qt.rgba(Theme.onPrimary.r, Theme.onPrimary.g, Theme.onPrimary.b, 0.75) : Theme.fgDim
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => root.clicked(e.button)
    }
}
