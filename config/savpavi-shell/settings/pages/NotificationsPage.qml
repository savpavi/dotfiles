import QtQuick
import Quickshell
import qs.common
import qs.services

Column {
    readonly property var cfg: ShellState.settings
    spacing: 0

    Toggle {
        title: "Rahatsız etme"
        hint: "Açılır bildirimleri gizler; kritik olanlar yine görünür. Bardaki zile sağ tık da açar/kapatır."
        checked: cfg.dnd
        onToggled: v => cfg.dnd = v
    }
    SettingRow {
        title: "Açılır bildirim süresi"
        hint: "Uygulama kendi süresini vermediyse"
        Select {
            boxWidth: 140
            value: cfg.popupSeconds
            options: [4, 6, 10, 15, 30].map(v => ({ value: v, label: v + " saniye" }))
            onPicked: v => cfg.popupSeconds = v
        }
    }
    SettingRow {
        title: "Bildirim geçmişi"
        hint: Notifs.count + " bildirim (shell yeniden başlayınca sıfırlanır)"
        BarButton {
            Icon { name: "clear_all"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Temizle"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: Notifs.clearAll()
        }
    }
    SettingRow {
        title: "Deneme"
        BarButton {
            Icon { name: "send"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Deneme bildirimi gönder"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: Quickshell.execDetached(["notify-send", "-a", "savpavi-shell", "Deneme", "Bildirimler çalışıyor."])
        }
    }
}
