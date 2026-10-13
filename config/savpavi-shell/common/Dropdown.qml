import QtQuick
import Quickshell
import Quickshell.Hyprland

// Panel that drops below a bar item. Clicking anywhere else closes it.
// Usage: Dropdown { id: dd; anchorItem: someButton; <content> }  then dd.toggle()
PopupWindow {
    id: root

    required property Item anchorItem
    default property alias content: body.data
    property int contentWidth: 300
    property int padding: 12

    function toggle() { visible = !visible; }
    function close() { visible = false; }

    anchor.item: anchorItem
    anchor.rect.y: anchorItem.height + Theme.barMargin + 2
    anchor.rect.x: (anchorItem.width - implicitWidth) / 2
    anchor.adjustment: PopupAdjustment.SlideX

    implicitWidth: contentWidth + padding * 2
    implicitHeight: body.childrenRect.height + padding * 2
    color: "transparent"
    visible: false

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.35)

        Item {
            id: body
            x: root.padding
            y: root.padding
            width: root.contentWidth
        }
    }
}
