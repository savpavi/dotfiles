import QtQuick

// Settings row: title + optional hint on the left, a switch on the right.
Item {
    id: root

    property string title
    property string hint
    property bool checked: false
    signal toggled(bool value)

    width: parent ? parent.width : 400
    height: Math.max(44, texts.implicitHeight + 16)

    Column {
        id: texts
        anchors.left: parent.left
        anchors.right: knob.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Label { width: parent.width; text: root.title }
        Label { width: parent.width; visible: root.hint !== ""; text: root.hint; color: Theme.fgDim; font.pixelSize: Theme.fontSmall; wrapMode: Text.WordWrap; elide: Text.ElideNone }
    }

    Rectangle {
        id: knob
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 24
        radius: 12
        color: root.checked ? Theme.primary : Theme.bgHighest
        Behavior on color { ColorAnimation { duration: Theme.animMs } }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.onPrimary : Theme.fg
            Behavior on x { NumberAnimation { duration: Theme.animMs; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
