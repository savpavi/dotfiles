import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common

// System tray. Left click activates (or opens the menu for menu-only items), right click opens the menu.
Row {
    id: root
    spacing: 2

    Repeater {
        model: SystemTray.items.values

        BarButton {
            id: btn
            required property SystemTrayItem modelData
            padding: 5

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 16
                source: {
                    // Some apps pass "name?path=/dir"; resolve those to a file
                    const s = btn.modelData.icon;
                    if (s.includes("?path=")) {
                        const [name, path] = s.split("?path=");
                        const base = name.slice(name.lastIndexOf("/") + 1);
                        // Flatpak apps report paths inside their sandbox; use the exported theme icon
                        if (path.startsWith("/app/")) return Quickshell.iconPath(base, true);
                        return "file://" + path + "/" + base;
                    }
                    return s;
                }
            }

            onClicked: button => {
                if (button === Qt.LeftButton && !btn.modelData.onlyMenu) btn.modelData.activate();
                else if (button === Qt.MiddleButton) btn.modelData.secondaryActivate();
                else if (btn.modelData.hasMenu) menu.open();
            }
            onScrolled: delta => btn.modelData.scroll(delta, false)

            QsMenuAnchor {
                id: menu
                menu: btn.modelData.menu
                anchor.item: btn
                anchor.rect.y: btn.height + Theme.barMargin + 2
                anchor.rect.height: 0
            }
        }
    }
}
