// Sistem tepsisi (StatusNotifierItem): Solaar, KDE Connect, Discord, Spotify...
// Sol tık: uygulamayı aç/etkinleştir, sağ tık: uygulamanın kendi menüsü.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Grid {
    id: tray
    required property var win // menünün bağlanacağı bar penceresi
    property bool vertical: false
    property int cell: 26
    property int icon: 16

    columns: vertical ? 1 : Math.max(1, SystemTray.items.values.length)
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        Item {
            id: entry
            required property var modelData
            width: tray.cell
            height: tray.cell

            IconImage {
                anchors.centerIn: parent
                implicitSize: tray.icon
                source: entry.modelData.icon
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: ev => {
                    if (ev.button === Qt.MiddleButton) {
                        entry.modelData.secondaryActivate();
                    } else if (ev.button === Qt.LeftButton && !entry.modelData.onlyMenu) {
                        entry.modelData.activate();
                    } else if (entry.modelData.hasMenu) {
                        const p = entry.mapToItem(null, 0, entry.height);
                        entry.modelData.display(tray.win, Math.round(p.x), Math.round(p.y));
                    }
                }
                onWheel: ev => entry.modelData.scroll(ev.angleDelta.y, false)
            }
        }
    }
}
