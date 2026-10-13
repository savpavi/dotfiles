import QtQuick

// Settings line: title (+ hint) on the left, any control on the right.
Item {
    id: root

    property string title
    property string hint
    default property alias control: slot.data

    width: parent ? parent.width : 500
    height: Math.max(48, texts.implicitHeight + 16, slot.childrenRect.height + 12)

    Column {
        id: texts
        anchors.left: parent.left
        anchors.right: slot.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Label { width: parent.width; text: root.title }
        Label {
            width: parent.width
            visible: root.hint !== ""
            text: root.hint
            color: Theme.fgDim
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
        }
    }

    Item {
        id: slot
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.bgHighest
        opacity: 0.6
    }
}
