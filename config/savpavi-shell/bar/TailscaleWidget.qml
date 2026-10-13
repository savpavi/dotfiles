import QtQuick
import Quickshell
import qs.common
import qs.services

// Tailscale: icon shows state; dropdown toggles the connection, picks an exit
// node and copies device IPs.
BarButton {
    id: root
    visible: ShellState.settings.showTailscale && Tailscale.state !== ""
    padding: 6

    Icon {
        name: Tailscale.exitNode ? "vpn_lock" : "lan"
        filled: Tailscale.up
        color: Tailscale.up ? Theme.primary : Theme.fgDim
        anchors.verticalCenter: parent.verticalCenter
    }

    onClicked: dd.toggle()

    Dropdown {
        id: dd
        anchorItem: root
        contentWidth: 280
        onVisibleChanged: if (visible) Tailscale.refresh()

        Column {
            width: parent.width
            spacing: 4

            MenuItem {
                icon: Tailscale.up ? "toggle_on" : "toggle_off"
                iconColor: Tailscale.up ? Theme.primary : Theme.fgDim
                text: Tailscale.up ? "Tailscale bağlı" : "Tailscale kapalı"
                detail: Tailscale.ip
                onClicked: Tailscale.setUp(!Tailscale.up)
            }

            MenuItem {
                visible: Tailscale.up && Tailscale.ip !== ""
                icon: "content_copy"
                text: "IP'yi kopyala"
                onClicked: { Quickshell.execDetached(["wl-copy", Tailscale.ip]); dd.close(); }
            }

            Label {
                visible: Tailscale.up
                text: "Cihazlar"
                color: Theme.fgDim
                font.pixelSize: Theme.fontSmall
                leftPadding: 10
                topPadding: 6
            }

            Repeater {
                model: Tailscale.up ? Tailscale.peers : []
                MenuItem {
                    required property var modelData
                    icon: modelData.os === "android" || modelData.os === "iOS" ? "smartphone" : "computer"
                    iconColor: modelData.online ? Theme.fg : Theme.fgDim
                    text: modelData.name + (Tailscale.exitNode === modelData.name ? "  (çıkış)" : "")
                    detail: modelData.ip
                    // left: copy IP, right: use / stop using as exit node
                    onClicked: button => {
                        if (button === Qt.RightButton && modelData.exitNodeOption)
                            Tailscale.setExitNode(Tailscale.exitNode === modelData.name ? "" : modelData.ip);
                        else
                            Quickshell.execDetached(["wl-copy", modelData.ip]);
                        dd.close();
                    }
                }
            }
        }
    }
}
