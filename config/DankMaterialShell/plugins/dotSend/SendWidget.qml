import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Telefon simgesi: sol tık dosya seçip KDE Connect ile yollar, sağ tık LocalSend'i açar.
// Durum ve gönderim: ~/dotfiles/bin/dot-send (status / localsend / dosya).
PluginComponent {
    id: root

    layerNamespacePlugin: "dot-send"

    readonly property string tool: Quickshell.env("HOME") + "/dotfiles/bin/dot-send"
    property var state: ({ reachable: false, device: "", paired: false, localsend: false })

    function refresh() {
        if (!statusProc.running)
            statusProc.running = true;
    }

    pillClickAction: () => {
        Quickshell.execDetached([tool]);
        refreshTimer.restart();
    }
    pillRightClickAction: () => Quickshell.execDetached([tool, "localsend"])

    Process {
        id: statusProc
        command: [root.tool, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.state = JSON.parse(text);
                } catch (e) {
                    console.warn("dotSend: durum okunamadı:", e);
                }
            }
        }
    }

    // Telefon ağa girip çıktıkça simge rengi değişsin
    Timer {
        interval: 20000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshTimer
        interval: 3000
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    horizontalBarPill: Component {
        DankIcon {
            name: root.state.reachable ? "send_to_mobile" : "mobile_off"
            size: Theme.iconSize - 6
            color: root.state.reachable ? Theme.primary : Theme.surfaceVariantText
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: root.state.reachable ? "send_to_mobile" : "mobile_off"
            size: Theme.iconSize - 6
            color: root.state.reachable ? Theme.primary : Theme.surfaceVariantText
        }
    }
}
