import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.common

// Output / input device and volume, plus per-application volume.
Column {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isStream && n.isSink)

    function nodeName(n) { return n?.nickname || n?.description || n?.name || "—"; }

    PwObjectTracker { objects: [root.sink, root.source, ...root.streams] }

    spacing: 0

    Label { text: "Çıkış"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall; bottomPadding: 4 }
    SettingRow {
        title: "Cihaz"
        Select {
            boxWidth: 320
            options: root.sinks.map(n => ({ value: n, label: root.nodeName(n) }))
            value: root.sink
            onPicked: v => Pipewire.preferredDefaultAudioSink = v
        }
    }
    Slider {
        width: parent.width
        icon: root.sink?.audio?.muted ? "volume_off" : "volume_up"
        muted: root.sink?.audio?.muted ?? false
        value: root.sink?.audio?.volume ?? 0
        onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v; }
        onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
    }

    Item { width: 1; height: 18 }
    Label { text: "Giriş"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall; bottomPadding: 4 }
    SettingRow {
        title: "Mikrofon"
        Select {
            boxWidth: 320
            options: root.sources.map(n => ({ value: n, label: root.nodeName(n) }))
            value: root.source
            onPicked: v => Pipewire.preferredDefaultAudioSource = v
        }
    }
    Slider {
        width: parent.width
        icon: root.source?.audio?.muted ? "mic_off" : "mic"
        muted: root.source?.audio?.muted ?? false
        value: root.source?.audio?.volume ?? 0
        onMoved: v => { if (root.source?.audio) root.source.audio.volume = v; }
        onIconClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
    }

    Item { width: 1; height: 18 }
    Label { text: "Uygulamalar"; color: Theme.fgDim; font.pixelSize: Theme.fontSmall; bottomPadding: 4 }
    Label { visible: root.streams.length === 0; text: "Şu an ses çalan uygulama yok"; color: Theme.fgDim; topPadding: 6 }
    Repeater {
        model: root.streams
        Column {
            required property PwNode modelData
            width: root.width
            Label { text: modelData.properties["application.name"] || root.nodeName(modelData); topPadding: 8 }
            Slider {
                width: parent.width
                icon: modelData.audio?.muted ? "volume_off" : "graphic_eq"
                muted: modelData.audio?.muted ?? false
                value: modelData.audio?.volume ?? 0
                onMoved: v => { if (modelData.audio) modelData.audio.volume = v; }
                onIconClicked: if (modelData.audio) modelData.audio.muted = !modelData.audio.muted
            }
        }
    }

    Item { width: 1; height: 14 }
    BarButton {
        Icon { name: "tune"; anchors.verticalCenter: parent.verticalCenter }
        Label { text: "Gelişmiş (pavucontrol)"; anchors.verticalCenter: parent.verticalCenter }
        onClicked: Quickshell.execDetached(["pavucontrol"])
    }
}
