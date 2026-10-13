import QtQuick
import Quickshell
import qs.common

// Power menu. Destructive entries ask for a second click.
BarButton {
    id: root
    padding: 6

    property string pending: ""

    Icon { name: "power_settings_new"; anchors.verticalCenter: parent.verticalCenter }

    onClicked: dd.toggle()

    function run(key, cmd, confirm) {
        if (confirm && pending !== key) {
            pending = key;
            return;
        }
        dd.close();
        Quickshell.execDetached(cmd);
    }

    Dropdown {
        id: dd
        anchorItem: root
        contentWidth: 200
        onVisibleChanged: root.pending = ""

        Column {
            width: parent.width
            spacing: 2
            MenuItem { icon: "lock"; text: "Kilitle"; onClicked: root.run("lock", ["dot-shell", "lock"], false) }
            MenuItem { icon: "bedtime"; text: root.pending === "suspend" ? "Emin misin?" : "Uyku"; onClicked: root.run("suspend", ["systemctl", "suspend"], true) }
            MenuItem { icon: "logout"; text: root.pending === "logout" ? "Emin misin?" : "Oturumu kapat"; onClicked: root.run("logout", ["uwsm", "stop"], true) }
            MenuItem { icon: "restart_alt"; text: root.pending === "reboot" ? "Emin misin?" : "Yeniden başlat"; onClicked: root.run("reboot", ["systemctl", "reboot"], true) }
            MenuItem { icon: "power_settings_new"; iconColor: Theme.error; text: root.pending === "poweroff" ? "Emin misin?" : "Kapat"; onClicked: root.run("poweroff", ["systemctl", "poweroff"], true) }
        }
    }
}
