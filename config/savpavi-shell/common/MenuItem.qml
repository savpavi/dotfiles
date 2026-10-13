import QtQuick

// One row in a Dropdown: icon, text, optional trailing text.
Rectangle {
    id: root

    property string icon
    property string text
    property string detail
    property bool checked: false
    property color iconColor: Theme.fg

    signal clicked(int button)

    width: parent ? parent.width : 200
    height: 34
    radius: Theme.radiusSmall
    color: checked ? Theme.primaryContainer : (mouse.containsMouse ? Theme.bgHighest : "transparent")
    Behavior on color { ColorAnimation { duration: Theme.animMs } }

    Icon {
        id: ic
        name: root.icon
        visible: root.icon !== ""
        color: root.iconColor
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    Label {
        text: root.text
        anchors.left: ic.visible ? ic.right : parent.left
        anchors.leftMargin: 10
        anchors.right: det.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }

    Label {
        id: det
        text: root.detail
        color: Theme.fgDim
        font.pixelSize: Theme.fontSmall
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
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
