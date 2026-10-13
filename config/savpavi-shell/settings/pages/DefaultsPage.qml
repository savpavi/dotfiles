import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Default applications per category (xdg-mime), via scripts/default-apps.py.
Column {
    id: root

    property var cats: []
    readonly property string script: Qt.resolvedUrl("../../scripts/default-apps.py").toString().replace("file://", "")

    Process {
        id: list
        running: true
        command: ["python3", root.script, "list"]
        stdout: StdioCollector { onStreamFinished: { try { root.cats = JSON.parse(text); } catch (e) {} } }
    }
    Process {
        id: setter
        onExited: list.running = true
    }

    spacing: 0

    Repeater {
        model: root.cats
        SettingRow {
            required property var modelData
            title: modelData.name
            hint: modelData.apps.length === 0 ? "Uygun uygulama bulunamadı" : ""
            Select {
                boxWidth: 300
                options: modelData.apps.map(a => ({ value: a.id, label: a.name }))
                value: modelData.current
                onPicked: v => {
                    setter.command = ["python3", root.script, "set", modelData.id, v];
                    setter.running = true;
                }
            }
        }
    }

    Label {
        topPadding: 14
        width: parent.width
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        color: Theme.fgDim
        font.pixelSize: Theme.fontSmall
        text: "Seçim, kategorinin tüm dosya türleri için ~/.config/mimeapps.list dosyasına yazılır (xdg-mime). Terminal seçimi bazı uygulamalarda TERMINAL ortam değişkenine de bağlıdır (şu an kitty)."
    }
}
