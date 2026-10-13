import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.common
import qs.services

Column {
    readonly property var cfg: ShellState.settings
    spacing: 0

    SettingRow {
        title: "Güç profili"
        Select {
            boxWidth: 200
            options: [{ value: PowerProfile.PowerSaver, label: "Tasarruf" }, { value: PowerProfile.Balanced, label: "Dengeli" }]
                .concat(PowerProfiles.hasPerformanceProfile ? [{ value: PowerProfile.Performance, label: "Performans" }] : [])
            value: PowerProfiles.profile
            onPicked: v => PowerProfiles.profile = v
        }
    }
    SettingRow {
        title: "Boşta kalınca kilitle"
        hint: "hypridle; uyku öncesi her zaman kilitlenir"
        Select {
            boxWidth: 200
            options: [0, 300, 600, 900, 1800, 3600].map(v => ({ value: v, label: v === 0 ? "Asla" : (v / 60) + " dakika" }))
            value: HyprSettings.data?.idle ?? 600
            onPicked: v => HyprSettings.idleSet(v)
        }
    }
    Toggle {
        title: "Uyanık kal"
        hint: "Açıkken ekran kararmaz ve kilitlenmez (bardaki kahve düğmesi)"
        checked: cfg.idleInhibit
        onToggled: v => cfg.idleInhibit = v
    }

    Item { width: 1; height: 18 }
    Label { text: "Oturum"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall; bottomPadding: 8 }
    Row {
        spacing: 8
        BarButton { Icon { name: "lock"; anchors.verticalCenter: parent.verticalCenter } Label { text: "Kilitle"; anchors.verticalCenter: parent.verticalCenter } onClicked: Quickshell.execDetached(["dot-shell", "lock"]) }
        BarButton { Icon { name: "bedtime"; anchors.verticalCenter: parent.verticalCenter } Label { text: "Uyku"; anchors.verticalCenter: parent.verticalCenter } onClicked: Quickshell.execDetached(["systemctl", "suspend"]) }
        BarButton { Icon { name: "logout"; anchors.verticalCenter: parent.verticalCenter } Label { text: "Oturum menüsü…"; anchors.verticalCenter: parent.verticalCenter } onClicked: Quickshell.execDetached(["dot-shell", "session"]) }
    }
}
