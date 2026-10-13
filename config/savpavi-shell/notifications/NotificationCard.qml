import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.common
import qs.services

// One notification: app icon or image, summary, body, action buttons.
// Click runs the default action (or dismisses); the × dismisses.
Rectangle {
    id: root

    required property Notification notif
    property bool popup: false          // popups expire on their own
    signal expired

    width: parent ? parent.width : 360
    height: content.implicitHeight + 24
    radius: Theme.radius
    color: popup ? Theme.bg : Theme.bgHigh
    border.width: notif?.urgency === NotificationUrgency.Critical ? 2 : 1
    border.color: notif?.urgency === NotificationUrgency.Critical ? Theme.error : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.25)

    Timer {
        running: root.popup && !hover.containsMouse && root.notif?.urgency !== NotificationUrgency.Critical
        interval: root.notif?.expireTimeout > 0 ? root.notif.expireTimeout * 1000 : ShellState.settings.popupSeconds * 1000
        onTriggered: root.expired()
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => {
            const def = root.notif.actions.find(a => a.identifier === "default");
            if (e.button === Qt.LeftButton && def) def.invoke();
            else root.notif.dismiss();
        }
    }

    Row {
        id: content
        x: 12
        y: 12
        width: parent.width - 24
        spacing: 12

        Item {
            width: 36
            height: 36

            Image {
                id: img
                anchors.fill: parent
                source: root.notif?.image ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                asynchronous: true
            }
            IconImage {
                anchors.fill: parent
                visible: !img.visible && source.toString() !== ""
                source: root.notif?.appIcon ? Quickshell.iconPath(root.notif.appIcon, true) : ""
            }
            Icon {
                anchors.centerIn: parent
                visible: !img.visible && !(root.notif?.appIcon)
                name: "notifications"
                size: 24
                color: Theme.primary
            }
        }

        Column {
            width: parent.width - 48
            spacing: 3

            Item {
                width: parent.width
                height: summary.implicitHeight

                Label {
                    id: summary
                    anchors.left: parent.left
                    anchors.right: close.left
                    anchors.rightMargin: 6
                    text: root.notif?.summary ?? ""
                    font.weight: Font.DemiBold
                }
                Icon {
                    id: close
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    name: "close"
                    size: 16
                    color: Theme.fgDim
                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: root.notif.dismiss() }
                }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.notif?.body ?? ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: root.popup ? 4 : 3
                elide: Text.ElideRight
                color: Theme.fgDim
                font.family: Theme.sans
                font.pixelSize: Theme.fontSize
                linkColor: Theme.primary
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Label {
                text: (root.notif?.appName ?? "")
                color: Theme.fgDim
                font.pixelSize: Theme.fontSmall
                opacity: 0.7
                visible: !root.popup && text !== ""
            }

            Flow {
                width: parent.width
                spacing: 6
                topPadding: 4
                visible: actions.count > 0

                Repeater {
                    id: actions
                    model: (root.notif?.actions ?? []).filter(a => a.identifier !== "default")
                    Rectangle {
                        required property var modelData
                        width: actLabel.implicitWidth + 20
                        height: 28
                        radius: 14
                        color: actMouse.containsMouse ? Theme.primary : Theme.bgHighest
                        Label {
                            id: actLabel
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            font.pixelSize: Theme.fontSmall
                            color: actMouse.containsMouse ? Theme.onPrimary : Theme.fg
                        }
                        MouseArea { id: actMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.invoke() }
                    }
                }
            }
        }
    }
}
