import QtQuick
import QtQuick.Controls
import Quickshell
import qs.common
import qs.services

// "Sal 13 · 13:42"; click for a month calendar.
BarButton {
    id: root

    SystemClock { id: clock; precision: ShellState.settings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.locale("tr_TR").toString(clock.date, "ddd d") + "  ·  " + Qt.formatTime(clock.date, ShellState.settings.clockSeconds ? "HH:mm:ss" : "HH:mm")
        font.weight: Font.DemiBold
    }

    onClicked: dd.toggle()

    Dropdown {
        id: dd
        anchorItem: root
        contentWidth: 260

        property date shown: new Date()
        onVisibleChanged: if (visible) shown = new Date()

        Column {
            width: parent.width
            spacing: 8

            Item {
                width: parent.width
                height: 28
                BarButton {
                    anchors.left: parent.left
                    Icon { name: "chevron_left" }
                    onClicked: dd.shown = new Date(dd.shown.getFullYear(), dd.shown.getMonth() - 1, 1)
                }
                Label {
                    anchors.centerIn: parent
                    text: Qt.locale("tr_TR").toString(dd.shown, "MMMM yyyy")
                    font.weight: Font.DemiBold
                }
                BarButton {
                    anchors.right: parent.right
                    Icon { name: "chevron_right" }
                    onClicked: dd.shown = new Date(dd.shown.getFullYear(), dd.shown.getMonth() + 1, 1)
                }
            }

            DayOfWeekRow {
                width: parent.width
                locale: Qt.locale("tr_TR")
                delegate: Label {
                    required property string shortName
                    text: shortName
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.fgDim
                    font.pixelSize: Theme.fontSmall
                }
            }

            MonthGrid {
                id: grid
                width: parent.width
                month: dd.shown.getMonth()
                year: dd.shown.getFullYear()
                locale: Qt.locale("tr_TR")
                delegate: Rectangle {
                    required property var model
                    readonly property bool today: model.today
                    implicitHeight: 28
                    radius: 14
                    color: today ? Theme.primary : "transparent"
                    Label {
                        anchors.centerIn: parent
                        text: parent.model.day
                        color: parent.today ? Theme.onPrimary : (parent.model.month === grid.month ? Theme.fg : Theme.fgDim)
                        opacity: parent.model.month === grid.month ? 1 : 0.5
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }
    }
}
