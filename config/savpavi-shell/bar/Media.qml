import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.common
import qs.services

// Now playing + cava bars. Left: play/pause, right: player card, scroll: prev/next.
BarButton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false

    visible: ShellState.settings.showMedia && player !== null && (player.trackTitle ?? "") !== ""
    spacing: 7

    Binding { target: Cava; property: "active"; value: root.visible && root.playing && ShellState.settings.showCava }

    // cava levels
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        height: 14
        visible: root.playing && ShellState.settings.showCava

        Repeater {
            model: Cava.levels
            Rectangle {
                required property real modelData
                anchors.bottom: parent.bottom
                width: 2
                radius: 1
                height: Math.max(2, modelData * 14)
                color: Theme.primary
            }
        }
    }

    Icon {
        visible: !(root.playing && ShellState.settings.showCava)
        name: "music_note"
        color: Theme.fgDim
        anchors.verticalCenter: parent.verticalCenter
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 260)
        text: (root.player?.trackTitle ?? "") + (root.player?.trackArtist ? "  ·  " + root.player.trackArtist : "")
        color: root.playing ? Theme.fg : Theme.fgDim
    }

    onClicked: button => {
        if (button === Qt.LeftButton) root.player?.togglePlaying();
        else if (button === Qt.MiddleButton) root.player?.next();
        else card.toggle();
    }
    onScrolled: delta => delta > 0 ? root.player?.previous() : root.player?.next()

    Dropdown {
        id: card
        anchorItem: root
        contentWidth: 320

        Column {
            width: parent.width
            spacing: 12

            Row {
                spacing: 12
                width: parent.width

                Rectangle {
                    width: 72
                    height: 72
                    radius: Theme.radiusSmall
                    color: Theme.bgHighest
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Column {
                    width: parent.width - 84
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Label { width: parent.width; text: root.player?.trackTitle ?? ""; font.weight: Font.DemiBold }
                    Label { width: parent.width; text: root.player?.trackArtist ?? ""; color: Theme.fgDim }
                    Label { width: parent.width; text: root.player?.identity ?? ""; color: Theme.fgDim; font.pixelSize: Theme.fontSmall }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18
                BarButton { Icon { name: "skip_previous"; size: 22 } onClicked: root.player?.previous() }
                BarButton { Icon { name: root.playing ? "pause" : "play_arrow"; size: 22; filled: true } onClicked: root.player?.togglePlaying() }
                BarButton { Icon { name: "skip_next"; size: 22 } onClicked: root.player?.next() }
            }
        }
    }
}
