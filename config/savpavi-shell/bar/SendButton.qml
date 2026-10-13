import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Send to phone: left click picks a file for KDE Connect, right click opens LocalSend.
// State and sending: ~/dotfiles/bin/dot-send (status / localsend / file).
BarButton {
    id: root
    padding: 6

    readonly property string tool: Quickshell.env("HOME") + "/dotfiles/bin/dot-send"
    property var state: ({ reachable: false })

    function refresh() {
        if (!status.running) status.running = true;
    }

    Icon {
        name: root.state.reachable ? "send_to_mobile" : "mobile_off"
        color: root.state.reachable ? Theme.primary : Theme.fgDim
        anchors.verticalCenter: parent.verticalCenter
    }

    onClicked: button => {
        Quickshell.execDetached(button === Qt.RightButton ? [tool, "localsend"] : [tool]);
        later.restart();
    }

    Process {
        id: status
        command: [root.tool, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.state = JSON.parse(text); } catch (e) {}
            }
        }
    }

    Timer { interval: 20000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: later; interval: 3000; onTriggered: root.refresh() }
}
