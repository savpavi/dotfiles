import QtQuick
import Quickshell
import qs.common

Column {
    spacing: 0

    SettingRow {
        title: "Kaynak"
        hint: Quickshell.shellDir
        BarButton {
            Icon { name: "folder_open"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Klasörü aç"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: Quickshell.execDetached(["thunar", Quickshell.shellDir])
        }
    }
    SettingRow {
        title: "Ayar dosyası"
        hint: "~/.config/savpavi-shell/settings.json"
        BarButton {
            Icon { name: "edit_note"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Düzenle"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/.config/savpavi-shell/settings.json"])
        }
    }
    SettingRow {
        title: "Shell'i yeniden başlat"
        hint: "savpavi-shell.service; bildirim geçmişi sıfırlanır"
        BarButton {
            Icon { name: "restart_alt"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Yeniden başlat"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: Quickshell.execDetached(["systemctl", "--user", "restart", "savpavi-shell.service"])
        }
    }
    SettingRow {
        title: "Launcher geçmişi"
        hint: "Sık açılan uygulamaların sırası"
        BarButton {
            Icon { name: "history"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Sıfırla"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: Quickshell.execDetached(["sh", "-c", "printf '{}' > \"$HOME/.local/state/savpavi-shell/launcher.json\""])
        }
    }
    SettingRow {
        title: "Yedek shell"
        hint: "DankMaterialShell'e geçer; dönmek için onun ayarlarından ya da `dot-shell switch`"
        BarButton {
            Icon { name: "swap_horiz"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "DMS'e geç"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: Quickshell.execDetached(["dot-shell", "switch"])
        }
    }
}
