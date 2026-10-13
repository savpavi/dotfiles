import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Column {
    id: root

    property var info: null

    Process {
        running: true
        command: ["python3", Qt.resolvedUrl("../../scripts/sysinfo.py").toString().replace("file://", "")]
        stdout: StdioCollector { onStreamFinished: { try { root.info = JSON.parse(text); } catch (e) {} } }
    }

    spacing: 0

    SettingRow { title: "İşletim sistemi"; Label { text: root.info?.os ?? "…" } }
    SettingRow { title: "Çekirdek"; Label { text: root.info?.kernel ?? "…"; font.family: Theme.mono } }
    SettingRow { title: "Makine adı"; Label { text: root.info?.host ?? "…"; font.family: Theme.mono } }
    SettingRow { title: "Kullanıcı"; Label { text: root.info?.user ?? "…" } }
    SettingRow { title: "Açık kalma süresi"; Label { text: root.info?.uptime ?? "…" } }
    SettingRow { title: "İşlemci"; Label { text: root.info?.cpu ?? "…" } }
    SettingRow {
        title: "Ekran kartları"
        Column {
            Repeater {
                model: root.info?.gpus ?? []
                Label { required property string modelData; text: modelData; anchors.right: parent.right }
            }
        }
    }
    SettingRow {
        title: "Bellek"
        Label { text: root.info ? root.info.memory.used_gb + " / " + root.info.memory.total_gb + " GB kullanımda" : "…" }
    }
    Repeater {
        model: root.info?.disks ?? []
        SettingRow {
            required property var modelData
            title: "Disk  " + modelData.mount
            Row {
                spacing: 10
                Rectangle {
                    width: 180
                    height: 8
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.bgHighest
                    Rectangle {
                        width: parent.width * modelData.used_gb / Math.max(1, modelData.total_gb)
                        height: parent.height
                        radius: 4
                        color: modelData.used_gb / modelData.total_gb > 0.9 ? Theme.error : Theme.primary
                    }
                }
                Label { text: modelData.used_gb + " / " + modelData.total_gb + " GB"; font.family: Theme.mono; font.pixelSize: Theme.fontSmall }
            }
        }
    }
    SettingRow { title: "Hyprland"; Label { text: root.info?.hyprland ?? "…"; font.family: Theme.mono } }
    SettingRow { title: "Quickshell"; Label { text: (root.info?.quickshell ?? "…").replace(/ \(.*/, ""); font.family: Theme.mono } }

    Row {
        topPadding: 14
        spacing: 8
        BarButton {
            Icon { name: "content_copy"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Bilgileri kopyala"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: if (root.info) Quickshell.execDetached(["wl-copy", JSON.stringify(root.info, null, 2)])
        }
        BarButton {
            Icon { name: "monitoring"; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Sistem izleyici"; anchors.verticalCenter: parent.verticalCenter }
            onClicked: Quickshell.execDetached(["kitty", "--class", "btop", "btop"])
        }
    }
}
