import QtQuick
import qs.common
import qs.notifications
import qs.services

// Bell with unread count; dropdown is the notification centre (history, DND, clear).
BarButton {
    id: root
    padding: 6

    Item {
        width: 18
        height: 18
        anchors.verticalCenter: parent.verticalCenter

        Icon {
            anchors.centerIn: parent
            name: Notifs.dnd ? "notifications_off" : "notifications"
            filled: Notifs.count > 0
            color: Notifs.dnd ? Theme.fgDim : Theme.fg
        }
        Rectangle {
            visible: Notifs.count > 0 && !Notifs.dnd
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -3
            anchors.topMargin: -2
            width: 8
            height: 8
            radius: 4
            color: Theme.primary
        }
    }

    onClicked: button => button === Qt.RightButton ? ShellState.settings.dnd = !ShellState.settings.dnd : dd.toggle()

    Dropdown {
        id: dd
        anchorItem: root
        contentWidth: 380

        Column {
            width: parent.width
            spacing: 10

            Item {
                width: parent.width
                height: 30

                Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bildirimler" + (Notifs.count ? "  ·  " + Notifs.count : "")
                    font.weight: Font.DemiBold
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    BarButton {
                        active: Notifs.dnd
                        Icon { name: "do_not_disturb_on"; size: 16; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: "Rahatsız etme"; font.pixelSize: Theme.fontSmall; anchors.verticalCenter: parent.verticalCenter }
                        onClicked: ShellState.settings.dnd = !ShellState.settings.dnd
                    }
                    BarButton {
                        visible: Notifs.count > 0
                        Icon { name: "clear_all"; size: 16; anchors.verticalCenter: parent.verticalCenter }
                        Label { text: "Temizle"; font.pixelSize: Theme.fontSmall; anchors.verticalCenter: parent.verticalCenter }
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            Label {
                visible: Notifs.count === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                topPadding: 20
                bottomPadding: 20
                text: "Bildirim yok"
                color: Theme.fgDim
            }

            ListView {
                width: parent.width
                height: Math.min(contentHeight, 520)
                visible: Notifs.count > 0
                clip: true
                spacing: 8
                model: Notifs.history.slice().reverse()
                boundsBehavior: Flickable.StopAtBounds
                delegate: NotificationCard {
                    required property var modelData
                    width: ListView.view.width
                    notif: modelData
                }
            }
        }
    }
}
