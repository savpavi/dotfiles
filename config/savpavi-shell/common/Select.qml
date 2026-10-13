import QtQuick
import QtQuick.Controls as QC

// Drop-down select. options: [{ value, label, detail? }]; emits picked(value).
Item {
    id: root

    property var options: []
    property var value
    property int boxWidth: 240
    signal picked(var value)

    readonly property var currentOption: options.find(o => o.value === value) ?? null

    width: boxWidth
    height: 34

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: mouse.containsMouse || pop.opened ? Theme.bgHighest : Theme.bgHigh
        border.width: pop.opened ? 1 : 0
        border.color: Theme.primary

        Label {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: arrow.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentOption?.label ?? "—"
        }
        Icon {
            id: arrow
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            name: "expand_more"
            color: Theme.fgDim
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pop.opened ? pop.close() : pop.open()
        }
    }

    QC.Popup {
        id: pop
        y: root.height + 4
        width: root.width
        height: Math.min(list.contentHeight + 12, 320)
        padding: 6
        background: Rectangle {
            radius: Theme.radiusSmall
            color: Theme.bg
            border.width: 1
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
        }

        ListView {
            id: list
            anchors.fill: parent
            clip: true
            model: root.options
            boundsBehavior: Flickable.StopAtBounds
            delegate: MenuItem {
                required property var modelData
                width: ListView.view.width
                text: modelData.label
                detail: modelData.detail ?? ""
                checked: modelData.value === root.value
                onClicked: { pop.close(); root.picked(modelData.value); }
            }
        }
    }
}
