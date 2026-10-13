import QtQuick
import qs.common
import qs.services

// Claude Code limits: a ring per limit (5-hour, weekly), details on click.
BarButton {
    id: root

    readonly property var limits: {
        const out = [];
        if (ClaudeUsage.fiveHour) out.push({ name: "5 saatlik", pct: ClaudeUsage.fiveHour.used_percentage, reset: ClaudeUsage.fiveHour.resets_at });
        if (ClaudeUsage.sevenDay) out.push({ name: "Haftalık", pct: ClaudeUsage.sevenDay.used_percentage, reset: ClaudeUsage.sevenDay.resets_at });
        return out;
    }

    function tint(pct) {
        return pct >= 90 ? Theme.error : pct >= 70 ? Theme.warning : Theme.primary;
    }

    spacing: 8

    Label {
        visible: !ClaudeUsage.ready
        text: "✳ --"
        color: Theme.fgDim
        anchors.verticalCenter: parent.verticalCenter
    }

    Repeater {
        model: root.limits
        Row {
            required property var modelData
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            UsageRing { percentage: modelData.pct; ringColor: root.tint(modelData.pct); anchors.verticalCenter: parent.verticalCenter }
            Label { text: modelData.pct + "%"; font.pixelSize: Theme.fontSmall; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    onClicked: dd.toggle()

    Dropdown {
        id: dd
        anchorItem: root
        contentWidth: 260

        Column {
            width: parent.width
            spacing: 10

            Label { text: "Claude kullanımı"; font.weight: Font.DemiBold }

            Repeater {
                model: root.limits
                Row {
                    required property var modelData
                    spacing: 10
                    UsageRing { percentage: modelData.pct; ringColor: root.tint(modelData.pct); diameter: 30; thickness: 3.5; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label { text: modelData.name + "  ·  %" + modelData.pct }
                        Label {
                            readonly property int t: ClaudeUsage.now
                            text: "sıfırlanma: " + ClaudeUsage.countdown(modelData.reset)
                            color: Theme.fgDim
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }
            }

            Label {
                visible: !ClaudeUsage.ready
                width: parent.width
                wrapMode: Text.WordWrap
                text: ClaudeUsage.failed ? "Okunamadı. Claude Code oturumu açık mı?" : "Yükleniyor…"
                color: Theme.fgDim
            }
        }
    }
}
