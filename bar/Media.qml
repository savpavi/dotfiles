// Çalan parça (MPRIS: Spotify, tarayıcı, mpv...). Tıkla: oynat/duraklat, tekerlek: sonraki/önceki.
import QtQuick

Item {
    id: media
    required property var sh
    property color fg: sh.b.fg
    property color dim: sh.b.faded
    property int maxWidth: 300
    property bool glyphOnly: false // dikey ray: yalnız simge

    readonly property var player: sh.player
    readonly property bool playing: player !== null && player.isPlaying

    visible: player !== null && (player.trackTitle ?? "") !== ""
    implicitWidth: visible ? (glyphOnly ? height : Math.min(Math.ceil(metrics.advanceWidth), maxWidth) + 20) : 0

    // Doğal genişlik ayrı ölçülür; Text'in kendi implicitWidth'i elide ile döngüye giriyor.
    TextMetrics { id: metrics; font: label.font; text: label.text }

    Text {
        id: label
        anchors.centerIn: parent
        width: media.glyphOnly ? implicitWidth : media.width - 20
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        font.family: media.glyphOnly ? "JetBrainsMono Nerd Font" : media.sh.b.font
        font.pixelSize: media.sh.b.fontPx + (media.glyphOnly ? 2 : 0)
        color: media.playing ? media.fg : media.dim
        text: {
            if (!media.player)
                return "";
            const icon = media.playing ? "\u{F075A}" : "\u{F03E4}";
            if (media.glyphOnly)
                return icon;
            const artist = media.player.trackArtist ?? "";
            return icon + "  " + media.player.trackTitle + (artist !== "" ? " — " + artist : "");
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: ev => {
            if (ev.button === Qt.RightButton && media.player.canRaise)
                media.player.raise();
            else if (media.player.canTogglePlaying)
                media.player.togglePlaying();
        }
        onWheel: ev => {
            if (ev.angleDelta.y < 0 && media.player.canGoNext)
                media.player.next();
            else if (ev.angleDelta.y > 0 && media.player.canGoPrevious)
                media.player.previous();
        }
    }
}
